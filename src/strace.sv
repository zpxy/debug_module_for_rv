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

`ifndef STRACE_SV
`define STRACE_SV
 
module strace (
    input clk,
    input rst_n,
    //dtm <--> strace ,like  apb // now link to afifo
    input  req_vld,
    output logic req_rdy,
    input logic [1:0] req_opt_code,
    input logic [6:0] req_addr,
    input logic [31:0] req_data,

    output logic resp_vld,
    input  resp_rdy,
    output logic [1:0] resp_sta_code,
    output logic [6:0] resp_addr,
    output logic [31:0] resp_data,
    
    //from hart 
    input [31:0] hart_pc,
    input [31:0] hart_code,
    input [31:0] hart_ra,
    input [31:0] hart_sp,
    input [31:0] hart_a0,
    input [31:0] hart_t0
);

logic rd_empty;
logic wr_full;

logic rd_en;
logic rd_ing;
logic wr_en;

logic [31:0] hart_pc_i;
logic [31:0] hart_code_i;
logic [31:0] hart_ra_i;
logic [31:0] hart_sp_i;
logic [31:0] hart_a0_i;
logic [31:0] hart_t0_i;

logic [31:0] index_o;
logic [31:0] hart_pc_o;
logic [31:0] hart_code_o;
logic [31:0] hart_ra_o;
logic [31:0] hart_sp_o;
logic [31:0] hart_a0_o;
logic [31:0] hart_t0_o;

logic [31:0] index_r;     //7'h20
logic [31:0] hart_pc_r;   //7'h21
logic [31:0] hart_code_r; //7'h22
logic [31:0] hart_ra_r;   //7'h23
logic [31:0] hart_sp_r;   //7'h24
logic [31:0] hart_a0_r;   //7'h25
logic [31:0] hart_t0_r;   //7'h26

assign hart_pc_i   = hart_pc;
assign hart_code_i = hart_code;
assign hart_ra_i   = hart_ra;
assign hart_sp_i   = hart_sp;
assign hart_a0_i   = hart_a0;
assign hart_t0_i   = hart_t0;

logic [31:0] trace_magic;//7'h12
logic [31:0] trace_magic_r;
logic [31:0] trace_sr; // 7'h11;
logic [31:0] trace_cr; // 7'h10;
logic [31:0] trace_cr_r;

// logic resp_fire;
logic req_fire;

assign req_fire  = req_vld  && req_rdy;
//assign resp_fire = resp_vld && resp_rdy;

logic [1:0] state;
logic [1:0] state_next;

logic me;  // module en ,if 0 do not any read & write,and update is off  
logic rfl; // read fifo line 
logic [2:0] fuse; // close the module

logic [1:0] sr_rd_fifo_line_state;
logic sr_rd_empty;
logic sr_wr_full;

//state machine surport 
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state    <= 2'b00;
    end
    else  begin
       state <= state_next;
    end
end

logic [2:0]  req_opt_code_r;
logic [6:0]  req_addr_r;
logic [31:0] req_data_r;


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        req_addr_r     <= 7'd0;
        req_data_r     <= 32'd0;
        req_opt_code_r <= 2'd0;
        //trace_magic_r  <= 32'habcd_beaf;
        trace_magic_r  <= 32'hbeaf_cafe;
    end
    else begin 
        req_addr_r <= req_addr;
        req_data_r <= req_data;
        req_opt_code_r <= req_opt_code;
        trace_magic_r <= trace_magic;
    end
end

logic rtl_set_down;
logic [31:0] strace_cr_inner;
logic trace_cr_wrote_by_dtm;
logic [31:0] strace_cr_dtm;



