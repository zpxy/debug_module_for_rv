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

`ifndef DTM_SV
`define DTM_SV

module dtm (
    // input clk,
    // input rst_n,
    //jtag 
    input dtm_tck,
    input dtm_tms,
    input dtm_rst_n,
    input dtm_tdi,
    output dtm_tdo,
    output dtm_tdo_vld,
    
    //to dm 
    output logic req_vld,
    input  logic req_rdy,
    output logic [1:0] req_op,
    output logic [31:0]req_data,
    output logic [6:0] req_addr,

    input logic resp_vld,
    output logic resp_rdy,
    input logic [1:0] resp_op,
    input logic [31:0] resp_data,
    input logic [6:0] resp_addr,

    //to spi 
    output logic req_spi_vld,
    input  logic req_spi_rdy,
    output logic [7:0] req_spi_op,
    output logic [23:0]req_spi_addr,
    output logic [31:0] req_spi_data,

    input logic resp_spi_vld,
    output logic resp_spi_rdy,
    input logic [7:0]  resp_spi_op,
    input logic [23:0] resp_spi_addr,
    input logic [31:0] resp_spi_data,
   
    //to trace 
    output logic req_strace_vld,
    input  logic req_strace_rdy,
    output logic [1:0] req_strace_op,
    output logic [31:0]req_strace_data,
    output logic [6:0] req_strace_addr,

    input logic resp_strace_vld,
    output logic resp_strace_rdy,
    input logic [1:0] resp_strace_op,
    input logic [31:0] resp_strace_data,
    input logic [6:0] resp_strace_addr
);

logic ir_out;
logic ir_in;
logic dr_in;
logic dr_out;

localparam IDCODE  = 32'habcd_beaf; // hack magic number 
localparam DTMINFO = {14'h0,1'h0,1'h0,1'h0,3'h5,2'h0,6'h7,4'h1};

// sfr register
logic [4:0]  instruction_r;
logic [31:0] idcode_r;
logic [31:0] dtmcs_r;
logic [40:0] dmaccess_r;
logic [63:0] spiaccess_r;
logic [40:0] strace_r;
logic        bypass_r;

// tap signals
logic test_logic_reset_vld;
logic test_idle_vld;
logic select_ir_scan_vld;
logic capture_ir_vld;
logic shift_ir_vld;
logic update_ir_vld;
logic select_dr_scan_vld;
logic capture_dr_vld;
logic shift_dr_vld;
logic update_dr_vld;
logic [3:0] curstate;

// in shift phase, give the valid signal
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

assign ir_in       = (dtm_tdi);
assign dr_in       = (dtm_tdi);

assign dtm_tdo_vld = (shift_dr_vld || shift_ir_vld);

logic is_ir_scan ;
assign is_ir_scan = ( (curstate == test_select_ir_scan) 
    || (curstate == test_capture_ir) 
    || (curstate == test_shift_ir) 
    || (curstate == test_exit1_ir)
    || (curstate == test_exit2_ir)
    || (curstate == test_pause_ir)
    || (curstate == test_update_ir));

logic is_dr_scan;
assign is_dr_scan = ( (curstate == test_select_dr_scan) 
    || (curstate == test_capture_dr) 
    || (curstate == test_shift_dr) 
    || (curstate == test_exit1_dr)
    || (curstate == test_exit2_dr)
    || (curstate == test_pause_dr)
    || (curstate == test_update_dr));

logic is_other;
assign is_other = (curstate == test_idle || curstate == test_logic_reset);

