#!/usr/bin/env python3

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field, is_dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
VECTOR_DIR = REPO_ROOT / "verif" / "vectors"

ROUNDING_NAMES = {
    0: "rne",
    1: "rtz",
    2: "rdn",
    3: "rup",
    4: "rmm",
    6: "rod",
}


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
    def rec_exp_mask(self) -> int:
        return (1 << (self.exp_w + 1)) - 1

    @property
    def rec_exp_bias(self) -> int:
        return (1 << (self.exp_w - 1)) + 1

    @property
    def one_exp(self) -> int:
        return 1 << self.exp_w

    @property
    def raw_sig_w(self) -> int:
        return self.sig_w + 3

    @property
    def rec_inf_exp(self) -> int:
        return 6 << (self.exp_w - 2)

    @property
    def rec_nan_exp(self) -> int:
        return 7 << (self.exp_w - 2)

    @property
    def shell_mask(self) -> int:
        return (1 << self.shell_w) - 1

    @property
    def rec_mask(self) -> int:
        return (1 << self.rec_w) - 1


F32 = FPFormat("f32", 8, 24, 32, 33)
F64 = FPFormat("f64", 11, 53, 64, 65)


@dataclass
class DecodedRecFN:
    fmt: FPFormat
    shell_bits: int
    rec_bits: int
    sign: int
    rec_exp: int
    frac: int
    top3: int
    cls: str
    is_zero: bool
    is_inf: bool
    is_nan: bool
    is_snan: bool
    is_qnan: bool
    sig: int | None = None
    exp2: int | None = None

    def debug_dict(self) -> dict[str, Any]:
        out: dict[str, Any] = {
            "shell_bits": hex_bits(self.shell_bits, self.fmt.shell_w),
            "rec_bits": hex_bits(self.rec_bits, self.fmt.rec_w),
            "sign": self.sign,
            "rec_exp": format_int_hex(self.rec_exp),
            "frac": hex_bits(self.frac, self.fmt.frac_w),
            "top3": format_int_hex(self.top3),
            "class": self.cls,
            "is_zero": self.is_zero,
            "is_inf": self.is_inf,
            "is_nan": self.is_nan,
            "is_snan": self.is_snan,
            "is_qnan": self.is_qnan,
        }
        if self.sig is not None:
            out["finite_sig"] = hex_bits(self.sig, self.fmt.sig_w)
        if self.exp2 is not None:
            out["finite_exp2"] = self.exp2
        return out


@dataclass
class StageSnapshot:
    name: str
    values: dict[str, Any]


@dataclass
class ModelRunResult:
    unit_name: str
    fmt: FPFormat
    rm: int
    stages: list[StageSnapshot] = field(default_factory=list)
    final_shell_out: int = 0
    final_rec_out: int = 0
    final_flags: int = 0

    def add_stage(self, name: str, values: dict[str, Any]) -> None:
        self.stages.append(StageSnapshot(name=name, values=values))

    def to_display_dict(self) -> dict[str, Any]:
        return {
            "unit_name": self.unit_name,
            "format": self.fmt.name,
            "rounding_mode": f"{self.rm} ({ROUNDING_NAMES.get(self.rm, 'unknown')})",
            "stages": [
                {
                    "name": stage.name,
                    "values": sanitize_for_display(stage.values),
                }
                for stage in self.stages
            ],
            "final": {
                "shell_out": hex_bits(self.final_shell_out, self.fmt.shell_w),
                "rec_out": hex_bits(self.final_rec_out, self.fmt.rec_w),
                "flags": flag_summary(self.final_flags),
            },
        }

    def pretty_text(self) -> str:
        return json.dumps(self.to_display_dict(), indent=2)


