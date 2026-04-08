#!/usr/bin/env python3

import argparse
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[1]
BOOMV3_ROOT = REPO_ROOT.parent
TESTFLOAT_GEN = BOOMV3_ROOT / "berkeley-hardfloat" / "berkeley-testfloat-3" / "build" / "Linux-x86_64-GCC" / "testfloat_gen"
OUT_DIR = REPO_ROOT / "verif" / "vectors"

ROUNDING_MODES = [0, 1, 2, 3, 4, 6]
SEEDS = [1, 2, 3, 7]


@dataclass(frozen=True)
class FPFormat:
    name: str
    exp_w: int
    sig_w: int
    ieee_w: int
    rec_w: int
    shell_w: int = 65

    @property
    def frac_w(self) -> int:
        return self.sig_w - 1

    @property
    def bias(self) -> int:
        return (1 << (self.exp_w - 1)) - 1

    @property
    def exp_mask(self) -> int:
        return (1 << self.exp_w) - 1

    @property
    def frac_mask(self) -> int:
        return (1 << self.frac_w) - 1

    @property
    def rec_exp_bias(self) -> int:
        return (1 << (self.exp_w - 1)) + 1

    @property
    def rec_inf_exp(self) -> int:
        return 6 << (self.exp_w - 2)

    @property
    def rec_nan_exp(self) -> int:
        return 7 << (self.exp_w - 2)

    @property
    def quiet_nan_frac(self) -> int:
        return 1 << (self.frac_w - 1)


F32 = FPFormat("f32", 8, 24, 32, 33)
F64 = FPFormat("f64", 11, 53, 64, 65)


def split_ieee(bits: int, fmt: FPFormat):
    sign = (bits >> (fmt.exp_w + fmt.frac_w)) & 1
    exp = (bits >> fmt.frac_w) & fmt.exp_mask
    frac = bits & fmt.frac_mask
    return sign, exp, frac


def recode_from_ieee(bits: int, fmt: FPFormat) -> int:
    sign, exp, frac = split_ieee(bits, fmt)

    if exp == 0:
        if frac == 0:
            rec_exp = 0
            rec_frac = 0
        else:
            norm_dist = fmt.frac_w - frac.bit_length()
            rec_exp = fmt.rec_exp_bias - norm_dist
            rec_frac = (frac << (norm_dist + 1)) & fmt.frac_mask
    elif exp == fmt.exp_mask:
        rec_exp = fmt.rec_nan_exp if frac else fmt.rec_inf_exp
        rec_frac = frac
    else:
        rec_exp = exp + fmt.rec_exp_bias
        rec_frac = frac

    return (sign << (fmt.exp_w + fmt.frac_w + 1)) | (rec_exp << fmt.frac_w) | rec_frac


def shell_extend(rec_bits: int, fmt: FPFormat) -> int:
    if fmt.rec_w == fmt.shell_w:
        return rec_bits
    return rec_bits


def decode_ieee(bits: int, fmt: FPFormat):
    sign, exp, frac = split_ieee(bits, fmt)

    if exp == 0:
        if frac == 0:
            return {"cls": "zero", "sign": sign}
        n = frac.bit_length()
        shift = fmt.sig_w - n
        sig = frac << shift
        exp2 = 1 - fmt.bias - fmt.frac_w - shift
        return {"cls": "finite", "sign": sign, "sig": sig, "exp2": exp2}

    if exp == fmt.exp_mask:
        if frac == 0:
            return {"cls": "inf", "sign": sign}
        quiet = (frac >> (fmt.frac_w - 1)) & 1
        return {"cls": "qnan" if quiet else "snan", "sign": sign, "payload": frac}

    sig = (1 << fmt.frac_w) | frac
    exp2 = exp - fmt.bias - fmt.frac_w
    return {"cls": "finite", "sign": sign, "sig": sig, "exp2": exp2}


def encode_ieee(sign: int, exp: int, frac: int, fmt: FPFormat) -> int:
    return (sign << (fmt.exp_w + fmt.frac_w)) | (exp << fmt.frac_w) | frac


def round_mag(abs_sig: int, shift: int, sign: int, rm: int):
    if shift <= 0:
        return abs_sig << (-shift), False

    trunc = abs_sig >> shift
    lost = abs_sig & ((1 << shift) - 1)
    inexact = lost != 0
    if not inexact:
        return trunc, False

    if rm == 1:
        return trunc, True
    if rm == 6:
        return trunc | 1, True
    if rm == 2:
        return trunc + (1 if sign else 0), True
    if rm == 3:
        return trunc + (0 if sign else 1), True

    half = 1 << (shift - 1)
    if rm == 0:
        inc = (lost > half) or (lost == half and (trunc & 1))
    elif rm == 4:
        inc = lost >= half
    else:
        raise ValueError(f"unsupported rounding mode {rm}")
    return trunc + (1 if inc else 0), True


