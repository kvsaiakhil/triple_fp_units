#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path

from triple_fp_reference_lib import (
    VECTOR_DIR,
    F32,
    F64,
    build_model,
    decode_recfn,
    parse_hex,
    recfn_matches_expected,
)


def iter_cases(path: Path, limit: int):
    count = 0
    with path.open("r", encoding="utf-8") as fh:
        for line in fh:
            toks = line.strip().split()
            if len(toks) != 7:
                continue
            rm, cmp_mode, in1, in2, in3, exp_out, exp_exc = [parse_hex(tok) for tok in toks]
            yield rm, cmp_mode, in1, in2, in3, exp_out, exp_exc
            count += 1
            if count >= limit:
                break


def check_case(unit: str, fmt, rm: int, cmp_mode: int, in1: int, in2: int, in3: int, exp_out: int, exp_exc: int) -> None:
    model = build_model(unit)
    result = model.run(rm, in1, in2, in3)
    if cmp_mode == 0:
        assert recfn_matches_expected(result.final_shell_out, exp_out, fmt), (
            unit,
            hex(in1),
            hex(in2),
            hex(in3),
            hex(result.final_shell_out),
            hex(exp_out),
        )
    else:
        assert decode_recfn(result.final_shell_out, fmt).is_nan
    assert result.final_flags == (exp_exc & 0x1F), (
        unit,
        hex(in1),
        hex(in2),
        hex(in3),
        hex(result.final_flags),
        hex(exp_exc),
    )


def main() -> int:
    suites = [
        ("triple_add_f64", F64, VECTOR_DIR / "vectors_f64_add.txt"),
        ("triple_mul_f64", F64, VECTOR_DIR / "vectors_f64_mul.txt"),
        ("triple_add_f32", F32, VECTOR_DIR / "vectors_f32_add.txt"),
        ("triple_mul_f32", F32, VECTOR_DIR / "vectors_f32_mul.txt"),
    ]
    per_file = 32
    for unit, fmt, path in suites:
        for rm, cmp_mode, in1, in2, in3, exp_out, exp_exc in iter_cases(path, per_file):
            check_case(unit, fmt, rm, cmp_mode, in1, in2, in3, exp_out, exp_exc)
        print(f"{unit}: PASS ({per_file} sampled vectors)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
