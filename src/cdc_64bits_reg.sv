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
`ifndef CDC_64BITS_REG_SV
`define CDC_64BITS_REG_SV

module cdc_64bits_reg (
    input clk1,
    input rst_n_ck1,

    input               req_vld_ck1,
    output logic        req_rdy_ck1,
    input [23:0]        req_addr_ck1,
    input [31:0]        req_data_ck1,
    input [7:0]         req_op_ck1,

    output logic         resp_vld_ck1,
    input                resp_rdy_ck1,
    output logic [23:0]  resp_addr_ck1,
    output logic [31:0]  resp_data_ck1,
    output logic [7:0]   resp_op_ck1,
    //------------------------------------
    input clk2,
    input rst_n_ck2,

    output logic            req_vld_ck2,
    input  logic            req_rdy_ck2,
    output logic [23:0]     req_addr_ck2,
    output logic [31:0]     req_data_ck2,
    output logic [7:0]      req_op_ck2,

    input  logic            resp_vld_ck2,
    output logic            resp_rdy_ck2,
    input  logic [23:0]     resp_addr_ck2,
    input  logic [31:0]     resp_data_ck2,
    input  logic [7:0]      resp_op_ck2
);

logic ck1_req_fire;
logic ck1_ack_fire;

logic ck1_data_arve;
logic ck1_data_arve_ck2_r;
logic ck1_data_arve_ck2_2r;

always @(posedge clk2 or negedge rst_n_ck2) begin
    if(~rst_n_ck2) begin 
        ck1_data_arve_ck2_r <= 1'b0;
        ck1_data_arve_ck2_2r<= 1'b0;
    end else begin
        ck1_data_arve_ck2_r <= ck1_data_arve;
        ck1_data_arve_ck2_2r<= ck1_data_arve_ck2_r;
    end
end

logic ck2_data_arve;
logic ck2_data_arve_ck2_r;
logic ck2_data_arve_ck1_r;
logic ck2_data_arve_ck1_2r;

always @(posedge clk1 or negedge rst_n_ck1) begin
    if(~rst_n_ck1) begin 
        ck2_data_arve_ck1_r  <= 1'b0;
        ck2_data_arve_ck1_2r <= 1'b0;
    end else begin 
        ck2_data_arve_ck1_r  <= ck2_data_arve;
        ck2_data_arve_ck1_2r <= ck2_data_arve_ck1_r;
    end
end

logic ck1_get_data_from_ck2;
logic ck1_get_data_from_ck2_ck2_r;
logic ck1_get_data_from_ck2_ck2_2r;

always @(posedge clk2 or negedge rst_n_ck2) begin
    if(~rst_n_ck2) begin 
        ck1_get_data_from_ck2_ck2_r  <= 1'b0;
        ck1_get_data_from_ck2_ck2_2r <= 1'b0;
    end else begin
        ck1_get_data_from_ck2_ck2_r  <= ck1_get_data_from_ck2;
        ck1_get_data_from_ck2_ck2_2r <= ck1_get_data_from_ck2_ck2_r;
    end
end

logic ck2_req_fire;
logic ck2_ack_fire;
    
assign ck1_req_fire = req_vld_ck1 && req_rdy_ck1;
assign ck1_ack_fire = resp_vld_ck1 && resp_rdy_ck1;

assign ck2_req_fire = req_vld_ck2 && req_rdy_ck2;
assign ck2_ack_fire = resp_vld_ck2 && req_rdy_ck2;

logic [63:0] cdc_req_reg;
logic [63:0] cdc_resp_reg;

logic [63:0] cdc_req_reg_r;
logic [63:0] cdc_resp_reg_r;


logic [1:0] cdc_ck1_state;
logic [1:0] cdc_ck1_state_next;

localparam cdc_ck1_idle= 2'd0;
localparam cdc_ck1_req = 2'd1;
localparam cdc_ck1_wait= 2'd2;
localparam cdc_ck1_ack = 2'd3;

logic [1:0] cdc_ck2_state;
logic [1:0] cdc_ck2_state_next;

localparam cdc_ck2_idle = 2'd0;
localparam cdc_ck2_req  = 2'd1;
localparam cdc_ck2_ack  = 2'd2;
localparam cdc_ck2_wait = 2'd3;

always @(posedge clk1 or negedge rst_n_ck1 ) begin
    if (~rst_n_ck1) begin
       cdc_ck1_state <= cdc_ck1_idle;
       cdc_req_reg_r <= 64'd0;
    end
    else begin
        cdc_ck1_state <= cdc_ck1_state_next;
        cdc_req_reg_r <= cdc_req_reg;
        //ck2_data_arve_ck2_r <= ck2_data_arve;
    end
end

