proof of concept exposing `BTreeMap` to OCaml:

negative result; naive bindings are more than 10x slower
```
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
```