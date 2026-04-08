# Quickstart command examples for the standalone triple-FP repo.
# Copy and paste the commands you want to run.

cd /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units

# 1. Python reference model for triple multiply-add, f64.
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/run_reference_model.py \
  --unit triple_mul_add_f64 \
  --input-format ieee \
  --rm rne \
  --a 0x3ff0000000000000 \
  --b 0x4000000000000000 \
  --c 0x4008000000000000 \
  --d 0x4010000000000000

# 2. Directed f64 bench for triple multiply-add.
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

# 3. Generate random vectors for the triple multiply-add family.
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/generate_triple_mul_add_vectors.py --n 4096

# 4. Deep random replay for triple multiply-add, f64.
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

# 5. Python sanity-check sweep across the available units.
python3 /Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/python_reference_models/test_reference_models.py
