# Triple FP Spec Validation

This note records the local RTL facts used to validate the design in `TRIPLE_FP_SPEC.md`.

## 1. FMA Stage Match

The original FMA path is 4 registered stages at the interface:

1. wrapper input capture
2. inner pipe stage 0
3. inner pipe stage 1
4. wrapper output capture

Validated from the parent BOOM workspace:

- `FPUFMAPipe_l4_f64.sv:74`
- `FPUFMAPipe_l4_f32.sv:74`
- `MulAddRecFNPipe_l2_e11_s53.sv:115`
- `MulAddRecFNPipe_l2_e8_s24.sv:115`

The spec preserves this shape exactly.

## 2. Reused Rounders Are Valid Standalone Leaves

The same-width rounders are already present and self-contained in the parent BOOM workspace:

- `RoundRawFNToRecFN_e11_s53.sv`
- `RoundRawFNToRecFN_e8_s24.sv`

These wrap:

- `RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv`
- `RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv`

So it is valid to build new arithmetic units that terminate in these exact rounders.

## 3. Local RecFN Decode Rules Are Reusable

The existing generated RTL repeatedly uses the same recFN decode rules:

- zero detected from zero exponent-class bits
- infinity detected from all exponent-class bits set and NaN bit clear
- NaN detected from all exponent-class bits set and NaN bit set
- finite hidden bit derived from nonzero exponent class

Concrete examples in the parent BOOM workspace:

- `MulAddRecFNToRaw_preMul_e11_s53.sv`
- `MulAddRecFNToRaw_preMul_e8_s24.sv`
- `RecFNToRecFN.sv`

This validates using the same decode style in the new `*_ToRaw_*` blocks.

## 4. Raw Rounder Interface Can Be Driven By New Arithmetic Cores

The rounders accept:

- `isNaN`
- `isInf`
- `isZero`
- `sign`
- raw signed exponent
- raw significand with extra rounding bits

The existing generated RTL already drives these rounders from nontrivial arithmetic blocks, so the same contract can be honored by new standalone raw cores.

Examples in the parent BOOM workspace:

- `MulAddRecFNPipe_l2_e11_s53.sv:256`
- `MulAddRecFNPipe_l2_e8_s24.sv:256`

## 5. Addition Core Feasibility

Triple add is strongly validated as feasible because:

- addition alignment only depends on exponent differences
- the recFN exponent field ordering is already used directly in local arithmetic alignment logic
- the final normalization and IEEE flagging can be delegated to the existing rounder

The spec therefore keeps triple add as:

- exact aligned sum
- one final round

## 6. Multiply Core Feasibility

Triple multiply is feasible with one implementation assumption:

- the recFN "1.0" reference exponent is modeled as `1 << EXP_W`

Why this assumption is acceptable:

- the local generated arithmetic uses recoded exponent fields directly rather than unpacking to IEEE exponent first
- the final same-width rounding is delegated to the existing HardFloat rounders
- the new core only needs a consistent recFN-domain exponent reference to normalize the exact wide product before final rounding

This is the main arithmetic assumption that must be checked by the supplied offline testbenches.

## 7. Verification Constraint

There is no reusable standalone simulator flow in this repo.

Validation of the spec therefore means:

- local structural validation against existing RTL contracts
- delivery of standalone self-checking SV testbenches for offline simulation

The implementation phase will preserve this validation model.
