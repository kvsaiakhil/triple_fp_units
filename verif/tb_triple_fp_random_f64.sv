module tb_triple_fp_random_f64;
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

  integer fd;
  integer rc;
  integer tests;
  reg  [3:0]  mode;
  reg  [3:0]  cmp_mode;
  reg  [64:0] exp_in1;
  reg  [64:0] exp_in2;
  reg  [64:0] exp_in3;
  reg  [64:0] exp_out;
  reg  [7:0]  exp_exc;

  TripleAddPipe_l4_f64 dut_add (
    .clock(clock), .reset(reset), .io_in_valid(in_valid), .io_in_bits_rm(rm),
    .io_in_bits_in1(in1), .io_in_bits_in2(in2), .io_in_bits_in3(in3),
    .io_out_valid(add_valid), .io_out_bits_data(add_data), .io_out_bits_exc(add_exc)
  );

  TripleMulPipe_l4_f64 dut_mul (
    .clock(clock), .reset(reset), .io_in_valid(in_valid), .io_in_bits_rm(rm),
    .io_in_bits_in1(in1), .io_in_bits_in2(in2), .io_in_bits_in3(in3),
    .io_out_valid(mul_valid), .io_out_bits_data(mul_data), .io_out_bits_exc(mul_exc)
  );

  initial begin
    clock = 1'b0;
    forever #5 clock = ~clock;
  end

  task automatic drive_case;
    input [2:0]   rm_i;
    input [64:0]  a_i;
    input [64:0]  b_i;
    input [64:0]  c_i;
    begin
      rm = rm_i;
      in1 = a_i;
      in2 = b_i;
      in3 = c_i;
      in_valid = 1'b1;
      @(posedge clock);
      #1;
      in_valid = 1'b0;
    end
  endtask

  task automatic check_add_case;
    input [3:0]   cmp_i;
    input [64:0]  out_i;
    input [4:0]   exc_i;
    input         valid_i;
    input [64:0]  exp_out_i;
    input [7:0]   exp_exc_i;
    begin
      if (!valid_i) $fatal(1, "f64 add vector missing valid");
      if (cmp_i == 0) begin
        if (
          ((exp_out_i[63:61] === 3'b000) && !(out_i[64] === exp_out_i[64] && out_i[63:61] === 3'b000)) ||
          ((exp_out_i[63:61] === 3'b110) && !(out_i[64] === exp_out_i[64] && out_i[63:61] === 3'b110)) ||
          ((exp_out_i[63:61] !== 3'b000 && exp_out_i[63:61] !== 3'b110) && (out_i !== exp_out_i)) ||
          exc_i !== exp_exc_i[4:0]
        ) begin
          $display("f64 add mismatch rm=%0h in1=%h in2=%h in3=%h", rm, in1, in2, in3);
          $display("f64 add mismatch out=%h exp=%h exc=%h exp_exc=%h", out_i, exp_out_i, exc_i, exp_exc_i[4:0]);
          $fatal(1, "f64 add exact vector failed");
        end
      end else begin
        if (out_i[63:61] !== 3'b111 || exc_i !== exp_exc_i[4:0]) begin
          $display("f64 add NaN mismatch rm=%0h in1=%h in2=%h in3=%h", rm, in1, in2, in3);
          $display("f64 add NaN mismatch out=%h exc=%h exp_exc=%h", out_i, exc_i, exp_exc_i[4:0]);
          $fatal(1, "f64 add NaN vector failed");
        end
      end
    end
  endtask

  task automatic check_mul_case;
    input [3:0]   cmp_i;
    input [64:0]  out_i;
    input [4:0]   exc_i;
    input         valid_i;
    input [64:0]  exp_out_i;
    input [7:0]   exp_exc_i;
    begin
      if (!valid_i) $fatal(1, "f64 mul vector missing valid");
      if (cmp_i == 0) begin
        if (
          ((exp_out_i[63:61] === 3'b000) && !(out_i[64] === exp_out_i[64] && out_i[63:61] === 3'b000)) ||
          ((exp_out_i[63:61] === 3'b110) && !(out_i[64] === exp_out_i[64] && out_i[63:61] === 3'b110)) ||
          ((exp_out_i[63:61] !== 3'b000 && exp_out_i[63:61] !== 3'b110) && (out_i !== exp_out_i)) ||
          exc_i !== exp_exc_i[4:0]
        ) begin
          $display("f64 mul mismatch rm=%0h in1=%h in2=%h in3=%h", rm, in1, in2, in3);
          $display("f64 mul mismatch out=%h exp=%h exc=%h exp_exc=%h", out_i, exp_out_i, exc_i, exp_exc_i[4:0]);
          $fatal(1, "f64 mul exact vector failed");
        end
      end else begin
        if (out_i[63:61] !== 3'b111 || exc_i !== exp_exc_i[4:0]) begin
          $display("f64 mul NaN mismatch rm=%0h in1=%h in2=%h in3=%h", rm, in1, in2, in3);
          $display("f64 mul NaN mismatch out=%h exc=%h exp_exc=%h", out_i, exc_i, exp_exc_i[4:0]);
          $fatal(1, "f64 mul NaN vector failed");
        end
      end
    end
  endtask

  task automatic run_file;
    input [1023:0] path;
    input          is_mul;
    begin
      fd = $fopen(path, "r");
      if (fd == 0) $fatal(1, "failed to open %0s", path);
      while (!$feof(fd)) begin
        rc = $fscanf(fd, "%h %h %h %h %h %h %h\n", mode, cmp_mode, exp_in1, exp_in2, exp_in3, exp_out, exp_exc);
        if (rc != 7) begin
          if (!$feof(fd)) $fatal(1, "bad vector line in %0s", path);
        end else begin
          drive_case(mode[2:0], exp_in1, exp_in2, exp_in3);
          repeat (3) @(posedge clock);
          #1;
          if (is_mul) begin
            check_mul_case(cmp_mode, mul_data, mul_exc, mul_valid, exp_out, exp_exc);
          end else begin
            check_add_case(cmp_mode, add_data, add_exc, add_valid, exp_out, exp_exc);
          end
          tests = tests + 1;
        end
      end
      $fclose(fd);
    end
  endtask

  initial begin
    reset = 1'b1;
    in_valid = 1'b0;
    rm = 3'h0;
    in1 = '0;
    in2 = '0;
    in3 = '0;
    tests = 0;

    repeat (3) @(posedge clock);
    reset = 1'b0;

    run_file("/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/vectors/vectors_f64_add.txt", 1'b0);
    run_file("/Users/kvsaiakhil/Projects/BoomV3/triple_fp_units/verif/vectors/vectors_f64_mul.txt", 1'b1);

    $display("tb_triple_fp_random_f64 PASS (%0d checks)", tests);
    $finish;
  end
endmodule
