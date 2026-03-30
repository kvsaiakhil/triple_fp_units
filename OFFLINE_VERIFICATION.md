# Offline Verification

This environment now has a working local HDL flow:

- `verilator 5.046`
- `svlint 0.9.5`

The standalone triple-FP units were compiled and simulated locally with Verilator in this workspace.

The folder ships:

- standalone RTL
- standalone self-checking testbenches
- a spec and a spec-validation note
- a reusable `uvm_lite/` verification scaffold

## Testbenches

- `tb_triple_fp_f64.sv`
- `tb_triple_fp_f32.sv`
- `verif/tb_triple_fp_random_f64.sv`
- `verif/tb_triple_fp_random_f32.sv`
- `uvm_lite/tb_triple_fp_uvm_lite_f64.sv`
- `uvm_lite/tb_triple_fp_uvm_lite_f32.sv`

Current testbench coverage is directed and pragmatic:

- exact small-integer add/mul cases using local `INToRecFN_*` encoders
- `+inf`
- `+inf + -inf`
- `inf * 0`

The `verif/` folder adds a larger randomized flow based on Berkeley TestFloat 3-operand operand streams.

## Suggested Compile Inputs

### Common new RTL

- `triple_fp_units/TripleAddRecFNToRaw.sv`
- `triple_fp_units/TripleMulRecFNToRaw.sv`
- `triple_fp_units/TripleAddRecFNPipe_l2.sv`
- `triple_fp_units/TripleMulRecFNPipe_l2.sv`
- `triple_fp_units/TripleAddPipe_l4_f64.sv`
- `triple_fp_units/TripleMulPipe_l4_f64.sv`
- `triple_fp_units/TripleAddPipe_l4_f32.sv`
- `triple_fp_units/TripleMulPipe_l4_f32.sv`

### Existing repo dependencies

- `RoundRawFNToRecFN_e11_s53.sv`
- `RoundRawFNToRecFN_e8_s24.sv`
- `RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv`
- `RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv`
- `RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv`
- `RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv`
- `INToRecFN_i64_e11_s53.sv`
- `INToRecFN_i64_e8_s24.sv`

## Verified Local Verilator Flow

### Tool install

```sh
brew install verilator svlint
```

### f64 testbench

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv
./obj_dir/Vtb_triple_fp_f64
```

### f32 testbench

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv
./obj_dir/Vtb_triple_fp_f32
```

### Deep random f64 bench

First regenerate vectors:

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_fp_vectors.py --n-per-seed 128
```

Then compile and run:

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv
./obj_dir/Vtb_triple_fp_random_f64
```

### Deep random f32 bench

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv
./obj_dir/Vtb_triple_fp_random_f32
```

## Example `iverilog` Flow

### f64 testbench

```sh
iverilog -g2012 -o tb_triple_fp_f64.vvp \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f64.sv
vvp tb_triple_fp_f64.vvp
```

### f32 testbench

```sh
iverilog -g2012 -o tb_triple_fp_f32.vvp \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv
vvp tb_triple_fp_f32.vvp
```

## Current Results

Directed benches still exist for bring-up and simple sanity checks:

- `tb_triple_fp_f64 PASS`
- `tb_triple_fp_f32 PASS`

For the deeper HardFloat/TestFloat-driven flow:

- the random benches exposed a triple-add cancellation/range issue and a triple-multiply exponent-wrap issue
- `TripleAddRecFNToRaw.sv` was upgraded to a wide exact finite accumulator
- `TripleMulRecFNToRaw.sv` now clamps the raw signed exponent before it reaches the HardFloat rounder

Latest observed random-regression results:

- `tb_triple_fp_random_f64 PASS (73272 checks)`
- `tb_triple_fp_random_f32 PASS (73236 checks)`

Latest observed UVM-lite replay results:

- `uvm_lite precision=64 PASS total=73272 add=36636 mul=36636`
- `uvm_lite precision=32 PASS total=73236 add=36618 mul=36618`

So the latest verified state is:

- triple add: directed and deep random benches passing
- triple multiply: directed and deep random benches passing
- structured vector-replay UVM-lite benches: passing in both precisions

## Recommended Next Verification Step

The highest-value next step is to expand the vector count beyond `--n-per-seed 128` and add more directed stress around NaN payload behavior and extreme underflow boundaries.
