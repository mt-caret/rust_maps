open! Core

let () =
  let random = Random.State.make [| 42 |] in
  let map = Rust_maps.create (module Int) in
  for _ = 1 to 1_000_000 do
    let key = Random.State.int random 100000 in
    match Rust_maps.find map key with
    | None -> Rust_maps.set map ~key ~data:0
    | Some v -> Rust_maps.set map ~key ~data:(v + 1)
  done
;;
