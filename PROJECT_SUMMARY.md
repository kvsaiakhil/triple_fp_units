# Triple-FP Units Project Summary

This document is the top-level landing page for the standalone triple floating-point units project under `/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units`.

It points to:

- RTL implementation
- design/spec documents
- verification collateral
- Python reference/debug models

## What This Project Contains

This subproject adds four standalone pipelined floating-point units:

- triple add, double precision: [TripleAddPipe_l4_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv)
- triple add, single precision: [TripleAddPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv)
- triple multiply, double precision: [TripleMulPipe_l4_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv)
- triple multiply, single precision: [TripleMulPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv)

The units are standalone blocks, not integrated into BOOM decode/issue/writeback.

## RTL Structure

Top wrappers:

- [TripleAddPipe_l4_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv)
- [TripleAddPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv)
- [TripleMulPipe_l4_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv)
- [TripleMulPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv)

Shared inner pipes:

- [TripleAddRecFNPipe_l2.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv)
- [TripleMulRecFNPipe_l2.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv)

Raw arithmetic cores:

- [TripleAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv)
- [TripleMulRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv)

The externally visible pipeline shape matches the original FMA wrapper style:

1. wrapper input register
2. inner pipe stage 0 register
3. inner pipe stage 1 register
4. wrapper output register

## Specs And Design Notes

Primary spec:

- [TRIPLE_FP_UNITS_SPEC.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TRIPLE_FP_UNITS_SPEC.md)

Earlier design/spec notes:

- [TRIPLE_FP_SPEC.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TRIPLE_FP_SPEC.md)
- [TRIPLE_FP_SPEC_VALIDATION.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TRIPLE_FP_SPEC_VALIDATION.md)
- [SPEC_VALIDATION.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/SPEC_VALIDATION.md)

## Verification

Top-level offline verification note:

- [OFFLINE_VERIFICATION.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/OFFLINE_VERIFICATION.md)

Directed standalone benches:

- [tb_triple_fp_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f64.sv)
- [tb_triple_fp_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv)

Deeper vector-based verification:

- [verif/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/README.md)
- [generate_triple_fp_vectors.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_fp_vectors.py)
- [tb_triple_fp_random_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f64.sv)
- [tb_triple_fp_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv)

Reusable structured verification scaffold:

- [uvm_lite/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/README.md)
- [triple_fp_uvm_lite_env.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_env.sv)
- [triple_fp_uvm_lite_cov.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_cov.sv)
- [run_uvm_lite_verilator.sh](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/run_uvm_lite_verilator.sh)

## Python Reference Models

Python staged reference/debug models live here:

- [python_reference_models/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/README.md)
- [triple_fp_reference_lib.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/triple_fp_reference_lib.py)
- [run_reference_model.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py)
- [test_reference_models.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/test_reference_models.py)

These models are meant for:

- recFN format understanding
- stage-by-stage breakdown
- software-equivalent output/flag reference
- debug-friendly traces for add and multiply

## Recommended Reading Paths

If you want to understand the architecture first:

1. [TRIPLE_FP_UNITS_SPEC.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TRIPLE_FP_UNITS_SPEC.md)
2. [TripleAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv)
3. [TripleMulRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv)

If you want to understand verification first:

1. [OFFLINE_VERIFICATION.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/OFFLINE_VERIFICATION.md)
2. [verif/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/README.md)
3. [uvm_lite/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/README.md)

If you want an intuitive functional view first:

1. [python_reference_models/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/README.md)
2. [run_reference_model.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py)
3. [triple_fp_reference_lib.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/triple_fp_reference_lib.py)

## Current Project Status

As it stands, the standalone project includes:

- implemented RTL for all four units
- pipeline-stage alignment with the original FMA wrapper style
- directed benches
- deeper HardFloat/TestFloat-backed vector verification
- a UVM-lite reusable verification layer
- Python staged reference/debug models

For the standalone-unit goal, this project is in a strong completed state.
