<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Computes `(A + B) mod 3329` for unsigned 12-bit A, B < 3329. One shared adder is used twice: cycle 1 computes A+B, cycle 2 reuses it (operands muxed to `sum + ~MODN + 1`) and keeps the result if there was no borrow.

## How to test

Write three bytes on `ui_in` with `uio[2]` (load) high and `uio[1:0]` = 0,1,2: A = {byte1[3:0], byte0}, B = {byte2, byte1[7:4]}. Pulse `uio[3]` (start), wait 3 clocks, read `uo_out` (low 8 bits of result). Set `uio[4]` to read {0,0,0,done,result[11:8]}. The pin protocol is a template and may change.

## External hardware

List external hardware used in your project (e.g. PMOD, LED display, etc), if any
