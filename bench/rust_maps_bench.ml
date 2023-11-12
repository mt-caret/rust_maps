open! Core
open Core_bench

let seed = 42

let () =
  Command_unix.run
  @@ Bench.make_command
       [ Bench.Test.create_indexed
           ~name:"<do nothing>"
           ~args:[ 1; 10; 100; 1000; 10000 ]
           (fun len ->
              let random = Random.State.make [| seed |] in
              Staged.stage (fun () ->
                for _ = 1 to len do
                  ignore (Random.State.int random 100000 : int)
                done))
       ; Bench.Test.create_indexed
           ~name:"Rust_maps.set"
           ~args:[ 1; 10; 100; 1000; 10000 ]
           (fun len ->
              let random = Random.State.make [| seed |] in
              let map = Rust_maps.create (module Int) in
              Staged.stage (fun () ->
                for _ = 1 to len do
                  let key = Random.State.int random 100000 in
                  match Rust_maps.find map key with
                  | None -> Rust_maps.set map ~key ~data:0
                  | Some v -> Rust_maps.set map ~key ~data:(v + 1)
                done))
       ; Bench.Test.create_indexed
           ~name:"Hashtbl.set"
           ~args:[ 1; 10; 100; 1000; 10000 ]
           (fun len ->
              let random = Random.State.make [| seed |] in
              let map = Int.Table.create () in
              Staged.stage (fun () ->
                for _ = 1 to len do
                  let key = Random.State.int random 100000 in
                  match Hashtbl.find map key with
                  | None -> Hashtbl.set map ~key ~data:0
                  | Some v -> Hashtbl.set map ~key ~data:(v + 1)
                done))
       ; Bench.Test.create_indexed
           ~name:"Map.set"
           ~args:[ 1; 10; 100; 1000; 10000 ]
           (fun len ->
              let random = Random.State.make [| seed |] in
              let map = ref Int.Map.empty in
              Staged.stage (fun () ->
                for _ = 1 to len do
                  let key = Random.State.int random 100000 in
                  map
                  := match Map.find !map key with
                     | None -> Map.set !map ~key ~data:0
                     | Some v -> Map.set !map ~key ~data:(v + 1)
                done))
       ]
;;

(*
   (Rust dev profile, dune dev profile)
   $ ./_build/default/bench/rust_maps_bench.exe
   Estimated testing time 3m20s (20 benchmarks x 10s). Change using '-quota'.
   ┌─────────────────────┬─────────────────┬───────────────┬─────────────┬─────────────┬────────────┐
   │ Name                │        Time/Run │       mWd/Run │    mjWd/Run │    Prom/Run │ Percentage │
   ├─────────────────────┼─────────────────┼───────────────┼─────────────┼─────────────┼────────────┤
   │ <do nothing>:1      │          5.89ns │               │             │             │            │
   │ <do nothing>:10     │         59.44ns │               │             │             │            │
   │ <do nothing>:100    │        527.66ns │               │             │             │            │
   │ <do nothing>:1000   │      5_196.59ns │               │             │             │      0.01% │
   │ <do nothing>:10000  │     52_086.44ns │               │             │             │      0.11% │
   │ Rust_maps.set:1     │      4_895.19ns │         2.03w │             │             │      0.01% │
   │ Rust_maps.set:10    │     48_895.00ns │        20.63w │             │             │      0.10% │
   │ Rust_maps.set:100   │    488_664.37ns │       217.60w │             │             │      1.00% │
   │ Rust_maps.set:1000  │  4_888_304.61ns │     2_170.11w │       0.22w │       0.22w │     10.00% │
   │ Rust_maps.set:10000 │ 48_876_556.76ns │    21_555.72w │       1.56w │       1.56w │    100.00% │
   │ Hashtbl.set:1       │         71.57ns │         4.00w │             │             │            │
   │ Hashtbl.set:10      │        696.03ns │        39.98w │             │             │            │
   │ Hashtbl.set:100     │      6_860.13ns │       399.70w │      -0.36w │      -0.27w │      0.01% │
   │ Hashtbl.set:1000    │     68_490.15ns │     3_993.10w │      -8.28w │      -6.40w │      0.14% │
   │ Hashtbl.set:10000   │    684_488.89ns │    39_814.02w │    -222.90w │    -172.38w │      1.40% │
   │ Map.set:1           │        781.38ns │       151.00w │      31.04w │      31.04w │            │
   │ Map.set:10          │      7_861.81ns │     1_510.11w │     310.43w │     310.43w │      0.02% │
   │ Map.set:100         │     78_827.19ns │    15_105.28w │   3_107.93w │   3_107.93w │      0.16% │
   │ Map.set:1000        │    788_160.81ns │   151_160.45w │  31_145.51w │  31_145.51w │      1.61% │
   │ Map.set:10000       │  7_809_973.42ns │ 1_511_462.35w │ 311_272.37w │ 311_272.37w │     15.98% │
   └─────────────────────┴─────────────────┴───────────────┴─────────────┴─────────────┴────────────┘

   (Rust release profile, dune release profile)
   ┌─────────────────────┬─────────────────┬───────────────┬─────────────┬─────────────┬────────────┐
   │ Name                │        Time/Run │       mWd/Run │    mjWd/Run │    Prom/Run │ Percentage │
   ├─────────────────────┼─────────────────┼───────────────┼─────────────┼─────────────┼────────────┤
   │ <do nothing>:1      │          6.02ns │               │             │             │            │
   │ <do nothing>:10     │         59.24ns │               │             │             │            │
   │ <do nothing>:100    │        531.99ns │               │             │             │            │
   │ <do nothing>:1000   │      5_256.83ns │               │             │             │      0.05% │
   │ <do nothing>:10000  │     52_611.13ns │               │             │             │      0.50% │
   │ Rust_maps.set:1     │      1_054.96ns │         2.01w │             │             │            │
   │ Rust_maps.set:10    │     10_540.09ns │        20.10w │             │             │      0.10% │
   │ Rust_maps.set:100   │    105_439.22ns │       202.47w │             │             │      1.00% │
   │ Rust_maps.set:1000  │  1_053_393.33ns │     2_050.46w │       0.19w │       0.19w │      9.97% │
   │ Rust_maps.set:10000 │ 10_561_018.70ns │    20_474.03w │       0.46w │       0.46w │    100.00% │
   │ Hashtbl.set:1       │         70.38ns │         4.00w │             │             │            │
   │ Hashtbl.set:10      │        717.26ns │        39.98w │             │             │            │
   │ Hashtbl.set:100     │      6_948.15ns │       399.70w │      -0.36w │      -0.28w │      0.07% │
   │ Hashtbl.set:1000    │     69_074.36ns │     3_993.00w │      -8.40w │      -6.50w │      0.65% │
   │ Hashtbl.set:10000   │    689_474.06ns │    39_811.90w │    -225.44w │    -174.35w │      6.53% │
   │ Map.set:1           │        772.47ns │       151.00w │      31.05w │      31.05w │            │
   │ Map.set:10          │      7_780.95ns │     1_510.11w │     310.48w │     310.48w │      0.07% │
   │ Map.set:100         │     77_419.43ns │    15_105.10w │   3_107.24w │   3_107.24w │      0.73% │
   │ Map.set:1000        │    772_384.06ns │   151_156.70w │  31_136.37w │  31_136.37w │      7.31% │
   │ Map.set:10000       │  7_725_714.03ns │ 1_511_462.35w │ 311_250.52w │ 311_250.52w │     73.15% │
   └─────────────────────┴─────────────────┴───────────────┴─────────────┴─────────────┴────────────┘
*)
