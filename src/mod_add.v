/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

// Unsigned adder: {cout, s} = a + b + cin
module adder #(
    parameter W = 12
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    input  wire         cin,
    output wire [W-1:0] s,
    output wire         cout
);
  assign {cout, s} = a + b + cin;
endmodule

// Unsigned subtract-by-adder: a - b = a + ~b + 1. cout = 1 means no borrow (a >= b).
// Only builds the operands; the sum itself is produced by a shared adder.
module subtractor #(
    parameter W = 12
) (
    input  wire [W-1:0] b,
    output wire [W-1:0] b_inv,
    output wire         cin
);
  assign b_inv = ~b;
  assign cin   = 1'b1;
endmodule

// y = (a + b) mod MODN, unsigned, valid for a, b < MODN.
// A single adder is time-shared: cycle 1 computes a + b, cycle 2 reuses it
// (operands muxed to sum - MODN) and keeps the result if there was no borrow.
module mod_add #(
    parameter W = 12,
    parameter [W-1:0] MODN = 12'd3329
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    output reg  [W-1:0] y,
    output reg          done
);
  localparam IDLE = 2'd0, ADD = 2'd1, SUB = 2'd2;

  reg [1:0]   state;
  reg [W:0]   sum;  // W+1 bits, holds a + b

  wire [W:0]  sub_binv;
  wire        sub_cin;
  subtractor #(.W(W + 1)) u_sub (.b({1'b0, MODN}), .b_inv(sub_binv), .cin(sub_cin));

  // Operand mux for the shared adder
  wire        is_sub = (state == SUB);
  wire [W:0]  op_a   = is_sub ? sum      : {1'b0, a};
  wire [W:0]  op_b   = is_sub ? sub_binv : {1'b0, b};
  wire        op_cin = is_sub ? sub_cin  : 1'b0;

  wire [W:0]  res;
  wire        cout;
  adder #(.W(W + 1)) u_add (.a(op_a), .b(op_b), .cin(op_cin), .s(res), .cout(cout));

  always @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
      sum   <= 0;
      y     <= 0;
      done  <= 1'b0;
    end else begin
      case (state)
        IDLE: if (start) begin
          done  <= 1'b0;
          state <= ADD;
        end
        ADD: begin
          sum   <= res;
          state <= SUB;
        end
        SUB: begin
          y     <= cout ? res[W-1:0] : sum[W-1:0];
          done  <= 1'b1;
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule
