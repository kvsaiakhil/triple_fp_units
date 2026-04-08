# BOOMv3 Setup

This note explains how to reproduce the original BOOMv3 / Chipyard context that was used as the reference environment for this project.

The `triple_fp_units` repo does not require this setup for normal build or verification. Use this guide only if you want to:

- inspect the original `LargeBoomV3Config` generated RTL
- trace back to the BOOM / HardFloat-generated FMA environment
- regenerate the broader BOOMv3 collateral independently

## Goal

At the end of this setup, you should have:

- a working Chipyard workspace
- the environment activated
- the `LargeBoomV3Config` Verilator build completed
- generated RTL under `sims/verilator/generated-src/.../gen-collateral/`
- the FMA RTL of interest available as `FPUFMAPipe_l4_f64.sv`

## 1. Initial Chipyard Setup

Follow the official Chipyard initial setup guide:

- [Chipyard Initial Repo Setup](https://chipyard.readthedocs.io/en/latest/Chipyard-Basics/Initial-Repo-Setup.html)

Make sure you already have either:

- Anaconda / Miniconda
- or another supported Conda distribution

installed before starting.

## 2. Prepare A Modern C/C++ Toolchain

Chipyard and its dependencies work best with a modern compiler toolchain.

On Linux:

- if your distro already provides a recent GCC or Clang, use that
- on RHEL / CentOS-like systems, you may need to enable a newer toolset, for example:

```sh
source scl_source enable gcc-toolset-14
```

On macOS:

- install current Xcode command-line tools
- ensure `clang`, `make`, and related build tools are available

If your environment needs a toolchain activation step, run it before Chipyard commands.

## 3. Build Chipyard Toolchain With Lean Conda

From the Chipyard root:

```sh
cd /path/to/chipyard
./build-setup.sh riscv-tools --use-lean-conda
```

This step:

- initializes submodules
- creates the lean conda environment
- builds the RISC-V tools

Wait for the flow to complete successfully before continuing.

## 4. Activate Chipyard Environment

After `build-setup.sh` completes:

```sh
cd /path/to/chipyard
source env.sh
```

This configures:

- `PATH`
- Chipyard tool locations
- environment variables needed by the build flow

## 5. Install OpenJDK In The Conda Environment

With the Chipyard environment active:

```sh
conda install -y openjdk=11
# or:
# mamba install -y openjdk=11
```

Verify the Java compiler:

```sh
which javac
javac -version
```

This ensures `javac` is available for FIRRTL / Scala compilation and avoids the missing-Java-compiler error during the flow.

## 6. Build The Verilator Simulator For LargeBoomV3

Go to the Verilator sim directory:

```sh
cd /path/to/chipyard/sims/verilator
```

Activate the Chipyard environment, choose one:

```sh
conda activate /path/to/chipyard/.conda-env
# or from chipyard root:
# source env.sh
```

Build the Verilator simulator:

```sh
make CONFIG=LargeBoomV3Config
```

This generates RTL for the `LargeBoomV3Config` configuration.

## 7. Locate Generated RTL And FPU Module

After a successful build, the generated RTL and collateral are under:

```text
sims/verilator/generated-src/.../gen-collateral/
```

The FPU FMA module of interest is:

```text
FPUFMAPipe_l4_f64.sv
```

This file contains the double-precision FMA pipeline RTL used as the original reference point for this project.

## 8. What To Do Next

Once you have reached this stage, you can compare the generated collateral against this standalone repo, or you can simply build this repo independently. A common standalone layout is:

```text
/path/to/triple_fp_units
```

Then return to the main repo guide here:

- [README.md](../README.md)

From there, set:

```sh
export REPO_ROOT=/path/to/triple_fp_units
export DEPS_DIR="$REPO_ROOT/deps/hardfloat"
cd "$REPO_ROOT"
```

and proceed with the standalone RTL, verification, and Python-model flows.
