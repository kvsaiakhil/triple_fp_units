#!/usr/bin/env python3

from __future__ import annotations

import struct
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
PY_REF_DIR = REPO_ROOT / "python_reference_models"
if str(PY_REF_DIR) not in sys.path:
    sys.path.insert(0, str(PY_REF_DIR))

from triple_fp_reference_lib import F32, F64, build_model, decode_recfn, recode_from_ieee

OUT_DIR = REPO_ROOT / "verilator4_compat" / "vectors"


def f32_bits(value: float) -> int:
    return struct.unpack(">I", struct.pack(">f", value))[0]


def f64_bits(value: float) -> int:
    return struct.unpack(">Q", struct.pack(">d", value))[0]


def shell_hex(bits: int) -> str:
    return f"{bits & ((1 << 65) - 1):017x}"


def emit_three_op(unit: str, fmt, out_path: Path, cases: list[tuple[int, int, int, int]]) -> None:
    model = build_model(unit)
    with out_path.open("w", encoding="utf-8") as fh:
        for rm, a_ieee, b_ieee, c_ieee in cases:
            a_shell = recode_from_ieee(a_ieee, fmt)
            b_shell = recode_from_ieee(b_ieee, fmt)
            c_shell = recode_from_ieee(c_ieee, fmt)
            result = model.run(rm, a_shell, b_shell, c_shell)
            cmp_mode = 1 if decode_recfn(result.final_shell_out, fmt).is_nan else 0
            fh.write(
                f"{rm:01x} {cmp_mode:01x} "
                f"{shell_hex(a_shell)} {shell_hex(b_shell)} {shell_hex(c_shell)} "
                f"{shell_hex(result.final_shell_out)} {result.final_flags:02x}\n"
            )


def emit_four_op(unit: str, fmt, out_path: Path, cases: list[tuple[int, int, int, int, int]]) -> None:
    model = build_model(unit)
    with out_path.open("w", encoding="utf-8") as fh:
        for rm, a_ieee, b_ieee, c_ieee, d_ieee in cases:
            a_shell = recode_from_ieee(a_ieee, fmt)
            b_shell = recode_from_ieee(b_ieee, fmt)
            c_shell = recode_from_ieee(c_ieee, fmt)
            d_shell = recode_from_ieee(d_ieee, fmt)
            result = model.run(rm, a_shell, b_shell, c_shell, d_shell)
            cmp_mode = 1 if decode_recfn(result.final_shell_out, fmt).is_nan else 0
            fh.write(
                f"{rm:01x} {cmp_mode:01x} "
                f"{shell_hex(a_shell)} {shell_hex(b_shell)} {shell_hex(c_shell)} {shell_hex(d_shell)} "
                f"{shell_hex(result.final_shell_out)} {result.final_flags:02x}\n"
            )


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    pos_inf_f32 = 0x7F800000
    neg_inf_f32 = 0xFF800000
    pos_zero_f32 = 0x00000000
    pos_inf_f64 = 0x7FF0000000000000
    neg_inf_f64 = 0xFFF0000000000000
    pos_zero_f64 = 0x0000000000000000

    add_mul_cases_f32 = {
        "triple_add_f32_directed.txt": ("triple_add_f32", [
            (0, f32_bits(2.0), f32_bits(3.0), f32_bits(4.0)),
            (0, pos_inf_f32, f32_bits(2.0), f32_bits(3.0)),
            (0, pos_inf_f32, neg_inf_f32, pos_zero_f32),
        ]),
        "triple_mul_f32_directed.txt": ("triple_mul_f32", [
            (0, f32_bits(2.0), f32_bits(3.0), f32_bits(4.0)),
            (0, pos_inf_f32, pos_zero_f32, f32_bits(2.0)),
        ]),
        "triple_add_f64_directed.txt": ("triple_add_f64", [
            (0, f64_bits(2.0), f64_bits(3.0), f64_bits(4.0)),
            (0, pos_inf_f64, f64_bits(2.0), f64_bits(3.0)),
            (0, pos_inf_f64, neg_inf_f64, pos_zero_f64),
        ]),
        "triple_mul_f64_directed.txt": ("triple_mul_f64", [
            (0, f64_bits(2.0), f64_bits(3.0), f64_bits(4.0)),
            (0, pos_inf_f64, pos_zero_f64, f64_bits(2.0)),
        ]),
    }

    muladd_cases = {
        "triple_mul_add_f32_directed.txt": ("triple_mul_add_f32", F32, [
            (0, f32_bits(1.0), f32_bits(2.0), f32_bits(3.0), f32_bits(4.0)),
            (0, pos_inf_f32, f32_bits(1.0), f32_bits(2.0), f32_bits(4.0)),
            (0, pos_inf_f32, pos_zero_f32, f32_bits(1.0), f32_bits(4.0)),
            (0, pos_inf_f32, f32_bits(1.0), f32_bits(2.0), neg_inf_f32),
            (0, pos_zero_f32, f32_bits(1.0), f32_bits(2.0), f32_bits(4.0)),
        ]),
        "triple_mul_add_f64_directed.txt": ("triple_mul_add_f64", F64, [
            (0, f64_bits(1.0), f64_bits(2.0), f64_bits(3.0), f64_bits(4.0)),
            (0, pos_inf_f64, f64_bits(1.0), f64_bits(2.0), f64_bits(4.0)),
            (0, pos_inf_f64, pos_zero_f64, f64_bits(1.0), f64_bits(4.0)),
            (0, pos_inf_f64, f64_bits(1.0), f64_bits(2.0), neg_inf_f64),
            (0, pos_zero_f64, f64_bits(1.0), f64_bits(2.0), f64_bits(4.0)),
        ]),
    }

    for filename, (unit, cases) in add_mul_cases_f32.items():
        fmt = F32 if "f32" in filename else F64
        emit_three_op(unit, fmt, OUT_DIR / filename, cases)

    for filename, (unit, fmt, cases) in muladd_cases.items():
        emit_four_op(unit, fmt, OUT_DIR / filename, cases)

    print(f"generated directed vectors under {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
