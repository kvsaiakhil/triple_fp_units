`timescale 1ns/1ps

module triple_fp_uvm_lite_cov #(
  parameter int PRECISION = 64
) ();
  import triple_fp_uvm_lite_pkg::*;

`ifndef VERILATOR
  triple_fp_op_e sample_op;
  int unsigned   sample_rm;
  recfn_class_e  sample_in1_cls;
  recfn_class_e  sample_in2_cls;
  recfn_class_e  sample_in3_cls;
  recfn_class_e  sample_out_cls;
  logic [2:0]    sample_special_combo;
  logic [2:0]    sample_sign_pattern;
  bit            sample_invalid;
  bit            sample_overflow;
  bit            sample_underflow;
  bit            sample_inexact;

  covergroup triple_fp_cg;
    option.per_instance = 1;

    cp_op: coverpoint sample_op {
      bins add = {TRIPLE_OP_ADD};
      bins mul = {TRIPLE_OP_MUL};
    }

    cp_rm: coverpoint sample_rm {
      bins rne = {0};
      bins rtz = {1};
      bins rdn = {2};
      bins rup = {3};
      bins rmm = {4};
      bins rod = {6};
    }

    cp_in1_cls: coverpoint sample_in1_cls;
    cp_in2_cls: coverpoint sample_in2_cls;
    cp_in3_cls: coverpoint sample_in3_cls;
    cp_out_cls: coverpoint sample_out_cls;

    cp_special_combo: coverpoint sample_special_combo {
      bins none          = {0};
      bins zero_only     = {1};
      bins inf_only      = {2};
      bins zero_inf      = {3};
      bins nan_only      = {4};
      bins zero_nan      = {5};
      bins inf_nan       = {6};
      bins zero_inf_nan  = {7};
    }

    cp_sign_pattern: coverpoint sample_sign_pattern {
      bins patterns[] = {[0:7]};
    }

    cp_invalid: coverpoint sample_invalid {
      bins no = {0};
      bins yes = {1};
    }

    cp_overflow: coverpoint sample_overflow {
      bins no = {0};
      bins yes = {1};
    }

    cp_underflow: coverpoint sample_underflow {
      bins no = {0};
      bins yes = {1};
    }

    cp_inexact: coverpoint sample_inexact {
      bins no = {0};
      bins yes = {1};
    }

    x_op_rm: cross cp_op, cp_rm;
    x_op_special: cross cp_op, cp_special_combo;
    x_op_out_cls: cross cp_op, cp_out_cls;
    x_rm_overflow: cross cp_rm, cp_overflow;
    x_rm_underflow: cross cp_rm, cp_underflow;
    x_sign_op: cross cp_sign_pattern, cp_op;
  endgroup

  initial begin
    triple_fp_cg = new();
  end

  task automatic sample_case(
    input triple_fp_op_e op,
    input logic [2:0]    rm,
    input logic [64:0]   in1,
    input logic [64:0]   in2,
    input logic [64:0]   in3,
    input logic [64:0]   out_data,
    input logic [4:0]    out_exc
  );
    begin
      sample_op = op;
      sample_rm = rm;
      sample_in1_cls = recfn_class(PRECISION, in1);
      sample_in2_cls = recfn_class(PRECISION, in2);
      sample_in3_cls = recfn_class(PRECISION, in3);
      sample_out_cls = recfn_class(PRECISION, out_data);
      sample_special_combo = special_combo3(PRECISION, in1, in2, in3);
      sample_sign_pattern = sign_pattern3(PRECISION, in1, in2, in3);
      sample_invalid = out_exc[4];
      sample_overflow = out_exc[2];
      sample_underflow = out_exc[1];
      sample_inexact = out_exc[0];
      triple_fp_cg.sample();
    end
  endtask

  task automatic report();
    begin
      $display("uvm_lite coverage precision=%0d overall=%0.2f%%", PRECISION, triple_fp_cg.get_inst_coverage());
    end
  endtask
`else
  task automatic sample_case(
    input triple_fp_op_e op,
    input logic [2:0]    rm,
    input logic [64:0]   in1,
    input logic [64:0]   in2,
    input logic [64:0]   in3,
    input logic [64:0]   out_data,
    input logic [4:0]    out_exc
  );
    begin
    end
  endtask

  task automatic report();
    begin
      $display("uvm_lite coverage precision=%0d disabled under Verilator", PRECISION);
    end
  endtask
`endif
endmodule
