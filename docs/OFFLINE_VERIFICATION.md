# Offline Verification

This workspace was verified with a local HDL flow based on:

- `verilator`
- `svlint`

The standalone floating-point units in this folder were compiled and simulated locally with Verilator.

Assumed shell variables:

```sh
export REPO_ROOT=/path/to/triple_fp_units
export DEPS_DIR="$REPO_ROOT/deps/hardfloat"
cd "$REPO_ROOT"
```

## What Ships In This Folder

- standalone RTL
- standalone self-checking directed testbenches
- deep vector-replay benches
- a spec and design notes
- a reusable `uvm_lite/` verification scaffold for the original triple-op families
- Python staged reference/debug models for all implemented units

## Testbenches

Directed benches:

- `tb_triple_fp_f64.sv`
- `tb_triple_fp_f32.sv`
- `tb_triple_mul_add_f64.sv`
- `tb_triple_mul_add_f32.sv`

Deep replay benches:

- `verif/tb_triple_fp_random_f64.sv`
- `verif/tb_triple_fp_random_f32.sv`
- `verif/tb_triple_mul_add_random_f64.sv`
- `verif/tb_triple_mul_add_random_f32.sv`

Structured replay:

- `uvm_lite/tb_triple_fp_uvm_lite_f64.sv`
- `uvm_lite/tb_triple_fp_uvm_lite_f32.sv`

## Suggested Compile Inputs

New RTL in this subproject:

- `TripleAddRecFNToRaw.sv`
- `TripleMulRecFNToRaw.sv`
- `TripleMulAddRecFNToRaw.sv`
- `TripleAddRecFNPipe_l2.sv`
- `TripleMulRecFNPipe_l2.sv`
- `TripleMulAddRecFNPipe_l2.sv`
- `TripleAddPipe_l4_f64.sv`
- `TripleMulPipe_l4_f64.sv`
- `TripleMulAddPipe_l4_f64.sv`
- `TripleAddPipe_l4_f32.sv`
- `TripleMulPipe_l4_f32.sv`
- `TripleMulAddPipe_l4_f32.sv`

Vendored local dependencies:

- `deps/hardfloat/RoundRawFNToRecFN_e11_s53.sv`
- `deps/hardfloat/RoundRawFNToRecFN_e8_s24.sv`
- `deps/hardfloat/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv`
- `deps/hardfloat/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv`
- `deps/hardfloat/RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv`
- `deps/hardfloat/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv`
- `deps/hardfloat/INToRecFN_i64_e11_s53.sv`
- `deps/hardfloat/INToRecFN_i64_e8_s24.sv`

## Tool Install

macOS:

```sh
brew install verilator python svlint
```

Linux:

```sh
sudo apt update
sudo apt install -y build-essential git python3 python3-pip verilator
```

Optional `svlint` on Linux:

```sh
sudo apt install -y cargo
cargo install svlint
```

## Verified Local Flows

### Directed `a*b*c+d` `f64`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_f64 \
  -Mdir "$REPO_ROOT/obj_dir_quad_f64" \
  "$REPO_ROOT/tb_triple_mul_add_f64.sv" \
  "$REPO_ROOT/TripleMulAddPipe_l4_f64.sv" \
  "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
  "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
  "$DEPS_DIR/INToRecFN_i64_e11_s53.sv" \
  "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
  "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv" \
  "$DEPS_DIR/RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv"
"$REPO_ROOT/obj_dir_quad_f64/Vtb_triple_mul_add_f64"
```

Observed result:

- `tb_triple_mul_add_f64 PASS`

### Directed `a*b*c+d` `f32`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_f32 \
  -Mdir "$REPO_ROOT/obj_dir_quad_f32" \
  "$REPO_ROOT/tb_triple_mul_add_f32.sv" \
  "$REPO_ROOT/TripleMulAddPipe_l4_f32.sv" \
  "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
  "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
  "$DEPS_DIR/INToRecFN_i64_e8_s24.sv" \
  "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
  "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv" \
  "$DEPS_DIR/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv"
"$REPO_ROOT/obj_dir_quad_f32/Vtb_triple_mul_add_f32"
```

Observed result:

- `tb_triple_mul_add_f32 PASS`

### Deep random `a*b*c+d`

First regenerate vectors:

```sh
python3 "$REPO_ROOT/verif/generate_triple_mul_add_vectors.py" --n 4096
```

Then run `f64`:

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_random_f64 \
  -Mdir "$REPO_ROOT/obj_dir_muladd_rand_f64" \
  "$REPO_ROOT/verif/tb_triple_mul_add_random_f64.sv" \
  "$REPO_ROOT/TripleMulAddPipe_l4_f64.sv" \
  "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
  "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
  "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
  "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"
"$REPO_ROOT/obj_dir_muladd_rand_f64/Vtb_triple_mul_add_random_f64"
```

Then run `f32`:

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_random_f32 \
  -Mdir "$REPO_ROOT/obj_dir_muladd_rand_f32" \
  "$REPO_ROOT/verif/tb_triple_mul_add_random_f32.sv" \
  "$REPO_ROOT/TripleMulAddPipe_l4_f32.sv" \
  "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
  "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
  "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
  "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"
"$REPO_ROOT/obj_dir_muladd_rand_f32/Vtb_triple_mul_add_random_f32"
```

Observed results:

- `tb_triple_mul_add_random_f64 PASS (4096 checks)`
- `tb_triple_mul_add_random_f32 PASS (4096 checks)`

### Existing Verified Flows

From the earlier triple-op project work:

- `tb_triple_fp_f64 PASS`
- `tb_triple_fp_f32 PASS`
- `tb_triple_fp_random_f64 PASS (73272 checks)`
- `tb_triple_fp_random_f32 PASS (73236 checks)`
- `uvm_lite precision=64 PASS total=73272 add=36636 mul=36636`
- `uvm_lite precision=32 PASS total=73236 add=36618 mul=36618`

## Notes

- the `a*b*c+d` deep flow is Python-reference-backed, not TestFloat-backed
- the new family currently is not yet wired into the `uvm_lite/` environment
- Verilator may emit width-related warnings in the wide `f64` add/align path, but the bench still builds and runs
