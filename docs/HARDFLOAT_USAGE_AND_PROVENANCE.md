# HardFloat Usage And Provenance

This document explains what parts of Berkeley HardFloat were used directly or indirectly by the custom standalone units in this repo, and what parts were newly implemented here.

It is meant to answer a simple question clearly:

What in this project is HardFloat-derived infrastructure, and what in this project is our own custom arithmetic RTL?

## Executive Summary

Directly used from the local HardFloat-generated environment:

- existing rounders
- existing recFN format conventions
- existing integer-to-recFN conversion modules in testbenches

Indirectly used:

- the FMA pipeline split style
- the raw pre-round contract shape
- recFN classification conventions and special-case semantics
- HardFloat/TestFloat-based verification ideas and tooling

Custom in this project:

- the new multi-operand arithmetic raw cores
- the new alignment, accumulation, normalization, and exact-product logic for the standalone units
- the standalone wrappers and dedicated benches for the new units

## 1. Direct HardFloat-Related Dependencies

The new units directly instantiate the existing rounder modules already present in the BOOM/Chipyard RTL tree:

- [RoundRawFNToRecFN_e11_s53.sv](/Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv)
- [RoundRawFNToRecFN_e8_s24.sv](/Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv)

Those rounders are used in:

- [TripleAddRecFNPipe_l2.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv)
- [TripleMulRecFNPipe_l2.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv)
- [TripleMulAddRecFNPipe_l2.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv)

These modules are not reimplemented here. The project reuses them as existing infrastructure.

## 2. Direct Testbench-Side HardFloat Dependencies

The directed benches use the existing integer-to-recFN conversion modules for stimulus and exact integer references:

- [INToRecFN_i64_e11_s53.sv](/Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e11_s53.sv)
- [INToRecFN_i64_e8_s24.sv](/Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e8_s24.sv)

These are used in:

- [tb_triple_fp_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f64.sv)
- [tb_triple_fp_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv)
- [tb_triple_mul_add_f64.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_mul_add_f64.sv)
- [tb_triple_mul_add_f32.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_mul_add_f32.sv)

Again, these are reused as existing local infrastructure rather than rewritten.

## 3. Indirect HardFloat Influence On The New RTL

The custom units follow several HardFloat conventions indirectly:

- recFN shell widths and field layout
- classification style for zero, infinity, and NaN
- the pre-round raw bundle shape consumed by `RoundRawFNToRecFN_*`
- special-case handling expectations for invalid, infinity, zero, and NaN

The units also inherit the same broad structural idea seen in local FMA pipelines:

- wrapper-level input capture
- inner pipe carrying a pre-round bundle
- existing HardFloat rounder
- wrapper-level output capture

## 4. What Was Not Directly Copied

The following were not copied as arithmetic implementations into the new standalone raw cores:

- the existing HardFloat fused multiply-add arithmetic datapath
- a stock HardFloat `addRecFN` datapath
- a stock HardFloat `mulRecFN` datapath
- a stock HardFloat `mulAddRecFNToRaw` arithmetic core

In particular, the following files contain custom arithmetic logic written specifically for this project:

- [TripleAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv)
- [TripleMulRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv)
- [TripleMulAddRecFNToRaw.sv](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv)

Those files implement:

- custom multi-input alignment
- custom exact accumulation
- custom exact triple-product handling
- custom normalization before handing results to the existing rounders

## 5. BOOM / Chipyard Influence Versus HardFloat Influence

It is useful to separate the roles:

BOOM / Chipyard contributed:

- the generated environment where these units were studied and implemented
- the wrapper style and integration context that motivated the pipeline contract
- the local generated RTL files that exposed the active recFN shell style

HardFloat contributed:

- the recFN conventions
- the raw pre-round contract shape
- the rounders
- the general arithmetic and verification vocabulary used by the surrounding ecosystem

## 6. Verification Influence From HardFloat / TestFloat

HardFloat and its companion tooling influenced verification in two ways:

- by providing the local rounder behavior and recFN conventions that the benches compare against
- by enabling the Berkeley TestFloat-backed replay flow used earlier for the triple-add and triple-multiply families

For the later `a*b*c+d` unit family, the project reused the same style of verification thinking, but the random vector flow is Python-reference-backed because the external source used in this project is naturally 3-operand-oriented.

## 7. Bottom Line

The cleanest provenance summary is:

- the arithmetic raw cores are custom project RTL
- the round/final-pack stage is reused HardFloat infrastructure
- the recFN ecosystem and verification style are strongly HardFloat-influenced
- the project is not a direct copy of HardFloat arithmetic modules, but it is intentionally built to live inside a HardFloat-style environment
