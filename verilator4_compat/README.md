# Verilator 4.x Compatibility

This folder provides a compatibility verification flow for older Verilator 4.x environments.

The main repo verification flow is written for modern Verilator 5.x and uses:

- `--binary`
- newer warning-switch names
- newer SystemVerilog bench timing-control support

Older Verilator releases such as `4.038` do not support that flow directly.

This compatibility layer keeps the RTL unchanged and adds:

- C++ runners that instantiate the standalone RTL tops directly
- a shell script that builds and runs each unit with Verilator 4.x
- a small directed vector corpus for quick smoke testing
- reuse of the existing checked-in random replay vectors for broader coverage

## What Is Covered

Supported unit tops:

- `TripleAddPipe_l4_f32`
- `TripleAddPipe_l4_f64`
- `TripleMulPipe_l4_f32`
- `TripleMulPipe_l4_f64`
- `TripleMulAddPipe_l4_f32`
- `TripleMulAddPipe_l4_f64`

Supported verification modes:

- `directed`
- `random`
- `all`

Notes:

- The 4.x compatibility flow does not use the original SV self-checking benches.
- The 4.x compatibility flow does not run the `uvm_lite/` environment.
- It compares the unit outputs against checked-in vector files instead.

## Layout

- `cpp/`
  C++ runners and shared helper code
- `vectors/`
  small directed vector files generated from the Python reference models
- `run_verilator4_compat.sh`
  main entry point for the legacy flow
- `generate_directed_vectors.py`
  regenerates the directed vector files if needed

## Requirements

- Verilator 4.x in `PATH`, or set `VERILATOR=/path/to/verilator`
- a C++ compiler with C++11 support
- `python3` only if you want to regenerate the directed vectors

## Quick Start

From the repo root:

```sh
export REPO_ROOT=/path/to/triple_fp_units
cd "$REPO_ROOT"

bash verilator4_compat/run_verilator4_compat.sh directed
```

Run the broader vector replay:

```sh
bash verilator4_compat/run_verilator4_compat.sh random
```

Run both:

```sh
bash verilator4_compat/run_verilator4_compat.sh all
```

## Selecting A Specific Verilator 4.x Binary

If your 4.x binary is not the default `verilator` in `PATH`:

```sh
export VERILATOR=/path/to/verilator-4.x/bin/verilator
bash verilator4_compat/run_verilator4_compat.sh all
```

## Regenerating Directed Vectors

The directed vectors are checked in, but you can regenerate them:

```sh
python3 verilator4_compat/generate_directed_vectors.py
```

This uses the Python reference models already present in the repo.

## Output Directories

By default, object files are written under:

```text
verilator4_compat/obj_dir/
```

To override that:

```sh
export VERILATOR4_OBJ_BASE=/tmp/verilator4_obj
bash verilator4_compat/run_verilator4_compat.sh all
```

## Compatibility Summary

This layer exists because older Verilator releases do not accept some of the current repo assumptions.

In particular, Verilator 4.x differs from the default 5.x flow in:

- no `--binary`
- different warning-switch vocabulary
- stricter support for timing-control placement in SV testbenches

Driving the unit tops from C++ avoids those bench-language limitations while keeping the RTL under test the same.
