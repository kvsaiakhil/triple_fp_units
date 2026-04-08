#!/usr/bin/env python3

from __future__ import annotations

import argparse

from triple_fp_reference_lib import ROUNDING_NAMES, UNITS, build_model, parse_operand


def parse_rm(value: str) -> int:
    value_l = value.lower()
    for rm, name in ROUNDING_NAMES.items():
        if value_l == name:
            return rm
    return int(value, 0)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the Python reference/debug model for a triple-FP unit.")
    parser.add_argument("--unit", choices=sorted(UNITS.keys()), required=True)
    parser.add_argument("--input-format", choices=["ieee", "recfn"], default="recfn")
    parser.add_argument("--rm", default="rne", help="rounding mode name or integer")
    parser.add_argument("--a", required=True, help="operand A in hex")
    parser.add_argument("--b", required=True, help="operand B in hex")
    parser.add_argument("--c", required=True, help="operand C in hex")
    parser.add_argument("--d", help="operand D in hex, required for triple_mul_add_* units")
    args = parser.parse_args()

    rm = parse_rm(args.rm)
    model = build_model(args.unit)
    fmt = model.fmt
    a_shell, _ = parse_operand(args.a, fmt, args.input_format)
    b_shell, _ = parse_operand(args.b, fmt, args.input_format)
    c_shell, _ = parse_operand(args.c, fmt, args.input_format)
    if args.unit.startswith("triple_mul_add_"):
        if args.d is None:
            parser.error("--d is required for triple_mul_add_* units")
        d_shell, _ = parse_operand(args.d, fmt, args.input_format)
        result = model.run(rm, a_shell, b_shell, c_shell, d_shell)
    else:
        result = model.run(rm, a_shell, b_shell, c_shell)
    print(result.pretty_text())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
