# Bug Report And Fixes

This document records the main implementation and verification bugs encountered during development of the standalone triple-FP units, along with the fix that was applied.

It is focused on the issues that materially affected correctness, verification quality, or reproducibility.

## 1. Triple add finite cancellation and range handling

### Symptom

The deeper randomized HardFloat/TestFloat-backed regressions exposed failing `triple add` cases, especially around:

- strong cancellation
- small residual magnitudes
- subnormal-range behavior
- wider recFN exponent spread than the initial implementation safely handled

### Root cause

The first version of the add raw core did not preserve enough exact intermediate information across the full alignment and accumulation range. That caused some cases with cancellation or tiny post-cancel results to lose the information needed for correct final normalization and rounding.

### Fix

The add raw core was reworked to use a much wider exact finite accumulator and more careful normalization handling.

Relevant files:

- [TripleAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv)
- [verif/tb_triple_fp_random_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f64.sv)
- [verif/tb_triple_fp_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv)

### Result

The random cancellation failures disappeared after the fix, and the deeper regression passed in both precisions.

## 2. Triple multiply exponent wraparound

### Symptom

The deeper randomized regressions exposed `triple multiply` mismatches in cases that should overflow. Some overflow-class products instead looked like underflow or otherwise incorrect exponent behavior.

### Root cause

The raw signed exponent for the triple product could exceed the signed range expected by the HardFloat rounder input. The earlier implementation truncated it directly into the recFN-domain signed exponent field. That allowed large positive values to wrap around into negative values.

### Fix

Clamp the raw exponent before handing it to the rounder.

Relevant file:

- [TripleMulRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv)

### Result

The overflow/underflow misclassification bug was removed, and the deep randomized multiply regressions passed in both precisions.

## 3. Standalone wrapper valid/reset behavior

### Symptom

During local verification bring-up, the standalone wrappers were susceptible to stale or poorly initialized `valid` behavior around reset.

### Root cause

The wrapper `valid` path needed explicit clean reset behavior to make the standalone benches robust and predictable.

### Fix

Reset the internal `valid`/output-valid registers cleanly in the standalone wrappers.

Relevant files:

- [TripleAddPipe_l4_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv)
- [TripleMulPipe_l4_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv)
- [TripleAddPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv)
- [TripleMulPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv)

### Result

Reset and valid timing became stable under local standalone simulation.

## 4. Testbench event-ordering races

### Symptom

Some early bench behavior was inconsistent because of race-like ordering between driving `in_valid`, clock edges, and response sampling.

### Root cause

The standalone benches needed cleaner cycle alignment around request drive and output observation.

### Fix

Adjust the benches to avoid ordering ambiguity around valid assertion/deassertion and output sampling.

Relevant files:

- [tb_triple_fp_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f64.sv)
- [tb_triple_fp_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv)

### Result

Directed simulation became stable and repeatable.

## 5. recFN vector recoding and oracle issues

### Symptom

The deeper vector flow initially had issues around:

- recFN subnormal recoding
- IEEE subnormal decode behavior
- class-aware result comparison for zeros and infinities

### Root cause

The verification-side Python/oracle path needed better handling of:

- recoded subnormal mapping
- IEEE decode details for tiny values
- recFN class/sign comparison rules for non-canonical zero/inf payload-style fields

### Fix

Improve the vector generator and bench comparison rules.

Relevant files:

- [verif/generate_triple_fp_vectors.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_fp_vectors.py)
- [uvm_lite/triple_fp_uvm_lite_pkg.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_pkg.sv)
- [verif/tb_triple_fp_random_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f64.sv)
- [verif/tb_triple_fp_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv)

### Result

The vector flow became a much stronger and more trustworthy oracle for the RTL.

## 6. UVM-lite compile/top-module bring-up issues

### Symptom

The first UVM-lite Verilator compile path built the wrong effective top because the package/source ordering and top selection were not explicit enough.

### Root cause

The compile invocation needed explicit `--top-module` selection and stable output directories.

### Fix

Update the UVM-lite run flow to:

- use explicit `--top-module`
- use dedicated `obj_dir_f32` and `obj_dir_f64`
- add a helper script for reproducible runs

Relevant files:

- [uvm_lite/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/README.md)
- [uvm_lite/run_uvm_lite_verilator.sh](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/run_uvm_lite_verilator.sh)

### Result

The UVM-lite replay flow became easy to rerun and passed in both precisions.

## 7. Documentation gap: missing project-level README and diagrams

### Symptom

The remote repo initially had only a minimal README, which made the project hard to approach for a new reader.

### Root cause

The engineering work and verification were present, but the repo landing experience was not yet aligned with the maturity of the project.

### Fix

Add:

- a detailed [README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/README.md)
- a top-level [PROJECT_SUMMARY.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/PROJECT_SUMMARY.md)
- a diagrams-only [BLOCK_DIAGRAMS.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/BLOCK_DIAGRAMS.md)

### Result

The project now has a much better handoff and onboarding path.

## Current Status

At the current project state:

- standalone triple add RTL is implemented and locally verified
- standalone triple multiply RTL is implemented and locally verified
- directed benches pass
- deep HardFloat/TestFloat-backed replay passes
- UVM-lite replay passes
- Python reference/debug models are in place

That means the bugs above are resolved in the checked-in project state.
