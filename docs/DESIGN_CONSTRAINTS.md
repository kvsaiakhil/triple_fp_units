# Design Constraints

This document collects the design constraints that shaped the standalone floating-point units in this project.

It covers the original triple-add and triple-multiply units, and the later triple-multiply-add (`a*b*c+d`) units.

## 1. Project Scope Constraints

- The units must be standalone RTL blocks.
- They are not integrated into BOOM decode, rename, issue, writeback, or ISA decode.
- They must live comfortably inside the BOOM/Chipyard-generated RTL environment already present in this workspace.

## 2. Pipeline Contract Constraints

- The externally visible pipeline shape must match the original BOOM/HardFloat FMA wrapper style.
- The required visible shape is:
  1. wrapper input register
  2. inner pipe stage 0 register
  3. inner pipe stage 1 register
  4. wrapper output register
- The goal is latency-shape compatibility, not guaranteed identical post-synthesis timing slack or Fmax.

## 3. Reuse Constraints

- Do not build the new functionality by chaining two top-level FMA wrapper blocks together.
- Reuse the existing infrastructure already present in the environment where practical.
- The main reusable pieces are:
  - recFN conventions
  - HardFloat rounders
  - integer-to-recFN conversion modules for testbench stimulus
  - the wrapper/inner-pipe structure seen in the existing FMA path

## 4. Arithmetic-Construction Constraints

- The arithmetic raw cores must be custom implementations built specifically for:
  - `a+b+c`
  - `a*b*c`
  - `a*b*c+d`
- The implementations should use exact or sufficiently wide intermediate arithmetic so one final rounding is performed at the output contract.
- Intermediate structure may be inspired by the FMA path, but the new units are not simple repackagings of existing top-level FMA blocks.

## 5. Format Constraints

- `f64` uses the same 65-bit recFN shell already used by the local BOOM/HardFloat-generated RTL.
- `f32` keeps the same 65-bit shell externally, with the active recFN value in the low 33 bits.
- The units must preserve the local rounding-mode and exception-flag interface style.

## 6. HardFloat Interface Constraints

- The new raw cores must emit the same style of pre-round bundle expected by the existing HardFloat rounders:
  - invalid
  - isNaN
  - isInf
  - isZero
  - sign
  - signed exponent
  - raw significand
- Final recFN packing and exception-flag generation should continue to use the existing HardFloat rounders already in the repo.

## 7. Verification Constraints

- The project must be verifiable in a local offline flow.
- Directed self-checking benches are required.
- Deeper replay-based verification is required.
- Python reference/debug models are required for understanding and cross-checking the units.
- Where available, Berkeley HardFloat/TestFloat infrastructure should be reused to improve confidence.

## 8. Documentation Constraints

- The repo should explain:
  - architecture and hierarchy
  - pipeline stages
  - verification flows
  - Python reference models
  - provenance of HardFloat-related ideas and dependencies
- The root of the repo should remain readable, with the detailed project docs placed under [docs](./).

## 9. Practical Constraints Found During Implementation

- `triple add` needed a very wide exact accumulator to survive cancellation and subnormal-range cases.
- `triple multiply` needed signed-exponent clamping before the HardFloat rounder.
- `triple multiply-add` needed the fourth operand to be added against the full exact triple product, not a pre-compressed product term, in order to preserve correct `inexact` behavior.

## 10. Resulting Design Philosophy

The final project follows this rule set:

- keep the visible BOOM/HardFloat pipeline contract
- reuse the local recFN/rounder ecosystem
- build the arithmetic middle stages as custom standalone datapaths
- verify deeply enough that the units are useful as real standalone reference RTL