assign dtm_tdo = (is_ir_scan ? ir_out : (is_dr_scan ? dr_out : '0));

// always @(posedge clk or negedge rst_n) begin
//     if(!rst_n) begin
//         instruction_r;
//         idcode_r;
//         dtmcs_r;
//         dmaccess_r;
//         spiaccess_r;
//         strace_r;
//     end
// end

// IR REG
//---------------------------------------------------
always @(posedge dtm_tck or negedge dtm_rst_n ) begin
    if(!dtm_rst_n) begin
        instruction_r <= 5'h01; 
    end
    else begin
        if (capture_ir_vld) begin
           instruction_r <= 5'h01; 
        end
        if (shift_ir_vld) begin
            instruction_r <= {ir_in,instruction_r[4:1]};
        end
        if (update_ir_vld) begin
            // latch keep 
        end
    end
end

always @(negedge dtm_tck) begin
    if (shift_ir_vld) begin
        ir_out <= instruction_r[0];
    end
    else begin 
        ir_out <= '0;
    end
end


logic dm_req_trig;
logic spi_req_trig;
logic strace_req_trig;

// logic [40:0] dm_req_data;

// addr--data--op
logic [40:0] dm_resp_data;
logic [40:0] dm_resp_data_r;


// addr-data--op
logic [63:0] spiam_resp_data;
logic [63:0] spiam_resp_data_r;

// addr--data--op
logic [40:0] strace_resp_data;
logic [40:0] strace_resp_data_r;

// data reg
//-----------------------------------
always @(posedge dtm_tck or negedge dtm_rst_n ) begin
    if(!dtm_rst_n) begin
        idcode_r    <= IDCODE;
        dtmcs_r     <= DTMINFO;
        dmaccess_r  <= 41'h0;
        spiaccess_r <= 64'h0;
        strace_r    <= 41'h0;
        bypass_r    <= 1'b0;
    end
    else begin
        if (capture_dr_vld) begin
           case (instruction_r)
                5'h01:  idcode_r    <= IDCODE;
                5'h10:  dtmcs_r     <= DTMINFO;
                //catpture interface data;
                5'h11:  dmaccess_r  <= 41'(dm_resp_data_r);
                5'h12:  spiaccess_r <= 64'(spiam_resp_data_r);
                5'h13:  strace_r    <= 41'(strace_resp_data_r);
                5'h1f:  bypass_r    <= bypass_r;
                default: begin
                    // dr_out <= '1;
                    bypass_r    <= bypass_r;
                end
            endcase
        end
        if (shift_dr_vld) begin
            case (instruction_r)
                5'h01: idcode_r     <= {dr_in,idcode_r[31:1]} ;
                5'h10: dtmcs_r      <= {dr_in,dtmcs_r[31:1]};
                5'h11: dmaccess_r   <= {dr_in,dmaccess_r[40:1]};
                5'h12: spiaccess_r  <= {dr_in,spiaccess_r[63:1]};
                5'h13: strace_r     <= {dr_in,strace_r[40:1]};
                5'h1f: bypass_r     <= dr_in;
                default: begin
                    bypass_r <= dr_in;
                end
            endcase
        end
        if (update_dr_vld) begin
            // do nothings 

            // if(instruction_r == 5'h12) begin
            //      $display("spi update is %24b %32b %8b ",spiaccess_r[63:40],spiaccess_r[39:8],spiaccess_r[7:0]);
            // end
            // if(instruction_r == 5'h11) begin
            //      $display("strace update is %7b %32b %2b ",dmaccess_r[40:34],dmaccess_r[33:2],dmaccess_r[1:0]);
            // end
            // if(instruction_r == 5'h13) begin
            //      $display("strace update is %7b %32b %2b ",strace_r[40:34],strace_r[33:2],strace_r[1:0]);
            // end
        end
    end
end

//update trig 
assign dm_req_trig     = (instruction_r == 5'h11 && update_dr_vld)?1:0;
assign spi_req_trig    = (instruction_r == 5'h12 && update_dr_vld)?1:0;
assign strace_req_trig = (instruction_r == 5'h13 && update_dr_vld)?1:0; 

logic  dtm_tck_n;
assign dtm_tck_n = ~dtm_tck;

// dr_out 
always @(posedge dtm_tck_n or negedge dtm_rst_n) begin
    if(~dtm_rst_n) begin
        dr_out <= '0;
    end else begin 
        if (shift_dr_vld) begin
            case (instruction_r)
                5'h01: dr_out <= idcode_r[0];
                5'h10: dr_out <= dtmcs_r[0];
                5'h11: dr_out <= dmaccess_r[0];
                5'h12: dr_out <= spiaccess_r[0];
                5'h13: dr_out <= strace_r[0];
                5'h1f: dr_out <= bypass_r;
                default: begin
                    dr_out <= '1;
                end
            endcase
        end
        else begin
          dr_out <= '0;
        end
    end
end

//dm access 
logic [1:0] dm_state;
logic [1:0] dm_state_next;



logic dm_req_fire;
logic dm_resp_fire;

assign dm_req_fire  = req_rdy && req_vld;
assign dm_resp_fire = resp_rdy && resp_vld;

localparam dm_idle = 2'd0;
localparam dm_tirg = 2'd1;
localparam dm_req  = 2'd2;
localparam dm_ack  = 2'd3;

logic [6:0]  req_addr_r;
logic [31:0] req_data_r;
logic [1:0]  req_op_r;

always @(posedge dtm_tck or negedge dtm_rst_n) begin
   if(~dtm_rst_n) begin
        dm_state     <= dm_idle;
        dm_resp_data_r <= 41'd0; 
        //dm_state_next <= dm_idle;
        req_addr_r <= 7'd0;
        req_data_r <= 32'd0;
        req_op_r   <= 2'd0;
   end 
   else begin
        dm_state <= dm_state_next;
        dm_resp_data_r <= dm_resp_data;
        req_addr_r <= req_addr;
        req_data_r <= req_data;
        req_op_r   <= req_op;
   end
end

always @(*) begin
    if(~dtm_rst_n) begin
        resp_rdy       = '1;
        dm_state_next  = dm_idle;
        dm_resp_data   = 40'd0;
        req_vld        = 1'b0;
        req_addr = 7'd0;
        req_data = 32'd0;
        req_op   = 2'd0;


    end else begin
        resp_rdy =1'b1;
        dm_state_next = dm_idle;
        dm_resp_data = dm_resp_data_r;
        req_vld  = 1'b0;
        req_data = req_data_r;
        req_addr = req_addr_r;
        req_op   = req_op_r;

        case (dm_state) 
            dm_idle: begin
                resp_rdy = '1;
                req_vld  = 1'b0;
                //dm_resp_data = dm_resp_data;
                //dm_resp_data = 40'd0;
                if(dm_req_trig) begin
                    dm_state_next = dm_req;
                end
                else begin
                    dm_state_next = dm_idle;
                end
            end
            dm_tirg:begin
                resp_rdy = '1;
                req_vld  = 1'b0;
                dm_state_next = dm_req;
                //dm_resp_data = dm_resp_data;
            end
            dm_req:begin
                resp_rdy = '1;
                req_vld = '1;
                req_addr = dmaccess_r[40:34];
                req_data = dmaccess_r[33:2];
                req_op   = dmaccess_r[1:0];
                //dm_resp_data = dm_resp_data;
                if(dm_req_fire) begin
                    dm_state_next = dm_ack;
                end
                else begin
                    dm_state_next = dm_req;
                end
            end
            dm_ack:begin
                req_vld  ='0;
                resp_rdy = '1;
                if(dm_resp_fire) begin
                    dm_state_next = dm_idle;
                    dm_resp_data = {resp_addr,resp_data,resp_op};
                end
                else begin
                    dm_state_next = dm_ack;
                    //dm_resp_data  = dm_resp_data;
                end
            end
            default:begin
                resp_rdy = 1'bx;
                req_vld = 1'bx;
                dm_resp_data = 41'hx;
                dm_state_next = 2'bx;
            end
        endcase
    end
end

//---------------------------------------------------------------------------------
//spi access 
//---------------------------------------------------------------------------------
logic [1:0] spiam_state;
logic [1:0] spiam_state_next;

logic spiam_req_fire;
logic spiam_resp_fire;

assign spiam_req_fire  = req_spi_rdy  && req_spi_vld;
assign spiam_resp_fire = resp_spi_rdy && resp_spi_vld;

localparam spiam_idle = 2'd0;
localparam spiam_tirg = 2'd1;
localparam spiam_req  = 2'd2;
localparam spiam_ack  = 2'd3;

logic [23:0] req_spi_addr_r;
logic [31:0] req_spi_data_r;
logic [7:0]  req_spi_op_r;

always @(posedge dtm_tck or negedge dtm_rst_n) begin
   if(~dtm_rst_n) begin
        spiam_state <= spiam_idle;
        spiam_resp_data_r <= 64'd0;
        //spiam_state_next <= spiam_idle;
        req_spi_addr_r <= 24'd0;
        req_spi_data_r <= 32'd0;
        req_spi_op_r   <= 8'd0;
   end 
   else begin
        spiam_state <= spiam_state_next;
        spiam_resp_data_r <= spiam_resp_data;
        req_spi_addr_r <= req_spi_addr;
        req_spi_data_r <= req_spi_addr;
        req_spi_op_r   <= req_spi_op;
   end
end

always @(*) begin
    if(~dtm_rst_n) begin 
        spiam_state_next = spiam_idle;
        spiam_resp_data = 64'd0;
        resp_spi_rdy = 1'b1;;
        req_spi_vld  = 1'b0;
        req_spi_addr = 24'd0;;
        req_spi_data = 32'd0;;
        req_spi_op   = 8'd0;;

    end else begin
        req_spi_vld  = 1'b0;
        resp_spi_rdy = 1'b1;
        spiam_resp_data = spiam_resp_data_r;
        spiam_state_next= spiam_idle;
        req_spi_addr  = req_spi_addr_r;
        req_spi_data  = req_spi_addr_r;
        req_spi_op    = req_spi_op_r;

         case (spiam_state) 
            spiam_idle: begin
                resp_spi_rdy = '1;
                //spiam_resp_data = 40'd0;
                if(spi_req_trig) begin
                    spiam_state_next = spiam_req;
                end
                else begin
                    spiam_state_next = spiam_idle;
                end
            end
            spiam_tirg:begin
                resp_spi_rdy = '1;
                spiam_state_next = spiam_req;
            end
            spiam_req:begin
                //todo
                resp_spi_rdy = '1;
                req_spi_vld = '1;
                req_spi_addr = spiaccess_r[63:40];
                req_spi_data = spiaccess_r[39:8];
                req_spi_op   = spiaccess_r[7:0];
                if(spiam_req_fire) begin
                    spiam_state_next = spiam_ack;
                end
                else begin
                    spiam_state_next = spiam_req;
                end
            end
            spiam_ack:begin
                req_spi_vld ='0;
                resp_spi_rdy = '1;
                if(spiam_resp_fire) begin
                    spiam_state_next = spiam_idle;
                    spiam_resp_data = {resp_spi_addr,resp_spi_data,resp_spi_op};
                end
                else begin
                    spiam_state_next = spiam_ack;
                end
            end
            default:begin
                resp_spi_rdy = 1'bx;
                req_spi_vld  = 1'bx;
            end 
        endcase
    end
end

//----------------------------------
// strace access
//-----------------------------------
logic [1:0] strace_state;
logic [1:0] strace_state_next;

logic strace_req_fire;
logic strace_resp_fire;

assign strace_req_fire  = req_strace_rdy  && req_strace_vld;
assign strace_resp_fire = resp_strace_rdy && resp_strace_vld;

localparam strace_idle = 2'd0;
localparam strace_tirg = 2'd1;
localparam strace_req  = 2'd2;
localparam strace_ack  = 2'd3;

logic [6:0] req_strace_addr_r;
logic [31:0] req_strace_data_r;
logic [1:0] req_strace_op_r;


always @(posedge dtm_tck or negedge dtm_rst_n) begin
   if(~dtm_rst_n) begin
        strace_state <= strace_idle;
        //strace_state_next <= strace_idle;
        strace_resp_data_r <= 41'd0;
        
        req_strace_addr_r <= 7'd0;
        req_strace_data_r <= 32'd0;
        req_strace_op_r   <= 2'd0;

   end 
   else begin
        strace_state <= strace_state_next;
        strace_resp_data_r <= strace_resp_data;
        req_strace_addr_r <= req_strace_addr;
        req_strace_data_r <= req_strace_data;
        req_strace_op_r   <= req_strace_op;
   end
end

always @(*) begin
    if(~dtm_rst_n) begin

         resp_strace_rdy   = '1;
         strace_state_next = strace_idle;
         strace_resp_data = 41'd0;
        
         req_strace_vld   = 1'b0;
         req_strace_addr  = 7'd0;
         req_strace_data  = 32'd0;
         req_strace_op    = 2'd0;

    end else begin
        resp_strace_rdy = 1'b1;
        strace_resp_data = strace_resp_data_r;
        strace_state_next = strace_idle;

        req_strace_vld   = 1'b0;
        req_strace_addr  = req_strace_addr_r;
        req_strace_data  = req_strace_data_r;
        req_strace_op    = req_strace_op_r;

        case (strace_state) 
            strace_idle: begin
                resp_strace_rdy = '1;
                //strace_resp_data = 40'd0;
                if(strace_req_trig) begin
                    strace_state_next = strace_req;
                end
                else begin
                    strace_state_next = strace_idle;
                end
            end
            strace_tirg:begin
                strace_state_next = strace_req;
            end
            strace_req:begin
                req_strace_vld  = '1;
                resp_strace_rdy = '1;
                req_strace_addr = strace_r[40:34];
                req_strace_data = strace_r[33:2];
                req_strace_op   = strace_r[1:0];
                if(strace_req_fire) begin
                    strace_state_next = strace_ack;
                end
                else begin
                    strace_state_next = strace_req;
                end
            end
            strace_ack:begin
                req_strace_vld ='0;
                resp_strace_rdy = '1;
                if(strace_resp_fire) begin
                    strace_state_next = strace_idle;
                    strace_resp_data = {resp_strace_addr,resp_strace_data,resp_strace_op};
                end
                else begin
                    strace_state_next = strace_ack;
                end
            end
            default:begin
                req_strace_vld  = 1'bx;
                resp_strace_rdy = 1'bx;
            end
        endcase
    end
end
//----------------------------------
// tap ctrl
//-----------------------------------
jtag_tap_statemachine TAP_ctrl(
    .jtag_rst_n(dtm_rst_n),
    .jtag_tap_tck(dtm_tck),
    .jtag_tap_tms(dtm_tms),

    .test_logic_reset_vld(test_logic_reset_vld),
    .test_idle_vld(test_idle_vld),

    .select_ir_scan_vld(select_ir_scan_vld),
    .capture_ir_vld(capture_ir_vld),
    .shift_ir_vld(shift_ir_vld),
    .update_ir_vld(update_ir_vld),

    .select_dr_scan_vld(select_dr_scan_vld),
    .capture_dr_vld(capture_dr_vld),
    .shift_dr_vld(shift_dr_vld),
    .update_dr_vld(update_dr_vld),

    .curstate(curstate)
);

endmodule

`endif
 
