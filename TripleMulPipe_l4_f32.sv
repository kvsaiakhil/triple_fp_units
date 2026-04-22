module TripleMulPipe_l4_f32(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [2:0]  io_in_bits_rm,
  input  [64:0] io_in_bits_in1,
  input  [64:0] io_in_bits_in2,
  input  [64:0] io_in_bits_in3,
  output        io_out_valid,
  output [64:0] io_out_bits_data,
  output [4:0]  io_out_bits_exc
);

  wire [32:0] inner_out;
  wire [4:0]  inner_exc;
  wire        inner_validout;
  wire [31:0] in1_shell_hi = io_in_bits_in1[64:33];
  wire [31:0] in2_shell_hi = io_in_bits_in2[64:33];
  wire [31:0] in3_shell_hi = io_in_bits_in3[64:33];

  reg         valid;
  reg  [2:0]  in_rm;
  reg  [32:0] in1;
  reg  [32:0] in2;
  reg  [32:0] in3;
  reg         out_valid_r;
  reg  [64:0] out_data_r;
  reg  [4:0]  out_exc_r;

  TripleMulRecFNPipe_l2 #(
    .EXP_W (8),
    .SIG_W (24),
    .REC_W (33)
  ) inner_pipe (
    .clock            (clock),
    .reset            (reset),
    .io_validin       (valid),
    .io_roundingMode  (in_rm),
    .io_a             (in1),
    .io_b             (in2),
    .io_c             (in3),
    .io_out           (inner_out),
    .io_exceptionFlags(inner_exc),
    .io_validout      (inner_validout)
  );

  always @(posedge clock) begin
    if (reset) begin
      valid <= 1'b0;
    end else begin
      valid <= io_in_valid;
    end
    if (io_in_valid) begin
      in_rm <= io_in_bits_rm;
      in1 <= io_in_bits_in1[32:0];
      in2 <= io_in_bits_in2[32:0];
      in3 <= io_in_bits_in3[32:0];
    end

    if (inner_validout) begin
      out_data_r <= {32'h0, inner_out};
      out_exc_r <= inner_exc;
    end

    if (reset) begin
      out_valid_r <= 1'b0;
    end else begin
      out_valid_r <= inner_validout;
    end
  end

  assign io_out_valid = out_valid_r;
  assign io_out_bits_data = out_data_r;
  assign io_out_bits_exc = out_exc_r;

  wire _unused_shell_hi_ok = &{1'b0, in1_shell_hi, in2_shell_hi, in3_shell_hi};
endmodule
