# Command History Dump

This file is a reconstructed command dump of the main shell commands used during the project session that produced the standalone triple-FP units, verification collateral, Python reference models, and documentation.

It is intended as a practical audit trail and rerun reference.

Notes:

- this is reconstructed from the development session, not copied from a persistent shell history file
- commands are grouped by purpose
- some commands were run multiple times during debugging; representative successful forms are listed here

## Workspace And Inspection

```sh
pwd
ls -la /Users/kvsaiakhil/Projects/BoomV3
ls -1 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units
sed -n '1,260p' /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv
sed -n '1,260p' /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv
sed -n '1,320p' /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv
sed -n '1,320p' /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv
sed -n '1,380p' /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv
sed -n '1,380p' /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv
rg -n "recfn|recFN|decode_recfn|encode_recfn|ieee_to_recfn|recfn_to" /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units /Users/kvsaiakhil/Projects/BoomV3
```

## HardFloat / TestFloat Bring-Up

```sh
git clone https://github.com/ucb-bar/berkeley-hardfloat /Users/kvsaiakhil/Projects/BoomV3/berkeley-hardfloat
```

Representative resulting local paths used later:

```sh
/Users/kvsaiakhil/Projects/BoomV3/berkeley-hardfloat
/Users/kvsaiakhil/Projects/BoomV3/berkeley-hardfloat/berkeley-testfloat-3/build/Linux-x86_64-GCC/testfloat_gen
```

## Tool Installation

```sh
brew install verilator svlint
```

## Directed RTL Verification

### `f64`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv
/Users/kvsaiakhil/Projects/BoomV3/obj_dir/Vtb_triple_fp_f64
```

### `f32`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_fp_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv
/Users/kvsaiakhil/Projects/BoomV3/obj_dir/Vtb_triple_fp_f32
```

## Deep Vector-Based Verification

### Vector generation

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_fp_vectors.py --n-per-seed 128
```

### `f64`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv
/Users/kvsaiakhil/Projects/BoomV3/obj_dir/Vtb_triple_fp_random_f64
```

### `f32`

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_fp_random_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv
/Users/kvsaiakhil/Projects/BoomV3/obj_dir/Vtb_triple_fp_random_f32
```

## UVM-Lite Verification

### Script-based run

```sh
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/run_uvm_lite_verilator.sh all
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/run_uvm_lite_verilator.sh f64
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/run_uvm_lite_verilator.sh f32
```

### Representative direct `f64` compile/run

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_fp_uvm_lite_f64 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/obj_dir_f64 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_pkg.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_req_if.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_rsp_if.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_cov.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_env.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/tb_triple_fp_uvm_lite_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/obj_dir_f64/Vtb_triple_fp_uvm_lite_f64
```

### Representative direct `f32` compile/run

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_fp_uvm_lite_f32 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/obj_dir_f32 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_pkg.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_req_if.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_rsp_if.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_cov.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/triple_fp_uvm_lite_env.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/tb_triple_fp_uvm_lite_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/uvm_lite/obj_dir_f32/Vtb_triple_fp_uvm_lite_f32
```

## Python Reference Models

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_add_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000

python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_add_f32 \
  --input-format ieee \
  --rm rne \
  --a 0x3f800000 \
  --b 0x40000000 \
  --c 0x40400000

python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000

python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_f32 \
  --input-format ieee \
  --rm rne \
  --a 0x3f800000 \
  --b 0x40000000 \
  --c 0x40400000

python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_add_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000 \
  --d 0x4010000000000000
```

### Sampled Python validation

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/test_reference_models.py
```

## Triple Multiply-Add Bring-Up And Verification

### Directed benches

```sh
verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_f64 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_quad_f64 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_mul_add_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe11_os53.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_quad_f64/Vtb_triple_mul_add_f64

verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_f32 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_quad_f32 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/tb_triple_mul_add_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/INToRecFN_i64_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie7_is64_oe8_os24.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_quad_f32/Vtb_triple_mul_add_f32
```

### Random vector generation and replay

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_mul_add_vectors.py --n 1024
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_mul_add_vectors.py --n 4096

verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_random_f64 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f64 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f64.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e11_s53.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f64/Vtb_triple_mul_add_random_f64

verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
  --top-module tb_triple_mul_add_random_f32 \
  -Mdir /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f32 \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/tb_triple_mul_add_random_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddPipe_l4_f32.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNPipe_l2.sv \
  /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/TripleMulAddRecFNToRaw.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundRawFNToRecFN_e8_s24.sv \
  /Users/kvsaiakhil/Projects/BoomV3/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv
/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/obj_dir_muladd_rand_f32/Vtb_triple_mul_add_random_f32
```

