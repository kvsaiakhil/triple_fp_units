# Triple-FP Python Reference Models

This folder contains Python reference/debug models for the standalone custom FP units in this repo:

- `TripleAddPipe_l4_f64`
- `TripleAddPipe_l4_f32`
- `TripleMulPipe_l4_f64`
- `TripleMulPipe_l4_f32`
- `TripleMulAddPipe_l4_f64`
- `TripleMulAddPipe_l4_f32`

The goal is understanding first:

- show the recFN format breakdown per operand
- mirror the visible wrapper and inner-pipe stages
- expose the main intermediate values from each raw combinational substage
- provide a software reference result for the final output and exception flags

## Files

- `triple_fp_reference_lib.py`
  shared recFN helpers, staged model classes, and pretty-print support
- `run_reference_model.py`
  CLI entry point for one-off debug runs
- `test_reference_models.py`
  lightweight validation against the existing vector corpus

## Model Scope

These Python models are intended as:

- a readable functional reference
- a recFN-format exploration tool
- a stage-by-stage debug aid

They are not trying to reimplement the internal HardFloat rounder gate-for-gate.
Instead, they do two things:

- match the custom triple-add/triple-mul raw-core structure closely
- use a software rounding/reference path for the final packed result

So the raw-stage debug values are designed to line up with the RTL, while the final output is a practical software-equivalent result.

## Stage Mapping

### Triple Add

- `stage0_capture`
  wrapper input register in `TripleAddPipe_l4_*`
- `stage1_decode_special`
  raw-core class decode and special-case arbitration in `TripleAddRecFNToRaw`
- `stage1_align`
  `minExp`, significand extension, and wide alignment
- `stage1_accumulate`
  signed accumulation and exact-zero handling
- `stage1_normalize_raw`
  raw pre-round normalization into `raw_sign/raw_sExp/raw_sig`
- `stage2_round_register`
  captured raw bundle in `TripleAddRecFNPipe_l2`
- `stage3_output`
  software-equivalent final output and wrapper-format result

### Triple Multiply

- `stage0_capture`
  wrapper input register in `TripleMulPipe_l4_*`
- `stage1_decode_special`
  raw-core class decode and special-case arbitration in `TripleMulRecFNToRaw`
- `stage1_finite_product`
  hidden-bit significands, exact triple product, and scaled product
- `stage1_normalize_raw`
  normalization and signed-exponent clamp
- `stage2_round_register`
  captured raw bundle in `TripleMulRecFNPipe_l2`
- `stage3_output`
  software-equivalent final output and wrapper-format result

### Triple Multiply-Add

- `stage0_capture`
  wrapper input register in `TripleMulAddPipe_l4_*`
- `stage1_decode_special`
  raw-core class decode and special-case arbitration in `TripleMulAddRecFNToRaw`
- `stage1_finite_product`
  exact `a*b*c` product formation before the addend merge
- `stage1_add_normalize`
  addend alignment, signed accumulation, and raw-result shaping
- `stage2_round_register`
  captured raw bundle in `TripleMulAddRecFNPipe_l2`
- `stage3_output`
  software-equivalent final output and wrapper-format result

## Example Usage

### Triple add, f64, IEEE inputs

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_add_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000
```

### Triple mul, f32, recFN-shell inputs

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_f32 \
  --input-format recfn \
  --rm rtz \
  --a 0x00000000040000000 \
  --b 0x00000000040800000 \
  --c 0x00000000041000000
```

### Triple mul-add, f64, IEEE inputs

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_add_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000 \
  --d 0x4010000000000000
```

## Validation

To run the lightweight local check against the existing verification vectors:

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/test_reference_models.py
```

That script samples the existing vector files and checks that the Python model output matches the expected result/class and exception flags.
