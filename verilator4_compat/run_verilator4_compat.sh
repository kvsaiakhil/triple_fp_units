#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-all}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CPP_DIR="$SCRIPT_DIR/cpp"
DEPS_DIR="$REPO_ROOT/deps/hardfloat"
VECTOR_DIR="$REPO_ROOT/verif/vectors"
DIRECTED_DIR="$SCRIPT_DIR/vectors"
OBJ_BASE="${VERILATOR4_OBJ_BASE:-$SCRIPT_DIR/obj_dir}"
VERILATOR_BIN="${VERILATOR:-verilator}"

mkdir -p "$OBJ_BASE"

compile_and_run() {
  local label="$1"
  local top="$2"
  local obj_dir="$3"
  local harness="$4"
  local vector_file="$5"
  shift 5
  local rtl=("$@")

  echo "[verilator4] building $label"
  "$VERILATOR_BIN" --cc --exe --build -Wall -Wno-fatal \
    -CFLAGS -std=c++11 \
    -CFLAGS -Wno-deprecated-declarations \
    --top-module "$top" \
    -Mdir "$obj_dir" \
    "${rtl[@]}" \
    "$harness"

  echo "[verilator4] running $label"
  "$obj_dir/V${top}" "$vector_file"
}

run_directed() {
  compile_and_run "TripleAddPipe_l4_f32 directed" \
    "TripleAddPipe_l4_f32" \
    "$OBJ_BASE/add_f32_directed" \
    "$CPP_DIR/run_triple_add_f32.cpp" \
    "$DIRECTED_DIR/triple_add_f32_directed.txt" \
    "$REPO_ROOT/TripleAddPipe_l4_f32.sv" \
    "$REPO_ROOT/TripleAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  compile_and_run "TripleMulPipe_l4_f32 directed" \
    "TripleMulPipe_l4_f32" \
    "$OBJ_BASE/mul_f32_directed" \
    "$CPP_DIR/run_triple_mul_f32.cpp" \
    "$DIRECTED_DIR/triple_mul_f32_directed.txt" \
    "$REPO_ROOT/TripleMulPipe_l4_f32.sv" \
    "$REPO_ROOT/TripleMulRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  compile_and_run "TripleMulAddPipe_l4_f32 directed" \
    "TripleMulAddPipe_l4_f32" \
    "$OBJ_BASE/muladd_f32_directed" \
    "$CPP_DIR/run_triple_mul_add_f32.cpp" \
    "$DIRECTED_DIR/triple_mul_add_f32_directed.txt" \
    "$REPO_ROOT/TripleMulAddPipe_l4_f32.sv" \
    "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  compile_and_run "TripleAddPipe_l4_f64 directed" \
    "TripleAddPipe_l4_f64" \
    "$OBJ_BASE/add_f64_directed" \
    "$CPP_DIR/run_triple_add_f64.cpp" \
    "$DIRECTED_DIR/triple_add_f64_directed.txt" \
    "$REPO_ROOT/TripleAddPipe_l4_f64.sv" \
    "$REPO_ROOT/TripleAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"

  compile_and_run "TripleMulPipe_l4_f64 directed" \
    "TripleMulPipe_l4_f64" \
    "$OBJ_BASE/mul_f64_directed" \
    "$CPP_DIR/run_triple_mul_f64.cpp" \
    "$DIRECTED_DIR/triple_mul_f64_directed.txt" \
    "$REPO_ROOT/TripleMulPipe_l4_f64.sv" \
    "$REPO_ROOT/TripleMulRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"

  compile_and_run "TripleMulAddPipe_l4_f64 directed" \
    "TripleMulAddPipe_l4_f64" \
    "$OBJ_BASE/muladd_f64_directed" \
    "$CPP_DIR/run_triple_mul_add_f64.cpp" \
    "$DIRECTED_DIR/triple_mul_add_f64_directed.txt" \
    "$REPO_ROOT/TripleMulAddPipe_l4_f64.sv" \
    "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"
}

run_random() {
  compile_and_run "TripleAddPipe_l4_f32 random" \
    "TripleAddPipe_l4_f32" \
    "$OBJ_BASE/add_f32_random" \
    "$CPP_DIR/run_triple_add_f32.cpp" \
    "$VECTOR_DIR/vectors_f32_add.txt" \
    "$REPO_ROOT/TripleAddPipe_l4_f32.sv" \
    "$REPO_ROOT/TripleAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  compile_and_run "TripleMulPipe_l4_f32 random" \
    "TripleMulPipe_l4_f32" \
    "$OBJ_BASE/mul_f32_random" \
    "$CPP_DIR/run_triple_mul_f32.cpp" \
    "$VECTOR_DIR/vectors_f32_mul.txt" \
    "$REPO_ROOT/TripleMulPipe_l4_f32.sv" \
    "$REPO_ROOT/TripleMulRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  compile_and_run "TripleMulAddPipe_l4_f32 random" \
    "TripleMulAddPipe_l4_f32" \
    "$OBJ_BASE/muladd_f32_random" \
    "$CPP_DIR/run_triple_mul_add_f32.cpp" \
    "$VECTOR_DIR/vectors_f32_muladd.txt" \
    "$REPO_ROOT/TripleMulAddPipe_l4_f32.sv" \
    "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e8_s24.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  compile_and_run "TripleAddPipe_l4_f64 random" \
    "TripleAddPipe_l4_f64" \
    "$OBJ_BASE/add_f64_random" \
    "$CPP_DIR/run_triple_add_f64.cpp" \
    "$VECTOR_DIR/vectors_f64_add.txt" \
    "$REPO_ROOT/TripleAddPipe_l4_f64.sv" \
    "$REPO_ROOT/TripleAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"

  compile_and_run "TripleMulPipe_l4_f64 random" \
    "TripleMulPipe_l4_f64" \
    "$OBJ_BASE/mul_f64_random" \
    "$CPP_DIR/run_triple_mul_f64.cpp" \
    "$VECTOR_DIR/vectors_f64_mul.txt" \
    "$REPO_ROOT/TripleMulPipe_l4_f64.sv" \
    "$REPO_ROOT/TripleMulRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"

  compile_and_run "TripleMulAddPipe_l4_f64 random" \
    "TripleMulAddPipe_l4_f64" \
    "$OBJ_BASE/muladd_f64_random" \
    "$CPP_DIR/run_triple_mul_add_f64.cpp" \
    "$VECTOR_DIR/vectors_f64_muladd.txt" \
    "$REPO_ROOT/TripleMulAddPipe_l4_f64.sv" \
    "$REPO_ROOT/TripleMulAddRecFNPipe_l2.sv" \
    "$REPO_ROOT/TripleMulAddRecFNToRaw.sv" \
    "$DEPS_DIR/RoundRawFNToRecFN_e11_s53.sv" \
    "$DEPS_DIR/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"
}

echo "[verilator4] using $VERILATOR_BIN"
"$VERILATOR_BIN" --version

case "$MODE" in
  directed)
    run_directed
    ;;
  random)
    run_random
    ;;
  all)
    run_directed
    run_random
    ;;
  *)
    echo "usage: $0 {directed|random|all}" >&2
    exit 2
    ;;
esac
