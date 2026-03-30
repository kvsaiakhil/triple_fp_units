`timescale 1ns/1ps

module tb_triple_fp_uvm_lite_f64;
  logic clock;
  logic reset;

  triple_fp_req_if #(65) req_if (.clock(clock));
  triple_fp_rsp_if #(65) add_rsp_if (.clock(clock));
  triple_fp_rsp_if #(65) mul_rsp_if (.clock(clock));

  TripleAddPipe_l4_f64 dut_add (
    .clock(clock),
    .reset(reset),
    .io_in_valid(req_if.valid),
    .io_in_bits_rm(req_if.rm),
    .io_in_bits_in1(req_if.in1),
    .io_in_bits_in2(req_if.in2),
    .io_in_bits_in3(req_if.in3),
    .io_out_valid(add_rsp_if.valid),
    .io_out_bits_data(add_rsp_if.data),
    .io_out_bits_exc(add_rsp_if.exc)
  );

  TripleMulPipe_l4_f64 dut_mul (
    .clock(clock),
    .reset(reset),
    .io_in_valid(req_if.valid),
    .io_in_bits_rm(req_if.rm),
    .io_in_bits_in1(req_if.in1),
    .io_in_bits_in2(req_if.in2),
    .io_in_bits_in3(req_if.in3),
    .io_out_valid(mul_rsp_if.valid),
    .io_out_bits_data(mul_rsp_if.data),
    .io_out_bits_exc(mul_rsp_if.exc)
  );

  triple_fp_uvm_lite_env #(
    .PRECISION(64),
    .ADD_VECTOR_PATH("/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/vectors/vectors_f64_add.txt"),
    .MUL_VECTOR_PATH("/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/vectors/vectors_f64_mul.txt")
  ) env (
    .clock(clock),
    .reset(reset),
    .req_if(req_if),
    .add_rsp_if(add_rsp_if),
    .mul_rsp_if(mul_rsp_if)
  );

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1'b1;
    repeat (3) @(posedge clock);
    reset = 1'b0;
  end
endmodule
