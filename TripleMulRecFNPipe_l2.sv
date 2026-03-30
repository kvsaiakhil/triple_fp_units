module TripleMulRecFNPipe_l2 #(
  parameter int EXP_W = 11,
  parameter int SIG_W = 53,
  parameter int REC_W = 65
) (
  input                    clock,
  input                    reset,
  input                    io_validin,
  input  [2:0]             io_roundingMode,
  input  [REC_W-1:0]       io_a,
  input  [REC_W-1:0]       io_b,
  input  [REC_W-1:0]       io_c,
  output [REC_W-1:0]       io_out,
  output [4:0]             io_exceptionFlags,
  output                   io_validout
);

  localparam int RAW_EXP_W = EXP_W + 2;
  localparam int RAW_SIG_W = SIG_W + 3;

  wire                     raw_invalidExc;
  wire                     raw_isNaN;
  wire                     raw_isInf;
  wire                     raw_isZero;
  wire                     raw_sign;
  wire [RAW_EXP_W-1:0]     raw_sExp;
  wire [RAW_SIG_W-1:0]     raw_sig;
  wire [REC_W-1:0]         round_out;
  wire [4:0]               round_flags;

  reg                      stage0_valid;
  reg                      out_valid_r;
  reg                      round_invalidExc_r;
  reg                      round_isNaN_r;
  reg                      round_isInf_r;
  reg                      round_isZero_r;
  reg                      round_sign_r;
  reg  [RAW_EXP_W-1:0]     round_sExp_r;
  reg  [RAW_SIG_W-1:0]     round_sig_r;
  reg  [2:0]               round_rm_r;
  reg  [REC_W-1:0]         out_data_r;
  reg  [4:0]               out_exc_r;

  TripleMulRecFNToRaw #(
    .EXP_W (EXP_W),
    .SIG_W (SIG_W),
    .REC_W (REC_W)
  ) raw_core (
    .io_a             (io_a),
    .io_b             (io_b),
    .io_c             (io_c),
    .io_invalidExc    (raw_invalidExc),
    .io_rawOut_isNaN  (raw_isNaN),
    .io_rawOut_isInf  (raw_isInf),
    .io_rawOut_isZero (raw_isZero),
    .io_rawOut_sign   (raw_sign),
    .io_rawOut_sExp   (raw_sExp),
    .io_rawOut_sig    (raw_sig)
  );

  generate
    if (EXP_W == 11) begin : gen_f64
      RoundRawFNToRecFN_e11_s53 rounder (
        .io_invalidExc     (round_invalidExc_r),
        .io_in_isNaN       (round_isNaN_r),
        .io_in_isInf       (round_isInf_r),
        .io_in_isZero      (round_isZero_r),
        .io_in_sign        (round_sign_r),
        .io_in_sExp        (round_sExp_r),
        .io_in_sig         (round_sig_r),
        .io_roundingMode   (round_rm_r),
        .io_out            (round_out),
        .io_exceptionFlags (round_flags)
      );
    end else begin : gen_f32
      RoundRawFNToRecFN_e8_s24 rounder (
        .io_invalidExc     (round_invalidExc_r),
        .io_in_isNaN       (round_isNaN_r),
        .io_in_isInf       (round_isInf_r),
        .io_in_isZero      (round_isZero_r),
        .io_in_sign        (round_sign_r),
        .io_in_sExp        (round_sExp_r),
        .io_in_sig         (round_sig_r),
        .io_roundingMode   (round_rm_r),
        .io_out            (round_out),
        .io_exceptionFlags (round_flags)
      );
    end
  endgenerate

  always @(posedge clock) begin
    if (io_validin) begin
      round_invalidExc_r <= raw_invalidExc;
      round_isNaN_r <= raw_isNaN;
      round_isInf_r <= raw_isInf;
      round_isZero_r <= raw_isZero;
      round_sign_r <= raw_sign;
      round_sExp_r <= raw_sExp;
      round_sig_r <= raw_sig;
      round_rm_r <= io_roundingMode;
    end

    if (stage0_valid) begin
      out_data_r <= round_out;
      out_exc_r <= round_flags;
    end

    if (reset) begin
      stage0_valid <= 1'b0;
      out_valid_r <= 1'b0;
    end else begin
      stage0_valid <= io_validin;
      out_valid_r <= stage0_valid;
    end
  end

  assign io_out = out_data_r;
  assign io_exceptionFlags = out_exc_r;
  assign io_validout = out_valid_r;
endmodule
