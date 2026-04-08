# Triple FP Units Spec

## Scope

This subproject adds standalone triple-operand floating-point units that match the externally visible pipeline shape of the existing BOOM/Rocket FMA wrappers:

- triple multiply: `a * b * c`
- triple add: `a + b + c`

Precisions:

- single precision (`f32`)
- double precision (`f64`)

The new units are standalone RTL blocks. They are not integrated into BOOM decode/issue/writeback.

## Design Constraints

The implementation is constrained by the local generated RTL already present in this workspace:

- the original FMA path is a 4-stage registered pipeline at the interface
- no standalone generated `AddRecFN` or `MulRecFN` modules are present
- the available reusable arithmetic leaf modules include:
  - `RoundRawFNToRecFN_e11_s53`
  - `RoundRawFNToRecFN_e8_s24`
  - `MulAddRecFNToRaw_preMul_*`
  - `MulAddRecFNToRaw_postMul_*`

This design does not chain two top-level FMA wrappers. It instead reuses the same structural pattern:

- wrapper input register
- 2-stage inner pipe
- wrapper output register

## Top-Level Modules

The new folder contains four standalone top-level modules:

- `TripleAddPipe_l4_f64`
- `TripleAddPipe_l4_f32`
- `TripleMulPipe_l4_f64`
- `TripleMulPipe_l4_f32`

Each top-level module exposes an FMA-like interface:

- `clock`
- `reset`
- `io_in_valid`
- `io_in_bits_rm`
- `io_in_bits_in1`
- `io_in_bits_in2`
- `io_in_bits_in3`
- `io_out_valid`
- `io_out_bits_data`
- `io_out_bits_exc`

Input and output data use the same recoded floating-point format already used by the local FMA path:

- `f64`: 65-bit recFN
- `f32`: carried in the same 65-bit shell as BOOM FPU wrappers, with the active value in the low 33 bits

## Pipeline Contract

The new units match the original FMA unit at the interface:

1. wrapper input capture
2. inner pipe stage 0 register
3. inner pipe stage 1 register
4. wrapper output capture

Externally, the target is the same timing shape as:

- `FPUFMAPipe_l4_f64`
- `FPUFMAPipe_l4_f32`
- `MulAddRecFNPipe_l2_e11_s53`
- `MulAddRecFNPipe_l2_e8_s24`

The new units therefore present the same 4 registered stages total from `io_in_valid` to `io_out_valid`.

## Arithmetic Semantics

### Triple add

`TripleAdd*` implements a true 3-input floating-point sum with one final rounding at the output stage:

- exact mathematical sum of `a + b + c`
- one final rounding using the supplied rounding mode
- no intermediate visible rounding between partial additions

This is intentionally different from `((a + b) + c)` if intermediate rounding would matter.

### Triple multiply

`TripleMul*` implements a true 3-input floating-point product with one final rounding at the output stage:

- exact mathematical product of `a * b * c`
- one final rounding using the supplied rounding mode
- no intermediate visible rounding between partial products

This is intentionally different from `((a * b) * c)` if intermediate rounding would matter.

## recFN Handling Rules

The implementation follows local facts visible in the generated HardFloat RTL:

- zero detect:
  - `f64`: `~(|in[63:61])`
  - `f32`: `~(|in[31:29])`
- infinity detect:
  - `f64`: `(&(in[63:62])) & ~in[61]`
  - `f32`: `(&(in[31:30])) & ~in[29]`
- NaN detect:
  - `f64`: `(&(in[63:62])) & in[61]`
  - `f32`: `(&(in[31:30])) & in[29]`
- finite nonzero hidden/significand bit:
  - `f64`: `|(in[63:61])`
  - `f32`: `|(in[31:29])`

The implementation treats the finite significand as:

- `f64`: `{ hidden, frac[51:0] }`
- `f32`: `{ hidden, frac[22:0] }`

## Raw Rounder Contract

The design uses the existing same-width rounders:

- `RoundRawFNToRecFN_e11_s53`
- `RoundRawFNToRecFN_e8_s24`

The new arithmetic cores produce:

- `invalidExc`
- `rawOut_isNaN`
- `rawOut_isInf`
- `rawOut_isZero`
- `rawOut_sign`
- `rawOut_sExp`
- `rawOut_sig`

The raw significand is formed in the same style as local HardFloat usage:

- one leading format/control bit
- one hidden/integer bit
- fraction bits
- round bit
- sticky information in the low tail

Operationally, the new cores normalize their exact finite result to the raw format expected by the rounder, then delegate final packing and exception generation to the local HardFloat rounder.

## Special-Case Policy

### Common

- signaling NaN input raises invalid and produces NaN
- quiet NaN input propagates NaN
- output NaN encoding uses the local recFN NaN exponent region

### Triple add

- if both positive and negative infinity are present in the operand set, result is invalid NaN
- otherwise, any infinity operand dominates with its sign
- if all finite magnitudes cancel exactly, output is zero

### Triple multiply

- if any zero operand and any infinity operand are both present, result is invalid NaN
- otherwise, any infinity operand dominates and sign is the xor of operand signs
- otherwise, any zero operand produces zero and sign is the xor of operand signs

## Finite Arithmetic Core

### Triple add core

Finite triple add is implemented as:

1. classify and extract sign, recoded exponent, and significand
2. choose the dominant exponent
3. align all three significands to that exponent with sticky-bit generation
4. apply signs and sum in a signed wide accumulator
5. take sign/magnitude of the exact sum
6. normalize into the raw rounder contract

### Triple multiply core

Finite triple multiply is implemented as:

1. classify and extract sign, recoded exponent, and significand
2. compute result sign as xor of operand signs
3. compute exact wide significand product
4. compute result exponent in the same recoded exponent domain
5. normalize product into the raw rounder contract

## Verification Plan

There is no reusable standalone simulation flow in the repo root. Verification collateral is therefore shipped with the units:

- standalone self-checking SV testbenches
- directed corner-case tests
- exact integer-domain tests using the local `INToRecFN_*` modules as stimulus/reference encoders

The initial testbench scope focuses on:

- exact small-integer cases
- zero / signed-zero behavior
- infinity behavior
- NaN / invalid behavior

## Non-Goals

This subproject does not:

- add new BOOM instructions
- add BOOM decode/rename/issue support
- guarantee the same post-synthesis timing slack as the original FMA path

The target is interface-equivalent pipeline depth and a local standalone verification story.