def overflow_result(sign: int, rm: int, fmt: FPFormat):
    if rm == 1 or (rm == 2 and not sign) or (rm == 3 and sign) or rm == 6:
        exp = fmt.exp_mask - 1
        frac = fmt.frac_mask
    else:
        exp = fmt.exp_mask
        frac = 0
    return encode_ieee(sign, exp, frac, fmt)


def round_finite(sign: int, abs_sig: int, exp2: int, fmt: FPFormat, rm: int):
    bias = fmt.bias
    emin = 1 - bias
    emax = bias
    frac_w = fmt.frac_w
    flags = 0

    if abs_sig == 0:
        return encode_ieee(sign, 0, 0, fmt), flags

    k = abs_sig.bit_length() - 1
    E = exp2 + k

    if E >= emin:
        shift = k - frac_w
        mant, inexact = round_mag(abs_sig, shift, sign, rm)
        if mant >= (1 << fmt.sig_w):
            mant >>= 1
            E += 1
        if E > emax:
            flags |= 0x4 | 0x1
            return overflow_result(sign, rm, fmt), flags
        exp = E + bias
        frac = mant & fmt.frac_mask
        if inexact:
            flags |= 0x1
        return encode_ieee(sign, exp, frac, fmt), flags

    sub_exp2 = emin - frac_w
    shift = sub_exp2 - exp2
    mant, inexact = round_mag(abs_sig, shift, sign, rm)

    if mant >= (1 << frac_w):
        if inexact:
            flags |= 0x1
        return encode_ieee(sign, 1, mant & fmt.frac_mask, fmt), flags

    if inexact:
        flags |= 0x1 | 0x2
    return encode_ieee(sign, 0, mant & fmt.frac_mask, fmt), flags


def add3_reference(a_bits: int, b_bits: int, c_bits: int, fmt: FPFormat, rm: int):
    ops = [decode_ieee(x, fmt) for x in (a_bits, b_bits, c_bits)]

    if any(op["cls"] == "snan" for op in ops):
        return {"kind": "nan", "flags": 0x10}
    if any(op["cls"] == "qnan" for op in ops):
        return {"kind": "nan", "flags": 0x00}

    has_pos_inf = any(op["cls"] == "inf" and op["sign"] == 0 for op in ops)
    has_neg_inf = any(op["cls"] == "inf" and op["sign"] == 1 for op in ops)
    if has_pos_inf and has_neg_inf:
        return {"kind": "nan", "flags": 0x10}
    if has_pos_inf or has_neg_inf:
        sign = 1 if has_neg_inf else 0
        return {"kind": "exact", "bits": encode_ieee(sign, fmt.exp_mask, 0, fmt), "flags": 0x00}

    min_exp2 = None
    any_negative_finite = False
    finite_ops = []
    for op in ops:
        if op["cls"] == "finite":
            min_exp2 = op["exp2"] if min_exp2 is None else min(min_exp2, op["exp2"])
            any_negative_finite |= bool(op["sign"])
            finite_ops.append(op)

    total = 0
    if min_exp2 is not None:
        for op in finite_ops:
            aligned = op["sig"] << (op["exp2"] - min_exp2)
            total += -aligned if op["sign"] else aligned

    if total == 0:
        sign = 1 if (rm == 2 and any_negative_finite) else 0
        return {"kind": "exact", "bits": encode_ieee(sign, 0, 0, fmt), "flags": 0x00}

    sign = 1 if total < 0 else 0
    bits, flags = round_finite(sign, abs(total), min_exp2, fmt, rm)
    return {"kind": "exact", "bits": bits, "flags": flags}


def mul3_reference(a_bits: int, b_bits: int, c_bits: int, fmt: FPFormat, rm: int):
    ops = [decode_ieee(x, fmt) for x in (a_bits, b_bits, c_bits)]

    if any(op["cls"] == "snan" for op in ops):
        return {"kind": "nan", "flags": 0x10}
    if any(op["cls"] == "qnan" for op in ops):
        return {"kind": "nan", "flags": 0x00}

    sign = 0
    any_inf = False
    any_zero = False
    for op in ops:
        sign ^= op["sign"]
        any_inf |= op["cls"] == "inf"
        any_zero |= op["cls"] == "zero"

    if any_inf and any_zero:
        return {"kind": "nan", "flags": 0x10}
    if any_inf:
        return {"kind": "exact", "bits": encode_ieee(sign, fmt.exp_mask, 0, fmt), "flags": 0x00}
    if any_zero:
        return {"kind": "exact", "bits": encode_ieee(sign, 0, 0, fmt), "flags": 0x00}

    abs_sig = 1
    exp2 = 0
    for op in ops:
        abs_sig *= op["sig"]
        exp2 += op["exp2"]

    bits, flags = round_finite(sign, abs_sig, exp2, fmt, rm)
    return {"kind": "exact", "bits": bits, "flags": flags}


