`timescale 1ns/1ps

interface triple_fp_rsp_if #(
  parameter int SHELL_W = 65
) (
  input logic clock
);
  logic              valid;
  logic [SHELL_W-1:0] data;
  logic [4:0]        exc;

  modport mon (
    input clock,
    input valid,
    input data,
    input exc
  );
endinterface
