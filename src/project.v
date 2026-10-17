/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // 64-bit register file: 8 bytes x 8 bits, used to check how many tiles
  // a plain flop-based register bank needs.
  //   uio_in[2:0] = byte address
  //   uio_in[3]   = write enable (writes ui_in to the addressed byte)
  //   uo_out      = addressed byte (combinational read)
  reg [7:0] mem[0:7];
  wire [2:0] addr = uio_in[2:0];
  wire       we   = uio_in[3];

  integer i;
  always @(posedge clk) begin
    if (!rst_n) begin
      for (i = 0; i < 8; i = i + 1) mem[i] <= 8'h00;
    end else if (we) begin
      mem[addr] <= ui_in;
    end
  end

  assign uo_out  = mem[addr];
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:4], 1'b0};

endmodule