always @(*) begin
    if(~rst_n) begin
        strace_cr_dtm = 32'd0;
        trace_cr_wrote_by_dtm = 1'b0;
        req_rdy     = 1'b1;
        resp_vld    = 1'b0;
        trace_magic = 32'hbeaf_cafe;
        state_next  = 2'b00;
        resp_data   = 32'd0;
        resp_addr   = 7'd0;
        resp_sta_code = 2'd0;
    end
    else begin
        trace_magic = trace_magic_r;//shoule use a reg 
        req_rdy  = 1'b1;
        resp_vld = 1'b0;
        resp_sta_code = 2'b00;
        resp_addr     = 7'd0;
        resp_data     = 32'd0;
        strace_cr_dtm = 32'd0;     //just a net line;
        trace_cr_wrote_by_dtm = 1'b0;
        state_next = 2'b00;
        // req_addr_r is a reg;
        // req_data_r is a reg;
        case (state)
            //idle 
            2'b00:begin
                resp_vld = '0;
                if(req_fire) begin
                    case (req_opt_code)
                        2'b00: state_next = 2'b11;
                        2'b01: begin 
                            state_next = 2'b01;
                        end
                        2'b11: state_next = 2'b11; // 错误需要跳到这里
                        2'b10: begin 
                            state_next = 2'b10;
                        end
                    endcase
                end
                else begin
                    state_next = 2'b00;
                end
            end
            //read and read ack
            2'b01:begin
                resp_vld = '1;
                case (req_addr_r)
                    7'h10:begin
                        resp_sta_code = 2'b00;
                        resp_addr     = req_addr_r;
                        resp_data     = trace_cr_r;
                    end
                    7'h11:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = trace_sr;
                    end
                    7'h12:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = trace_magic_r;
                    end
                    7'h20:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = index_r;
                    end
                    7'h21:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = hart_pc_r;
                    end
                    7'h22:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = hart_code_r;
                    end
                    7'h23:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = hart_ra_r;
                    end
                    7'h24:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = hart_sp_r;
                    end
                    7'h25:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = hart_a0_r;
                    end
                    7'h26:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = hart_t0_r;
                    end
                    default: begin
                        // error 
                        resp_sta_code = 2'b11;
                        resp_addr = 7'h0;
                        resp_data = 32'hffff_ffff;
                    end
                endcase
                if(req_fire) begin
                    case (req_opt_code)
                        2'b00: state_next = 2'b11;
                        2'b01: begin 
                            state_next = 2'b01;
                        end
                        2'b11: state_next = 2'b11;//state_next = 2'b11;
                        2'b10: begin
                            //req_addr_r = req_addr;
                            //req_data_r = req_data;
                            state_next = 2'b10;
                        end
                    endcase
                end
                else begin
                    state_next = 2'b00;
                end 
            end
            //none
            2'b11:begin
                resp_vld   = '1;
                resp_addr  = 7'h0;;
                resp_data  = 32'h0;
                state_next = 2'b00;
            end
            //write and write ack
            2'b10:begin
                resp_vld   = '1;
                resp_addr  = req_addr_r;
               // resp_data  = 32'h0;
                state_next = 2'b00;
                resp_sta_code = 2'b00;
                case (req_addr_r)
                    7'h10:begin
                        resp_sta_code = 2'b00;
                        trace_cr_wrote_by_dtm = '1;
                        strace_cr_dtm = req_data_r;
           //             trace_magic   = trace_magic_r;
                    end
                    7'h12:begin
                        resp_sta_code = 2'b00;
                        trace_magic = req_data_r;
                    end
                    default: begin
                        // error 
                        trace_magic = trace_magic_r;
                        resp_sta_code = 2'b11;
                    end
                 endcase
               
                if(req_fire) begin
           //     state_next = 2'b00;
                    case (req_opt_code)
                        2'b00: state_next = 2'b00;
                        2'b01: begin 
           //                 //req_addr_r = req_addr;
                            state_next = 2'b01;
                        end
                        2'b11: state_next = 2'b11;
                        2'b10: begin
           //                 //req_addr_r = req_addr;
           //                 //req_data_r = req_data;
                             state_next = 2'b10;
                        end
                   endcase
                 end
                 else begin
                     state_next = 2'b00;
                 end
            end
        endcase
    end
end

assign sr_rd_empty = rd_empty;
assign sr_wr_full  = wr_full;

assign me  = trace_cr_r[0];
assign rfl = trace_cr_r[1];
assign fuse = {trace_cr_r[7],trace_cr_r[6],trace_cr_r[2]};

assign rd_en = (me && rfl) ? 1:0; //可以提前一拍
//read fifo line 
//trace_cr is double driven!


always @(posedge clk or negedge rst_n) begin
     if(~rst_n) begin
        rd_ing      <= '0;
        sr_rd_fifo_line_state <= 2'b00;
        strace_cr_inner <= 32'd0;
        rtl_set_down    <= '0;
     end
     else begin
         if (me && rfl) begin
            rd_ing       <= '1;
            rtl_set_down <= '1;
            strace_cr_inner <= {trace_cr[31:1],'0};
            sr_rd_fifo_line_state[1:0] <= 2'b10;  
        end
        else begin
            rtl_set_down <= '0;
            //sr_rd_fifo_line_state[1:0] <= 2'b11;  
        end
        if(rd_ing == '1) begin
            rd_ing <= '0;
            index_r     <= index_o;
            hart_pc_r   <= hart_pc_o;
            hart_code_r <= hart_code_o;
            hart_ra_r   <= hart_ra_o;
            hart_sp_r   <= hart_sp_o;
            hart_a0_r   <= hart_a0_o;
            hart_t0_r   <= hart_t0_o;
            sr_rd_fifo_line_state[1:0] <= 2'b01;
        end
        else begin
            //sr_rd_fifo_line_state[1:0] <= 2'b00;
        end
     end
end


always @(posedge clk or negedge rst_n) begin
     if(~rst_n) begin
         trace_cr_r <= 32'd0;
     end
     else begin
           trace_cr_r <= trace_cr;
     end
end

always @(*) begin
    if(~rst_n) begin
        trace_cr = 32'd0;
    end else begin
        case({trace_cr_wrote_by_dtm,rtl_set_down}) 
            2'b10:begin
                trace_cr = strace_cr_dtm;
            end
            2'b01:begin
                trace_cr = strace_cr_inner;
            end
            default:begin
                trace_cr = trace_cr_r;
            end
        endcase
    end
end

assign trace_sr = {28'h0,sr_rd_empty,sr_wr_full,sr_rd_fifo_line_state};

trace_fifo strace_ram(
    .clk(clk),
    .rst_n(rst_n),

    .hart_pc_i(hart_pc_i),
    .hart_code_i(hart_code_i),
    .hart_ra_i(hart_ra_i),
    .hart_sp_i(hart_sp_i),
    .hart_a0_i(hart_a0_i),
    .hart_t0_i(hart_t0_i),

    .index_o(index_o),
    .hart_pc_o(hart_pc_o),
    .hart_code_o(hart_code_o),
    .hart_ra_o(hart_ra_o),
    .hart_sp_o(hart_sp_o),
    .hart_a0_o(hart_a0_o),
    .hart_t0_o(hart_t0_o),

    .wr_en(wr_en),
    .rd_en(rd_en),
    .rd_empty(rd_empty),
    .wr_full(wr_full)
);

//当branch pc来了使能wr_en;
trace_update trace_fifo_update(
    .clk(clk),
    .rst_n(rst_n),
    .hart_pc_in(hart_pc_i),
    .strace_ram_wr_en(wr_en)
);

endmodule

`endif
 