### Python debug commands used during the `f32` inexact investigation

```sh
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_add_f32 \
  --input-format recfn \
  --rm 0 \
  --a 0x00000000064415e18 \
  --b 0x00000000080800000 \
  --c 0x0000000006901cfb8 \
  --d 0x00000000141000000

python3 - <<'PY'
import sys
sys.path.insert(0, '/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models')
from triple_fp_reference_lib import build_model
m = build_model('triple_mul_add_f32')
r = m.run(0, 0x00000000064415e18, 0x00000000080800000, 0x0000000006901cfb8, 0x00000000141000000)
print(hex(r.final_shell_out), hex(r.final_flags))
PY
```

## Git Bring-Up And Publishing

```sh
git init -b main
git config user.name
git config user.email
git add .
git commit -m "Add standalone triple FP units project"
git remote add origin https://github.com/kvsaiakhil/triple_fp_units.git
git remote -v
ssh -T git@github.com
git remote set-url origin git@github.com:kvsaiakhil/triple_fp_units.git
git fetch origin main
git ls-remote --heads origin
git show --stat --summary origin/main
git merge origin/main --allow-unrelated-histories -m "Merge remote main before publishing triple FP units project"
git push -u origin main
git add README.md BLOCK_DIAGRAMS.md
git commit -m "Improve README and add block diagrams"
git push
```

## Notes

- some inspection commands like `sed`, `ls`, and `git status` were run many times during development; only representative forms are listed here
- the commands above cover the main build, verification, Python-reference, and Git publishing steps used during the session
diff --git a/BLOCK_DIAGRAMS.md b/BLOCK_DIAGRAMS.md
new file mode 100644
index 0000000..e932bfa
--- /dev/null
+++ b/BLOCK_DIAGRAMS.md
@@ -0,0 +1,56 @@
+# Triple-FP Block Diagrams
+
+This document collects the top-level block diagrams for the four implemented units in one place.
+
+The diagrams are also mirrored in [README.md](/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/README.md).
+
+## `TripleAddPipe_l4_f64`
+
+```mermaid
+flowchart LR
+  A["65-bit recFN shell inputs"] --> B["Wrapper Input Register"]
+  B --> C["TripleAddRecFNToRaw<br/>decode<br/>align<br/>accumulate<br/>normalize"]
+  C --> D["Inner Stage-0 Register<br/>raw bundle + rm"]
+  D --> E["RoundRawFNToRecFN_e11_s53"]
+  E --> F["Inner Stage-1 Register"]
+  F --> G["Wrapper Output Register"]
+```
+
+## `TripleAddPipe_l4_f32`
+
+```mermaid
+flowchart LR
+  A["65-bit shell inputs"] --> B["Wrapper Input Register"]
+  B --> C["Low 33-bit extract"]
+  C --> D["TripleAddRecFNToRaw<br/>decode<br/>align<br/>accumulate<br/>normalize"]
+  D --> E["Inner Stage-0 Register<br/>raw bundle + rm"]
+  E --> F["RoundRawFNToRecFN_e8_s24"]
+  F --> G["Inner Stage-1 Register"]
+  G --> H["Wrapper Output Register<br/>33-bit result repacked into 65-bit shell"]
+```
+
+## `TripleMulPipe_l4_f64`
+
+```mermaid
+flowchart LR
+  A["65-bit recFN shell inputs"] --> B["Wrapper Input Register"]
+  B --> C["TripleMulRecFNToRaw<br/>decode<br/>triple product<br/>normalize<br/>exp clamp"]
+  C --> D["Inner Stage-0 Register<br/>raw bundle + rm"]
+  D --> E["RoundRawFNToRecFN_e11_s53"]
+  E --> F["Inner Stage-1 Register"]
+  F --> G["Wrapper Output Register"]
+```
+
+## `TripleMulPipe_l4_f32`
+
+```mermaid
+flowchart LR
+  A["65-bit shell inputs"] --> B["Wrapper Input Register"]
+  B --> C["Low 33-bit extract"]
+  C --> D["TripleMulRecFNToRaw<br/>decode<br/>triple product<br/>normalize<br/>exp clamp"]
+  D --> E["Inner Stage-0 Register<br/>raw bundle + rm"]
+  E --> F["RoundRawFNToRecFN_e8_s24"]
+  F --> G["Inner Stage-1 Register"]
+  G --> H["Wrapper Output Register<br/>33-bit result repacked into 65-bit shell"]
+```
+
+## Reading Notes
+
+- `f64` units operate directly on 65-bit recFN inputs and outputs.
+- `f32` units use the BOOM-style 65-bit shell externally, but the active datapath is the low 33 bits.
+- All four units preserve the same visible 4-stage interface shape as the original FMA wrappers.
