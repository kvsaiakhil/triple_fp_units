#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TRIPLE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
UVM_LITE_DIR="${TRIPLE_DIR}/uvm_lite"
DEPS_DIR="${TRIPLE_DIR}/deps/hardfloat"

run_f64() {
  verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
    --top-module tb_triple_fp_uvm_lite_f64 \
    -Mdir "${UVM_LITE_DIR}/obj_dir_f64" \
    "${UVM_LITE_DIR}/triple_fp_uvm_lite_pkg.sv" \
    "${UVM_LITE_DIR}/triple_fp_req_if.sv" \
    "${UVM_LITE_DIR}/triple_fp_rsp_if.sv" \
    "${UVM_LITE_DIR}/triple_fp_uvm_lite_cov.sv" \
    "${UVM_LITE_DIR}/triple_fp_uvm_lite_env.sv" \
    "${UVM_LITE_DIR}/tb_triple_fp_uvm_lite_f64.sv" \
    "${TRIPLE_DIR}/TripleAddPipe_l4_f64.sv" \
    "${TRIPLE_DIR}/TripleAddRecFNPipe_l2.sv" \
    "${TRIPLE_DIR}/TripleAddRecFNToRaw.sv" \
    "${TRIPLE_DIR}/TripleMulPipe_l4_f64.sv" \
    "${TRIPLE_DIR}/TripleMulRecFNPipe_l2.sv" \
    "${TRIPLE_DIR}/TripleMulRecFNToRaw.sv" \
    "${DEPS_DIR}/RoundRawFNToRecFN_e11_s53.sv" \
    "${DEPS_DIR}/RoundAnyRawFNToRecFN_ie11_is55_oe11_os53.sv"

  "${UVM_LITE_DIR}/obj_dir_f64/Vtb_triple_fp_uvm_lite_f64"
}

run_f32() {
  verilator --binary --timing -Wall -Wno-fatal -Wno-UNUSEDSIGNAL \
    --top-module tb_triple_fp_uvm_lite_f32 \
    -Mdir "${UVM_LITE_DIR}/obj_dir_f32" \
    "${UVM_LITE_DIR}/triple_fp_uvm_lite_pkg.sv" \
    "${UVM_LITE_DIR}/triple_fp_req_if.sv" \
    "${UVM_LITE_DIR}/triple_fp_rsp_if.sv" \
    "${UVM_LITE_DIR}/triple_fp_uvm_lite_cov.sv" \
    "${UVM_LITE_DIR}/triple_fp_uvm_lite_env.sv" \
    "${UVM_LITE_DIR}/tb_triple_fp_uvm_lite_f32.sv" \
    "${TRIPLE_DIR}/TripleAddPipe_l4_f32.sv" \
    "${TRIPLE_DIR}/TripleAddRecFNPipe_l2.sv" \
    "${TRIPLE_DIR}/TripleAddRecFNToRaw.sv" \
    "${TRIPLE_DIR}/TripleMulPipe_l4_f32.sv" \
    "${TRIPLE_DIR}/TripleMulRecFNPipe_l2.sv" \
    "${TRIPLE_DIR}/TripleMulRecFNToRaw.sv" \
    "${DEPS_DIR}/RoundRawFNToRecFN_e8_s24.sv" \
    "${DEPS_DIR}/RoundAnyRawFNToRecFN_ie8_is26_oe8_os24.sv"

  "${UVM_LITE_DIR}/obj_dir_f32/Vtb_triple_fp_uvm_lite_f32"
}

usage() {
  echo "Usage: $0 [f64|f32|all]"
}

mode="${1:-all}"

case "${mode}" in
  f64)
    run_f64
    ;;
  f32)
    run_f32
    ;;
  all)
    run_f64
    run_f32
    ;;
  *)
    usage
    exit 1
    ;;
esac
