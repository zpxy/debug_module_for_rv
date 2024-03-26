//------------------------------------------------------------------------------
// MIT License
// 
// Copyright (c) [2024] [ZhaoPeng Hainan University]
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 
// File: [risc-v 0.13.2 debug module on chip ,add spi flash access and simple trace]
// Author: [ZhaoPeng]
// Description: [For external debug using 5-wire jtag!]
// Created on: [2024-03-12 compelte this basic version in System verilog.]
//------------------------------------------------------------------------------

module DebugModule_top (
    input clk,
    input rst_n,
    // jtag signal,slow clock
    input  jtag_tck,
    input  jtag_rst_n,
    input  jtag_tms,
    input  jtag_tdi,
    output logic jtag_tdo,
    output logic jtag_tdo_vld,
    // spi signal 
    // output logic spi_csn,
    // output logic spi_sclk,
    // output logic spi_mosi,
    // input        spi_miso,
    //core signal
    input        core_is_in_reset,
    output logic ndmreset,
    output logic debug_irq

);

DebugModule u_debug_module(
    .clk(clk),
    .rst_n(rst_n),
    // jtag signal,slow clock
    .jtag_tck(jtag_tck),
    .jtag_rst_n(jtag_rst_n),
    .jtag_tms(jtag_tms),
    .jtag_tdi(jtag_tdi),
    .jtag_tdo(jtag_tdo),
    .jtag_tdo_vld(jtag_tdo_vld),
    // spi signal 
    // .spi_csn(spi_csn),
    // .spi_sclk(spi_sclk),
    // .spi_mosi(spi_mosi),
    // .spi_miso(spi_miso),
    //core signal
    .core_is_in_reset(core_is_in_reset),
    .ndmreset(ndmreset),
    .debug_irq(debug_irq)
);

endmodule