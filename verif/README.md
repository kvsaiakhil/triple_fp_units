# Triple-FP Deep Verification

This folder extends the original directed smoke tests with deeper vector-replay flows.

There are now two deep-verification backbones:

- Berkeley TestFloat-backed operand streams for `a+b+c` and `a*b*c`
- Python-reference-backed random vectors for `a*b*c+d`

## What It Uses

For the original 3-operand flows:

- Berkeley HardFloat repo at `/Users/kvsaiakhil/Projects/BoomV3/berkeley-hardfloat`
- Berkeley TestFloat `testfloat_gen` as the randomized operand source
- a local Python oracle for `a + b + c` and `a * b * c`
- Verilator replay benches for the standalone recFN RTL

For the new 4-operand flow:

- the staged Python model in [python_reference_models/triple_fp_reference_lib.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/triple_fp_reference_lib.py)
- a random vector generator for `a*b*c+d`
- Verilator replay benches for the standalone recFN RTL

## Files

Original triple-op deep flow:

- [generate_triple_fp_vectors.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_fp_vectors.py)
- [tb_triple_fp_random_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f64.sv)
- [tb_triple_fp_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv)

New triple-multiply-add deep flow:

- [generate_triple_mul_add_vectors.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_mul_add_vectors.py)
- [tb_triple_mul_add_random_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f64.sv)
- [tb_triple_mul_add_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f32.sv)
- [vectors/](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/vectors)

## Current Status

The original triple-op deep flow found two real implementation issues and both are already fixed:

- [TripleAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv) was reworked to use a wide exact finite accumulator so cancellation and full recFN exponent spread are handled correctly
- [TripleMulRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv) now clamps the raw signed exponent before handing it to the HardFloat rounder, which fixes wrapped-overflow cases

The new `a*b*c+d` flow is Python-oracle-backed rather than TestFloat-backed, because the external source only provides 3-operand streams.

The replay benches compare recFN zeros and infinities by class and sign instead of assuming canonical don't-care bits.

Latest observed local results for the new `a*b*c+d` flow:

- `tb_triple_mul_add_random_f64 PASS (4096 checks)`
- `tb_triple_mul_add_random_f32 PASS (4096 checks)`

## Example Commands

Regenerate `a*b*c+d` vectors:

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_mul_add_vectors.py --n 4096
```

Run `f64` replay:

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_random_f64 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f64 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f64/Vtb_triple_mul_add_random_f64
```

Run `f32` replay:

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_random_f32 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f32 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f32/Vtb_triple_mul_add_random_f32
```
