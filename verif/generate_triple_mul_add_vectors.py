#!/usr/bin/env python3

from __future__ import annotations

import argparse
import random
import sys
from pathlib import Path

ROOT = Path("/Users/kvsaiakhil/Projects/BoomV3")
PY_REF_DIR = ROOT / "triple_fp_units/python_reference_models"
if str(PY_REF_DIR) not in sys.path:
    sys.path.insert(0, str(PY_REF_DIR))

from triple_fp_reference_lib import (
    F32,
    F64,
    ROUNDING_NAMES,
    build_model,
    decode_recfn,
    recode_from_ieee,
)
OUT_DIR = ROOT / "triple_fp_units/verif/vectors"


def ieee_hex(bits: int, width_bits: int) -> str:
    width_hex = width_bits // 4
    return f"{bits & ((1 << width_bits) - 1):0{width_hex}x}"


def shell_hex(bits: int) -> str:
    return f"{bits & ((1 << 65) - 1):017x}"


def special_pool(fmt):
    if fmt is F64:
        return [
            0x0000000000000000,
            0x8000000000000000,
            0x3ff0000000000000,
            0xbff0000000000000,
            0x4000000000000000,
            0xc000000000000000,
            0x7ff0000000000000,
            0xfff0000000000000,
            0x7ff8000000000000,
            0x7ff0000000000001,
            0x0000000000000001,
            0x8000000000000001,
            0x0010000000000000,
            0x8010000000000000,
            0x7fefffffffffffff,
            0xffefffffffffffff,
        ]
    return [
        0x00000000,
        0x80000000,
        0x3f800000,
        0xbf800000,
        0x40000000,
        0xc0000000,
        0x7f800000,
        0xff800000,
        0x7fc00000,
        0x7f800001,
        0x00000001,
        0x80000001,
        0x00800000,
        0x80800000,
        0x7f7fffff,
        0xff7fffff,
    ]


def random_ieee_bits(rng: random.Random, fmt) -> int:
    roll = rng.randrange(100)
    if roll < 35:
        return rng.choice(special_pool(fmt))
    return rng.getrandbits(fmt.ieee_w)


def emit_vectors(unit: str, fmt, out_path: Path, n_cases: int, seed: int) -> int:
    rng = random.Random(seed)
    model = build_model(unit)
    rms = sorted(ROUNDING_NAMES.keys())
    count = 0

    with out_path.open("w", encoding="utf-8") as fh:
        for _ in range(n_cases):
            rm = rng.choice(rms)
            a_ieee = random_ieee_bits(rng, fmt)
            b_ieee = random_ieee_bits(rng, fmt)
            c_ieee = random_ieee_bits(rng, fmt)
            d_ieee = random_ieee_bits(rng, fmt)

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
            count += 1

    return count


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate randomized vector files for the standalone triple-multiply-add units.")
    parser.add_argument("--n", type=int, default=4096, help="cases per precision")
    parser.add_argument("--seed-f64", type=int, default=401, help="seed for f64 vectors")
    parser.add_argument("--seed-f32", type=int, default=733, help="seed for f32 vectors")
    args = parser.parse_args()

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    count64 = emit_vectors("triple_mul_add_f64", F64, OUT_DIR / "vectors_f64_muladd.txt", args.n, args.seed_f64)
    count32 = emit_vectors("triple_mul_add_f32", F32, OUT_DIR / "vectors_f32_muladd.txt", args.n, args.seed_f32)
    print(f"generated vectors_f64_muladd.txt with {count64} cases")
    print(f"generated vectors_f32_muladd.txt with {count32} cases")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
