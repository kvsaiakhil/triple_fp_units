module TripleMulRecFNToRaw #(
  parameter int EXP_W = 11,
  parameter int SIG_W = 53,
  parameter int REC_W = 65
) (
  input  [REC_W-1:0]       io_a,
  input  [REC_W-1:0]       io_b,
  input  [REC_W-1:0]       io_c,
  output                   io_invalidExc,
  output                   io_rawOut_isNaN,
  output                   io_rawOut_isInf,
  output                   io_rawOut_isZero,
  output                   io_rawOut_sign,
  output [EXP_W+1:0]       io_rawOut_sExp,
  output [SIG_W+2:0]       io_rawOut_sig
);

  localparam int RECEXP_W = EXP_W + 1;
  localparam int FRAC_W = SIG_W - 1;
  localparam int RAW_SIG_W = SIG_W + 3;
  localparam int PROD_W = SIG_W * 3;
  localparam int WIDE_SIG_W = RAW_SIG_W + 2;
  localparam int BASE_SHIFT = 2 * FRAC_W - 2;
  localparam int ONE_EXP = (1 << EXP_W);
  localparam int SEXP_MAX = (1 << (EXP_W + 1)) - 1;
  localparam int SEXP_MIN = -(1 << (EXP_W + 1));

  function automatic [WIDE_SIG_W-1:0] sticky_rshift_prod(
    input [PROD_W-1:0] value,
    input integer      shamt
  );
    reg [PROD_W-1:0]      shifted;
    reg [WIDE_SIG_W-1:0] tmp;
    reg                  sticky;
    integer              i;
    begin
      if (shamt <= 0) begin
        sticky_rshift_prod = value[WIDE_SIG_W-1:0];
      end else if (shamt >= PROD_W) begin
        sticky_rshift_prod = {{(WIDE_SIG_W-1){1'b0}}, |value};
      end else begin
        shifted = value >> shamt;
        tmp = shifted[WIDE_SIG_W-1:0];
        sticky = 1'b0;
        for (i = 0; i < shamt; i = i + 1) begin
          sticky = sticky | value[i];
        end
        tmp[0] = tmp[0] | sticky;
        sticky_rshift_prod = tmp;
      end
    end
  endfunction

  function automatic [WIDE_SIG_W-1:0] sticky_rshift_wide(
    input [WIDE_SIG_W-1:0] value,
    input integer          shamt
  );
    reg [WIDE_SIG_W-1:0] tmp;
    reg                  sticky;
    integer              i;
    begin
      if (shamt <= 0) begin
        sticky_rshift_wide = value;
      end else if (shamt >= WIDE_SIG_W) begin
        sticky_rshift_wide = {{(WIDE_SIG_W-1){1'b0}}, |value};
      end else begin
        tmp = value >> shamt;
        sticky = 1'b0;
        for (i = 0; i < shamt; i = i + 1) begin
          sticky = sticky | value[i];
        end
        tmp[0] = tmp[0] | sticky;
        sticky_rshift_wide = tmp;
      end
    end
  endfunction

  function automatic integer msb_index_wide(input [WIDE_SIG_W-1:0] value);
    integer i;
    begin
      msb_index_wide = -1;
      for (i = 0; i < WIDE_SIG_W; i = i + 1) begin
        if (value[i]) begin
          msb_index_wide = i;
        end
      end
    end
  endfunction

  wire                    signA = io_a[REC_W-1];
  wire                    signB = io_b[REC_W-1];
  wire                    signC = io_c[REC_W-1];
  wire [RECEXP_W-1:0]     expA  = io_a[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0]     expB  = io_b[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0]     expC  = io_c[REC_W-2 -: RECEXP_W];
  wire [FRAC_W-1:0]       fracA = io_a[FRAC_W-1:0];
  wire [FRAC_W-1:0]       fracB = io_b[FRAC_W-1:0];
  wire [FRAC_W-1:0]       fracC = io_c[FRAC_W-1:0];
  wire [2:0]              topA  = expA[RECEXP_W-1 -: 3];
  wire [2:0]              topB  = expB[RECEXP_W-1 -: 3];
  wire [2:0]              topC  = expC[RECEXP_W-1 -: 3];
  wire                    isNaNA = (&topA[2:1]) & topA[0];
  wire                    isNaNB = (&topB[2:1]) & topB[0];
  wire                    isNaNC = (&topC[2:1]) & topC[0];
  wire                    isInfA = (&topA[2:1]) & ~topA[0];
  wire                    isInfB = (&topB[2:1]) & ~topB[0];
  wire                    isInfC = (&topC[2:1]) & ~topC[0];
  wire                    isZeroA = ~(|topA);
  wire                    isZeroB = ~(|topB);
  wire                    isZeroC = ~(|topC);
  wire                    isSigNaNA = isNaNA & ~fracA[FRAC_W-1];
  wire                    isSigNaNB = isNaNB & ~fracB[FRAC_W-1];
  wire                    isSigNaNC = isNaNC & ~fracC[FRAC_W-1];
  wire                    anyInf = isInfA | isInfB | isInfC;
  wire                    anyZero = isZeroA | isZeroB | isZeroC;
  wire [SIG_W-1:0]        sigA = {1'b1, fracA};
  wire [SIG_W-1:0]        sigB = {1'b1, fracB};
  wire [SIG_W-1:0]        sigC = {1'b1, fracC};

  reg                     invalidExc_r;
  reg                     isNaN_r;
  reg                     isInf_r;
  reg                     isZero_r;
  reg                     sign_r;
  reg  [EXP_W+1:0]        sExp_r;
  reg  [RAW_SIG_W-1:0]    sig_r;

  reg  [PROD_W-1:0]       prod;
  reg  [WIDE_SIG_W-1:0]   scaledSig;
  reg  [WIDE_SIG_W-1:0]   normSigWide;
  reg  [RAW_SIG_W-1:0]    normSig;
  integer                 msbIdx;
  integer                 shiftAmt;
  integer                 rawExpInt;

  always @* begin
    invalidExc_r = 1'b0;
    isNaN_r = 1'b0;
    isInf_r = 1'b0;
    isZero_r = 1'b0;
    sign_r = signA ^ signB ^ signC;
    sExp_r = {(EXP_W+2){1'b0}};
    sig_r = {RAW_SIG_W{1'b0}};
    prod = {PROD_W{1'b0}};
    scaledSig = {WIDE_SIG_W{1'b0}};
    normSigWide = {WIDE_SIG_W{1'b0}};
    normSig = {RAW_SIG_W{1'b0}};
    msbIdx = -1;
    shiftAmt = 0;
    rawExpInt = 0;

    if (isSigNaNA | isSigNaNB | isSigNaNC) begin
      invalidExc_r = 1'b1;
      isNaN_r = 1'b1;
    end else if (isNaNA | isNaNB | isNaNC) begin
      isNaN_r = 1'b1;
    end else if (anyInf & anyZero) begin
      invalidExc_r = 1'b1;
      isNaN_r = 1'b1;
    end else if (anyInf) begin
      isInf_r = 1'b1;
    end else if (anyZero) begin
      isZero_r = 1'b1;
    end else begin
      prod = sigA * sigB * sigC;
      scaledSig = sticky_rshift_prod(prod, BASE_SHIFT);
      rawExpInt =
        {{(32-RECEXP_W){1'b0}}, expA} +
        {{(32-RECEXP_W){1'b0}}, expB} +
        {{(32-RECEXP_W){1'b0}}, expC} -
        (2 * ONE_EXP);

      msbIdx = msb_index_wide(scaledSig);

      if (msbIdx < RAW_SIG_W-2) begin
        shiftAmt = (RAW_SIG_W-2) - msbIdx;
        normSigWide = scaledSig << shiftAmt;
        normSig = normSigWide[RAW_SIG_W-1:0];
        sig_r = normSig;
        rawExpInt = rawExpInt - shiftAmt;
      end else if (msbIdx > RAW_SIG_W-1) begin
        shiftAmt = msbIdx - (RAW_SIG_W-1);
        normSigWide = sticky_rshift_wide(scaledSig, shiftAmt);
        normSig = normSigWide[RAW_SIG_W-1:0];
        sig_r = normSig;
        rawExpInt = rawExpInt + shiftAmt;
      end else begin
        sig_r = scaledSig[RAW_SIG_W-1:0];
      end

      if (rawExpInt > SEXP_MAX) begin
        sExp_r = SEXP_MAX[EXP_W+1:0];
      end else if (rawExpInt < SEXP_MIN) begin
        sExp_r = SEXP_MIN[EXP_W+1:0];
      end else begin
      if (rawExpInt > SEXP_MAX) begin
        sExp_r = SEXP_MAX[EXP_W+1:0];
      end else if (rawExpInt < SEXP_MIN) begin
        sExp_r = SEXP_MIN[EXP_W+1:0];
      end else begin
        sExp_r = rawExpInt[EXP_W+1:0];
      end
    end
  end
  end

  assign io_invalidExc = invalidExc_r;
  assign io_rawOut_isNaN = isNaN_r;
  assign io_rawOut_isInf = isInf_r;
  assign io_rawOut_isZero = isZero_r;
  assign io_rawOut_sign = sign_r;
  assign io_rawOut_sExp = sExp_r;
  assign io_rawOut_sig = sig_r;
endmodule
