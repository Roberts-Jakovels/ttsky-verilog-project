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

  localparam [11:0] MODN = 12'd3329;

  // uio_in: [1:0] byte index (0..2), [2] load strobe, [3] start, [4] output select (0 = low byte, 1 = high nibble)
  // 3 bytes -> A = {byte1[3:0], byte0}, B = {byte2, byte1[7:4]}
  reg [7:0] bytes[0:2];
  wire [11:0] a = {bytes[1][3:0], bytes[0]};
  wire [11:0] b = {bytes[2], bytes[1][7:4]};

  wire [11:0] y;
  wire        done;

  always @(posedge clk) begin
    if (!rst_n) begin
      bytes[0] <= 8'd0;
      bytes[1] <= 8'd0;
      bytes[2] <= 8'd0;
    end else if (uio_in[2] && uio_in[1:0] < 2'd3) begin
      bytes[uio_in[1:0]] <= ui_in;
    end
  end

  mod_add #(.W(12), .MODN(MODN)) u_mod_add (
      .clk(clk), .rst_n(rst_n), .start(uio_in[3]), .a(a), .b(b), .y(y), .done(done)
  );

  assign uo_out  = uio_in[4] ? {3'b0, done, y[11:8]} : y[7:0];
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in[7:5], 1'b0};

endmodule
