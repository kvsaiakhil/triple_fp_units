module TripleMulAddRecFNToRaw #(
  parameter int EXP_W = 11,
  parameter int SIG_W = 53,
  parameter int REC_W = 65
) (
  input  [2:0]             io_roundingMode,
  input  [REC_W-1:0]       io_a,
  input  [REC_W-1:0]       io_b,
  input  [REC_W-1:0]       io_c,
  input  [REC_W-1:0]       io_d,
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
  // Product raw sExp may be signed-negative after normalization, so the
  // alignment span must cover that range when adding the fourth operand.
  localparam int MAX_ALIGN = (1 << (EXP_W + 2)) - 1;
  localparam int TERM_W = (PROD_W > RAW_SIG_W) ? PROD_W : RAW_SIG_W;
  localparam int ACC_W = TERM_W + MAX_ALIGN + 2;
  localparam int SUM_W = ACC_W + 1;
  localparam int BASE_SHIFT = 2 * FRAC_W - 2;
  localparam int ONE_EXP = (1 << EXP_W);
  localparam int SEXP_MAX = (1 << (EXP_W + 1)) - 1;
  localparam int SEXP_MIN = -(1 << (EXP_W + 1));
  localparam int TARGET_NORM_MSB = RAW_SIG_W - 2;
  localparam int TARGET_CARRY_MSB = RAW_SIG_W - 1;

  function automatic [ACC_W-1:0] sticky_rshift_acc(
    input [ACC_W-1:0] value,
    input integer     shamt
  );
    reg [ACC_W-1:0] tmp;
    reg             sticky;
    integer         i;
    begin
      if (shamt <= 0) begin
        sticky_rshift_acc = value;
      end else if (shamt >= ACC_W) begin
        sticky_rshift_acc = {{(ACC_W-1){1'b0}}, |value};
      end else begin
        tmp = value >> shamt;
        sticky = 1'b0;
        for (i = 0; i < shamt; i = i + 1) begin
          sticky = sticky | value[i];
        end
        tmp[0] = tmp[0] | sticky;
        sticky_rshift_acc = tmp;
      end
    end
  endfunction

  function automatic integer msb_index_acc(input [ACC_W-1:0] value);
    integer i;
    begin
      msb_index_acc = -1;
      for (i = 0; i < ACC_W; i = i + 1) begin
        if (value[i]) begin
          msb_index_acc = i;
        end
      end
    end
  endfunction

  wire                signA = io_a[REC_W-1];
  wire                signB = io_b[REC_W-1];
  wire                signC = io_c[REC_W-1];
  wire                signD = io_d[REC_W-1];
  wire [RECEXP_W-1:0] expA  = io_a[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0] expB  = io_b[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0] expC  = io_c[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0] expD  = io_d[REC_W-2 -: RECEXP_W];
  wire [FRAC_W-1:0]   fracA = io_a[FRAC_W-1:0];
  wire [FRAC_W-1:0]   fracB = io_b[FRAC_W-1:0];
  wire [FRAC_W-1:0]   fracC = io_c[FRAC_W-1:0];
  wire [FRAC_W-1:0]   fracD = io_d[FRAC_W-1:0];
  wire [2:0]          topA  = expA[RECEXP_W-1 -: 3];
  wire [2:0]          topB  = expB[RECEXP_W-1 -: 3];
  wire [2:0]          topC  = expC[RECEXP_W-1 -: 3];
  wire [2:0]          topD  = expD[RECEXP_W-1 -: 3];
  wire                isNaNA = (&topA[2:1]) & topA[0];
  wire                isNaNB = (&topB[2:1]) & topB[0];
  wire                isNaNC = (&topC[2:1]) & topC[0];
  wire                isNaND = (&topD[2:1]) & topD[0];
  wire                isInfA = (&topA[2:1]) & ~topA[0];
  wire                isInfB = (&topB[2:1]) & ~topB[0];
  wire                isInfC = (&topC[2:1]) & ~topC[0];
  wire                isInfD = (&topD[2:1]) & ~topD[0];
  wire                isZeroA = ~(|topA);
  wire                isZeroB = ~(|topB);
  wire                isZeroC = ~(|topC);
  wire                isZeroD = ~(|topD);
  wire                isSigNaNA = isNaNA & ~fracA[FRAC_W-1];
  wire                isSigNaNB = isNaNB & ~fracB[FRAC_W-1];
  wire                isSigNaNC = isNaNC & ~fracC[FRAC_W-1];
  wire                isSigNaND = isNaND & ~fracD[FRAC_W-1];
  wire                prodSign = signA ^ signB ^ signC;
  wire                anyInfABC = isInfA | isInfB | isInfC;
  wire                anyZeroABC = isZeroA | isZeroB | isZeroC;
  wire [SIG_W-1:0]    sigA = {1'b1, fracA};
  wire [SIG_W-1:0]    sigB = {1'b1, fracB};
  wire [SIG_W-1:0]    sigC = {1'b1, fracC};

  reg                 invalidExc_r;
  reg                 isNaN_r;
  reg                 isInf_r;
  reg                 isZero_r;
  reg                 sign_r;
  reg [EXP_W+1:0]     sExp_r;
  reg [RAW_SIG_W-1:0] sig_r;

  reg                 prodIsZero;
  reg                 prodIsFinite;
  reg                 prodIsInf;
  reg                 prodIsNaN;
  reg                 prodIsInvalid;
  reg                 prodTermValid;
  reg                 dTermValid;
  reg                 anyNegativeTerm;
  reg [PROD_W-1:0]    prodExact;
  reg [RAW_SIG_W-1:0] dSigExt;
  reg [RAW_SIG_W-1:0] narrowedSig;
  reg [ACC_W-1:0]     wideProd;
  reg [ACC_W-1:0]     wideD;
  reg [ACC_W-1:0]     absSum;
  reg [ACC_W-1:0]     shiftedSum;
  reg [SUM_W-1:0]     absSumWide;
  reg signed [SUM_W-1:0] sumSigned;
  integer             msbIdx;
  integer             shiftAmt;
  integer             prodBaseExpInt;
  integer             dExpInt;
  integer             minExpInt;
  integer             rawExpInt;
  integer             shiftProdAlign;
  integer             shiftDAlign;

  always @* begin
    invalidExc_r = 1'b0;
    isNaN_r = 1'b0;
    isInf_r = 1'b0;
    isZero_r = 1'b0;
    sign_r = 1'b0;
    sExp_r = {(EXP_W+2){1'b0}};
    sig_r = {RAW_SIG_W{1'b0}};

    prodIsZero = 1'b0;
    prodIsFinite = 1'b0;
    prodIsInf = 1'b0;
    prodIsNaN = 1'b0;
    prodIsInvalid = 1'b0;
    prodTermValid = 1'b0;
    dTermValid = 1'b0;
    anyNegativeTerm = 1'b0;
    prodExact = {PROD_W{1'b0}};
    dSigExt = {RAW_SIG_W{1'b0}};
    narrowedSig = {RAW_SIG_W{1'b0}};
    wideProd = {ACC_W{1'b0}};
    wideD = {ACC_W{1'b0}};
    absSum = {ACC_W{1'b0}};
    shiftedSum = {ACC_W{1'b0}};
    absSumWide = {SUM_W{1'b0}};
    sumSigned = {SUM_W{1'b0}};
    msbIdx = -1;
    shiftAmt = 0;
    prodBaseExpInt = 0;
    dExpInt = 0;
    minExpInt = 0;
    rawExpInt = 0;
    shiftProdAlign = 0;
    shiftDAlign = 0;

    if (isSigNaNA | isSigNaNB | isSigNaNC | isSigNaND) begin
      invalidExc_r = 1'b1;
      isNaN_r = 1'b1;
    end else if (isNaNA | isNaNB | isNaNC | isNaND) begin
      isNaN_r = 1'b1;
    end else begin
      prodIsInvalid = anyInfABC & anyZeroABC;
      prodIsInf = anyInfABC & ~anyZeroABC;
      prodIsZero = anyZeroABC & ~anyInfABC;
      prodIsFinite = ~prodIsInvalid & ~prodIsInf & ~prodIsZero;
      prodIsNaN = prodIsInvalid;

      if (prodIsInvalid) begin
        invalidExc_r = 1'b1;
        isNaN_r = 1'b1;
      end else if (prodIsInf & isInfD & (prodSign ^ signD)) begin
        invalidExc_r = 1'b1;
        isNaN_r = 1'b1;
      end else if (prodIsInf) begin
        isInf_r = 1'b1;
        sign_r = prodSign;
      end else if (isInfD) begin
        isInf_r = 1'b1;
        sign_r = signD;
      end else begin
        if (prodIsFinite) begin
          prodExact = sigA * sigB * sigC;
          prodBaseExpInt =
            {{(32-RECEXP_W){1'b0}}, expA} +
            {{(32-RECEXP_W){1'b0}}, expB} +
            {{(32-RECEXP_W){1'b0}}, expC} -
            (2 * ONE_EXP) -
            BASE_SHIFT;
          prodTermValid = 1'b1;
          anyNegativeTerm = prodSign;
        end else if (prodIsZero) begin
          anyNegativeTerm = prodSign;
        end

        if (~isZeroD) begin
          dSigExt = {2'b01, fracD, 2'b00};
          dExpInt = {{(32-RECEXP_W){1'b0}}, expD};
          dTermValid = 1'b1;
          anyNegativeTerm = anyNegativeTerm | signD;
        end else begin
          anyNegativeTerm = anyNegativeTerm | signD;
        end

        if (~prodTermValid & ~dTermValid) begin
          isZero_r = 1'b1;
          sign_r = (io_roundingMode == 3'h2) & anyNegativeTerm;
        end else begin
          if (prodTermValid) begin
            minExpInt = prodBaseExpInt;
          end else begin
            minExpInt = dExpInt;
          end
          if (dTermValid && (~prodTermValid || dExpInt < minExpInt)) begin
            minExpInt = dExpInt;
          end

          if (prodTermValid) begin
            shiftProdAlign = prodBaseExpInt - minExpInt;
            wideProd = {{(ACC_W-PROD_W){1'b0}}, prodExact} << shiftProdAlign;
          end
          if (dTermValid) begin
            shiftDAlign = dExpInt - minExpInt;
            wideD = {{(ACC_W-RAW_SIG_W){1'b0}}, dSigExt} << shiftDAlign;
          end

          sumSigned =
            (prodTermValid ? (prodSign ? -$signed({1'b0, wideProd}) : $signed({1'b0, wideProd})) : {SUM_W{1'b0}}) +
            (dTermValid ? (signD ? -$signed({1'b0, wideD}) : $signed({1'b0, wideD})) : {SUM_W{1'b0}});

          if (sumSigned == {SUM_W{1'b0}}) begin
            isZero_r = 1'b1;
            sign_r = (io_roundingMode == 3'h2) & anyNegativeTerm;
          end else begin
            sign_r = sumSigned[SUM_W-1];
            absSumWide = sign_r ? $unsigned(-sumSigned) : $unsigned(sumSigned);
            absSum = absSumWide[ACC_W-1:0];
            msbIdx = msb_index_acc(absSum);

            if (msbIdx < TARGET_NORM_MSB) begin
              shiftAmt = TARGET_NORM_MSB - msbIdx;
              shiftedSum = absSum << shiftAmt;
              narrowedSig = shiftedSum[RAW_SIG_W-1:0];
              rawExpInt = minExpInt - shiftAmt;
            end else if (msbIdx > TARGET_CARRY_MSB) begin
              shiftAmt = msbIdx - TARGET_CARRY_MSB;
              shiftedSum = sticky_rshift_acc(absSum, shiftAmt);
              narrowedSig = shiftedSum[RAW_SIG_W-1:0];
              rawExpInt = minExpInt + shiftAmt;
            end else begin
              narrowedSig = absSum[RAW_SIG_W-1:0];
              rawExpInt = minExpInt;
            end

            sig_r = narrowedSig;
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
