`timescale 1ns/1ps

package triple_fp_uvm_lite_pkg;
  typedef enum int unsigned {
    TRIPLE_OP_ADD = 0,
    TRIPLE_OP_MUL = 1
  } triple_fp_op_e;

  typedef enum int unsigned {
    REC_CLASS_ZERO   = 0,
    REC_CLASS_FINITE = 1,
    REC_CLASS_INF    = 2,
    REC_CLASS_QNAN   = 3,
    REC_CLASS_SNAN   = 4
  } recfn_class_e;

  function automatic recfn_class_e recfn_class(
    input int          precision,
    input logic [64:0] bits
  );
    logic [2:0] class_bits;
    logic       quiet_bit;
    begin
      if (precision == 64) begin
        class_bits = bits[63:61];
        quiet_bit = bits[51];
      end else begin
        class_bits = bits[31:29];
        quiet_bit = bits[22];
      end

      case (class_bits)
        3'b000: recfn_class = REC_CLASS_ZERO;
        3'b110: recfn_class = REC_CLASS_INF;
        3'b111: recfn_class = quiet_bit ? REC_CLASS_QNAN : REC_CLASS_SNAN;
        default: recfn_class = REC_CLASS_FINITE;
      endcase
    end
  endfunction

  function automatic logic recfn_sign(
    input int          precision,
    input logic [64:0] bits
  );
    begin
      recfn_sign = (precision == 64) ? bits[64] : bits[32];
    end
  endfunction

  function automatic logic recfn_is_nan(
    input int          precision,
    input logic [64:0] bits
  );
    recfn_class_e cls;
    begin
      cls = recfn_class(precision, bits);
      recfn_is_nan = (cls == REC_CLASS_QNAN) || (cls == REC_CLASS_SNAN);
    end
  endfunction

  function automatic logic recfn_matches_expected(
    input int          precision,
    input logic [64:0] actual,
    input logic [64:0] expected
  );
    recfn_class_e exp_cls;
    recfn_class_e act_cls;
    begin
      exp_cls = recfn_class(precision, expected);
      act_cls = recfn_class(precision, actual);

      if (exp_cls == REC_CLASS_ZERO || exp_cls == REC_CLASS_INF) begin
        recfn_matches_expected =
          (act_cls == exp_cls) &&
          (recfn_sign(precision, actual) == recfn_sign(precision, expected));
      end else begin
        recfn_matches_expected = (actual == expected);
      end
    end
  endfunction

  function automatic logic [2:0] sign_pattern3(
    input int          precision,
    input logic [64:0] in1,
    input logic [64:0] in2,
    input logic [64:0] in3
  );
    begin
      sign_pattern3 = {
        recfn_sign(precision, in1),
        recfn_sign(precision, in2),
        recfn_sign(precision, in3)
      };
    end
  endfunction

  function automatic logic [2:0] special_combo3(
    input int          precision,
    input logic [64:0] in1,
    input logic [64:0] in2,
    input logic [64:0] in3
  );
    bit has_zero;
    bit has_inf;
    bit has_nan;
    recfn_class_e cls1;
    recfn_class_e cls2;
    recfn_class_e cls3;
    begin
      cls1 = recfn_class(precision, in1);
      cls2 = recfn_class(precision, in2);
      cls3 = recfn_class(precision, in3);

      has_zero = (cls1 == REC_CLASS_ZERO) || (cls2 == REC_CLASS_ZERO) || (cls3 == REC_CLASS_ZERO);
      has_inf = (cls1 == REC_CLASS_INF) || (cls2 == REC_CLASS_INF) || (cls3 == REC_CLASS_INF);
      has_nan =
        (cls1 == REC_CLASS_QNAN) || (cls1 == REC_CLASS_SNAN) ||
        (cls2 == REC_CLASS_QNAN) || (cls2 == REC_CLASS_SNAN) ||
        (cls3 == REC_CLASS_QNAN) || (cls3 == REC_CLASS_SNAN);

      special_combo3 = {has_nan, has_inf, has_zero};
    end
  endfunction
endpackage
