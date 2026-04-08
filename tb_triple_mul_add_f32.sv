module tb_triple_mul_add_f32;
  reg         clock;
  reg         reset;
  reg         in_valid;
  reg  [2:0]  rm;
  reg  [64:0] in1;
  reg  [64:0] in2;
  reg  [64:0] in3;
  reg  [64:0] in4;
  wire        out_valid;
  wire [64:0] out_data;
  wire [4:0]  out_exc;

  reg  [63:0] enc_in1;
  reg  [63:0] enc_in2;
  reg  [63:0] enc_in3;
  reg  [63:0] enc_in4;
  reg  [63:0] enc_exp;
  wire [32:0] rec_in1;
  wire [32:0] rec_in2;
  wire [32:0] rec_in3;
  wire [32:0] rec_in4;
  wire [32:0] rec_exp;
  wire [4:0]  enc1_exc;
  wire [4:0]  enc2_exc;
  wire [4:0]  enc3_exc;
  wire [4:0]  enc4_exc;
  wire [4:0]  ence_exc;

  localparam [32:0] POS_INF  = {1'b0, 9'h180, 23'h0};
  localparam [32:0] NEG_INF  = {1'b1, 9'h180, 23'h0};
  localparam [32:0] POS_ZERO = 33'h0;

  INToRecFN_i64_e8_s24 enc1 (.io_signedIn(1'b1), .io_in(enc_in1), .io_roundingMode(3'h0), .io_out(rec_in1), .io_exceptionFlags(enc1_exc));
  INToRecFN_i64_e8_s24 enc2 (.io_signedIn(1'b1), .io_in(enc_in2), .io_roundingMode(3'h0), .io_out(rec_in2), .io_exceptionFlags(enc2_exc));
  INToRecFN_i64_e8_s24 enc3 (.io_signedIn(1'b1), .io_in(enc_in3), .io_roundingMode(3'h0), .io_out(rec_in3), .io_exceptionFlags(enc3_exc));
  INToRecFN_i64_e8_s24 enc4 (.io_signedIn(1'b1), .io_in(enc_in4), .io_roundingMode(3'h0), .io_out(rec_in4), .io_exceptionFlags(enc4_exc));
  INToRecFN_i64_e8_s24 ence (.io_signedIn(1'b1), .io_in(enc_exp), .io_roundingMode(3'h0), .io_out(rec_exp), .io_exceptionFlags(ence_exc));

  TripleMulAddPipe_l4_f32 dut (
    .clock(clock), .reset(reset), .io_in_valid(in_valid), .io_in_bits_rm(rm),
    .io_in_bits_in1(in1), .io_in_bits_in2(in2), .io_in_bits_in3(in3), .io_in_bits_in4(in4),
    .io_out_valid(out_valid), .io_out_bits_data(out_data), .io_out_bits_exc(out_exc)
  );

  task automatic drive_case(
    input [32:0] a,
    input [32:0] b,
    input [32:0] c,
    input [32:0] d
  );
    begin
      in1 = {32'h0, a};
      in2 = {32'h0, b};
      in3 = {32'h0, c};
      in4 = {32'h0, d};
      in_valid = 1'b1;
      @(posedge clock);
      #1;
      in_valid = 1'b0;
    end
  endtask

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
    in4 = '0;
    enc_in1 = '0;
    enc_in2 = '0;
    enc_in3 = '0;
    enc_in4 = '0;
    enc_exp = '0;

    repeat (3) @(posedge clock);
    reset = 1'b0;

    enc_in1 = 1;
    enc_in2 = 2;
    enc_in3 = 3;
    enc_in4 = 4;
    #1;
    drive_case(rec_in1, rec_in2, rec_in3, rec_in4);
    repeat (3) @(posedge clock);
    enc_exp = 10;
    #1;
    if (!out_valid || out_data[32:0] !== rec_exp || out_exc !== 5'h0) begin
      $display("f32 muladd exact debug: valid=%0d data=%h exp=%h exc=%h", out_valid, out_data[32:0], rec_exp, out_exc);
      $fatal(1, "f32 muladd exact case failed");
    end

    drive_case(POS_INF, rec_in1, rec_in2, rec_in4);
    repeat (3) @(posedge clock);
    #1;
    if (!out_valid || out_data[31:23] !== 9'h180 || out_exc !== 5'h0) begin
      $display("f32 muladd +inf debug: valid=%0d data=%h exc=%h", out_valid, out_data, out_exc);
      $fatal(1, "f32 muladd inf-dominates case failed");
    end

    drive_case(POS_INF, POS_ZERO, rec_in1, rec_in4);
    repeat (3) @(posedge clock);
    #1;
    if (!out_valid || out_data[31:23] !== 9'h1C0 || !out_exc[4]) begin
      $display("f32 muladd inf-zero debug: valid=%0d data=%h exc=%h", out_valid, out_data, out_exc);
      $fatal(1, "f32 muladd inf-zero invalid case failed");
    end

    drive_case(POS_INF, rec_in1, rec_in2, NEG_INF);
    repeat (3) @(posedge clock);
    #1;
    if (!out_valid || out_data[31:23] !== 9'h1C0 || !out_exc[4]) begin
      $display("f32 muladd inf-conflict debug: valid=%0d data=%h exc=%h", out_valid, out_data, out_exc);
      $fatal(1, "f32 muladd inf conflict case failed");
    end

    drive_case(POS_ZERO, rec_in1, rec_in2, rec_in4);
    repeat (3) @(posedge clock);
    #1;
    if (!out_valid || out_data[32:0] !== rec_in4 || out_exc !== 5'h0) begin
      $display("f32 muladd zero-plus-d debug: valid=%0d data=%h exp=%h exc=%h", out_valid, out_data[32:0], rec_in4, out_exc);
      $fatal(1, "f32 muladd zero-plus-d case failed");
    end

    $display("tb_triple_mul_add_f32 PASS");
    $finish;
  end
endmodule
