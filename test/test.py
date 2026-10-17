# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

MODN = 3329


async def mod_add(dut, a, b):
    data = [a & 0xFF, ((b & 0xF) << 4) | (a >> 8), b >> 4]
    for i, d in enumerate(data):
        dut.ui_in.value = d
        dut.uio_in.value = 0x4 | i
        await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0x8
    await ClockCycles(dut.clk, 1)
    dut.uio_in.value = 0
    await ClockCycles(dut.clk, 3)
    lo = int(dut.uo_out.value)
    dut.uio_in.value = 0x10
    await ClockCycles(dut.clk, 1)
    hi = int(dut.uo_out.value)
    assert hi & 0x10, "done not set"
    dut.uio_in.value = 0
    return ((hi & 0xF) << 8) | lo


@cocotb.test()
async def test_project(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="us").start())
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    cases = [(0, 0), (1, 2), (3328, 1), (3328, 3328), (1665, 1664), (1665, 1665)]
    cases += [(random.randrange(MODN), random.randrange(MODN)) for _ in range(100)]
    for a, b in cases:
        got = await mod_add(dut, a, b)
        assert got == (a + b) % MODN, f"{a}+{b}: got {got}, want {(a + b) % MODN}"