always @(*) begin
    if(~rst_n_ck1) begin
        cdc_ck1_state_next = cdc_ck1_idle;
        cdc_req_reg   = 63'd0;
        ck1_data_arve = 1'b0;
        req_rdy_ck1   = 1'b1;
        
        resp_vld_ck1  = 1'b0;
        resp_addr_ck1 = 24'h0;
        resp_data_ck1 = 32'h0;
        resp_op_ck1   = 8'h0;
        
        ck1_get_data_from_ck2 = 1'b0;
    end else begin
        cdc_req_reg = cdc_req_reg_r;
        ck1_get_data_from_ck2 = 1'b0;
        
        ck1_data_arve = 1'b0;
        cdc_ck1_state_next = cdc_ck1_idle;

        req_rdy_ck1 = 1'b1;
        
        resp_vld_ck1  = 1'b0;
        resp_addr_ck1 = 24'h0;
        resp_data_ck1 = 32'h0;
        resp_op_ck1   = 8'h0;

         case (cdc_ck1_state)
            cdc_ck1_idle:begin
                ck1_data_arve = '0;
                req_rdy_ck1   = '1;
                resp_vld_ck1  = '0;
                //cdc_req_reg   = cdc_req_reg;
                if(ck1_req_fire) begin
                    //todo 1
                    // addr -- data --op
                    cdc_req_reg       = {req_addr_ck1,req_data_ck1,req_op_ck1};
                    cdc_ck1_state_next= cdc_ck1_req;
                end
                else begin
                    cdc_ck1_state_next= cdc_ck1_idle;
                    //cdc_req_reg   = cdc_req_reg;
                end
            end
            cdc_ck1_req:begin
                ck1_data_arve = '1;
                //cdc_req_reg   = cdc_req_reg;
                cdc_ck1_state_next= cdc_ck1_wait;
            end
            cdc_ck1_wait:begin
               // cdc_req_reg   = cdc_req_reg;

                if(ck2_data_arve_ck1_2r) begin
                    ck1_data_arve         = '0;
                    ck1_get_data_from_ck2 = '1;
                    //todo1 
                    //addr -- data -- op  
                    {resp_addr_ck1,resp_data_ck1,resp_op_ck1} = cdc_resp_reg_r;
                    cdc_ck1_state_next= cdc_ck1_ack;
                end
                else begin
                    cdc_ck1_state_next= cdc_ck1_wait;
                end
            end
            cdc_ck1_ack:begin 
                //cdc_req_reg   = cdc_req_reg;
                ck1_get_data_from_ck2 = '0;
                resp_vld_ck1  = '1;
                {resp_addr_ck1,resp_data_ck1,resp_op_ck1} = cdc_resp_reg_r;
                if(ck1_ack_fire) begin
                    cdc_ck1_state_next= cdc_ck1_idle;
                end else begin
                    cdc_ck1_state_next= cdc_ck1_ack;
                end 
            end
        endcase
    end
    
end

always @(posedge clk2 or negedge rst_n_ck2) begin
    if (~rst_n_ck2) begin
       cdc_ck2_state <= cdc_ck2_idle;
       cdc_resp_reg_r<= 64'd0;
       ck2_data_arve_ck2_r <= 1'b0;
    end
    else begin
        cdc_ck2_state <= cdc_ck2_state_next;
        cdc_resp_reg_r<= cdc_resp_reg;
       ck2_data_arve_ck2_r <= ck2_data_arve;
    end
end

always @(*) begin
    if(~rst_n_ck2) begin
       cdc_ck2_state_next = cdc_ck2_idle;
       cdc_resp_reg   = 64'd0;
       ck2_data_arve  = '0;
       resp_rdy_ck2   = '1;
       req_vld_ck2    = '0;
       req_addr_ck2   = 24'h0;
       req_data_ck2   = 32'h0;
       req_op_ck2     = 8'h0; 
    end else begin
        
       cdc_ck2_state_next = cdc_ck2_idle;
       ck2_data_arve  = ck2_data_arve_ck2_r;
       resp_rdy_ck2   = '1;
       req_vld_ck2    = '0;
       req_addr_ck2   = 24'h0;
       req_data_ck2   = 32'h0;
       req_op_ck2     = 8'h0; 
       cdc_resp_reg = cdc_resp_reg_r;
        case (cdc_ck2_state)
            cdc_ck2_idle:begin
                ck2_data_arve = '0;
                resp_rdy_ck2  = '1;
                req_vld_ck2   = '0; 
                //cdc_resp_reg  = cdc_resp_reg;
                if(ck1_data_arve_ck2_2r) begin
                    // addr -- data --op
                    req_addr_ck2 = cdc_req_reg_r[63:40];
                    req_data_ck2 = cdc_req_reg_r[39:8];
                    req_op_ck2   = cdc_req_reg_r[7:0];
                    cdc_ck2_state_next= cdc_ck2_req;
                end
                else begin
                    cdc_ck2_state_next= cdc_ck2_idle;
                end
            end
            cdc_ck2_req:begin
                //cdc_resp_reg  = cdc_resp_reg;
                req_vld_ck2 = '1;
                req_addr_ck2 = cdc_req_reg_r[63:40];
                req_data_ck2 = cdc_req_reg_r[39:8];
                req_op_ck2   = cdc_req_reg_r[7:0];
                if(ck2_req_fire) begin
                    cdc_ck2_state_next= cdc_ck2_ack;
                end
                else begin
                    cdc_ck2_state_next= cdc_ck2_req;
                end
            end
            cdc_ck2_ack:begin 
                ck2_data_arve = '1;
                req_vld_ck2   = '0;
                cdc_resp_reg = {resp_addr_ck2,resp_data_ck2,resp_op_ck2};
                if(ck2_ack_fire) begin
                    cdc_ck2_state_next= cdc_ck2_wait;
                end
                else begin
                    cdc_ck2_state_next= cdc_ck2_ack;
                end

            end
            cdc_ck2_wait:begin
                //cdc_resp_reg  = cdc_resp_reg;
                if(ck1_get_data_from_ck2_ck2_2r) begin
                    ck2_data_arve         = '0;
                    cdc_ck2_state_next= cdc_ck2_idle;
                end
                else begin
                    cdc_ck2_state_next= cdc_ck2_wait;
                end
            end        
        endcase
    end
end

endmodule
`endif
