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
`ifndef DEBUGMODULE_SV
`define DEBUGMODULE_SV

module DebugModule (
    // system clk ,fast clock 
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
    output logic spi_csn,
    output logic spi_sclk,
    output logic spi_mosi,
    input        spi_miso,
    //core signal
    input        core_is_in_reset,
    output logic ndmreset,
    output logic debug_irq,
    
    input [31:0] hart_pc,
    input [31:0] hart_code,
    input [31:0] hart_ra,
    input [31:0] hart_sp,
    input [31:0] hart_a0,
    input [31:0] hart_t0,
    //sysbus --> master
    input               sysbus_m_a_ready,
    output logic        sysbus_m_a_valid,
    output logic [ 2:0] sysbus_m_a_opcode,
    output logic [31:0] sysbus_m_a_address,
    output logic [ 3:0] sysbus_m_a_mask,
    output logic [31:0] sysbus_m_a_data,

    output logic  sysbus_m_d_ready,
    input         sysbus_m_d_valid,
    input  [31:0] sysbus_m_d_data,

    //sysbus --> slave
    output logic  sysbus_s_a_ready,
    input         sysbus_s_a_valid,
    input  [ 2:0] sysbus_s_a_opcode,
    input  [ 2:0] sysbus_s_a_size,
    input  [ 2:0] sysbus_s_a_source,
    input  [31:0] sysbus_s_a_address,
    input  [ 3:0] sysbus_s_a_mask,
    input  [31:0] sysbus_s_a_data,

    input               sysbus_s_d_ready,
    output logic        sysbus_s_d_valid,
    output logic [ 2:0] sysbus_s_d_size,
    output logic [ 2:0] sysbus_s_d_source,
    output logic [31:0] sysbus_s_d_data
);
// clock and reset
logic        clk1;
logic        rst_n_ck1;
logic        clk2;
logic        rst_n_ck2;

//cdc is from slow to fast,from clk1 to clk2
assign clk1      = jtag_tck;
assign rst_n_ck1 = jtag_rst_n;

assign clk2      = clk;
assign rst_n_ck2 = rst_n;

// // jtag signal
// logic jtag_tck;
// logic jtag_rst_n;
// logic jtag_tms;
// logic jtag_tdi;
// logic jtag_tdo;
// logic jtag_tdo_vld;

// // spi signal 
// logic spi_csn;
// logic spi_sclk;
// logic spi_mosi;
// logic spi_miso;

//core signal
// logic        core_is_in_reset;
// logic        ndmreset;
// logic        debug_irq;
// logic [31:0] hart_pc;
// logic [31:0] hart_code;
// logic [31:0] hart_ra;
// logic [31:0] hart_sp;
// logic [31:0] hart_a0;
// logic [31:0] hart_t0;

logic        dmactiveack;
logic        dmactive;
assign dmactiveack = dmactive;

// //sysbus --> master
// logic        sysbus_m_a_ready;
// logic        sysbus_m_a_valid;
// logic [ 2:0] sysbus_m_a_opcode;
// logic [31:0] sysbus_m_a_address;
// logic [ 3:0] sysbus_m_a_mask;
// logic [31:0] sysbus_m_a_data;

// logic        sysbus_m_d_ready;
// logic        sysbus_m_d_valid;
// logic [31:0] sysbus_m_d_data;

// //sysbus --> slave
// logic        sysbus_s_a_ready;
// logic        sysbus_s_a_valid;
// logic [ 2:0] sysbus_s_a_opcode;
// logic [ 2:0] sysbus_s_a_size;
// logic [ 2:0] sysbus_s_a_source;
// logic [31:0] sysbus_s_a_address;
// logic [ 3:0] sysbus_s_a_mask;
// logic [31:0] sysbus_s_a_data;

// logic        sysbus_s_d_ready;
// logic        sysbus_s_d_valid;
// logic [ 2:0] sysbus_s_d_size;
// logic [ 2:0] sysbus_s_d_source;
// logic [31:0] sysbus_s_d_data;

// inner line wrie;
// dm cdc
logic        req_vld_ck1;
logic        req_rdy_ck1;
logic [6:0]  req_addr_ck1;
logic [31:0] req_data_ck1;
logic [1:0]  req_op_ck1;

