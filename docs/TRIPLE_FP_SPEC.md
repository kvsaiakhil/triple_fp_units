# Triple FP Units Specification

## 1. Scope

This subproject adds standalone floating-point triple-operand units built in the style of the existing BOOM/HardFloat-generated FMA path.

Target units:

- triple multiply, single precision: `a * b * c`
- triple multiply, double precision: `a * b * c`
- triple add, single precision: `a + b + c`
- triple add, double precision: `a + b + c`

These are standalone RTL blocks only. They are not integrated into BOOM decode, issue, writeback, or ISA-visible instruction handling.

## 2. Design Constraints

The implementation must satisfy these constraints:

- Do not chain two existing top-level FMA wrappers.
- Build the new units from scratch at the same abstraction level as the inner FMA datapath.
- Reuse existing leaf-style building blocks where appropriate, especially the HardFloat rounders already present in this RTL dump.
- Match the externally visible pipeline stage count of the original FMA unit.

## 3. Reference Pipeline Model

The original FMA path has 4 registered stages at the interface:

1. wrapper input capture
2. inner pipe stage 0
3. inner pipe stage 1
4. wrapper output capture

This was validated against:

- `/Users/kvsaiakhil/Projects/BoomV3/FPUFMAPipe_l4_f64.sv`
- `/Users/kvsaiakhil/Projects/BoomV3/FPUFMAPipe_l4_f32.sv`
- `/Users/kvsaiakhil/Projects/BoomV3/MulAddRecFNPipe_l2_e11_s53.sv`
- `/Users/kvsaiakhil/Projects/BoomV3/MulAddRecFNPipe_l2_e8_s24.sv`

The new units must preserve the same external valid timing:

- `io_in_valid` sampled into an input register
- two internal registered pipe stages
- `io_out_valid` driven from a final output register

## 4. External Interface

All standalone units use the same style as the existing FMA wrappers:

- `clock`
- `reset`
- `io_in_valid`
- `io_in_bits_rm`
- three recoded FP operands
- `io_out_valid`
- recoded FP result
- IEEE exception flags

Planned top-level modules:

- `TripleMulPipe_l4_f64`
- `TripleMulPipe_l4_f32`
- `TripleAddPipe_l4_f64`
- `TripleAddPipe_l4_f32`

The operand/result encoding is the existing HardFloat recFN format already used by the BOOM FPU RTL:

- f64 recFN width: 65 bits
- f32 recFN width: 33 bits, carried through a 65-bit shell when wrapped in BOOM

For these standalone units, the direct precision-native interfaces will be used:

- f64 units use 65-bit recFN input/output
- f32 units use 33-bit recFN input/output internally, with wrapper modules allowed to expose either native 33-bit or BOOM-style 65-bit shells

Implementation choice for this subproject:

- internal arithmetic will use native precision widths
- top-level standalone wrappers will expose native widths

## 5. Module Tree

Planned module hierarchy:

```text
TripleAddPipe_l4_f64
  -> TripleAddRecFNPipe_l2_e11_s53
    -> TripleAddRecFNToRaw_e11_s53
    -> RoundRawFNToRecFN_e11_s53

TripleAddPipe_l4_f32
  -> TripleAddRecFNPipe_l2_e8_s24
    -> TripleAddRecFNToRaw_e8_s24
    -> RoundRawFNToRecFN_e8_s24

TripleMulPipe_l4_f64
  -> TripleMulRecFNPipe_l2_e11_s53
    -> TripleMulRecFNToRaw_e11_s53
    -> RoundRawFNToRecFN_e11_s53

TripleMulPipe_l4_f32
  -> TripleMulRecFNPipe_l2_e8_s24
    -> TripleMulRecFNToRaw_e8_s24
    -> RoundRawFNToRecFN_e8_s24
```

The `*_ToRaw_*` blocks are new combinational arithmetic stages.

The `RoundRawFNToRecFN_*` blocks are existing generated HardFloat rounders reused directly.

## 6. Arithmetic Semantics

### 6.1 Triple Add

The triple add units implement:

- exact three-input add of the three operands
- single final rounding through the reused HardFloat rounder

This is intentionally not `((a + b) + c)` as two separately rounded additions.

Semantics:

- for finite inputs, perform a single exact aligned-significand sum
- normalize once
- round once

### 6.2 Triple Multiply

The triple multiply units implement:

- exact three-input product of the three operands
- single final rounding through the reused HardFloat rounder

This is intentionally not `(a * b) * c` as two separately rounded multiplies.

Semantics:

- for finite inputs, perform a single exact wide significand product
- compute sign and exponent in one arithmetic core
- normalize once
- round once

## 7. Special-Case Rules

### 7.1 Common NaN policy

For both add and multiply:

- if any operand is a signaling NaN, output quiet NaN and raise invalid
- else if any operand is a NaN, output quiet NaN

### 7.2 Triple Multiply special cases

For `a * b * c`:

- if any NaN exists, NaN wins
- else if any operand is zero and any operand is infinity, output NaN and raise invalid
- else if any operand is infinity, output signed infinity
- else if any operand is zero, output signed zero
- else use finite arithmetic core

### 7.3 Triple Add special cases

For `a + b + c`:

- if any NaN exists, NaN wins
- else if both positive infinity and negative infinity appear in the operand set, output NaN and raise invalid
- else if any infinity exists, output infinity with that sign
- else use finite arithmetic core

### 7.4 Zero sign

For exact-zero finite results:

- default zero sign is positive
- round-toward-minus may produce negative zero when the mathematically exact result is zero and at least one contributing term is negative

This matches the spirit of the existing HardFloat handling even if the exact tie details differ from the FMA implementation.

## 8. Finite Arithmetic Core

### 8.1 Shared input decode

Each `*_ToRaw_*` block decodes each operand into:

- `isNaN`
- `isInf`
- `isZero`
- `sign`
- recoded exponent field
- normalized significand with hidden bit

The decode style must match the existing local HardFloat/BOOM RTL:

- NaN: `(&(exp_hi)) & quiet/signaling bit`
- Inf: all exponent class bits set, quiet/signaling bit clear
- Zero: exponent-class zero
- finite hidden bit: `|(exp_class_bits)`

### 8.2 Triple Add finite core

Finite add algorithm:

1. choose `maxExp` among the three finite nonzero operands
2. form widened signed significands with extra low bits for guard/sticky handling
3. right-shift smaller operands by exponent difference with sticky collapse
4. signed-sum all three aligned terms
5. take absolute value and determine result sign
6. normalize the exact sum into the raw rounder format
7. pass raw result to `RoundRawFNToRecFN_*`

Important property:

- triple add uses exponent differences only, so it can be implemented directly in recFN exponent space without requiring an external IEEE unpack stage

### 8.3 Triple Multiply finite core

Finite multiply algorithm:

1. compute result sign as xor of input signs
2. form normalized significands including hidden bit
3. compute full exact wide product of the three significands
4. compute base recoded exponent as:
   - `expA + expB + expC - 2*K`
5. normalize the product into the raw rounder format
6. adjust the raw exponent for any normalization right-shift beyond the base case
7. pass raw result to `RoundRawFNToRecFN_*`

Where:

- `K = 1 << EXP_W`
- `EXP_W = 11` for double precision
- `EXP_W = 8` for single precision

This `K` choice is the working assumption for the recFN "1.0" reference exponent and is validated against the local rounder contract and existing HardFloat-style recoded exponent usage.

## 9. Raw Rounder Contract

The reused rounders are:

- `RoundRawFNToRecFN_e11_s53`
- `RoundRawFNToRecFN_e8_s24`

The new raw cores must feed them with:

- `isNaN`
- `isInf`
- `isZero`
- `sign`
- raw signed exponent in the same recoded-exponent space used locally by HardFloat
- normalized raw significand with extra low bits for rounding

Normalized raw significand convention used in this project:

- top two bits represent whether the value is in `[1, 2)` or `[2, 4)`
- low bits include guard/sticky information
- the rounder is allowed to apply the final exponent increment when the normalized raw significand lands in the `[2, 4)` range

## 10. Pipeline Architecture

### 10.1 Top wrapper

Each `*_l4_*` top wrapper:

- captures input valid, operands, and rounding mode
- instantiates the matching `*_l2_*` inner pipe
- captures output valid, data, and flags

### 10.2 Inner pipe

Each `*_l2_*` inner pipe:

- stage 0 register:
  - captures raw-core outputs for round stage
- stage 1 register:
  - captures rounder outputs for the wrapper

This preserves the FMA-style shape:

- wrapper input reg
- inner stage 0 reg
- inner stage 1 reg
- wrapper output reg

## 11. Planned Files

Planned implementation files:

- `TripleAddPipe_l4_f64.sv`
- `TripleAddPipe_l4_f32.sv`
- `TripleAddRecFNPipe_l2_e11_s53.sv`
- `TripleAddRecFNPipe_l2_e8_s24.sv`
- `TripleAddRecFNToRaw_e11_s53.sv`
- `TripleAddRecFNToRaw_e8_s24.sv`
- `TripleMulPipe_l4_f64.sv`
- `TripleMulPipe_l4_f32.sv`
- `TripleMulRecFNPipe_l2_e11_s53.sv`
- `TripleMulRecFNPipe_l2_e8_s24.sv`
- `TripleMulRecFNToRaw_e11_s53.sv`
- `TripleMulRecFNToRaw_e8_s24.sv`
- `tb/tb_triple_add_f64.sv`
- `tb/tb_triple_add_f32.sv`
- `tb/tb_triple_mul_f64.sv`
- `tb/tb_triple_mul_f32.sv`

## 12. Verification Plan

Verification will be delivered as standalone self-checking testbenches.

Test categories:

- normal finite values
- signed zero handling
- infinities
- NaNs
- cancellation cases for add
- carry-growth cases for add
- normalization edge cases for multiply
- overflow and underflow cases

Because no local simulator flow is present in this workspace, the repository will include:

- self-checking SV testbenches
- suggested offline compile commands

## 13. Known Risks

Main implementation risks:

- exact same-width recFN exponent interpretation in the custom multiply core
- exact zero-sign behavior for add in rare corner cases
- subnormal/underflow corner handling around the reused rounders

Mitigation:

- keep all rounding in the reused HardFloat rounders
- validate stage timing against the original FMA path
- validate raw-format assumptions against the existing local HardFloat-generated RTL before implementation
