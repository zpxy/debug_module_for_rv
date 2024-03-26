
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
`ifndef TRACE_UPDATE_SV
`define TRACE_UPDATE_SV

module trace_update (
    input clk,
    input rst_n,

    input [31:0] hart_pc_in,
    output logic strace_ram_wr_en
);

localparam addr_branch_offset_aver = 32'h4;

logic [31:0] old_pc;
logic [31:0] cur_pc;

assign cur_pc = hart_pc_in;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        old_pc <= 32'h0;
    end
    else begin
        old_pc <= cur_pc;
    end
end

//only brach pc would update in 
assign strace_ram_wr_en = ((cur_pc - old_pc) > addr_branch_offset_aver) ? '1:'0;
    
endmodule

`endif