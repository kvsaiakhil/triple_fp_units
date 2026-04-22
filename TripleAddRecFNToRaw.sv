module TripleAddRecFNToRaw #(
  parameter int EXP_W = 11,
  parameter int SIG_W = 53,
  parameter int REC_W = 65
) (
  input  [2:0]             io_roundingMode,
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
  localparam int MAX_ALIGN = (1 << EXP_W) + FRAC_W - 3;
  localparam int ACC_W = RAW_SIG_W + MAX_ALIGN + 2;
  localparam int SUM_W = ACC_W + 1;
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
  wire [RECEXP_W-1:0] expA  = io_a[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0] expB  = io_b[REC_W-2 -: RECEXP_W];
  wire [RECEXP_W-1:0] expC  = io_c[REC_W-2 -: RECEXP_W];
  wire [FRAC_W-1:0]   fracA = io_a[FRAC_W-1:0];
  wire [FRAC_W-1:0]   fracB = io_b[FRAC_W-1:0];
  wire [FRAC_W-1:0]   fracC = io_c[FRAC_W-1:0];
  wire [2:0]          topA  = expA[RECEXP_W-1 -: 3];
  wire [2:0]          topB  = expB[RECEXP_W-1 -: 3];
  wire [2:0]          topC  = expC[RECEXP_W-1 -: 3];
  wire                isNaNA = (&topA[2:1]) & topA[0];
  wire                isNaNB = (&topB[2:1]) & topB[0];
  wire                isNaNC = (&topC[2:1]) & topC[0];
  wire                isInfA = (&topA[2:1]) & ~topA[0];
  wire                isInfB = (&topB[2:1]) & ~topB[0];
  wire                isInfC = (&topC[2:1]) & ~topC[0];
  wire                isZeroA = ~(|topA);
  wire                isZeroB = ~(|topB);
  wire                isZeroC = ~(|topC);
  wire                isSigNaNA = isNaNA & ~fracA[FRAC_W-1];
  wire                isSigNaNB = isNaNB & ~fracB[FRAC_W-1];
  wire                isSigNaNC = isNaNC & ~fracC[FRAC_W-1];
  wire                hasPosInf = (isInfA & ~signA) | (isInfB & ~signB) | (isInfC & ~signC);
  wire                hasNegInf = (isInfA & signA) | (isInfB & signB) | (isInfC & signC);

  reg                 invalidExc_r;
  reg                 isNaN_r;
  reg                 isInf_r;
  reg                 isZero_r;
  reg                 sign_r;
  reg [EXP_W+1:0]     sExp_r;
  reg [RAW_SIG_W-1:0] sig_r;

  reg [RECEXP_W-1:0]  minExp;
  reg [RAW_SIG_W-1:0] sigA_ext;
  reg [RAW_SIG_W-1:0] sigB_ext;
  reg [RAW_SIG_W-1:0] sigC_ext;
  reg [ACC_W-1:0]     wideA;
  reg [ACC_W-1:0]     wideB;
  reg [ACC_W-1:0]     wideC;
  reg signed [SUM_W-1:0] sumSigned;
  reg [SUM_W-1:0]     absSumWide;
  reg [ACC_W-1:0]     absSum;
  reg [ACC_W-1:0]     shiftedSum;
  reg [RAW_SIG_W-1:0] narrowedSig;
  reg                 anyNegativeFinite;
  integer             shiftA;
  integer             shiftB;
  integer             shiftC;
  integer             msbIdx;
  integer             shiftAmt;
  integer             rawExpInt;

  always @* begin
    invalidExc_r = 1'b0;
    isNaN_r = 1'b0;
    isInf_r = 1'b0;
    isZero_r = 1'b0;
    sign_r = 1'b0;
    sExp_r = {(EXP_W+2){1'b0}};
    sig_r = {RAW_SIG_W{1'b0}};

    minExp = {RECEXP_W{1'b0}};
    sigA_ext = {RAW_SIG_W{1'b0}};
    sigB_ext = {RAW_SIG_W{1'b0}};
    sigC_ext = {RAW_SIG_W{1'b0}};
    wideA = {ACC_W{1'b0}};
    wideB = {ACC_W{1'b0}};
    wideC = {ACC_W{1'b0}};
    sumSigned = {SUM_W{1'b0}};
    absSumWide = {SUM_W{1'b0}};
    absSum = {ACC_W{1'b0}};
    shiftedSum = {ACC_W{1'b0}};
    narrowedSig = {RAW_SIG_W{1'b0}};
    anyNegativeFinite = 1'b0;
    shiftA = 0;
    shiftB = 0;
    shiftC = 0;
    msbIdx = -1;
    shiftAmt = 0;
    rawExpInt = 0;

    if (isSigNaNA | isSigNaNB | isSigNaNC) begin
      invalidExc_r = 1'b1;
      isNaN_r = 1'b1;
    end else if (isNaNA | isNaNB | isNaNC) begin
      isNaN_r = 1'b1;
    end else if (hasPosInf & hasNegInf) begin
      invalidExc_r = 1'b1;
      isNaN_r = 1'b1;
    end else if (hasPosInf | hasNegInf) begin
      isInf_r = 1'b1;
      sign_r = hasNegInf;
    end else begin
      if (~isZeroA) minExp = expA;
      if (~isZeroB && (isZeroA || expB < minExp)) minExp = expB;
      if (~isZeroC && ((isZeroA & isZeroB) || expC < minExp)) minExp = expC;

      if (~isZeroA) begin
        sigA_ext = {2'b01, fracA, 2'b00};
        shiftA = {{(32-RECEXP_W){1'b0}}, expA} - {{(32-RECEXP_W){1'b0}}, minExp};
        wideA = {{(ACC_W-RAW_SIG_W){1'b0}}, sigA_ext} << shiftA;
        anyNegativeFinite = anyNegativeFinite | signA;
      end
      if (~isZeroB) begin
        sigB_ext = {2'b01, fracB, 2'b00};
        shiftB = {{(32-RECEXP_W){1'b0}}, expB} - {{(32-RECEXP_W){1'b0}}, minExp};
        wideB = {{(ACC_W-RAW_SIG_W){1'b0}}, sigB_ext} << shiftB;
        anyNegativeFinite = anyNegativeFinite | signB;
      end
      if (~isZeroC) begin
        sigC_ext = {2'b01, fracC, 2'b00};
        shiftC = {{(32-RECEXP_W){1'b0}}, expC} - {{(32-RECEXP_W){1'b0}}, minExp};
        wideC = {{(ACC_W-RAW_SIG_W){1'b0}}, sigC_ext} << shiftC;
        anyNegativeFinite = anyNegativeFinite | signC;
      end

      sumSigned =
        (signA ? -$signed({1'b0, wideA}) : $signed({1'b0, wideA})) +
        (signB ? -$signed({1'b0, wideB}) : $signed({1'b0, wideB})) +
        (signC ? -$signed({1'b0, wideC}) : $signed({1'b0, wideC}));

      if (sumSigned == {SUM_W{1'b0}}) begin
        isZero_r = 1'b1;
        sign_r = (io_roundingMode == 3'h2) & anyNegativeFinite;
      end else begin
        sign_r = sumSigned[SUM_W-1];
        absSumWide = sign_r ? $unsigned(-sumSigned) : $unsigned(sumSigned);
        absSum = absSumWide[ACC_W-1:0];
        msbIdx = msb_index_acc(absSum);

        if (msbIdx < TARGET_NORM_MSB) begin
          shiftAmt = TARGET_NORM_MSB - msbIdx;
          shiftedSum = absSum << shiftAmt;
          narrowedSig = shiftedSum[RAW_SIG_W-1:0];
          rawExpInt = {{(32-RECEXP_W){1'b0}}, minExp} - shiftAmt;
        end else if (msbIdx > TARGET_CARRY_MSB) begin
          shiftAmt = msbIdx - TARGET_CARRY_MSB;
          shiftedSum = sticky_rshift_acc(absSum, shiftAmt);
          narrowedSig = shiftedSum[RAW_SIG_W-1:0];
          rawExpInt = {{(32-RECEXP_W){1'b0}}, minExp} + shiftAmt;
        end else begin
          narrowedSig = absSum[RAW_SIG_W-1:0];
          rawExpInt = {{(32-RECEXP_W){1'b0}}, minExp};
        end

        sig_r = narrowedSig;
        sExp_r = rawExpInt[EXP_W+1:0];
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
