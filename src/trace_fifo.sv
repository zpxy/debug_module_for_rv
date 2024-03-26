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

`ifndef TRACE_FIFO_SV
`define TRACE_FIFO_SV


module trace_fifo (
    input clk,
    input rst_n,

    input logic rd_en,
    output logic rd_empty,
    //output logic [2:0] rd_num,

    output logic [31:0] index_o,
    output logic [31:0] hart_pc_o,
    output logic [31:0] hart_code_o,
    output logic [31:0] hart_ra_o,
    output logic [31:0] hart_sp_o,
    output logic [31:0] hart_a0_o,
    output logic [31:0] hart_t0_o,

    input logic wr_en,
    output logic wr_full,
    //output logic [2:0] wr_num,

    input logic [31:0] hart_pc_i,
    input logic [31:0] hart_code_i,
    input logic [31:0] hart_ra_i,
    input logic [31:0] hart_sp_i,
    input logic [31:0] hart_a0_i,
    input logic [31:0] hart_t0_i
);
    
// logic [31:0] pc[0:7];
// logic [31:0] code[0:7];
// logic [31:0] ra[0:7];
// logic [31:0] sp[0:7];
// logic [31:0] a0[0:7];
// logic [31:0] t0[0:7];
// logic [31:0] index[0:7];

logic [31:0] pc[7:0];
logic [31:0] code[7:0];
logic [31:0] ra[7:0];
logic [31:0] sp[7:0];
logic [31:0] a0[7:0];
logic [31:0] t0[7:0];
logic [31:0] index[7:0];

logic [31:0] wr_index;
logic [2:0] wr_ptr;
logic [2:0] rd_ptr;
// logic [2:0] wr_num_r;
// logic [2:0] rd_num_r;
logic fifo_empty;
logic fifo_full;
logic gb;

assign rd_empty = fifo_empty;
assign wr_full  = fifo_full;

//reset
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        pc[7]    <= 32'd0; pc[6]    <= 32'd0; pc[5]    <= 32'd0; pc[5]    <= 32'd0; pc[4]    <= 32'd0; pc[3]    <= 32'd0; pc[2]    <= 32'd0; pc[1]    <= 32'd0; pc[0]    <= 32'd0;
        code[7]  <= 32'd0; code[6]  <= 32'd0; code[5]  <= 32'd0; code[5]  <= 32'd0; code[4]  <= 32'd0; code[3]  <= 32'd0; code[2]  <= 32'd0; code[1]  <= 32'd0; code[0]  <= 32'd0;
        ra[7]    <= 32'd0; ra[6]    <= 32'd0; ra[5]    <= 32'd0; ra[5]    <= 32'd0; ra[4]    <= 32'd0; ra[3]    <= 32'd0; ra[2]    <= 32'd0; ra[1]    <= 32'd0; ra[0]    <= 32'd0;
        sp[7]    <= 32'd0; sp[6]    <= 32'd0; sp[5]    <= 32'd0; sp[5]    <= 32'd0; sp[4]    <= 32'd0; sp[3]    <= 32'd0; sp[2]    <= 32'd0; sp[1]    <= 32'd0; sp[0]    <= 32'd0;
        a0[7]    <= 32'd0; a0[6]    <= 32'd0; a0[5]    <= 32'd0; a0[5]    <= 32'd0; a0[4]    <= 32'd0; a0[3]    <= 32'd0; a0[2]    <= 32'd0; a0[1]    <= 32'd0; a0[0]    <= 32'd0;
        t0[7]    <= 32'd0; t0[6]    <= 32'd0; t0[5]    <= 32'd0; t0[5]    <= 32'd0; t0[4]    <= 32'd0; t0[3]    <= 32'd0; t0[2]    <= 32'd0; t0[1]    <= 32'd0; t0[0]    <= 32'd0;
        index[7] <= 32'd0; index[6] <= 32'd0; index[5] <= 32'd0; index[5] <= 32'd0; index[4] <= 32'd0; index[3] <= 32'd0; index[2] <= 32'd0; index[1] <= 32'd0; index[0] <= 32'd0;
        wr_ptr   <= 3'h0;
        rd_ptr   <= 3'h0;
        // wr_num_r <= 3'h0;
        // rd_num_r <= 3'h0;
        wr_index <= 32'h0;

        hart_pc_o   <= 32'h0;
        hart_code_o <= 32'h0;
        hart_ra_o   <= 32'h0;
        hart_sp_o   <= 32'h0;
        hart_a0_o   <= 32'h0; 
        hart_t0_o   <= 32'h0;
        index_o     <= 32'h0;
    end
    else begin
        // 只要有写就能写入
        if(wr_en) begin
            pc[wr_ptr]   <= hart_pc_i;
            code[wr_ptr] <= hart_code_i;
            ra[wr_ptr]   <= hart_ra_i;
            sp[wr_ptr]   <= hart_sp_i;
            a0[wr_ptr]   <= hart_a0_i;
            t0[wr_ptr]   <= hart_t0_i;
            index[wr_ptr] <= wr_index;
            wr_index      <= wr_index + 32'h1;
            wr_ptr        <= wr_ptr+3'h1;
            //保证读出的数据是最老的,因为被覆盖就是最新的数据，而这是一个先进先出队列，需要保持顺序性
            if(fifo_full) begin
                rd_ptr      <= rd_ptr+3'h1;
            end
        end
        // fifo 空的时候不能再读，此时数据无效
        if(rd_en && ~fifo_empty) begin
            hart_pc_o   <= pc[rd_ptr];   
            hart_code_o <= code[rd_ptr]; 
            hart_ra_o   <= ra[rd_ptr];   
            hart_sp_o   <= sp[rd_ptr];  
            hart_a0_o   <= a0[rd_ptr];  
            hart_t0_o   <= t0[rd_ptr];    
            index_o     <= index[rd_ptr];
            rd_ptr      <= rd_ptr+3'h1;
        end
    end
end

//状态产生器
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        fifo_empty  <= '1;
        fifo_full   <= '0;
    end
    else  begin
        if (wr_en) begin
            fifo_empty <='0;
        end
        else begin  
        end
        if(wr_en && (rd_ptr == (wr_ptr+3'h1))) begin
            fifo_full  <=  '1;
        end
        else begin      
        end

        if(rd_en) begin 
            fifo_full  <= '0; 
        end
        else begin         
        end
        if (rd_en && (wr_ptr == (rd_ptr+3'h1))) begin
            fifo_empty <= '1;
        end
        else begin            
        end
    end
end

endmodule

`endif