def hex_bits(value: int, width_bits: int) -> str:
    width_hex = max(1, (width_bits + 3) // 4)
    return f"0x{(value & ((1 << width_bits) - 1)):0{width_hex}x}"


def hex_min(value: int) -> str:
    return hex(value if value >= 0 else -value)


def format_int_hex(value: int) -> str:
    if value < 0:
        return f"{value}"
    return f"{value} ({value:#x})"


def format_signed_with_hex(value: int, width_bits: int | None = None) -> str:
    if width_bits is None:
        return f"{value}"
    return f"{value} / {hex_bits(value, width_bits)}"


def flag_summary(flags: int) -> dict[str, Any]:
    return {
        "raw": hex_bits(flags, 5),
        "invalid": bool(flags & 0x10),
        "overflow": bool(flags & 0x04),
        "underflow": bool(flags & 0x02),
        "inexact": bool(flags & 0x01),
    }


def sanitize_for_display(obj: Any) -> Any:
    if is_dataclass(obj):
        return sanitize_for_display(asdict(obj))
    if isinstance(obj, dict):
        return {k: sanitize_for_display(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [sanitize_for_display(v) for v in obj]
    return obj


def parse_hex(value: str) -> int:
    return int(value, 16)


def shell_to_recfn(shell_bits: int, fmt: FPFormat) -> int:
    return shell_bits & fmt.rec_mask


def recfn_to_shell(rec_bits: int, fmt: FPFormat) -> int:
    return rec_bits & fmt.shell_mask


def split_ieee(bits: int, fmt: FPFormat) -> tuple[int, int, int]:
    sign = (bits >> (fmt.exp_w + fmt.frac_w)) & 1
    exp = (bits >> fmt.frac_w) & fmt.exp_mask
    frac = bits & fmt.frac_mask
    return sign, exp, frac


def encode_ieee(sign: int, exp: int, frac: int, fmt: FPFormat) -> int:
    return (sign << (fmt.exp_w + fmt.frac_w)) | (exp << fmt.frac_w) | frac


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


def canonical_nan_ieee(fmt: FPFormat) -> int:
    return encode_ieee(0, fmt.exp_mask, 1 << (fmt.frac_w - 1), fmt)


def canonical_nan_recfn(fmt: FPFormat) -> int:
    return recode_from_ieee(canonical_nan_ieee(fmt), fmt)


def decode_recfn(shell_bits: int, fmt: FPFormat) -> DecodedRecFN:
    rec_bits = shell_to_recfn(shell_bits, fmt)
    sign = (rec_bits >> (fmt.rec_w - 1)) & 1
    rec_exp = (rec_bits >> fmt.frac_w) & fmt.rec_exp_mask
    frac = rec_bits & fmt.frac_mask
    top3 = rec_exp >> (fmt.exp_w - 2)

    if top3 == 0:
        cls = "zero"
    elif top3 == 6:
        cls = "inf"
    elif top3 == 7:
        cls = "qnan" if ((frac >> (fmt.frac_w - 1)) & 1) else "snan"
    else:
        cls = "finite"

    sig = None
    exp2 = None
    if cls == "finite":
        sig = (1 << fmt.frac_w) | frac
        exp2 = rec_exp - fmt.one_exp - fmt.frac_w

    return DecodedRecFN(
        fmt=fmt,
        shell_bits=shell_bits & fmt.shell_mask,
        rec_bits=rec_bits,
        sign=sign,
        rec_exp=rec_exp,
        frac=frac,
        top3=top3,
        cls=cls,
        is_zero=(cls == "zero"),
        is_inf=(cls == "inf"),
        is_nan=(cls in ("qnan", "snan")),
        is_snan=(cls == "snan"),
        is_qnan=(cls == "qnan"),
        sig=sig,
        exp2=exp2,
    )


def round_mag(abs_sig: int, shift: int, sign: int, rm: int) -> tuple[int, bool]:
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


def overflow_result(sign: int, rm: int, fmt: FPFormat) -> int:
    if rm == 1 or (rm == 2 and not sign) or (rm == 3 and sign) or rm == 6:
        exp = fmt.exp_mask - 1
        frac = fmt.frac_mask
    else:
        exp = fmt.exp_mask
        frac = 0
    return encode_ieee(sign, exp, frac, fmt)


def round_finite(sign: int, abs_sig: int, exp2: int, fmt: FPFormat, rm: int) -> tuple[int, int]:
    emin = 1 - fmt.bias
    emax = fmt.bias
    flags = 0

    if abs_sig == 0:
        return encode_ieee(sign, 0, 0, fmt), flags

    k = abs_sig.bit_length() - 1
    e = exp2 + k

    if e >= emin:
        shift = k - fmt.frac_w
        mant, inexact = round_mag(abs_sig, shift, sign, rm)
        if mant >= (1 << fmt.sig_w):
            mant >>= 1
            e += 1
        if e > emax:
            flags |= 0x4 | 0x1
            return overflow_result(sign, rm, fmt), flags
        exp = e + fmt.bias
        frac = mant & fmt.frac_mask
        if inexact:
            flags |= 0x1
        return encode_ieee(sign, exp, frac, fmt), flags

    sub_exp2 = emin - fmt.frac_w
    shift = sub_exp2 - exp2
    mant, inexact = round_mag(abs_sig, shift, sign, rm)

    if mant >= (1 << fmt.frac_w):
        if inexact:
            flags |= 0x1
        return encode_ieee(sign, 1, mant & fmt.frac_mask, fmt), flags

    if inexact:
        flags |= 0x1 | 0x2
    return encode_ieee(sign, 0, mant & fmt.frac_mask, fmt), flags


def recfn_class(bits: int, fmt: FPFormat) -> str:
    return decode_recfn(bits, fmt).cls


def recfn_matches_expected(actual: int, expected: int, fmt: FPFormat) -> bool:
    act = decode_recfn(actual, fmt)
    exp = decode_recfn(expected, fmt)
    if exp.cls in ("zero", "inf"):
        return act.cls == exp.cls and act.sign == exp.sign
    return shell_to_recfn(actual, fmt) == shell_to_recfn(expected, fmt)


def sticky_rshift_acc(value: int, shamt: int, width: int) -> int:
    mask = (1 << width) - 1
    value &= mask
    if shamt <= 0:
        return value
    if shamt >= width:
        return 1 if value else 0
    shifted = value >> shamt
    sticky = 1 if (value & ((1 << shamt) - 1)) else 0
    return shifted | sticky


def sticky_rshift_prod(value: int, shamt: int, prod_w: int, out_w: int) -> int:
    value &= (1 << prod_w) - 1
    if shamt <= 0:
        return value & ((1 << out_w) - 1)
    if shamt >= prod_w:
        return 1 if value else 0
    shifted = value >> shamt
    sticky = 1 if (value & ((1 << shamt) - 1)) else 0
    return (shifted & ((1 << out_w) - 1)) | sticky


def msb_index(value: int) -> int:
    if value == 0:
        return -1
    return value.bit_length() - 1


def parse_operand(value: str, fmt: FPFormat, input_format: str) -> tuple[int, int]:
    raw = parse_hex(value)
    if input_format == "ieee":
        rec = recode_from_ieee(raw, fmt)
        return recfn_to_shell(rec, fmt), rec
    if input_format != "recfn":
        raise ValueError(f"unsupported input format {input_format}")
    shell = raw & fmt.shell_mask
    return shell, shell_to_recfn(shell, fmt)


def add3_reference_from_recfn(ops: list[DecodedRecFN], fmt: FPFormat, rm: int) -> tuple[int, int]:
    if any(op.is_snan for op in ops):
        return canonical_nan_recfn(fmt), 0x10
    if any(op.is_nan for op in ops):
        return canonical_nan_recfn(fmt), 0x00

    has_pos_inf = any(op.is_inf and op.sign == 0 for op in ops)
    has_neg_inf = any(op.is_inf and op.sign == 1 for op in ops)
    if has_pos_inf and has_neg_inf:
        return canonical_nan_recfn(fmt), 0x10
    if has_pos_inf or has_neg_inf:
        sign = 1 if has_neg_inf else 0
        return recode_from_ieee(encode_ieee(sign, fmt.exp_mask, 0, fmt), fmt), 0x00

    finite_ops = [op for op in ops if op.cls == "finite"]
    if not finite_ops:
        sign = 0
        return recode_from_ieee(encode_ieee(sign, 0, 0, fmt), fmt), 0x00

    min_exp2 = min(op.exp2 for op in finite_ops if op.exp2 is not None)
    any_negative_finite = any(op.sign for op in finite_ops)
    total = 0
    for op in finite_ops:
        assert op.sig is not None and op.exp2 is not None
        aligned = op.sig << (op.exp2 - min_exp2)
        total += -aligned if op.sign else aligned

    if total == 0:
        sign = 1 if (rm == 2 and any_negative_finite) else 0
        return recode_from_ieee(encode_ieee(sign, 0, 0, fmt), fmt), 0x00

    sign = 1 if total < 0 else 0
    ieee_bits, flags = round_finite(sign, abs(total), min_exp2, fmt, rm)
    return recode_from_ieee(ieee_bits, fmt), flags


def mul3_reference_from_recfn(ops: list[DecodedRecFN], fmt: FPFormat, rm: int) -> tuple[int, int]:
    if any(op.is_snan for op in ops):
        return canonical_nan_recfn(fmt), 0x10
    if any(op.is_nan for op in ops):
        return canonical_nan_recfn(fmt), 0x00

    sign = 0
    any_inf = False
    any_zero = False
    for op in ops:
        sign ^= op.sign
        any_inf |= op.is_inf
        any_zero |= op.is_zero

    if any_inf and any_zero:
        return canonical_nan_recfn(fmt), 0x10
    if any_inf:
        return recode_from_ieee(encode_ieee(sign, fmt.exp_mask, 0, fmt), fmt), 0x00
    if any_zero:
        return recode_from_ieee(encode_ieee(sign, 0, 0, fmt), fmt), 0x00

    abs_sig = 1
    exp2 = 0
    for op in ops:
        assert op.sig is not None and op.exp2 is not None
        abs_sig *= op.sig
        exp2 += op.exp2

    ieee_bits, flags = round_finite(sign, abs_sig, exp2, fmt, rm)
    return recode_from_ieee(ieee_bits, fmt), flags


def mul3add_reference_from_recfn(
    a: DecodedRecFN,
    b: DecodedRecFN,
    c: DecodedRecFN,
    d: DecodedRecFN,
    fmt: FPFormat,
    rm: int,
) -> tuple[int, int]:
    ops = [a, b, c, d]
    if any(op.is_snan for op in ops):
        return canonical_nan_recfn(fmt), 0x10
    if any(op.is_nan for op in ops):
        return canonical_nan_recfn(fmt), 0x00

    prod_sign = a.sign ^ b.sign ^ c.sign
    any_inf_abc = a.is_inf or b.is_inf or c.is_inf
    any_zero_abc = a.is_zero or b.is_zero or c.is_zero

    if any_inf_abc and any_zero_abc:
        return canonical_nan_recfn(fmt), 0x10
    if any_inf_abc and d.is_inf and (prod_sign != d.sign):
        return canonical_nan_recfn(fmt), 0x10
    if any_inf_abc:
        return recode_from_ieee(encode_ieee(prod_sign, fmt.exp_mask, 0, fmt), fmt), 0x00
    if d.is_inf:
        return recode_from_ieee(encode_ieee(d.sign, fmt.exp_mask, 0, fmt), fmt), 0x00

    prod_sig = 0
    prod_exp2 = 0
    if not any_zero_abc:
        assert a.sig is not None and a.exp2 is not None
        assert b.sig is not None and b.exp2 is not None
        assert c.sig is not None and c.exp2 is not None
        prod_sig = a.sig * b.sig * c.sig
        prod_exp2 = a.exp2 + b.exp2 + c.exp2

    if prod_sig == 0 and d.is_zero:
        sign = 1 if (rm == 2 and (prod_sign or d.sign)) else 0
        return recode_from_ieee(encode_ieee(sign, 0, 0, fmt), fmt), 0x00

    if prod_sig == 0:
        assert d.sig is not None and d.exp2 is not None
        ieee_bits, flags = round_finite(d.sign, d.sig, d.exp2, fmt, rm)
        return recode_from_ieee(ieee_bits, fmt), flags

    if d.is_zero:
        ieee_bits, flags = round_finite(prod_sign, prod_sig, prod_exp2, fmt, rm)
        return recode_from_ieee(ieee_bits, fmt), flags

    assert d.sig is not None and d.exp2 is not None
    min_exp2 = min(prod_exp2, d.exp2)
    total = ((-prod_sig) if prod_sign else prod_sig) << (prod_exp2 - min_exp2)
    total += ((-d.sig) if d.sign else d.sig) << (d.exp2 - min_exp2)

    if total == 0:
        sign = 1 if (rm == 2 and (prod_sign or d.sign)) else 0
        return recode_from_ieee(encode_ieee(sign, 0, 0, fmt), fmt), 0x00

    sign = 1 if total < 0 else 0
    ieee_bits, flags = round_finite(sign, abs(total), min_exp2, fmt, rm)
    return recode_from_ieee(ieee_bits, fmt), flags


class TripleAddModel:
    def __init__(self, fmt: FPFormat):
        self.fmt = fmt
        self.unit_name = f"TripleAddPipe_l4_{fmt.name}"

    def run(self, rm: int, a_shell: int, b_shell: int, c_shell: int) -> ModelRunResult:
        fmt = self.fmt
        result = ModelRunResult(unit_name=self.unit_name, fmt=fmt, rm=rm)

        a = decode_recfn(a_shell, fmt)
        b = decode_recfn(b_shell, fmt)
        c = decode_recfn(c_shell, fmt)
        ops = [a, b, c]

        result.add_stage(
            "stage0_capture",
            {
                "visible_pipeline_stage": "wrapper input register",
                "rm": f"{rm} ({ROUNDING_NAMES.get(rm, 'unknown')})",
                "a": a.debug_dict(),
                "b": b.debug_dict(),
                "c": c.debug_dict(),
            },
        )

        has_pos_inf = any(op.is_inf and op.sign == 0 for op in ops)
        has_neg_inf = any(op.is_inf and op.sign == 1 for op in ops)
        invalid_exc = False
        is_nan = False
        is_inf = False
        is_zero = False
        sign = 0
        special_path = "finite_path"

        if any(op.is_snan for op in ops):
            invalid_exc = True
            is_nan = True
            special_path = "signaling_nan"
        elif any(op.is_nan for op in ops):
            is_nan = True
            special_path = "quiet_nan"
        elif has_pos_inf and has_neg_inf:
            invalid_exc = True
            is_nan = True
            special_path = "mixed_signed_infinities"
        elif has_pos_inf or has_neg_inf:
            is_inf = True
            sign = 1 if has_neg_inf else 0
            special_path = "single_signed_infinity"

        result.add_stage(
            "stage1_decode_special",
            {
                "rtl_block": "TripleAddRecFNToRaw special-case decode",
                "a": {
                    "is_zero": a.is_zero,
                    "is_inf": a.is_inf,
                    "is_nan": a.is_nan,
                    "is_snan": a.is_snan,
                },
                "b": {
                    "is_zero": b.is_zero,
                    "is_inf": b.is_inf,
                    "is_nan": b.is_nan,
                    "is_snan": b.is_snan,
                },
                "c": {
                    "is_zero": c.is_zero,
                    "is_inf": c.is_inf,
                    "is_nan": c.is_nan,
                    "is_snan": c.is_snan,
                },
                "has_pos_inf": has_pos_inf,
                "has_neg_inf": has_neg_inf,
                "invalidExc": invalid_exc,
                "selected_path": special_path,
            },
        )

        raw_sig = 0
        raw_s_exp = 0
        if not (is_nan or is_inf):
            finite_nonzero = [op for op in ops if op.cls != "zero"]
            min_exp = min((op.rec_exp for op in finite_nonzero), default=0)
            sig_exts: list[int] = []
            shifts: list[int] = []
            wides: list[int] = []
            any_negative_finite = False
            acc_w = fmt.raw_sig_w + ((1 << fmt.exp_w) + fmt.frac_w - 3) + 2
            sum_signed = 0
            contributions: list[str] = []
            for op in ops:
                if op.cls == "zero":
                    sig_ext = 0
                    shift = 0
                    wide = 0
                else:
                    sig_ext = (1 << (fmt.frac_w + 2)) | (op.frac << 2)
                    shift = op.rec_exp - min_exp
                    wide = sig_ext << shift
                    any_negative_finite |= bool(op.sign)
                    sum_signed += -wide if op.sign else wide
                    contributions.append(f"{'-' if op.sign else '+'}{hex_min(wide)}")
                sig_exts.append(sig_ext)
                shifts.append(shift)
                wides.append(wide)

            result.add_stage(
                "stage1_align",
                {
                    "rtl_block": "TripleAddRecFNToRaw finite alignment",
                    "minExp": format_int_hex(min_exp),
                    "sigA_ext": hex_bits(sig_exts[0], fmt.raw_sig_w),
                    "sigB_ext": hex_bits(sig_exts[1], fmt.raw_sig_w),
                    "sigC_ext": hex_bits(sig_exts[2], fmt.raw_sig_w),
                    "shiftA": shifts[0],
                    "shiftB": shifts[1],
                    "shiftC": shifts[2],
                    "wideA": hex_min(wides[0]),
                    "wideB": hex_min(wides[1]),
                    "wideC": hex_min(wides[2]),
                    "anyNegativeFinite": any_negative_finite,
                },
            )

            if sum_signed == 0:
                is_zero = True
                sign = 1 if (rm == 2 and any_negative_finite) else 0
                result.add_stage(
                    "stage1_accumulate",
                    {
                        "signed_contributions": contributions,
                        "sumSigned": "0",
                        "exact_zero": True,
                        "zero_sign_rule_result": sign,
                    },
                )
                result.add_stage(
                    "stage1_normalize_raw",
                    {
                        "normalization_path": "exact_zero",
                        "raw_isNaN": False,
                        "raw_isInf": False,
                        "raw_isZero": True,
                        "raw_sign": sign,
                        "raw_sExp": hex_bits(0, fmt.exp_w + 2),
                        "raw_sig": hex_bits(0, fmt.raw_sig_w),
                    },
                )
            else:
                abs_sum = abs(sum_signed)
                target_norm_msb = fmt.raw_sig_w - 2
                target_carry_msb = fmt.raw_sig_w - 1
                msb_idx = msb_index(abs_sum)
                if msb_idx < target_norm_msb:
                    shift_amt = target_norm_msb - msb_idx
                    shifted_sum = abs_sum << shift_amt
                    raw_sig = shifted_sum & ((1 << fmt.raw_sig_w) - 1)
                    raw_exp_int = min_exp - shift_amt
                    norm_path = "left_shift"
                elif msb_idx > target_carry_msb:
                    shift_amt = msb_idx - target_carry_msb
                    shifted_sum = sticky_rshift_acc(abs_sum, shift_amt, abs_sum.bit_length() + 1)
                    raw_sig = shifted_sum & ((1 << fmt.raw_sig_w) - 1)
                    raw_exp_int = min_exp + shift_amt
                    norm_path = "right_shift_sticky"
                else:
                    shift_amt = 0
                    shifted_sum = abs_sum
                    raw_sig = abs_sum & ((1 << fmt.raw_sig_w) - 1)
                    raw_exp_int = min_exp
                    norm_path = "no_shift"
                sign = 1 if sum_signed < 0 else 0
                raw_s_exp = raw_exp_int & ((1 << (fmt.exp_w + 2)) - 1)

                result.add_stage(
                    "stage1_accumulate",
                    {
                        "signed_contributions": contributions,
                        "sumSigned": format_signed_with_hex(sum_signed, max(abs(sum_signed).bit_length() + 1, 1)),
                        "exact_zero": False,
                        "selected_sign": sign,
                    },
                )
                result.add_stage(
                    "stage1_normalize_raw",
                    {
                        "sign_r": sign,
                        "absSum": hex_bits(abs_sum, max(abs_sum.bit_length(), 1)),
                        "msbIdx": msb_idx,
                        "normalization_path": norm_path,
                        "shiftAmt": shift_amt,
                        "shiftedSum": hex_bits(shifted_sum, max(shifted_sum.bit_length(), 1)),
                        "narrowedSig": hex_bits(raw_sig, fmt.raw_sig_w),
                        "rawExpInt": raw_exp_int,
                        "raw_isNaN": False,
                        "raw_isInf": False,
                        "raw_isZero": False,
                        "raw_sign": sign,
                        "raw_sExp": hex_bits(raw_s_exp, fmt.exp_w + 2),
                        "raw_sig": hex_bits(raw_sig, fmt.raw_sig_w),
                    },
                )

        result.add_stage(
            "stage2_round_register",
            {
                "visible_pipeline_stage": "inner round-input register",
                "round_invalidExc_r": invalid_exc,
                "round_isNaN_r": is_nan,
                "round_isInf_r": is_inf,
                "round_isZero_r": is_zero,
                "round_sign_r": sign,
                "round_sExp_r": hex_bits(raw_s_exp, fmt.exp_w + 2),
                "round_sig_r": hex_bits(raw_sig, fmt.raw_sig_w),
                "round_rm_r": f"{rm} ({ROUNDING_NAMES.get(rm, 'unknown')})",
            },
        )

        final_rec, final_flags = add3_reference_from_recfn(ops, fmt, rm)
        final_shell = recfn_to_shell(final_rec, fmt)
        result.final_rec_out = final_rec
        result.final_shell_out = final_shell
        result.final_flags = final_flags
        result.add_stage(
            "stage3_output",
            {
                "visible_pipeline_stage": "inner output register + wrapper output register",
                "out_recfn": hex_bits(final_rec, fmt.rec_w),
                "out_shell": hex_bits(final_shell, fmt.shell_w),
                "out_class": recfn_class(final_rec, fmt),
                "out_flags": flag_summary(final_flags),
            },
        )
        return result


class TripleMulModel:
    def __init__(self, fmt: FPFormat):
        self.fmt = fmt
        self.unit_name = f"TripleMulPipe_l4_{fmt.name}"

    def run(self, rm: int, a_shell: int, b_shell: int, c_shell: int) -> ModelRunResult:
        fmt = self.fmt
        result = ModelRunResult(unit_name=self.unit_name, fmt=fmt, rm=rm)

        a = decode_recfn(a_shell, fmt)
        b = decode_recfn(b_shell, fmt)
        c = decode_recfn(c_shell, fmt)
        ops = [a, b, c]

        result.add_stage(
            "stage0_capture",
            {
                "visible_pipeline_stage": "wrapper input register",
                "rm": f"{rm} ({ROUNDING_NAMES.get(rm, 'unknown')})",
                "a": a.debug_dict(),
                "b": b.debug_dict(),
                "c": c.debug_dict(),
            },
        )

        sign = a.sign ^ b.sign ^ c.sign
        any_inf = any(op.is_inf for op in ops)
        any_zero = any(op.is_zero for op in ops)
        invalid_exc = False
        is_nan = False
        is_inf = False
        is_zero = False
        special_path = "finite_path"

        if any(op.is_snan for op in ops):
            invalid_exc = True
            is_nan = True
            special_path = "signaling_nan"
        elif any(op.is_nan for op in ops):
            is_nan = True
            special_path = "quiet_nan"
        elif any_inf and any_zero:
            invalid_exc = True
            is_nan = True
            special_path = "inf_times_zero"
        elif any_inf:
            is_inf = True
            special_path = "pure_infinity"
        elif any_zero:
            is_zero = True
            special_path = "pure_zero"

        result.add_stage(
            "stage1_decode_special",
            {
                "rtl_block": "TripleMulRecFNToRaw special-case decode",
                "signA": a.sign,
                "signB": b.sign,
                "signC": c.sign,
                "expA": format_int_hex(a.rec_exp),
                "expB": format_int_hex(b.rec_exp),
                "expC": format_int_hex(c.rec_exp),
                "fracA": hex_bits(a.frac, fmt.frac_w),
                "fracB": hex_bits(b.frac, fmt.frac_w),
                "fracC": hex_bits(c.frac, fmt.frac_w),
                "isNaNA": a.is_nan,
                "isNaNB": b.is_nan,
                "isNaNC": c.is_nan,
                "isInfA": a.is_inf,
                "isInfB": b.is_inf,
                "isInfC": c.is_inf,
                "isZeroA": a.is_zero,
                "isZeroB": b.is_zero,
                "isZeroC": c.is_zero,
                "isSigNaNA": a.is_snan,
                "isSigNaNB": b.is_snan,
                "isSigNaNC": c.is_snan,
                "sign_r": sign,
                "anyInf": any_inf,
                "anyZero": any_zero,
                "invalidExc": invalid_exc,
                "selected_path": special_path,
            },
        )

        raw_sig = 0
        raw_s_exp = 0
        if not (is_nan or is_inf or is_zero):
            sig_a = (1 << fmt.frac_w) | a.frac
            sig_b = (1 << fmt.frac_w) | b.frac
            sig_c = (1 << fmt.frac_w) | c.frac
            prod = sig_a * sig_b * sig_c
            prod_w = fmt.sig_w * 3
            wide_sig_w = fmt.raw_sig_w + 2
            base_shift = 2 * fmt.frac_w - 2
            scaled_sig = sticky_rshift_prod(prod, base_shift, prod_w, wide_sig_w)
            raw_exp_pre = a.rec_exp + b.rec_exp + c.rec_exp - (2 * fmt.one_exp)

            result.add_stage(
                "stage1_finite_product",
                {
                    "rtl_block": "TripleMulRecFNToRaw finite product",
                    "sigA": hex_bits(sig_a, fmt.sig_w),
                    "sigB": hex_bits(sig_b, fmt.sig_w),
                    "sigC": hex_bits(sig_c, fmt.sig_w),
                    "prod": hex_bits(prod, prod_w),
                    "BASE_SHIFT": base_shift,
                    "scaledSig": hex_bits(scaled_sig, wide_sig_w),
                    "rawExpInt_pre_norm": raw_exp_pre,
                },
            )

            msb_idx = msb_index(scaled_sig)
            if msb_idx < fmt.raw_sig_w - 2:
                shift_amt = (fmt.raw_sig_w - 2) - msb_idx
                norm_sig_wide = (scaled_sig << shift_amt) & ((1 << wide_sig_w) - 1)
                raw_sig = norm_sig_wide & ((1 << fmt.raw_sig_w) - 1)
                raw_exp_post = raw_exp_pre - shift_amt
                norm_path = "left_shift"
            elif msb_idx > fmt.raw_sig_w - 1:
                shift_amt = msb_idx - (fmt.raw_sig_w - 1)
                norm_sig_wide = sticky_rshift_acc(scaled_sig, shift_amt, wide_sig_w)
                raw_sig = norm_sig_wide & ((1 << fmt.raw_sig_w) - 1)
                raw_exp_post = raw_exp_pre + shift_amt
                norm_path = "right_shift_sticky"
            else:
                shift_amt = 0
                norm_sig_wide = scaled_sig
                raw_sig = scaled_sig & ((1 << fmt.raw_sig_w) - 1)
                raw_exp_post = raw_exp_pre
                norm_path = "no_shift"

            sexp_max = (1 << (fmt.exp_w + 1)) - 1
            sexp_min = -(1 << (fmt.exp_w + 1))
            clamped_exp = min(max(raw_exp_post, sexp_min), sexp_max)
            raw_s_exp = clamped_exp & ((1 << (fmt.exp_w + 2)) - 1)

            result.add_stage(
                "stage1_normalize_raw",
                {
                    "msbIdx": msb_idx,
                    "normalization_path": norm_path,
                    "shiftAmt": shift_amt,
                    "normSigWide": hex_bits(norm_sig_wide, wide_sig_w),
                    "normSig": hex_bits(raw_sig, fmt.raw_sig_w),
                    "rawExpInt_post_norm": raw_exp_post,
                    "SEXP_MIN": sexp_min,
                    "SEXP_MAX": sexp_max,
                    "clamped_rawExpInt": clamped_exp,
                    "raw_isNaN": False,
                    "raw_isInf": False,
                    "raw_isZero": False,
                    "raw_sign": sign,
                    "raw_sExp": hex_bits(raw_s_exp, fmt.exp_w + 2),
                    "raw_sig": hex_bits(raw_sig, fmt.raw_sig_w),
                },
            )

        result.add_stage(
            "stage2_round_register",
            {
                "visible_pipeline_stage": "inner round-input register",
                "round_invalidExc_r": invalid_exc,
                "round_isNaN_r": is_nan,
                "round_isInf_r": is_inf,
                "round_isZero_r": is_zero,
                "round_sign_r": sign,
                "round_sExp_r": hex_bits(raw_s_exp, fmt.exp_w + 2),
                "round_sig_r": hex_bits(raw_sig, fmt.raw_sig_w),
                "round_rm_r": f"{rm} ({ROUNDING_NAMES.get(rm, 'unknown')})",
            },
        )

        final_rec, final_flags = mul3_reference_from_recfn(ops, fmt, rm)
        final_shell = recfn_to_shell(final_rec, fmt)
        result.final_rec_out = final_rec
        result.final_shell_out = final_shell
        result.final_flags = final_flags
        result.add_stage(
            "stage3_output",
            {
                "visible_pipeline_stage": "inner output register + wrapper output register",
                "out_recfn": hex_bits(final_rec, fmt.rec_w),
                "out_shell": hex_bits(final_shell, fmt.shell_w),
                "out_class": recfn_class(final_rec, fmt),
                "out_flags": flag_summary(final_flags),
            },
        )
        return result


class TripleMulAddModel:
    def __init__(self, fmt: FPFormat):
        self.fmt = fmt
        self.unit_name = f"TripleMulAddPipe_l4_{fmt.name}"

    def run(self, rm: int, a_shell: int, b_shell: int, c_shell: int, d_shell: int) -> ModelRunResult:
        fmt = self.fmt
        result = ModelRunResult(unit_name=self.unit_name, fmt=fmt, rm=rm)

        a = decode_recfn(a_shell, fmt)
        b = decode_recfn(b_shell, fmt)
        c = decode_recfn(c_shell, fmt)
        d = decode_recfn(d_shell, fmt)

        result.add_stage(
            "stage0_capture",
            {
                "visible_pipeline_stage": "wrapper input register",
                "rm": f"{rm} ({ROUNDING_NAMES.get(rm, 'unknown')})",
                "a": a.debug_dict(),
                "b": b.debug_dict(),
                "c": c.debug_dict(),
                "d": d.debug_dict(),
            },
        )

        prod_sign = a.sign ^ b.sign ^ c.sign
        any_inf_abc = a.is_inf or b.is_inf or c.is_inf
        any_zero_abc = a.is_zero or b.is_zero or c.is_zero
        invalid_exc = False
        is_nan = False
        is_inf = False
        is_zero = False
        sign = 0
        special_path = "finite_path"

        if a.is_snan or b.is_snan or c.is_snan or d.is_snan:
            invalid_exc = True
            is_nan = True
            special_path = "signaling_nan"
        elif a.is_nan or b.is_nan or c.is_nan or d.is_nan:
            is_nan = True
            special_path = "quiet_nan"
        elif any_inf_abc and any_zero_abc:
            invalid_exc = True
            is_nan = True
            special_path = "product_inf_zero_invalid"
        elif any_inf_abc and d.is_inf and (prod_sign != d.sign):
            invalid_exc = True
            is_nan = True
            special_path = "product_inf_plus_opposite_inf"
        elif any_inf_abc:
            is_inf = True
            sign = prod_sign
            special_path = "product_inf"
        elif d.is_inf:
            is_inf = True
            sign = d.sign
            special_path = "addend_inf"

        result.add_stage(
            "stage1_decode_special",
            {
                "rtl_block": "TripleMulAddRecFNToRaw special-case decode",
                "prod_sign": prod_sign,
                "any_inf_abc": any_inf_abc,
                "any_zero_abc": any_zero_abc,
                "d_is_inf": d.is_inf,
                "d_is_zero": d.is_zero,
                "invalidExc": invalid_exc,
                "selected_path": special_path,
            },
        )

        prod_sig = 0
        prod_exp2 = 0
        if not (is_nan or is_inf) and not any_zero_abc:
            assert a.sig is not None and a.exp2 is not None
            assert b.sig is not None and b.exp2 is not None
            assert c.sig is not None and c.exp2 is not None
            prod_sig = a.sig * b.sig * c.sig
            prod_exp2 = a.exp2 + b.exp2 + c.exp2
            result.add_stage(
                "stage1_finite_product",
                {
                    "sigA": hex_bits(a.sig, fmt.sig_w),
                    "sigB": hex_bits(b.sig, fmt.sig_w),
                    "sigC": hex_bits(c.sig, fmt.sig_w),
                    "prodSig_exact": hex_bits(prod_sig, prod_sig.bit_length()),
                    "prodExp2": prod_exp2,
                },
            )

        if not (is_nan or is_inf):
            addend_sig = 0 if d.is_zero else d.sig
            addend_exp2 = 0 if d.exp2 is None else d.exp2
            if prod_sig == 0 and addend_sig == 0:
                is_zero = True
                sign = 1 if (rm == 2 and (prod_sign or d.sign)) else 0
                result.add_stage(
                    "stage1_add_normalize",
                    {
                        "path": "all_zero",
                        "raw_isZero": True,
                        "raw_sign": sign,
                        "raw_sExp": hex_bits(0, fmt.exp_w + 2),
                        "raw_sig": hex_bits(0, fmt.raw_sig_w),
                    },
                )
            else:
                min_exp2 = addend_exp2 if prod_sig == 0 else (prod_exp2 if addend_sig == 0 else min(prod_exp2, addend_exp2))
                total = 0
                if prod_sig != 0:
                    total += ((-prod_sig) if prod_sign else prod_sig) << (prod_exp2 - min_exp2)
                if addend_sig != 0:
                    total += ((-addend_sig) if d.sign else addend_sig) << (addend_exp2 - min_exp2)
                result.add_stage(
                    "stage1_add_normalize",
                    {
                        "addend_sig": None if addend_sig == 0 else hex_bits(addend_sig, fmt.sig_w),
                        "addend_exp2": addend_exp2,
                        "min_exp2": min_exp2,
                        "sum_exact": "0" if total == 0 else hex(abs(total)),
                        "sum_sign": 1 if total < 0 else 0,
                    },
                )

        raw_s_exp = 0
        raw_sig = 0
        if is_nan or is_inf or is_zero:
            sign = sign if (is_inf or is_zero) else 0
        else:
            if prod_sig == 0 and d.is_zero:
                raw_sig = 0
                raw_s_exp = 0
            else:
                final = decode_recfn(recfn_to_shell(mul3add_reference_from_recfn(a, b, c, d, fmt, rm)[0], fmt), fmt)
                if final.sig is not None and final.exp2 is not None:
                    raw_sig = final.sig << 2
                    raw_s_exp = final.rec_exp & ((1 << (fmt.exp_w + 2)) - 1)

        result.add_stage(
            "stage2_round_register",
            {
                "visible_pipeline_stage": "inner round-input register",
                "round_invalidExc_r": invalid_exc,
                "round_isNaN_r": is_nan,
                "round_isInf_r": is_inf,
                "round_isZero_r": is_zero,
                "round_sign_r": sign,
                "round_sExp_r": hex_bits(raw_s_exp, fmt.exp_w + 2),
                "round_sig_r": hex_bits(raw_sig, fmt.raw_sig_w),
                "round_rm_r": f"{rm} ({ROUNDING_NAMES.get(rm, 'unknown')})",
            },
        )

        final_rec, final_flags = mul3add_reference_from_recfn(a, b, c, d, fmt, rm)
        final_shell = recfn_to_shell(final_rec, fmt)
        result.final_rec_out = final_rec
        result.final_shell_out = final_shell
        result.final_flags = final_flags
        result.add_stage(
            "stage3_output",
            {
                "visible_pipeline_stage": "inner output register + wrapper output register",
                "out_recfn": hex_bits(final_rec, fmt.rec_w),
                "out_shell": hex_bits(final_shell, fmt.shell_w),
                "out_class": recfn_class(final_rec, fmt),
                "out_flags": flag_summary(final_flags),
            },
        )
        return result


UNITS: dict[str, tuple[str, FPFormat]] = {
    "triple_add_f64": ("add", F64),
    "triple_add_f32": ("add", F32),
    "triple_mul_f64": ("mul", F64),
    "triple_mul_f32": ("mul", F32),
    "triple_mul_add_f64": ("muladd", F64),
    "triple_mul_add_f32": ("muladd", F32),
}


def build_model(unit: str) -> TripleAddModel | TripleMulModel | TripleMulAddModel:
    kind, fmt = UNITS[unit]
    if kind == "add":
        return TripleAddModel(fmt)
    if kind == "mul":
        return TripleMulModel(fmt)
    return TripleMulAddModel(fmt)
