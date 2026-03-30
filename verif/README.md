# Triple-FP Deep Verification

This folder extends the original directed smoke tests with a deeper HardFloat-backed vector flow.

What it uses:

- Berkeley HardFloat repo at `/Users/kvsaiakhil/Projects/BoomV3/berkeley-hardfloat`
- Berkeley TestFloat `testfloat_gen` as the 3-operand randomized source
- a local Python oracle for `a + b + c` and `a * b * c`
- Verilator replay benches for the standalone recFN RTL

Files:

- `generate_triple_fp_vectors.py`
- `tb_triple_fp_random_f64.sv`
- `tb_triple_fp_random_f32.sv`
- `vectors/`

## Current Status

The deeper flow found two real implementation issues and both are now addressed:

- `TripleAddRecFNToRaw.sv` was reworked to use a wide exact finite accumulator so cancellation and full recFN exponent spread are handled correctly
- `TripleMulRecFNToRaw.sv` now clamps the raw signed exponent before handing it to the HardFloat rounder, which fixes wrapped-overflow cases that were aliasing into underflow

The benches also compare recFN zeros and infinities by class/sign instead of assuming canonical don't-care bits.

Latest local result:

- `tb_triple_fp_random_f64 PASS (73272 checks)`
- `tb_triple_fp_random_f32 PASS (73236 checks)`
