# Examples

This folder provides practical example runs for the standalone floating-point units in this repo.

It is aimed at two use cases:

- getting a new user from zero to a first successful run quickly
- showing concrete commands for RTL simulation and Python-model exploration

Assumed shell variables:

```sh
export BOOMV3_ROOT=/path/to/BoomV3
export REPO_ROOT="$BOOMV3_ROOT/triple_fp_units"
cd "$REPO_ROOT"
```

## Files

- [quickstart_commands.sh](./quickstart_commands.sh)
  a copy-paste friendly command collection
- [STAGE_BY_STAGE_EXAMPLES.txt](./STAGE_BY_STAGE_EXAMPLES.txt)
  a plain-text walkthrough with one worked pipeline example for each implemented unit
- [RANDOM_STAGE_BY_STAGE_EXAMPLES.txt](./RANDOM_STAGE_BY_STAGE_EXAMPLES.txt)
  a second plain-text walkthrough using deterministic random floating-point inputs

## Example 1: Python model for `a*b*c+d` in `f64`

```sh
python3 "$REPO_ROOT/python_reference_models/run_reference_model.py" \
  --unit triple_mul_add_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000 \
  --d 0x4010000000000000
```

What this does:

- decodes the operands into recFN form
- shows the major intermediate stages
- prints the final output and flags

## Example 2: Directed RTL bench for `a*b*c+d` in `f32`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_f32 \
  -Mdir "$REPO_ROOT/obj_dir_quad_f32" \
  "$REPO_ROOT/tb_triple_mul_add_f32.sv" \
  "$REPO_ROOT/TripleMulAddPipe_l4_f32.sv" \
  "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
  "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
  "$BOOMV3_ROOT/INToRecFN_i64_e8_s24.sv" \
  "$BOOMV3_ROOT/RoundRawFNToRecFN_e8_s24.sv" \
  "$BOOMV3_ROOT/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv" \
  "$BOOMV3_ROOT/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv"
"$REPO_ROOT/obj_dir_quad_f32/Vtb_triple_mul_add_f32"
```

Expected result:

- `tb_triple_mul_add_f32 PASS`

## Example 3: Random replay for `a*b*c+d`

Generate vectors:

```sh
python3 "$REPO_ROOT/verif/generate_triple_mul_add_vectors.py" --n 4096
```

Run replay:

```sh
"$REPO_ROOT/obj_dir_muladd_rand_f64/Vtb_triple_mul_add_random_f64"
"$REPO_ROOT/obj_dir_muladd_rand_f32/Vtb_triple_mul_add_random_f32"
```

Expected results after a successful build:

- `tb_triple_mul_add_random_f64 PASS (4096 checks)`
- `tb_triple_mul_add_random_f32 PASS (4096 checks)`

## Example 4: Original triple-add / triple-multiply flows

These units are still part of the repo and can be explored in the same way:

- `triple_add_f64`
- `triple_add_f32`
- `triple_mul_f64`
- `triple_mul_f32`

See:

- [README.md](../README.md)
- [OFFLINE_VERIFICATION.md](../docs/OFFLINE_VERIFICATION.md)
- [python_reference_models/README.md](../python_reference_models/README.md)
