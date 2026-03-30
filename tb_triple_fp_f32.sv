module tb_triple_fp_f32;
  reg         clock;
  reg         reset;
  reg         in_valid;
  reg  [2:0]  rm;
  reg  [64:0] in1;
  reg  [64:0] in2;
  reg  [64:0] in3;
  wire        add_valid;
  wire [64:0] add_data;
  wire [4:0]  add_exc;
  wire        mul_valid;
  wire [64:0] mul_data;
  wire [4:0]  mul_exc;

  reg  [63:0] enc_in1;
  reg  [63:0] enc_in2;
  reg  [63:0] enc_in3;
  reg  [63:0] enc_exp;
  wire [32:0] rec_in1;
  wire [32:0] rec_in2;
  wire [32:0] rec_in3;
  wire [32:0] rec_exp;
  wire [4:0]  enc1_exc;
  wire [4:0]  enc2_exc;
  wire [4:0]  enc3_exc;
  wire [4:0]  ence_exc;

  localparam [32:0] POS_INF  = {1'b0, 9'h180, 23'h0};
  localparam [32:0] NEG_INF  = {1'b1, 9'h180, 23'h0};
  localparam [32:0] POS_ZERO = 33'h0;

  INToRecFN_i64_e8_s24 enc1 (.io_signedIn(1'b1), .io_in(enc_in1), .io_roundingMode(3'h0), .io_out(rec_in1), .io_exceptionFlags(enc1_exc));
  INToRecFN_i64_e8_s24 enc2 (.io_signedIn(1'b1), .io_in(enc_in2), .io_roundingMode(3'h0), .io_out(rec_in2), .io_exceptionFlags(enc2_exc));
  INToRecFN_i64_e8_s24 enc3 (.io_signedIn(1'b1), .io_in(enc_in3), .io_roundingMode(3'h0), .io_out(rec_in3), .io_exceptionFlags(enc3_exc));
  INToRecFN_i64_e8_s24 ence (.io_signedIn(1'b1), .io_in(enc_exp), .io_roundingMode(3'h0), .io_out(rec_exp), .io_exceptionFlags(ence_exc));

  TripleAddPipe_l4_f32 dut_add (
    .clock(clock), .reset(reset), .io_in_valid(in_valid), .io_in_bits_rm(rm),
    .io_in_bits_in1(in1), .io_in_bits_in2(in2), .io_in_bits_in3(in3),
    .io_out_valid(add_valid), .io_out_bits_data(add_data), .io_out_bits_exc(add_exc)
  );

  TripleMulPipe_l4_f32 dut_mul (
    .clock(clock), .reset(reset), .io_in_valid(in_valid), .io_in_bits_rm(rm),
    .io_in_bits_in1(in1), .io_in_bits_in2(in2), .io_in_bits_in3(in3),
    .io_out_valid(mul_valid), .io_out_bits_data(mul_data), .io_out_bits_exc(mul_exc)
  );

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end

  initial begin
    reset = 1'b1;
    in_valid = 1'b0;
    rm = 3'h0;
    in1 = '0;
    in2 = '0;
    in3 = '0;
    enc_in1 = '0;
    enc_in2 = '0;
    enc_in3 = '0;
    enc_exp = '0;

    repeat (3) @(posedge clock);
    reset = 1'b0;

    enc_in1 = 2;
    enc_in2 = 3;
    enc_in3 = 4;
    #1;
    in1 = {32'h0, rec_in1};
    in2 = {32'h0, rec_in2};
    in3 = {32'h0, rec_in3};
    in_valid = 1'b1;
    @(posedge clock);
    #1;
    in_valid = 1'b0;

    repeat (3) @(posedge clock);
    #1;
    enc_exp = 9;
    #1;
    if (!add_valid || add_data[32:0] !== rec_exp || add_exc !== 5'h0) $fatal(1, "f32 add exact-int case failed");
    enc_exp = 24;
    #1;
    if (!mul_valid || mul_data[32:0] !== rec_exp || mul_exc !== 5'h0) $fatal(1, "f32 mul exact-int case failed");

    in1 = {32'h0, POS_INF};
    in2 = {32'h0, rec_in1};
    in3 = {32'h0, rec_in2};
    in_valid = 1'b1;
    @(posedge clock);
    #1;
    in_valid = 1'b0;
    repeat (3) @(posedge clock);
    #1;
    if (!add_valid || add_data[31:23] !== 9'h180) $fatal(1, "f32 add +inf case failed");

    in1 = {32'h0, POS_INF};
    in2 = {32'h0, NEG_INF};
    in3 = {32'h0, POS_ZERO};
    in_valid = 1'b1;
    @(posedge clock);
    #1;
    in_valid = 1'b0;
    repeat (3) @(posedge clock);
    #1;
    if (!add_valid || add_data[31:23] !== 9'h1C0 || !add_exc[4]) $fatal(1, "f32 add inf conflict case failed");

    in1 = {32'h0, POS_INF};
    in2 = {32'h0, POS_ZERO};
    in3 = {32'h0, rec_in1};
    in_valid = 1'b1;
    @(posedge clock);
    #1;
    in_valid = 1'b0;
    repeat (3) @(posedge clock);
    #1;
    if (!mul_valid || mul_data[31:23] !== 9'h1C0 || !mul_exc[4]) $fatal(1, "f32 mul inf-zero invalid case failed");

    $display("tb_triple_fp_f32 PASS");
    $finish;
  end
endmodule
