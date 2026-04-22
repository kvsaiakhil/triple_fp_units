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
- a top-level [PROJECT_SUMMARY.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/docs/PROJECT_SUMMARY.md)
- a diagrams-only [BLOCK_DIAGRAMS.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/docs/BLOCK_DIAGRAMS.md)

### Result

The project now has a much better handoff and onboarding path.

## 8. Triple multiply-add lost inexact information in `f32`

### Symptom

During deeper random replay of the new `a*b*c+d` units, the `f32` bench exposed cases where:

- the final result bits matched the software oracle
- but the exception flags did not match
- specifically, the RTL was returning `inexact = 0` on cases that should have raised `inexact = 1`

### Root cause

The first version of the triple multiply-add raw core compressed the exact triple product down to raw-rounder width before adding the fourth operand `d`.

That preserved the rounded value in many cases, but it could discard information that mattered for final sticky/inexact behavior after the `product + d` accumulation step. In other words, the add was happening against a pre-compressed product term rather than the full exact product.

### Fix

Rework the raw core so the add uses the full exact triple product and only normalizes down to the HardFloat raw-rounder contract after the `product + d` accumulation.

Relevant files:

- [TripleMulAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv)
- [verif/tb_triple_mul_add_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f32.sv)
- [verif/tb_triple_mul_add_random_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f64.sv)
- [python_reference_models/triple_fp_reference_lib.py](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/triple_fp_reference_lib.py)

### Result

After the fix:

- directed `a*b*c+d` benches passed in both precisions
- random replay passed in both precisions
- the `f32` flag mismatch disappeared
- the implementation now preserves exact-product information long enough to generate the correct final `inexact` flag

## 9. Presto elaboration loop-limit failure in MSB search helpers

### Symptom

When compiling the standalone units under Synopsys Presto / Design Compiler, elaboration could fail with:

- `ELAB-900: Loop exceeded maximum iteration limit`

The first reported case was in the `f32` triple-add path, but the same loop style existed in the other raw cores as well.

### Root cause

The original MSB-search helper functions used a reverse-counting `for` loop and manually forced loop termination by assigning to the loop variable inside the loop body.

That style worked in Verilator, but it is not friendly to all synthesis elaborators.

### Fix

Rewrite the MSB-search helpers to use a simple forward-counting loop with no manual loop-variable modification. The final matching bit position still becomes the highest set bit.

Relevant files:

- [TripleAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv)
- [TripleMulRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv)
- [TripleMulAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv)

### Result

The raw cores are more synthesis-friendly across tools, and the Presto loop-limit failure is removed.

## 10. `f32` shell-bit synthesis lint noise

### Symptom

In the `f32` wrappers, synthesis lint could report large groups of unconnected top-level input bits because the wrappers intentionally use only the low 33 bits of the 65-bit BOOM-style shell.

### Root cause

The interface preserves BOOM compatibility at the wrapper boundary, but the higher shell bits are intentionally inactive for the local `f32` datapath.

### Fix

Connect the upper shell bits to explicit local wires in the `f32` wrappers so the shell is structurally consumed in a synthesis-friendly way while keeping behavior unchanged.

Relevant files:

- [TripleAddPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv)
- [TripleMulPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv)
- [TripleMulAddPipe_l4_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f32.sv)

### Result

The wrappers remain BOOM-shell-compatible, but the `f32` interface is friendlier to synthesis lint and structural checks.

## 11. Verilator 4.x CLI and bench incompatibilities

### Symptom

When trying to run the repo on older Verilator 4.x releases, several failures appeared immediately:

- `Invalid option: --binary`
- unsupported newer warning-control flags such as `-Wno-UNUSEDSIGNAL`
- `%Error-UNSUPPORTED: timing control statement in this location`

The last class of failure came from the modern SystemVerilog bench style used by the main directed, random-replay, and UVM-lite benches.

### Root cause

The default repo verification flow was written and validated primarily for Verilator 5.x. That flow assumes:

- newer CLI options such as `--binary`
- newer warning-switch support
- broader support for the current timing-control placement used in the SystemVerilog benches

The arithmetic RTL itself was mostly acceptable to Verilator 4.x, but the surrounding bench and invocation infrastructure was not.

### Fix

Add a dedicated Verilator 4.x compatibility layer rather than weakening the main 5.x flow.

That compatibility layer:

- replaces the unsupported SV bench flow with explicit C++ runners
- uses 4.x-compatible Verilator invocation flags
- reuses the checked-in random vector corpus
- adds small directed vector files for the legacy flow
- documents the separate legacy run path

Relevant files:

- [verilator4_compat/README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verilator4_compat/README.md)
- [verilator4_compat/run_verilator4_compat.sh](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verilator4_compat/run_verilator4_compat.sh)
- [verilator4_compat/cpp/run_three_op_vectors.h](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verilator4_compat/cpp/run_three_op_vectors.h)
- [verilator4_compat/cpp/run_four_op_vectors.h](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verilator4_compat/cpp/run_four_op_vectors.h)
- [tb_triple_fp_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv)
- [verif/tb_triple_fp_random_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv)
- [uvm_lite/triple_fp_uvm_lite_env.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_env.sv)

### Result

The repo now has two supported paths:

- the default modern Verilator 5.x flow
- a separate tested Verilator 4.x compatibility flow for older tool installations

This keeps the main verification path modern while still giving legacy environments a practical way to run and verify the units.

## Current Status

At the current project state:

- standalone triple add RTL is implemented and locally verified
- standalone triple multiply RTL is implemented and locally verified
- standalone triple multiply-add RTL is implemented and locally verified
- directed benches pass
- deep HardFloat/TestFloat-backed replay passes
- Python-backed deep replay for triple multiply-add passes
- UVM-lite replay passes
- Python reference/debug models are in place

That means the bugs above are resolved in the checked-in project state.
