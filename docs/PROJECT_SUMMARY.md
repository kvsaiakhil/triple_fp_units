# Triple-FP Units Project Summary

This is the top-level landing page for the standalone floating-point unit work under `triple_fp_units/`.

It points to:

- RTL implementation
- design/spec documents
- verification collateral
- Python reference/debug models

## What This Project Contains

This subproject currently includes six standalone pipelined floating-point units:

- triple add, double precision: [TripleAddPipe_l4_f64.sv](../TripleAddPipe_l4_f64.sv)
- triple add, single precision: [TripleAddPipe_l4_f32.sv](../TripleAddPipe_l4_f32.sv)
- triple multiply, double precision: [TripleMulPipe_l4_f64.sv](../TripleMulPipe_l4_f64.sv)
- triple multiply, single precision: [TripleMulPipe_l4_f32.sv](../TripleMulPipe_l4_f32.sv)
- triple multiply-add, double precision: [TripleMulAddPipe_l4_f64.sv](../TripleMulAddPipe_l4_f64.sv)
- triple multiply-add, single precision: [TripleMulAddPipe_l4_f32.sv](../TripleMulAddPipe_l4_f32.sv)

The units are standalone blocks. They are not integrated into BOOM decode, issue, or writeback.

## RTL Structure

Top wrappers:

- [TripleAddPipe_l4_f64.sv](../TripleAddPipe_l4_f64.sv)
- [TripleAddPipe_l4_f32.sv](../TripleAddPipe_l4_f32.sv)
- [TripleMulPipe_l4_f64.sv](../TripleMulPipe_l4_f64.sv)
- [TripleMulPipe_l4_f32.sv](../TripleMulPipe_l4_f32.sv)
- [TripleMulAddPipe_l4_f64.sv](../TripleMulAddPipe_l4_f64.sv)
- [TripleMulAddPipe_l4_f32.sv](../TripleMulAddPipe_l4_f32.sv)

Shared inner pipes:

- [TripleAddRecFNPipe_l2.sv](../TripleAddRecFNPipe_l2.sv)
- [TripleMulRecFNPipe_l2.sv](../TripleMulRecFNPipe_l2.sv)
- [TripleMulAddRecFNPipe_l2.sv](../TripleMulAddRecFNPipe_l2.sv)

Raw arithmetic cores:

- [TripleAddRecFNToRaw.sv](../TripleAddRecFNToRaw.sv)
- [TripleMulRecFNToRaw.sv](../TripleMulRecFNToRaw.sv)
- [TripleMulAddRecFNToRaw.sv](../TripleMulAddRecFNToRaw.sv)

All six units preserve the same visible 4-stage contract:

1. wrapper input register
2. inner pipe stage 0 register
3. inner pipe stage 1 register
4. wrapper output register

## Specs And Design Notes

Primary spec:

- [TRIPLE_FP_UNITS_SPEC.md](./TRIPLE_FP_UNITS_SPEC.md)

Additional notes:

- [SPEC_VALIDATION.md](./SPEC_VALIDATION.md)
- [BLOCK_DIAGRAMS.md](./BLOCK_DIAGRAMS.md)
- [DESIGN_CONSTRAINTS.md](./DESIGN_CONSTRAINTS.md)
- [HARDFLOAT_USAGE_AND_PROVENANCE.md](./HARDFLOAT_USAGE_AND_PROVENANCE.md)

## Verification

Top-level verification note:

- [OFFLINE_VERIFICATION.md](./OFFLINE_VERIFICATION.md)

Directed standalone benches:

- [tb_triple_fp_f64.sv](../tb_triple_fp_f64.sv)
- [tb_triple_fp_f32.sv](../tb_triple_fp_f32.sv)
- [tb_triple_mul_add_f64.sv](../tb_triple_mul_add_f64.sv)
- [tb_triple_mul_add_f32.sv](../tb_triple_mul_add_f32.sv)

Deep vector-based verification:

- [verif/README.md](../verif/README.md)
- [verif/generate_triple_fp_vectors.py](../verif/generate_triple_fp_vectors.py)
- [verif/generate_triple_mul_add_vectors.py](../verif/generate_triple_mul_add_vectors.py)
- [verif/tb_triple_fp_random_f64.sv](../verif/tb_triple_fp_random_f64.sv)
- [verif/tb_triple_fp_random_f32.sv](../verif/tb_triple_fp_random_f32.sv)
- [verif/tb_triple_mul_add_random_f64.sv](../verif/tb_triple_mul_add_random_f64.sv)
- [verif/tb_triple_mul_add_random_f32.sv](../verif/tb_triple_mul_add_random_f32.sv)

Reusable structured verification scaffold:

- [uvm_lite/README.md](../uvm_lite/README.md)
- [uvm_lite/triple_fp_uvm_lite_env.sv](../uvm_lite/triple_fp_uvm_lite_env.sv)
- [uvm_lite/triple_fp_uvm_lite_cov.sv](../uvm_lite/triple_fp_uvm_lite_cov.sv)
- [uvm_lite/run_uvm_lite_verilator.sh](../uvm_lite/run_uvm_lite_verilator.sh)

Note:

- `uvm_lite/` currently covers the original triple-add and triple-multiply families.
- the `a*b*c+d` family currently uses directed benches plus Python-backed random vector replay.

## Python Reference Models

Python staged reference/debug models live here:

- [python_reference_models/README.md](../python_reference_models/README.md)
- [python_reference_models/triple_fp_reference_lib.py](../python_reference_models/triple_fp_reference_lib.py)
- [python_reference_models/run_reference_model.py](../python_reference_models/run_reference_model.py)
- [python_reference_models/test_reference_models.py](../python_reference_models/test_reference_models.py)

These models are meant for:

- recFN format understanding
- stage-by-stage breakdown
- software-equivalent output and flag reference
- debug-friendly traces for add, multiply, and multiply-add

## Examples

Runnable examples live here:

- [examples/README.md](../examples/README.md)
- [examples/quickstart_commands.sh](../examples/quickstart_commands.sh)

## Recommended Reading Paths

If you want to understand the architecture first:

1. [README.md](../README.md)
2. [BLOCK_DIAGRAMS.md](./BLOCK_DIAGRAMS.md)
3. [TripleMulAddRecFNToRaw.sv](../TripleMulAddRecFNToRaw.sv)

If you want verification first:

1. [OFFLINE_VERIFICATION.md](./OFFLINE_VERIFICATION.md)
2. [verif/README.md](../verif/README.md)
3. [uvm_lite/README.md](../uvm_lite/README.md)

If you want the audit trail:

1. [BUG_REPORT_AND_FIXES.md](./BUG_REPORT_AND_FIXES.md)
2. [COMMAND_HISTORY_DUMP.md](./COMMAND_HISTORY_DUMP.md)
3. [PROMPT_HISTORY_DUMP.md](./PROMPT_HISTORY_DUMP.md)

If you want the software model first:

1. [python_reference_models/README.md](../python_reference_models/README.md)
2. [python_reference_models/run_reference_model.py](../python_reference_models/run_reference_model.py)
3. [python_reference_models/triple_fp_reference_lib.py](../python_reference_models/triple_fp_reference_lib.py)

## Current Project Status

As it stands, the standalone project includes:

- implemented RTL for six units
- pipeline-stage alignment with the original FMA wrapper style
- directed benches for all units
- deep vector replay for the original triple-add and triple-multiply families
- Python-backed deep vector replay for the triple-multiply-add family
- a reusable `uvm_lite/` layer for the original triple-add and triple-multiply families
- Python staged reference/debug models for all units