logic        resp_vld_ck1;
logic        resp_rdy_ck1;
logic [6:0]  resp_addr_ck1;
logic [31:0] resp_data_ck1;
logic [1:0]  resp_op_ck1;

logic        req_vld_ck2;
logic        req_rdy_ck2;
logic [6:0]  req_addr_ck2;
logic [31:0] req_data_ck2;
logic [1:0]  req_op_ck2;

logic        resp_vld_ck2;
logic        resp_rdy_ck2;
logic [6:0]  resp_addr_ck2;
logic [31:0] resp_data_ck2;
logic [1:0]  resp_op_ck2;

// spi cdc
logic req_spi_vld_ck1;
logic req_spi_rdy_ck1;
logic [7:0] req_spi_op_ck1;
logic [23:0] req_spi_addr_ck1;
logic [31:0] req_spi_data_ck1;

logic resp_spi_vld_ck1;
logic resp_spi_rdy_ck1;
logic [7:0]  resp_spi_op_ck1;
logic [23:0] resp_spi_addr_ck1;
logic [31:0] resp_spi_data_ck1;

logic req_spi_vld_ck2;
logic req_spi_rdy_ck2;
logic [7:0] req_spi_op_ck2;
logic [23:0] req_spi_addr_ck2;
logic [31:0] req_spi_data_ck2;

logic resp_spi_vld_ck2;
logic resp_spi_rdy_ck2;
logic [7:0]  resp_spi_op_ck2;
logic [23:0] resp_spi_addr_ck2;
logic [31:0] resp_spi_data_ck2;

//strace cdc
logic req_strace_vld_ck1;
logic req_strace_rdy_ck1;
logic [1:0] req_strace_op_ck1;
logic [6:0] req_strace_addr_ck1;
logic [31:0] req_strace_data_ck1;

logic resp_strace_vld_ck1;
logic resp_strace_rdy_ck1;
logic [1:0]  resp_strace_op_ck1;
logic [6:0] resp_strace_addr_ck1;
logic [31:0] resp_strace_data_ck1;

logic req_strace_vld_ck2;
logic req_strace_rdy_ck2;
logic [1:0] req_strace_op_ck2;
logic [6:0] req_strace_addr_ck2;
logic [31:0] req_strace_data_ck2;

logic resp_strace_vld_ck2;
logic resp_strace_rdy_ck2;
logic [1:0]  resp_strace_op_ck2;
logic [6:0] resp_strace_addr_ck2;
logic [31:0] resp_strace_data_ck2;

dtm u_dtm (
    .dtm_tck(jtag_tck),
    .dtm_tms(jtag_tms),
    .dtm_rst_n(jtag_rst_n),
    .dtm_tdi(jtag_tdi),
    .dtm_tdo(jtag_tdo),
    .dtm_tdo_vld(jtag_tdo_vld),
    
    .req_vld(req_vld_ck1),
    .req_rdy(req_rdy_ck1),
    .req_op(req_op_ck1),
    .req_data(req_data_ck1),
    .req_addr(req_addr_ck1),

    .resp_vld(resp_vld_ck1),
    .resp_rdy(resp_rdy_ck1),
    .resp_op(resp_op_ck1),
    .resp_data(resp_data_ck1),
    .resp_addr(resp_addr_ck1),

    //--- spi  --------------
    .req_spi_vld(req_spi_vld_ck1),
    .req_spi_rdy(req_spi_rdy_ck1),
    .req_spi_op(req_spi_op_ck1),
    .req_spi_addr(req_spi_addr_ck1),
    .req_spi_data(req_spi_data_ck1),

    .resp_spi_vld(resp_spi_vld_ck1),
    .resp_spi_rdy(resp_spi_rdy_ck1),
    .resp_spi_op(resp_spi_op_ck1),
    .resp_spi_addr(resp_spi_addr_ck1),
    .resp_spi_data(resp_spi_data_ck1),
    //------ strace -----------------

    .req_strace_vld(req_strace_vld_ck1),
    .req_strace_rdy(req_strace_rdy_ck1),
    .req_strace_op(req_strace_op_ck1),
    .req_strace_data(req_strace_data_ck1),
    .req_strace_addr(req_strace_addr_ck1),

    .resp_strace_vld(resp_strace_vld_ck1),
    .resp_strace_rdy(resp_strace_rdy_ck1),
    .resp_strace_op(resp_strace_op_ck1),
    .resp_strace_data(resp_strace_data_ck1),
    .resp_strace_addr(resp_strace_addr_ck1)
);


