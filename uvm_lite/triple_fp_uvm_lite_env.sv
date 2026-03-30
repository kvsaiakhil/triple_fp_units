`timescale 1ns/1ps

module triple_fp_uvm_lite_env #(
  parameter int PRECISION = 64,
  parameter string ADD_VECTOR_PATH = "",
  parameter string MUL_VECTOR_PATH = ""
) (
  input logic           clock,
  input logic           reset,
  triple_fp_req_if.drv  req_if,
  triple_fp_rsp_if.mon  add_rsp_if,
  triple_fp_rsp_if.mon  mul_rsp_if
);
  import triple_fp_uvm_lite_pkg::*;

  integer         fd;
  integer         rc;
  integer         total_checks;
  integer         add_checks;
  integer         mul_checks;
  logic [3:0]     file_rm;
  logic [3:0]     cmp_mode;
  logic [64:0]    exp_in1;
  logic [64:0]    exp_in2;
  logic [64:0]    exp_in3;
  logic [64:0]    exp_out;
  logic [7:0]     exp_exc;

  triple_fp_uvm_lite_cov #(
    .PRECISION(PRECISION)
  ) cov ();

  task automatic drive_case(
    input logic [2:0]    rm_i,
    input logic [64:0]   in1_i,
    input logic [64:0]   in2_i,
    input logic [64:0]   in3_i
  );
    begin
      req_if.rm = rm_i;
      req_if.in1 = in1_i;
      req_if.in2 = in2_i;
      req_if.in3 = in3_i;
      req_if.valid = 1'b1;
      @(posedge clock);
      #1;
      req_if.valid = 1'b0;
    end
  endtask

  task automatic check_case(
    input triple_fp_op_e op,
    input logic [3:0]    cmp_mode_i,
    input logic [64:0]   exp_out_i,
    input logic [7:0]    exp_exc_i
  );
    logic        rsp_valid;
    logic [64:0] rsp_data;
    logic [4:0]  rsp_exc;
    logic        pass;
    begin
      repeat (3) @(posedge clock);
      #1;

      if (op == TRIPLE_OP_ADD) begin
        rsp_valid = add_rsp_if.valid;
        rsp_data = add_rsp_if.data;
        rsp_exc = add_rsp_if.exc;
      end else begin
        rsp_valid = mul_rsp_if.valid;
        rsp_data = mul_rsp_if.data;
        rsp_exc = mul_rsp_if.exc;
      end

      if (!rsp_valid) begin
        $fatal(1, "uvm_lite %s missing valid", (op == TRIPLE_OP_ADD) ? "add" : "mul");
      end

      if (cmp_mode_i == 0) begin
        pass = recfn_matches_expected(PRECISION, rsp_data, exp_out_i) && (rsp_exc == exp_exc_i[4:0]);
      end else begin
        pass = recfn_is_nan(PRECISION, rsp_data) && (rsp_exc == exp_exc_i[4:0]);
      end

      if (!pass) begin
        $display("uvm_lite %s mismatch precision=%0d rm=%0h in1=%h in2=%h in3=%h",
          (op == TRIPLE_OP_ADD) ? "add" : "mul",
          PRECISION,
          req_if.rm,
          req_if.in1,
          req_if.in2,
          req_if.in3
        );
        $display("uvm_lite %s mismatch out=%h exp=%h exc=%h exp_exc=%h cmp_mode=%0h",
          (op == TRIPLE_OP_ADD) ? "add" : "mul",
          rsp_data,
          exp_out_i,
          rsp_exc,
          exp_exc_i[4:0],
          cmp_mode_i
        );
        $fatal(1, "uvm_lite scoreboard failure");
      end

      cov.sample_case(op, req_if.rm, req_if.in1, req_if.in2, req_if.in3, rsp_data, rsp_exc);
      total_checks = total_checks + 1;
      if (op == TRIPLE_OP_ADD) begin
        add_checks = add_checks + 1;
      end else begin
        mul_checks = mul_checks + 1;
      end
    end
  endtask

  task automatic run_file(
    input string         path,
    input triple_fp_op_e op
  );
    begin
      fd = $fopen(path, "r");
      if (fd == 0) begin
        $fatal(1, "uvm_lite failed to open %s", path);
      end

      while (!$feof(fd)) begin
        rc = $fscanf(fd, "%h %h %h %h %h %h %h\n",
          file_rm,
          cmp_mode,
          exp_in1,
          exp_in2,
          exp_in3,
          exp_out,
          exp_exc
        );

        if (rc != 7) begin
          if (!$feof(fd)) begin
            $fatal(1, "uvm_lite bad vector line in %s", path);
          end
        end else begin
          drive_case(file_rm[2:0], exp_in1, exp_in2, exp_in3);
          check_case(op, cmp_mode, exp_out, exp_exc);
        end
      end

      $fclose(fd);
    end
  endtask

  initial begin
    req_if.valid = 1'b0;
    req_if.rm = 3'h0;
    req_if.in1 = '0;
    req_if.in2 = '0;
    req_if.in3 = '0;
    total_checks = 0;
    add_checks = 0;
    mul_checks = 0;

    @(negedge reset);
    run_file(ADD_VECTOR_PATH, TRIPLE_OP_ADD);
    run_file(MUL_VECTOR_PATH, TRIPLE_OP_MUL);
    cov.report();
    $display("uvm_lite precision=%0d PASS total=%0d add=%0d mul=%0d", PRECISION, total_checks, add_checks, mul_checks);
    $finish;
  end
endmodule
