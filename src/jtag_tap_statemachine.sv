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

`ifndef JTAG_TAP_STATEMACHINE_SV
`define JTAG_TAP_STATEMACHINE_SV

module jtag_tap_statemachine (
    input jtag_rst_n,
    input jtag_tap_tck,
    input jtag_tap_tms,
    
    output test_logic_reset_vld,
    output test_idle_vld,

    output select_ir_scan_vld,
    output capture_ir_vld,
    output shift_ir_vld,
    output update_ir_vld,

    output select_dr_scan_vld,
    output capture_dr_vld,
    output shift_dr_vld,
    output update_dr_vld,

    output logic [3:0] curstate
);

//---------------------------------------
//state machine code IEEE 1149.1  
//---------------------------------------
localparam test_exit2_dr = 4'h0;
localparam test_exit1_dr = 4'h1;
localparam test_shift_dr = 4'h2;
localparam test_pause_dr = 4'h3;
localparam test_select_ir_scan = 4'h4;
localparam test_update_dr = 4'h5;
localparam test_capture_dr = 4'h6;
localparam test_select_dr_scan = 4'h7;

localparam test_exit2_ir = 4'h8;
localparam test_exit1_ir = 4'h9;
localparam test_shift_ir = 4'ha;
localparam test_pause_ir = 4'hb;
localparam test_idle = 4'hc;
localparam test_update_ir = 4'hd;
localparam test_capture_ir = 4'he;
localparam test_logic_reset = 4'hf;

//-----------------------------------
// state machine var
//-----------------------------------
logic [3:0] state_cur;
logic [3:0] state_next;

assign test_logic_reset_vld = (state_cur == test_logic_reset) ? 1:0;
assign test_idle_vld = (state_cur == test_idle) ? 1:0;

assign select_ir_scan_vld = (state_cur == test_select_ir_scan) ? 1:0;
assign capture_ir_vld     = (state_cur == test_capture_ir) ? 1:0;
assign shift_ir_vld       = (state_cur == test_shift_ir) ? 1:0;
assign update_ir_vld      = (state_cur == test_update_ir) ? 1:0;

assign select_dr_scan_vld =  (state_cur == test_select_dr_scan) ? 1:0;
assign capture_dr_vld     =  (state_cur == test_capture_dr) ? 1:0;
assign shift_dr_vld       =  (state_cur == test_shift_dr) ? 1:0;
assign update_dr_vld      =  (state_cur == test_update_dr) ? 1:0;

assign curstate           = state_cur;

always @(posedge jtag_tap_tck or negedge jtag_rst_n) begin
    if(!jtag_rst_n) begin
        state_cur  <= test_logic_reset;
        //state_next <= test_logic_reset;
    end else begin
        state_cur  <= state_next;
    end
end

always @(*) begin
    // $display("-----------------------------");
    // $display("tms is %b",jtag_tap_tms);
    // $display("state_next is %h",state_next);
    // $display("state_cur is %h",state_cur);
    // $display("-----------------------------");
    if(~jtag_rst_n) begin
        state_next = test_logic_reset;
    end else begin
        case (state_cur)

            test_logic_reset:begin
                if(jtag_tap_tms) begin
                    state_next = test_logic_reset;
                    // $display("f");
                end else begin
                    state_next = test_idle;
                end
            end

            test_idle: begin
                if(jtag_tap_tms) begin
                    state_next = test_select_dr_scan;
                    // $display("idle tms1 %d",state_next);
                end else begin
                    state_next = test_idle;
                end
            end

            test_select_dr_scan:begin
                if(jtag_tap_tms) begin
                    state_next = test_select_ir_scan;
                    // $display("ssss tms1 %d",state_next);
                end else begin
                    state_next = test_capture_dr;
                end
            end
            test_capture_dr:begin
                if(jtag_tap_tms) begin
                    state_next = test_exit1_dr;
                end else begin
                    state_next = test_shift_dr;
                end
            end
            test_shift_dr:begin
                if(jtag_tap_tms) begin
                    state_next = test_exit1_dr;
                end else begin
                    state_next = test_shift_dr;
                end
            end
            test_exit1_dr:begin
                if(jtag_tap_tms) begin
                    state_next = test_update_dr;
                end else begin
                    state_next = test_pause_dr;
                end
            end
            test_pause_dr:begin
                if(jtag_tap_tms) begin
                    state_next = test_exit2_dr;
                end else begin
                    state_next = test_pause_dr;
                end
            end
            test_exit2_dr:begin
                if(jtag_tap_tms) begin
                    state_next = test_update_dr;
                end else begin
                    state_next = test_shift_dr;
                end
            end
            test_update_dr:begin
                if(jtag_tap_tms) begin
                    state_next = test_select_dr_scan;
                end else begin
                    state_next = test_idle;
                end
            end

            /*------------------*/
            test_select_ir_scan:begin
                if(jtag_tap_tms) begin
                    state_next = test_logic_reset;
                end else begin
                    state_next = test_capture_ir;
                end
            end
            test_capture_ir:begin
                if(jtag_tap_tms) begin
                    state_next = test_exit1_ir;
                end else begin
                    state_next = test_shift_ir;
                end
            end
            test_shift_ir:begin
                if(jtag_tap_tms) begin
                    state_next = test_exit1_ir;
                end else begin
                    state_next = test_shift_ir;
                end
            end
            test_exit1_ir:begin
                if(jtag_tap_tms) begin
                    state_next = test_update_ir;
                end else begin
                    state_next = test_pause_ir;
                end
            end
            test_pause_ir:begin
                if(jtag_tap_tms) begin
                    state_next = test_exit2_ir;
                end else begin
                    state_next = test_pause_ir;
                end
            end
            test_exit2_ir:begin
                if(jtag_tap_tms) begin
                    state_next = test_update_ir;
                end else begin
                    state_next = test_shift_ir;
                end
            end
            test_update_ir:begin
                if(jtag_tap_tms) begin
                    state_next = test_select_dr_scan;
                end else begin
                    state_next = test_idle;
                end
            end
            default:begin
                state_next = test_logic_reset;
            end
        endcase
    end
end
endmodule 

`endif
 
