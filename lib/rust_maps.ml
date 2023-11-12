open! Core

module Raw = struct
  type ('key, 'value) t

  external create : compare:('key -> 'key -> int) -> ('key, _) t = "rust_map_create"
  external length : (_, _) t -> int = "rust_map_length"
  external mem : ('key, _) t -> 'key -> bool = "rust_map_mem"
  external set : ('key, 'value) t -> key:'key -> data:'value -> bool = "rust_map_set"
  external find : ('key, 'value) t -> 'key -> 'value option = "rust_map_find"
  external to_alist : ('key, 'value) t -> ('key * 'value) list = "rust_map_to_alist"
end

type ('key, 'value, 'cmp) t =
  { raw : ('key, 'value) Raw.t
  ; comparator : ('key, 'cmp) Comparator.t
  }

let create (type key cmp) ((module C) : (key, cmp) Comparator.Module.t) =
  let comparator = C.comparator in
  { raw = Raw.create ~compare:comparator.compare; comparator }
;;

let length t = Raw.length t.raw
let mem t key = Raw.mem t.raw key
let set t ~key ~data = ignore (Raw.set t.raw ~key ~data : bool)

let add t ~key ~data =
  let is_duplicate = Raw.set t.raw ~key ~data in
  if is_duplicate then `Duplicate else `Ok
;;

let add_exn t ~key ~data =
  match add t ~key ~data with
  | `Ok -> ()
  | `Duplicate ->
    let error =
      Error.create "Rust_maps.add_exn got key already present" key t.comparator.sexp_of_t
    in
    Error.raise error
;;

let find t key = Raw.find t.raw key
let to_alist t = Raw.to_alist t.raw

let compare key_compare data_compare _cmp_compare t1 t2 =
  if phys_equal t1 t2
  then 0
  else
    (* TODO: This is kind of slow, and should probably be implemented in Rust *)
    List.compare
      (Tuple2.compare ~cmp1:key_compare ~cmp2:data_compare)
      (to_alist t1)
      (to_alist t2)
;;

let of_alist_or_error comparator_module lst =
  let t = create comparator_module in
  let rec go = function
    | [] -> Ok t
    | (key, data) :: rest ->
      (match add t ~key ~data with
       | `Ok -> go rest
       | `Duplicate ->
         Or_error.error "Rust_maps.of_alist_exn: duplicate key" key t.comparator.sexp_of_t)
  in
  go lst
;;

let of_alist_exn comparator_module lst =
  match of_alist_or_error comparator_module lst with
  | Ok t -> t
  | Error err -> Error.raise err
;;

let sexp_of_t sexp_of_key sexp_of_data _sexp_of_cmp t =
  [%sexp_of: (key * data) list] (to_alist t)
;;