cdc_41bits_reg u_cdc_dm (
        .clk1(clk1),
        .rst_n_ck1(rst_n_ck1),
        .req_vld_ck1(req_vld_ck1),
        .req_rdy_ck1(req_rdy_ck1),
        .req_addr_ck1(req_addr_ck1),
        .req_data_ck1(req_data_ck1),
        .req_op_ck1(req_op_ck1),
        .resp_vld_ck1(resp_vld_ck1),
        .resp_rdy_ck1(resp_rdy_ck1),
        .resp_addr_ck1(resp_addr_ck1),
        .resp_data_ck1(resp_data_ck1),
        .resp_op_ck1(resp_op_ck1),

        .clk2(clk2),
        .rst_n_ck2(rst_n_ck2),
        .req_vld_ck2(req_vld_ck2),
        .req_rdy_ck2(req_rdy_ck2),
        .req_addr_ck2(req_addr_ck2),
        .req_data_ck2(req_data_ck2),
        .req_op_ck2(req_op_ck2),

        .resp_vld_ck2(resp_vld_ck2),
        .resp_rdy_ck2(resp_rdy_ck2),
        .resp_addr_ck2(resp_addr_ck2),
        .resp_data_ck2(resp_data_ck2),
        .resp_op_ck2(resp_op_ck2)
);

debug u_debug (
    .clk(clk2),
    .rst_n(rst_n_ck2),

    .req_vld(req_vld_ck2),
    .req_rdy(req_rdy_ck2),
    .req_opt_code(req_op_ck2),
    .req_addr(req_addr_ck2),
    .req_data(req_data_ck2),

    .resp_vld(resp_vld_ck2),
    .resp_rdy(resp_rdy_ck2),
    .resp_sta_code(resp_op_ck2),
    .resp_addr(resp_addr_ck2),
    .resp_data(resp_data_ck2),

    .dmactiveack(dmactiveack),
    .core_is_in_reset(core_is_in_reset),
    .dmactive(dmactive),
    .ndmreset(ndmreset),
    .debug_irq(debug_irq),

    .sysbus_m_a_ready(sysbus_m_a_ready),
    .sysbus_m_a_valid(sysbus_m_a_valid),
    .sysbus_m_a_opcode(sysbus_m_a_opcode),
    .sysbus_m_a_address(sysbus_m_a_address),
    .sysbus_m_a_mask(sysbus_m_a_mask),
    .sysbus_m_a_data(sysbus_m_a_data),

    .sysbus_m_d_ready(sysbus_m_d_ready),
    .sysbus_m_d_valid(sysbus_m_d_valid),
    .sysbus_m_d_data(sysbus_m_d_data),


    .sysbus_s_a_ready(sysbus_s_a_ready),
    .sysbus_s_a_valid(sysbus_s_a_valid),
    .sysbus_s_a_opcode(sysbus_s_a_opcode),
    .sysbus_s_a_size(sysbus_s_a_size),
    .sysbus_s_a_source(sysbus_s_a_source),
    .sysbus_s_a_address(sysbus_s_a_address),
    .sysbus_s_a_mask(sysbus_s_a_mask),
    .sysbus_s_a_data(sysbus_s_a_data),
    
    .sysbus_s_d_ready(sysbus_s_d_ready),
    .sysbus_s_d_valid(sysbus_s_d_valid),
    .sysbus_s_d_size(sysbus_s_d_size),
    .sysbus_s_d_source(sysbus_s_d_source),
    .sysbus_s_d_data(sysbus_s_d_data)
);