def collect_random_triples(fmt: FPFormat, n_per_seed: int):
    triples = []
    seen = set()
    for seed in SEEDS:
        seed_count = 0
        cmd = [
            str(TESTFLOAT_GEN),
            "-seed", str(seed),
            "-level", "2",
            fmt.name,
            "3",
        ]
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, text=True)
        assert proc.stdout is not None
        try:
            while seed_count < n_per_seed:
                line = proc.stdout.readline()
                if not line:
                    break
                toks = line.strip().split()
                if len(toks) != 3:
                    continue
                triple = tuple(int(tok, 16) for tok in toks)
                if triple not in seen:
                    seen.add(triple)
                    triples.append(triple)
                    seed_count += 1
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=5)
    return triples


def interesting_values(fmt: FPFormat):
    max_exp = fmt.exp_mask
    frac_w = fmt.frac_w
    vals = [
        0,
        1 << (fmt.ieee_w - 1),
        encode_ieee(0, fmt.bias, 0, fmt),
        encode_ieee(1, fmt.bias, 0, fmt),
        encode_ieee(0, fmt.bias + 1, 0, fmt),
        encode_ieee(1, fmt.bias + 1, 0, fmt),
        encode_ieee(0, 1, 0, fmt),
        encode_ieee(1, 1, 0, fmt),
        encode_ieee(0, 0, 1, fmt),
        encode_ieee(1, 0, 1, fmt),
        encode_ieee(0, max_exp - 1, fmt.frac_mask, fmt),
        encode_ieee(1, max_exp - 1, fmt.frac_mask, fmt),
        encode_ieee(0, max_exp, 0, fmt),
        encode_ieee(1, max_exp, 0, fmt),
        encode_ieee(0, max_exp, fmt.quiet_nan_frac, fmt),
        encode_ieee(1, max_exp, fmt.quiet_nan_frac | 1, fmt),
        encode_ieee(0, max_exp, 1, fmt),
        encode_ieee(1, max_exp, 1, fmt),
    ]
    return vals


def permute_triples(triples: Iterable[tuple[int, int, int]]):
    out = []
    seen = set()
    for a, b, c in triples:
        for perm in (
            (a, b, c),
            (a, c, b),
            (b, a, c),
            (b, c, a),
            (c, a, b),
            (c, b, a),
        ):
            if perm not in seen:
                seen.add(perm)
                out.append(perm)
    return out


def collect_directed_tripples(fmt: FPFormat):
    vals = interesting_values(fmt)
    triples = []
    for a in vals:
        for b in vals[:10]:
            for c in vals[:10]:
                triples.append((a, b, c))
    return triples


def format_shell(bits: int, fmt: FPFormat) -> str:
    rec = recode_from_ieee(bits, fmt)
    shell = shell_extend(rec, fmt)
    return f"{shell:017x}"


def write_vectors(fmt: FPFormat, triples):
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    add_path = OUT_DIR / f"vectors_{fmt.name}_add.txt"
    mul_path = OUT_DIR / f"vectors_{fmt.name}_mul.txt"

    with add_path.open("w") as addf, mul_path.open("w") as mulf:
        for rm in ROUNDING_MODES:
            for a_bits, b_bits, c_bits in triples:
                add_ref = add3_reference(a_bits, b_bits, c_bits, fmt, rm)
                mul_ref = mul3_reference(a_bits, b_bits, c_bits, fmt, rm)

                add_mode = 1 if add_ref["kind"] == "nan" else 0
                mul_mode = 1 if mul_ref["kind"] == "nan" else 0

                add_bits = encode_ieee(0, fmt.exp_mask, fmt.quiet_nan_frac, fmt) if add_mode else add_ref["bits"]
                mul_bits = encode_ieee(0, fmt.exp_mask, fmt.quiet_nan_frac, fmt) if mul_mode else mul_ref["bits"]

                fields = (
                    f"{rm:x}",
                    f"{add_mode:x}",
                    format_shell(a_bits, fmt),
                    format_shell(b_bits, fmt),
                    format_shell(c_bits, fmt),
                    format_shell(add_bits, fmt),
                    f"{add_ref['flags']:02x}",
                )
                addf.write(" ".join(fields) + "\n")

                fields = (
                    f"{rm:x}",
                    f"{mul_mode:x}",
                    format_shell(a_bits, fmt),
                    format_shell(b_bits, fmt),
                    format_shell(c_bits, fmt),
                    format_shell(mul_bits, fmt),
                    f"{mul_ref['flags']:02x}",
                )
                mulf.write(" ".join(fields) + "\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--n-per-seed", type=int, default=192)
    args = parser.parse_args()

    for fmt in (F64, F32):
        randoms = collect_random_triples(fmt, args.n_per_seed)
        directed = collect_directed_tripples(fmt)
        triples = list(dict.fromkeys(permute_triples(directed + randoms)))
        write_vectors(fmt, triples)
        print(f"{fmt.name}: wrote {len(triples)} operand triples")


if __name__ == "__main__":
    main()
