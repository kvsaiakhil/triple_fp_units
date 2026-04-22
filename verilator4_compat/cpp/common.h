#pragma once

#include "verilated.h"

#include <cstdint>
#include <fstream>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>

using u128 = unsigned __int128;

extern vluint64_t main_time;

inline u128 mask_bits(int width) {
    if (width >= 128) {
        return ~static_cast<u128>(0);
    }
    return (static_cast<u128>(1) << width) - 1;
}

inline u128 parse_hex_u128(const std::string& text) {
    std::string s = text;
    if (s.rfind("0x", 0) == 0 || s.rfind("0X", 0) == 0) {
        s = s.substr(2);
    }
    u128 value = 0;
    for (char c : s) {
        value <<= 4;
        if (c >= '0' && c <= '9') {
            value |= static_cast<u128>(c - '0');
        } else if (c >= 'a' && c <= 'f') {
            value |= static_cast<u128>(10 + (c - 'a'));
        } else if (c >= 'A' && c <= 'F') {
            value |= static_cast<u128>(10 + (c - 'A'));
        } else {
            throw std::runtime_error("invalid hex character in: " + text);
        }
    }
    return value;
}

inline std::string hex_u128(u128 value, int width_bits) {
    const int width_hex = (width_bits + 3) / 4;
    std::string out(width_hex, '0');
    value &= mask_bits(width_bits);
    for (int i = width_hex - 1; i >= 0; --i) {
        const unsigned digit = static_cast<unsigned>(value & 0xf);
        out[i] = static_cast<char>((digit < 10) ? ('0' + digit) : ('a' + digit - 10));
        value >>= 4;
    }
    return out;
}

template <size_t N>
inline void set_wide(WData (&dest)[N], u128 value) {
    for (size_t i = 0; i < N; ++i) {
        dest[i] = static_cast<WData>(value & 0xffffffffu);
        value >>= 32;
    }
}

template <size_t N>
inline u128 get_wide(const WData (&src)[N]) {
    u128 value = 0;
    for (size_t i = N; i-- > 0;) {
        value <<= 32;
        value |= static_cast<u128>(src[i]);
    }
    return value;
}

template <typename Top>
inline void step_clock(Top* top) {
    top->clock = 0;
    top->eval();
    ++main_time;
    top->clock = 1;
    top->eval();
    ++main_time;
}

template <typename Top>
inline void settle_low(Top* top) {
    top->clock = 0;
    top->eval();
}

inline bool recfn_matches_expected(u128 actual_shell, u128 expected_shell, int rec_w, int cmp_mode) {
    const u128 rec_mask = mask_bits(rec_w);
    const u128 actual = actual_shell & rec_mask;
    const u128 expected = expected_shell & rec_mask;
    const int top3_shift = rec_w - 4;
    const unsigned actual_sign = static_cast<unsigned>((actual >> (rec_w - 1)) & 1u);
    const unsigned expected_sign = static_cast<unsigned>((expected >> (rec_w - 1)) & 1u);
    const unsigned actual_top3 = static_cast<unsigned>((actual >> top3_shift) & 0x7u);
    const unsigned expected_top3 = static_cast<unsigned>((expected >> top3_shift) & 0x7u);

    if (cmp_mode == 0) {
        if (expected_top3 == 0u || expected_top3 == 6u) {
            return actual_sign == expected_sign && actual_top3 == expected_top3;
        }
        return actual == expected;
    }
    return actual_top3 == 7u;
}

inline void print_three_op_context(
    const std::string& label,
    unsigned rm,
    u128 in1,
    u128 in2,
    u128 in3,
    u128 actual,
    u128 expected,
    unsigned exc,
    unsigned expected_exc
) {
    std::cerr << label << " mismatch"
              << " rm=" << std::hex << rm
              << " in1=0x" << hex_u128(in1, 65)
              << " in2=0x" << hex_u128(in2, 65)
              << " in3=0x" << hex_u128(in3, 65)
              << " out=0x" << hex_u128(actual, 65)
              << " exp=0x" << hex_u128(expected, 65)
              << " exc=0x" << exc
              << " exp_exc=0x" << expected_exc
              << std::dec << std::endl;
}

inline void print_four_op_context(
    const std::string& label,
    unsigned rm,
    u128 in1,
    u128 in2,
    u128 in3,
    u128 in4,
    u128 actual,
    u128 expected,
    unsigned exc,
    unsigned expected_exc
) {
    std::cerr << label << " mismatch"
              << " rm=" << std::hex << rm
              << " in1=0x" << hex_u128(in1, 65)
              << " in2=0x" << hex_u128(in2, 65)
              << " in3=0x" << hex_u128(in3, 65)
              << " in4=0x" << hex_u128(in4, 65)
              << " out=0x" << hex_u128(actual, 65)
              << " exp=0x" << hex_u128(expected, 65)
              << " exc=0x" << exc
              << " exp_exc=0x" << expected_exc
              << std::dec << std::endl;
}
