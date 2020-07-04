// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sat Jul  4 15:50:13 2020
// Host        : Blake-Belladonna running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/VivadoProjects/project_1/project_1.srcs/sources_1/ip/signed_multiplier/signed_multiplier_stub.v
// Design      : signed_multiplier
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7vx485tffg1157-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "mult_gen_v12_0_16,Vivado 2019.2" *)
module signed_multiplier(CLK, A, B, P)
/* synthesis syn_black_box black_box_pad_pin="CLK,A[31:0],B[31:0],P[63:0]" */;
  input CLK;
  input [31:0]A;
  input [31:0]B;
  output [63:0]P;
endmodule
