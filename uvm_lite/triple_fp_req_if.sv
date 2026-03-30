`timescale 1ns/1ps

interface triple_fp_req_if #(
  parameter int SHELL_W = 65
) (
  input logic clock
);
  logic              valid;
  logic [2:0]        rm;
  logic [SHELL_W-1:0] in1;
  logic [SHELL_W-1:0] in2;
  logic [SHELL_W-1:0] in3;

  modport drv (
    input  clock,
    output valid,
    output rm,
    output in1,
    output in2,
    output in3
  );

  modport mon (
    input clock,
    input valid,
    input rm,
    input in1,
    input in2,
    input in3
  );
endinterface
