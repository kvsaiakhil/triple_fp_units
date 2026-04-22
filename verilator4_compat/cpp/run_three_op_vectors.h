#pragma once

#include "common.h"

template <typename Top>
int run_three_op_vectors(Top* top, const std::string& path, int rec_w, const std::string& label) {
    std::ifstream fin(path);
    if (!fin) {
        std::cerr << "failed to open vector file: " << path << std::endl;
        return 1;
    }

    top->reset = 1;
    top->io_in_valid = 0;
    top->io_in_bits_rm = 0;
    set_wide(top->io_in_bits_in1, 0);
    set_wide(top->io_in_bits_in2, 0);
    set_wide(top->io_in_bits_in3, 0);
    settle_low(top);
    step_clock(top);
    step_clock(top);
    step_clock(top);
    top->reset = 0;
    settle_low(top);

    std::string line;
    int tests = 0;
    while (std::getline(fin, line)) {
        if (line.empty() || line[0] == '#') {
            continue;
        }

        std::istringstream iss(line);
        std::string mode_s, cmp_s, in1_s, in2_s, in3_s, out_s, exc_s;
        if (!(iss >> mode_s >> cmp_s >> in1_s >> in2_s >> in3_s >> out_s >> exc_s)) {
            std::cerr << "bad vector line in " << path << ": " << line << std::endl;
            return 1;
        }

        const unsigned rm = static_cast<unsigned>(parse_hex_u128(mode_s));
        const unsigned cmp_mode = static_cast<unsigned>(parse_hex_u128(cmp_s));
        const u128 in1 = parse_hex_u128(in1_s);
        const u128 in2 = parse_hex_u128(in2_s);
        const u128 in3 = parse_hex_u128(in3_s);
        const u128 expected_out = parse_hex_u128(out_s);
        const unsigned expected_exc = static_cast<unsigned>(parse_hex_u128(exc_s)) & 0x1f;

        top->io_in_bits_rm = rm & 0x7u;
        set_wide(top->io_in_bits_in1, in1);
        set_wide(top->io_in_bits_in2, in2);
        set_wide(top->io_in_bits_in3, in3);
        top->io_in_valid = 1;
        step_clock(top);
        top->io_in_valid = 0;

        step_clock(top);
        step_clock(top);
        step_clock(top);
        settle_low(top);

        const u128 actual_out = get_wide(top->io_out_bits_data);
        const unsigned actual_exc = top->io_out_bits_exc & 0x1f;
        const bool valid = (top->io_out_valid & 0x1u) != 0;
        if (!valid || !recfn_matches_expected(actual_out, expected_out, rec_w, cmp_mode) || actual_exc != expected_exc) {
            print_three_op_context(label, rm, in1, in2, in3, actual_out, expected_out, actual_exc, expected_exc);
            return 1;
        }
        ++tests;
    }

    std::cout << label << " PASS (" << tests << " checks)" << std::endl;
    return 0;
}
