open! Core

type ('key, 'value, 'cmp) t [@@deriving sexp_of, compare]

val create : ('key, 'cmp) Comparator.Module.t -> ('key, 'a, 'cmp) t
val length : (_, _, _) t -> int
val mem : ('key, _, _) t -> 'key -> bool
val set : ('key, 'value, _) t -> key:'key -> data:'value -> unit
val add : ('key, 'value, _) t -> key:'key -> data:'value -> [ `Duplicate | `Ok ]
val add_exn : ('key, 'value, _) t -> key:'key -> data:'value -> unit
val find : ('key, 'value, _) t -> 'key -> 'value option
val to_alist : ('key, 'value, _) t -> ('key * 'value) list

val of_alist_exn
  :  ('key, 'cmp) Comparator.Module.t
  -> ('key * 'value) list
  -> ('key, 'value, 'cmp) t
