#![feature(never_type)]
use core::cmp::Ordering;
use std::borrow::Borrow;
use std::{cell::RefCell, collections::BTreeMap, rc::Rc};

use ocaml_interop::{
    ocaml_export, BoxRoot, DynBox, FromOCaml, OCaml, OCamlInt, OCamlList, OCamlRef, OCamlRuntime,
    ToOCaml,
};

struct Untyped {}

struct UntypedBoxRoot(BoxRoot<Untyped>);

impl UntypedBoxRoot {
    fn copy(&self, cr: &mut OCamlRuntime) -> Self {
        UntypedBoxRoot(self.0.to_boxroot(cr))
    }
}

// impl UntypedBoxRoot {
//     fn interpret<'a, T>(&self, cr: &'a OCamlRuntime) -> OCaml<'a, T> {
//         let ocaml_value: OCaml<Untyped> = self.0.get(cr);
//
//         unsafe { OCaml::new(cr, ocaml_value.raw()) }
//     }
// }

unsafe impl FromOCaml<Untyped> for UntypedBoxRoot {
    fn from_ocaml(v: OCaml<Untyped>) -> Self {
        UntypedBoxRoot(v.root())
    }
}

unsafe impl ToOCaml<Untyped> for UntypedBoxRoot {
    fn to_ocaml<'a>(&self, cr: &'a mut OCamlRuntime) -> OCaml<'a, Untyped> {
        self.0.get(cr)
    }
}

#[derive(Debug, Clone)]
struct Abstract<T>(T);

unsafe impl<T: 'static + Clone> FromOCaml<DynBox<T>> for Abstract<T> {
    fn from_ocaml(v: OCaml<DynBox<T>>) -> Self {
        Abstract(Borrow::<T>::borrow(&v).clone())
    }
}

unsafe impl<T: 'static + Clone> ToOCaml<DynBox<T>> for Abstract<T> {
    fn to_ocaml<'a>(&self, cr: &'a mut OCamlRuntime) -> OCaml<'a, DynBox<T>> {
        OCaml::box_value(cr, self.0.clone())
    }
}

struct Comparable {
    value: UntypedBoxRoot,
    compare: BoxRoot<fn(Untyped, Untyped) -> OCamlInt>,
}

impl Comparable {
    fn call_compare(&self, other: &Self, cr: &mut OCamlRuntime) -> i64 {
        let compare_result: OCaml<OCamlInt> = self
            .compare
            .try_call(cr, &self.value, &other.value)
            .map_err(|exception| {
                exception
                    .message()
                    .unwrap_or("<Empty exception>".to_string())
            })
            .expect("compare function unexpectedly raised");

        compare_result.to_i64()
    }
}

impl PartialEq for Comparable {
    fn eq(&self, other: &Self) -> bool {
        let cr = unsafe { OCamlRuntime::recover_handle() };

        self.call_compare(other, cr) == 0
    }
}

impl Eq for Comparable {}

impl Ord for Comparable {
    fn cmp(&self, other: &Self) -> Ordering {
        let cr = unsafe { OCamlRuntime::recover_handle() };

        let compare_result = self.call_compare(other, cr);

        match compare_result {
            0 => Ordering::Equal,
            _ if compare_result < 0 => Ordering::Less,
            _ => Ordering::Greater,
        }
    }
}

impl PartialOrd for Comparable {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

struct Map {
    map: BTreeMap<Comparable, UntypedBoxRoot>,
    compare: BoxRoot<fn(Untyped, Untyped) -> OCamlInt>,
}

impl Map {
    fn mint_key(&self, key: UntypedBoxRoot, cr: &mut OCamlRuntime) -> Comparable {
        Comparable {
            value: key,
            compare: self.compare.to_boxroot(cr),
        }
    }
}

type WrappedMap = Rc<RefCell<Map>>;

ocaml_export! {
    fn rust_map_create(cr, compare: OCamlRef<fn(Untyped, Untyped) -> OCamlInt>) -> OCaml<DynBox<WrappedMap>> {
        let map = Map {
            map: BTreeMap::new(),
            compare: compare.to_boxroot(cr),
        };

        OCaml::box_value(cr, Rc::new(RefCell::new(map)))
    }

    fn rust_map_mem(cr, map: OCamlRef<DynBox<WrappedMap>>, key: OCamlRef<Untyped>) -> OCaml<bool> {
        let Abstract(map) = map.to_rust(cr);
        let key: UntypedBoxRoot = key.to_rust(cr);
        let map = map.borrow_mut();
        let key = map.mint_key(key, cr);

        //cr.releasing_runtime(|| map.map.contains_key(&key)).to_ocaml(cr)
        map.map.contains_key(&key).to_ocaml(cr)
    }

    fn rust_map_set(cr, map: OCamlRef<DynBox<WrappedMap>>, key: OCamlRef<Untyped>, data: OCamlRef<Untyped>) -> OCaml<bool> {
        let Abstract(map) = map.to_rust(cr);
        let key: UntypedBoxRoot = key.to_rust(cr);
        let data: UntypedBoxRoot = data.to_rust(cr);
        let mut map = map.borrow_mut();
        let key = map.mint_key(key, cr);

        let is_duplicate = map.map.insert(key, data).is_some();

        is_duplicate.to_ocaml(cr)
    }

    fn rust_map_find(cr, map: OCamlRef<DynBox<WrappedMap>>, key: OCamlRef<Untyped>) -> OCaml<Option<Untyped>> {
        let Abstract(map) = map.to_rust(cr);
        let key: UntypedBoxRoot = key.to_rust(cr);
        let map = map.borrow_mut();
        let key = map.mint_key(key, cr);

        //cr.releasing_runtime(|| map.map.get(&key)).map(|boxroot| boxroot.to_boxroot(cr)).to_ocaml(cr)
        map.map.get(&key).map(|boxroot| boxroot.to_boxroot(cr)).to_ocaml(cr)
    }

    fn rust_map_remove(cr, map: OCamlRef<DynBox<WrappedMap>>, key: OCamlRef<Untyped>) -> OCaml<()> {
        let Abstract(map) = map.to_rust(cr);
        let key: UntypedBoxRoot = key.to_rust(cr);
        let mut map = map.borrow_mut();
        let key = map.mint_key(key, cr);

        cr.releasing_runtime(|| map.map.remove(&key));

        OCaml::unit()
    }

    fn rust_map_length(cr, map: OCamlRef<DynBox<WrappedMap>>) -> OCaml<OCamlInt> {
        let Abstract(map) = map.to_rust(cr);
        let map = map.borrow_mut();

        (map.map.len() as i64).to_ocaml(cr)
    }

    fn rust_map_to_alist(cr, map: OCamlRef<DynBox<WrappedMap>>) -> OCaml<OCamlList<(Untyped, Untyped)>> {
        let Abstract(map) = map.to_rust(cr);
        let map = map.borrow_mut();

        let alist: Vec<(UntypedBoxRoot, UntypedBoxRoot)> =
            map.map.iter().map(|(key, value)| (key.value.copy(cr), value.copy(cr))).collect();

        alist.to_ocaml(cr)
    }
}
