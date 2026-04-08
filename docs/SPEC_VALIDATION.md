# Spec Validation

This note validates the spec against concrete local RTL facts.

## Pipeline Depth Validation

The original FMA path is a 4-register-stage interface:

1. wrapper input register in `FPUFMAPipe_l4_*`
2. inner pipe stage 0 register in `MulAddRecFNPipe_l2_*`
3. inner pipe stage 1 register in `MulAddRecFNPipe_l2_*`
4. wrapper output register in `FPUFMAPipe_l4_*`

Relevant references in the parent BOOM workspace:

- `FPUFMAPipe_l4_f64.sv:74`
- `FPUFMAPipe_l4_f32.sv:74`
- `MulAddRecFNPipe_l2_e11_s53.sv:115`
- `MulAddRecFNPipe_l2_e8_s24.sv:115`
- `FPUFMAPipe_l4_f64.sv:85`
- `FPUFMAPipe_l4_f32.sv:85`

This validates the 4-stage target used by the new triple units.

## recFN Classification Validation

Local generated RTL consistently classifies recFN using the following patterns:

- `f64`:
  - NaN: `(&(io_in[63:62])) & io_in[61]`
  - Inf: `(&(io_in[63:62])) & ~(io_in[61])`
  - Zero: `~(|(io_in[63:61]))`
- `f32`:
  - same pattern on the 33-bit recFN shell

Relevant references in the parent BOOM workspace:

- `RecFNToRecFN.sv:11`
- `RecFNToRecFN.sv:16`
- `RecFNToRecFN.sv:17`
- `MulAddRecFNToRaw_preMul_e11_s53.sv:25`
- `MulAddRecFNToRaw_preMul_e11_s53.sv:46`
- `MulAddRecFNToRaw_preMul_e11_s53.sv:47`

This validates the classification rules used in the spec.

## Significand Extraction Validation

Local generated RTL forms the finite significand using the hidden bit plus fraction:

- `f64`: `{ |(io_in[63:61]), io_in[51:0] }`

Relevant references in the parent BOOM workspace:

- `RecFNToRecFN.sv:19`
- `MulAddRecFNToRaw_preMul_e11_s53.sv:41`
- `MulAddRecFNToRaw_preMul_e11_s53.sv:42`

This validates the internal finite-significand extraction used in the new cores.

## Rounder Reuse Validation

The local FMA pipe uses:

- combinational `preMul`
- combinational `postMul`
- combinational `RoundRawFNToRecFN_*`

with explicit registers around those combinational blocks.

Relevant references in the parent BOOM workspace:

- `MulAddRecFNPipe_l2_e11_s53.sv:204`
- `MulAddRecFNPipe_l2_e11_s53.sv:229`
- `MulAddRecFNPipe_l2_e11_s53.sv:256`
- `MulAddRecFNPipe_l2_e8_s24.sv:204`
- `MulAddRecFNPipe_l2_e8_s24.sv:229`
- `MulAddRecFNPipe_l2_e8_s24.sv:256`

This validates reusing the same-width rounders inside a new 2-stage inner pipe.

## Verification Flow Validation

The repo does not contain a reusable standalone simulation harness for new modules. The practical path is to ship dedicated self-checking testbenches.

Useful local pattern in the parent BOOM workspace:

- `TestDriver.v:10`

This validates the verification plan in the spec.
