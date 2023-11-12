open! Core

let%expect_test "after insertion, value exists" =
  Base_quickcheck.Test.run_exn
    (module Int)
    ~f:(fun key ->
      let t = Rust_maps.create (module Int) in
      Rust_maps.set t ~key ~data:();
      [%test_pred: (int, unit, _) Rust_maps.t] (fun t -> Rust_maps.mem t key) t)
;;
