module tb_triple_mul_add_random_f32;
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

  integer fd;
  integer rc;
  integer tests;
  reg  [3:0]  mode;
  reg  [3:0]  cmp_mode;
  reg  [64:0] exp_in1;
  reg  [64:0] exp_in2;
  reg  [64:0] exp_in3;
  reg  [64:0] exp_in4;
  reg  [64:0] exp_out;
  reg  [7:0]  exp_exc;

  TripleMulAddPipe_l4_f32 dut (
    .clock(clock), .reset(reset), .io_in_valid(in_valid), .io_in_bits_rm(rm),
    .io_in_bits_in1(in1), .io_in_bits_in2(in2), .io_in_bits_in3(in3), .io_in_bits_in4(in4),
    .io_out_valid(out_valid), .io_out_bits_data(out_data), .io_out_bits_exc(out_exc)
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
    input [64:0]  d_i;
    begin
      rm = rm_i;
      in1 = a_i;
      in2 = b_i;
      in3 = c_i;
      in4 = d_i;
      in_valid = 1'b1;
      @(posedge clock);
      #1;
      in_valid = 1'b0;
    end
  endtask

  task automatic check_case;
    input [3:0]   cmp_i;
    input [64:0]  out_i;
    input [4:0]   exc_i;
    input         valid_i;
    input [64:0]  exp_out_i;
    input [7:0]   exp_exc_i;
    begin
      if (!valid_i) $fatal(1, "f32 muladd vector missing valid");
      if (cmp_i == 0) begin
        if (
          ((exp_out_i[31:29] === 3'b000) && !(out_i[32] === exp_out_i[32] && out_i[31:29] === 3'b000)) ||
          ((exp_out_i[31:29] === 3'b110) && !(out_i[32] === exp_out_i[32] && out_i[31:29] === 3'b110)) ||
          ((exp_out_i[31:29] !== 3'b000 && exp_out_i[31:29] !== 3'b110) && (out_i[32:0] !== exp_out_i[32:0])) ||
          exc_i !== exp_exc_i[4:0]
        ) begin
          $display("f32 muladd mismatch rm=%0h in1=%h in2=%h in3=%h in4=%h", rm, in1, in2, in3, in4);
          $display("f32 muladd mismatch out=%h exp=%h exc=%h exp_exc=%h", out_i[32:0], exp_out_i[32:0], exc_i, exp_exc_i[4:0]);
          $fatal(1, "f32 muladd exact vector failed");
        end
      end else begin
        if (out_i[31:29] !== 3'b111 || exc_i !== exp_exc_i[4:0]) begin
          $display("f32 muladd NaN mismatch rm=%0h in1=%h in2=%h in3=%h in4=%h", rm, in1, in2, in3, in4);
          $display("f32 muladd NaN mismatch out=%h exc=%h exp_exc=%h", out_i[32:0], exc_i, exp_exc_i[4:0]);
          $fatal(1, "f32 muladd NaN vector failed");
        end
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    in_valid = 1'b0;
    rm = 3'h0;
    in1 = '0;
    in2 = '0;
    in3 = '0;
    in4 = '0;
    tests = 0;

    repeat (3) @(posedge clock);
    reset = 1'b0;

    fd = $fopen("verif/vectors/vectors_f32_muladd.txt", "r");
    if (fd == 0) $fatal(1, "failed to open muladd f32 vectors");
    while (!$feof(fd)) begin
      rc = $fscanf(fd, "%h %h %h %h %h %h %h %h\n", mode, cmp_mode, exp_in1, exp_in2, exp_in3, exp_in4, exp_out, exp_exc);
      if (rc != 8) begin
        if (!$feof(fd)) $fatal(1, "bad vector line in f32 muladd file");
      end else begin
        drive_case(mode[2:0], exp_in1, exp_in2, exp_in3, exp_in4);
        repeat (3) @(posedge clock);
        #1;
        check_case(cmp_mode, out_data, out_exc, out_valid, exp_out, exp_exc);
        tests = tests + 1;
      end
    end
    $fclose(fd);

    $display("tb_triple_mul_add_random_f32 PASS (%0d checks)", tests);
    $finish;
  end
endmodule