cdc_64bits_reg u_cdc_spi (
    //link to dtm
    .clk1(clk1),
    .rst_n_ck1(rst_n_ck1),

    .req_vld_ck1(req_spi_vld_ck1),
    .req_rdy_ck1(req_spi_rdy_ck1),

    .req_addr_ck1(req_spi_addr_ck1),
    .req_data_ck1(req_spi_data_ck1),
    .req_op_ck1(req_spi_op_ck1),

    .resp_vld_ck1(resp_spi_vld_ck1),
    .resp_rdy_ck1(resp_spi_rdy_ck1),
    .resp_addr_ck1(resp_spi_addr_ck1),
    .resp_data_ck1(resp_spi_data_ck1),
    .resp_op_ck1(resp_spi_op_ck1),

    
    //lin to spi 
    .clk2(clk2),
    .rst_n_ck2(rst_n_ck2),

    .req_vld_ck2(req_spi_vld_ck2),
    .req_rdy_ck2(req_spi_rdy_ck2),
    .req_addr_ck2(req_spi_addr_ck2),
    .req_data_ck2(req_spi_data_ck2),
    .req_op_ck2(req_spi_op_ck2),

    .resp_vld_ck2(resp_spi_vld_ck2),
    .resp_rdy_ck2(resp_spi_rdy_ck2),
    .resp_addr_ck2(resp_spi_addr_ck2),
    .resp_data_ck2(resp_spi_data_ck2),
    .resp_op_ck2(resp_spi_op_ck2)
);


spi_direct u_spi (
    .clk(clk2),
    .rst_n(rst_n_ck2),
    //dtm -- spi 
    .req_vld(req_spi_vld_ck2),
    .req_rdy(req_spi_rdy_ck2),
    .req_opt_code(req_spi_op_ck2),
    .req_addr(req_spi_addr_ck2),
    .req_data(req_spi_data_ck2),

    .resp_vld(resp_spi_vld_ck2),
    .resp_rdy(resp_spi_rdy_ck2),
    .resp_sta_code(resp_spi_op_ck2),
    .resp_addr(resp_spi_addr_ck2),
    .resp_data(resp_spi_data_ck2),
    // spi 
    .csn(spi_csn),
    .sclk(spi_sclk),
    .mosi(spi_mosi),
    .miso(spi_miso)
);

cdc_41bits_reg u_cdc_strace (
        .clk1(clk1),
        .rst_n_ck1(rst_n_ck1),

        .req_vld_ck1(req_strace_vld_ck1),
        .req_rdy_ck1(req_strace_rdy_ck1),
        .req_addr_ck1(req_strace_addr_ck1),
        .req_data_ck1(req_strace_data_ck1),
        .req_op_ck1(req_strace_op_ck1),

        .resp_vld_ck1(resp_strace_vld_ck1),
        .resp_rdy_ck1(resp_strace_rdy_ck1),
        .resp_addr_ck1(resp_strace_addr_ck1),
        .resp_data_ck1(resp_strace_data_ck1),
        .resp_op_ck1(resp_strace_op_ck1),

        .clk2(clk2),
        .rst_n_ck2(rst_n_ck2),
        .req_vld_ck2(req_strace_vld_ck2),
        .req_rdy_ck2(req_strace_rdy_ck2),
        .req_addr_ck2(req_strace_addr_ck2),
        .req_data_ck2(req_strace_data_ck2),
        .req_op_ck2(req_strace_op_ck2),

        .resp_vld_ck2(resp_strace_vld_ck2),
        .resp_rdy_ck2(resp_strace_rdy_ck2),
        .resp_addr_ck2(resp_strace_addr_ck2),
        .resp_data_ck2(resp_strace_data_ck2),
        .resp_op_ck2(resp_strace_op_ck2)
);

strace u_strace (
    .clk(clk2),
    .rst_n(rst_n_ck2),
    //dtm <--> strace ,like  apb // now link to afifo
    .req_vld(req_strace_vld_ck2),
    .req_rdy(req_strace_rdy_ck2),
    .req_opt_code(req_strace_op_ck2),
    .req_addr(req_strace_addr_ck2),
    .req_data(req_strace_data_ck2),

    .resp_vld(resp_strace_vld_ck2),
    .resp_rdy(resp_strace_rdy_ck2),
    .resp_sta_code(resp_strace_op_ck2),
    .resp_addr(resp_strace_addr_ck2),
    .resp_data(resp_strace_data_ck2),
    
    //from hart 
    .hart_pc(hart_pc),
    .hart_code(hart_code),
    .hart_ra(hart_ra),
    .hart_sp(hart_sp),
    .hart_a0(hart_a0),
    .hart_t0(hart_t0)
);

endmodule
`endif