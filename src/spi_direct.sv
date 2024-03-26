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

`ifndef SPI_DIRECT_SV
`define SPI_DIRECT_SV

module spi_direct (
    input clk,
    input rst_n,
    //dtm -- spi 
    input  req_vld,
    output req_rdy,
    input logic [7:0]  req_opt_code,
    input logic [23:0] req_addr,
    input logic [31:0] req_data,

    output logic resp_vld,
    input  resp_rdy,
    output logic [7:0]  resp_sta_code,
    output logic [23:0] resp_addr,
    output logic [31:0] resp_data,
    // spi 
    output logic csn,
    output logic sclk,
    output logic mosi,
    input  logic miso
);

localparam page_width = 256;

// SPI Flash Frame
// In Real Situation this should use SRAM.
logic [7:0] page_ram  [page_width-1:0]; // addr : 0xff_0300 ... 0xff_03ff
logic [7:0] page_addr [2:0];            // addr : 0xff_0020 0xff_0021 0xff_0022
logic [7:0] page_inst ;                 // addr : 0xff_0001

logic [31:0] spi_cr;                    // addr : 0xfe_0001
logic [31:0] spi_sr;                    // addr : 0xfe_0002
//spi_tx_trig                           // addr : 0xfe_0003 set 1
                                        // addr : 0xfe_0004 set 0
logic [11:0] spi_byte_len;              // addr : 0xfe_0005 auto set
logic [31:0] spi_magic   ;               // addr : 0xfe_000f magic test //add magic test register

logic spe;
assign spe = spi_cr[0];

logic spi_clk_vld;
logic spi_tx_trig;                      // addr : 0xfe_0003
logic spi_tx_trig_write_by_dtm;
logic spi_tx_trig_write_by_inner;
logic spi_tx_trig_dtm_r;
logic spi_tx_trig_inner_r;

logic spi_tx_trig_r;


always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin 
        spi_tx_trig_r <= 1'b0;
    end
    else begin 
        spi_tx_trig_r <= spi_tx_trig;
    end
end


always@(*) begin
    if(~rst_n) begin
        spi_tx_trig = '0;
    end else begin
        case ({spi_tx_trig_write_by_dtm,spi_tx_trig_write_by_inner})
            2'b10: spi_tx_trig = spi_tx_trig_dtm_r;
            2'b01: spi_tx_trig = spi_tx_trig_inner_r;
            default: spi_tx_trig =spi_tx_trig_r;
        endcase
    end
end

logic spi_flash_chip_erase;
logic spi_flash_page_program;
logic spi_flash_page_program_finish;

// logic [7:0]  shift_reg_tx;
logic [7:0]  shift_reg_rx;
logic [7:0]  shift_reg ;
logic [11:0] shift_bcnt; //diffrent option ,diffrent byte number;
//cpol cpha assume is (0,0)

//sclk gen : when not trig is idle
// trig --> csn --> sclk 
//                  do
//                  di
assign req_rdy = 1;
logic req_fire;
assign req_fire = req_vld && req_rdy;
//两拍响应
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_cr <= 32'h0;
        spi_sr <= 32'habcd_beaf;
        spi_magic <= 32'hbeaf_abcd;
        //spi_tx_trig <= '0;
        resp_sta_code <= 8'hff;
        resp_vld  <= '0;
        resp_data <= '0;
        //shift_bcnt <= 12'h0;
        //shift_reg  <= 8'h99;
        spi_byte_len <= 12'h0;
        spi_tx_trig_write_by_dtm <= '0;
        spi_tx_trig_dtm_r <= '0;
        // sclk <= cpol;
    end else begin
        if (req_fire) begin
            resp_vld <= '1;
            resp_sta_code <= 8'h00;
            case (req_opt_code)
                8'h10://write and write ack
                begin
                    case (req_addr)
                        24'hfe_0001: spi_cr <= req_data;
                        24'hfe_0002: spi_sr <= req_data;
                        24'hfe_0003: begin 
                            spi_tx_trig_write_by_dtm <= '1;
                            spi_tx_trig_dtm_r        <= '1;
                        end
                        24'hfe_0004: begin
                            spi_tx_trig_write_by_dtm <= '1;
                            spi_tx_trig_dtm_r        <= '0;
                        end
                        24'hfe_0005: spi_byte_len <= req_data[11:0];
                        24'hfe_000f: spi_magic    <= req_data;//magic test
                        24'hff_0001: page_inst    <= req_data[7:0];
                        24'hff_0020: begin
                            page_addr[0] <= req_data[7:0];
                            page_addr[1] <= req_data[15:8];
                            page_addr[2] <= req_data[23:16];
                        end

                        24'hff_0300:begin
                            page_ram[0] <= req_data[7:0];
                            page_ram[1] <= req_data[15:8];
                            page_ram[2] <= req_data[23:16];
                            page_ram[3] <= req_data[31:24];
                        end
                        24'hff_0304:begin
                            page_ram[4] <= req_data[7:0];
                            page_ram[5] <= req_data[15:8];
                            page_ram[6] <= req_data[23:16];
                            page_ram[7] <= req_data[31:24];
                        end
                        24'hff_0308:begin
                            page_ram[8] <= req_data[7:0];
                            page_ram[9] <= req_data[15:8];
                            page_ram[10] <= req_data[23:16];
                            page_ram[11] <= req_data[31:24];
                        end
                        24'hff_030c:begin
                            page_ram[12] <= req_data[7:0];
                            page_ram[13] <= req_data[15:8];
                            page_ram[14] <= req_data[23:16];
                            page_ram[15] <= req_data[31:24];
                        end
                        24'hff_0310:begin
                            page_ram[16] <= req_data[7:0];
                            page_ram[17] <= req_data[15:8];
                            page_ram[18] <= req_data[23:16];
                            page_ram[19] <= req_data[31:24];
                        end
                        24'hff_0314:begin
                            page_ram[20] <= req_data[7:0];
                            page_ram[21] <= req_data[15:8];
                            page_ram[22] <= req_data[23:16];
                            page_ram[23] <= req_data[31:24];
                        end
                        24'hff_0318:begin
                            page_ram[24] <= req_data[7:0];
                            page_ram[25] <= req_data[15:8];
                            page_ram[26] <= req_data[23:16];
                            page_ram[27] <= req_data[31:24];
                        end
                        24'hff_031c:begin
                            page_ram[28] <= req_data[7:0];
                            page_ram[29] <= req_data[15:8];
                            page_ram[30] <= req_data[23:16];
                            page_ram[31] <= req_data[31:24];
                        end

                        24'hff_0320:begin
                            page_ram[32] <= req_data[7:0];
                            page_ram[33] <= req_data[15:8];
                            page_ram[34] <= req_data[23:16];
                            page_ram[35] <= req_data[31:24];
                        end

                        24'hff_0324:begin
                            page_ram[36] <= req_data[7:0];
                            page_ram[37] <= req_data[15:8];
                            page_ram[38] <= req_data[23:16];
                            page_ram[39] <= req_data[31:24];
                        end

                        24'hff_0328:begin
                            page_ram[40] <= req_data[7:0];
                            page_ram[41] <= req_data[15:8];
                            page_ram[42] <= req_data[23:16];
                            page_ram[43] <= req_data[31:24];
                        end

                        24'hff_032c:begin
                            page_ram[44] <= req_data[7:0];
                            page_ram[45] <= req_data[15:8];
                            page_ram[46] <= req_data[23:16];
                            page_ram[47] <= req_data[31:24];
                        end

                        24'hff_0330:begin
                            page_ram[48] <= req_data[7:0];
                            page_ram[49] <= req_data[15:8];
                            page_ram[50] <= req_data[23:16];
                            page_ram[51] <= req_data[31:24];
                        end
                        24'hff_0334:begin
                            page_ram[52] <= req_data[7:0];
                            page_ram[53] <= req_data[15:8];
                            page_ram[54] <= req_data[23:16];
                            page_ram[55] <= req_data[31:24];
                        end
                        24'hff_0338:begin
                            page_ram[56] <= req_data[7:0];
                            page_ram[57] <= req_data[15:8];
                            page_ram[58] <= req_data[23:16];
                            page_ram[59] <= req_data[31:24];
                        end
                        24'hff_033c:begin
                            page_ram[60] <= req_data[7:0];
                            page_ram[61] <= req_data[15:8];
                            page_ram[62] <= req_data[23:16];
                            page_ram[63] <= req_data[31:24];
                        end

                        //-----------------------------------------
                        24'hff_0340:begin
                            page_ram[64] <= req_data[7:0];
                            page_ram[65] <= req_data[15:8];
                            page_ram[66] <= req_data[23:16];
                            page_ram[67] <= req_data[31:24];
                        end
                        24'hff_0344:begin
                            page_ram[68] <= req_data[7:0];
                            page_ram[69] <= req_data[15:8];
                            page_ram[70] <= req_data[23:16];
                            page_ram[71] <= req_data[31:24];
                        end
                        24'hff_0348:begin
                            page_ram[72] <= req_data[7:0];
                            page_ram[73] <= req_data[15:8];
                            page_ram[74] <= req_data[23:16];
                            page_ram[75] <= req_data[31:24];
                        end
                        24'hff_034c:begin
                            page_ram[76] <= req_data[7:0];
                            page_ram[77] <= req_data[15:8];
                            page_ram[78] <= req_data[23:16];
                            page_ram[79] <= req_data[31:24];
                        end
                        24'hff_0350:begin
                            page_ram[80] <= req_data[7:0];
                            page_ram[81] <= req_data[15:8];
                            page_ram[82] <= req_data[23:16];
                            page_ram[83] <= req_data[31:24];
                        end
                        24'hff_0354:begin
                            page_ram[84] <= req_data[7:0];
                            page_ram[85] <= req_data[15:8];
                            page_ram[86] <= req_data[23:16];
                            page_ram[87] <= req_data[31:24];
                        end
                        24'hff_0358:begin
                            page_ram[88] <= req_data[7:0];
                            page_ram[89] <= req_data[15:8];
                            page_ram[90] <= req_data[23:16];
                            page_ram[91] <= req_data[31:24];
                        end
                        24'hff_035c:begin
                            page_ram[92] <= req_data[7:0];
                            page_ram[93] <= req_data[15:8];
                            page_ram[94] <= req_data[23:16];
                            page_ram[95] <= req_data[31:24];
                        end
                        24'hff_0360:begin
                            page_ram[96] <= req_data[7:0];
                            page_ram[97] <= req_data[15:8];
                            page_ram[98] <= req_data[23:16];
                            page_ram[99] <= req_data[31:24];
                        end
                        24'hff_0364:begin
                            page_ram[100] <= req_data[7:0];
                            page_ram[101] <= req_data[15:8];
                            page_ram[102] <= req_data[23:16];
                            page_ram[103] <= req_data[31:24];
                        end
                        24'hff_0368:begin
                            page_ram[104] <= req_data[7:0];
                            page_ram[105] <= req_data[15:8];
                            page_ram[106] <= req_data[23:16];
                            page_ram[107] <= req_data[31:24];
                        end
                        24'hff_036c:begin
                            page_ram[108] <= req_data[7:0];
                            page_ram[109] <= req_data[15:8];
                            page_ram[110] <= req_data[23:16];
                            page_ram[111] <= req_data[31:24];
                        end
                        24'hff_0370:begin
                            page_ram[112] <= req_data[7:0];
                            page_ram[113] <= req_data[15:8];
                            page_ram[114] <= req_data[23:16];
                            page_ram[115] <= req_data[31:24];
                        end
                        24'hff_0374:begin
                            page_ram[116] <= req_data[7:0];
                            page_ram[117] <= req_data[15:8];
                            page_ram[118] <= req_data[23:16];
                            page_ram[119] <= req_data[31:24];
                        end
                        24'hff_0378:begin
                            page_ram[120] <= req_data[7:0];
                            page_ram[121] <= req_data[15:8];
                            page_ram[122] <= req_data[23:16];
                            page_ram[123] <= req_data[31:24];
                        end
                        24'hff_037c:begin
                            page_ram[124] <= req_data[7:0];
                            page_ram[125] <= req_data[15:8];
                            page_ram[126] <= req_data[23:16];
                            page_ram[127] <= req_data[31:24];
                        end
                        //------------------------------------
                        24'hff_0380:begin
                            page_ram[128] <= req_data[7:0];
                            page_ram[129] <= req_data[15:8];
                            page_ram[130] <= req_data[23:16];
                            page_ram[131] <= req_data[31:24];
                        end
                        24'hff_0384:begin
                            page_ram[132] <= req_data[7:0];
                            page_ram[133] <= req_data[15:8];
                            page_ram[134] <= req_data[23:16];
                            page_ram[135] <= req_data[31:24];
                        end
                        24'hff_0388:begin
                            page_ram[136] <= req_data[7:0];
                            page_ram[137] <= req_data[15:8];
                            page_ram[138] <= req_data[23:16];
                            page_ram[139] <= req_data[31:24];
                        end
                        24'hff_038c:begin
                            page_ram[140] <= req_data[7:0];
                            page_ram[141] <= req_data[15:8];
                            page_ram[142] <= req_data[23:16];
                            page_ram[143] <= req_data[31:24];
                        end
                        24'hff_0390:begin
                            page_ram[144] <= req_data[7:0];
                            page_ram[145] <= req_data[15:8];
                            page_ram[146] <= req_data[23:16];
                            page_ram[147] <= req_data[31:24];
                        end
                        24'hff_0394:begin
                            page_ram[148] <= req_data[7:0];
                            page_ram[149] <= req_data[15:8];
                            page_ram[150] <= req_data[23:16];
                            page_ram[151] <= req_data[31:24];
                        end
                        24'hff_0398:begin
                            page_ram[152] <= req_data[7:0];
                            page_ram[153] <= req_data[15:8];
                            page_ram[154] <= req_data[23:16];
                            page_ram[155] <= req_data[31:24];
                        end
                        24'hff_039c:begin
                            page_ram[156] <= req_data[7:0];
                            page_ram[157] <= req_data[15:8];
                            page_ram[158] <= req_data[23:16];
                            page_ram[159] <= req_data[31:24];
                        end

                        24'hff_03a0:begin
                            page_ram[160] <= req_data[7:0];
                            page_ram[161] <= req_data[15:8];
                            page_ram[162] <= req_data[23:16];
                            page_ram[163] <= req_data[31:24];
                        end

                        24'hff_03a4:begin
                            page_ram[164] <= req_data[7:0];
                            page_ram[165] <= req_data[15:8];
                            page_ram[166] <= req_data[23:16];
                            page_ram[167] <= req_data[31:24];
                        end

                        24'hff_03a8:begin
                            page_ram[168] <= req_data[7:0];
                            page_ram[169] <= req_data[15:8];
                            page_ram[170] <= req_data[23:16];
                            page_ram[171] <= req_data[31:24];
                        end

                        24'hff_03ac:begin
                            page_ram[172] <= req_data[7:0];
                            page_ram[173] <= req_data[15:8];
                            page_ram[174] <= req_data[23:16];
                            page_ram[175] <= req_data[31:24];
                        end

                        24'hff_03b0:begin
                            page_ram[176] <= req_data[7:0];
                            page_ram[177] <= req_data[15:8];
                            page_ram[178] <= req_data[23:16];
                            page_ram[179] <= req_data[31:24];
                        end
                        24'hff_03b4:begin
                            page_ram[180] <= req_data[7:0];
                            page_ram[181] <= req_data[15:8];
                            page_ram[182] <= req_data[23:16];
                            page_ram[183] <= req_data[31:24];
                        end
                        24'hff_03b8:begin
                            page_ram[184] <= req_data[7:0];
                            page_ram[185] <= req_data[15:8];
                            page_ram[186] <= req_data[23:16];
                            page_ram[187] <= req_data[31:24];
                        end
                        24'hff_03bc:begin
                            page_ram[188] <= req_data[7:0];
                            page_ram[189] <= req_data[15:8];
                            page_ram[190] <= req_data[23:16];
                            page_ram[191] <= req_data[31:24];
                        end

                        //-----------------------------------------
                        24'hff_03c0:begin
                            page_ram[192] <= req_data[7:0];
                            page_ram[193] <= req_data[15:8];
                            page_ram[194] <= req_data[23:16];
                            page_ram[195] <= req_data[31:24];
                        end
                        24'hff_03c4:begin
                            page_ram[196] <= req_data[7:0];
                            page_ram[197] <= req_data[15:8];
                            page_ram[198] <= req_data[23:16];
                            page_ram[199] <= req_data[31:24];
                        end
                        24'hff_03c8:begin
                            page_ram[200] <= req_data[7:0];
                            page_ram[201] <= req_data[15:8];
                            page_ram[202] <= req_data[23:16];
                            page_ram[203] <= req_data[31:24];
                        end
                        24'hff_03cc:begin
                            page_ram[204] <= req_data[7:0];
                            page_ram[205] <= req_data[15:8];
                            page_ram[206] <= req_data[23:16];
                            page_ram[207] <= req_data[31:24];
                        end
                        24'hff_03d0:begin
                            page_ram[208] <= req_data[7:0];
                            page_ram[209] <= req_data[15:8];
                            page_ram[210] <= req_data[23:16];
                            page_ram[211] <= req_data[31:24];
                        end
                        24'hff_03d4:begin
                            page_ram[212] <= req_data[7:0];
                            page_ram[213] <= req_data[15:8];
                            page_ram[214] <= req_data[23:16];
                            page_ram[215] <= req_data[31:24];
                        end
                        24'hff_03d8:begin
                            page_ram[216] <= req_data[7:0];
                            page_ram[217] <= req_data[15:8];
                            page_ram[218] <= req_data[23:16];
                            page_ram[219] <= req_data[31:24];
                        end
                        24'hff_03dc:begin
                            page_ram[220] <= req_data[7:0];
                            page_ram[221] <= req_data[15:8];
                            page_ram[222] <= req_data[23:16];
                            page_ram[223] <= req_data[31:24];
                        end
                        24'hff_03e0:begin
                            page_ram[224] <= req_data[7:0];
                            page_ram[225] <= req_data[15:8];
                            page_ram[226] <= req_data[23:16];
                            page_ram[227] <= req_data[31:24];
                        end
                        24'hff_03e4:begin
                            page_ram[228] <= req_data[7:0];
                            page_ram[229] <= req_data[15:8];
                            page_ram[230] <= req_data[23:16];
                            page_ram[231] <= req_data[31:24];
                        end
                        24'hff_03e8:begin
                            page_ram[232] <= req_data[7:0];
                            page_ram[233] <= req_data[15:8];
                            page_ram[234] <= req_data[23:16];
                            page_ram[235] <= req_data[31:24];
                        end
                        24'hff_03ec:begin
                            page_ram[236] <= req_data[7:0];
                            page_ram[237] <= req_data[15:8];
                            page_ram[238] <= req_data[23:16];
                            page_ram[239] <= req_data[31:24];
                        end
                        24'hff_03f0:begin
                            page_ram[240] <= req_data[7:0];
                            page_ram[241] <= req_data[15:8];
                            page_ram[242] <= req_data[23:16];
                            page_ram[243] <= req_data[31:24];
                        end
                        24'hff_03f4:begin
                            page_ram[244] <= req_data[7:0];
                            page_ram[245] <= req_data[15:8];
                            page_ram[246] <= req_data[23:16];
                            page_ram[247] <= req_data[31:24];
                        end
                        24'hff_03f8:begin
                            page_ram[248] <= req_data[7:0];
                            page_ram[249] <= req_data[15:8];
                            page_ram[250] <= req_data[23:16];
                            page_ram[251] <= req_data[31:24];
                        end
                        24'hff_03fc:begin
                            page_ram[252] <= req_data[7:0];
                            page_ram[253] <= req_data[15:8];
                            page_ram[254] <= req_data[23:16];
                            page_ram[255] <= req_data[31:24];
                        end
                        //------------------------------------
                        default: begin
                            resp_data     <= 32'h0;
                            resp_addr     <= 24'h0;
                            resp_sta_code <= 8'h00;
                        end
                    endcase
                end  
                8'h01://read 
                begin
                    case (req_addr)
                        24'hfe_0001: begin 
                            resp_vld      <= 1;
                            resp_data     <= spi_cr;
                            resp_addr     <= req_addr;
                            resp_sta_code <= 8'h00;
                        end
                        24'hfe_0002: begin 
                            resp_vld      <= 1;
                            resp_data     <= spi_sr;
                            resp_addr     <= req_addr;
                            resp_sta_code <= 8'h00;
                            //$display("READ SPI_SR");
                        end
                        24'hfe_000f:begin
                            resp_vld      <= 1;
                            resp_data     <= spi_magic;
                            resp_addr     <= req_addr;
                            resp_sta_code <= 8'h00;
                        end
                        default: begin
                            //$display("TBD ADDR");
                            resp_vld      <= 1;
                            resp_data     <= 31'h0;
                            resp_addr     <= 24'h0;
                            resp_sta_code <= 8'h00;
                        end
                    endcase
                    //$display("tbd this opcode!");
                end
                // 8'h11:begin
                //     resp_vld      <= 1;
                //     resp_data     <= 31'h0;
                //     resp_addr     <= 24'h0;
                //     resp_sta_code <= 8'h11;
                // end
                // 8'h00:begin
                //     resp_vld      <= 1;
                    // resp_data     <= 31'h0;
                    // resp_addr     <= 24'h0;
                    // resp_sta_code <= 8'h11;
                // end
                default:begin
                    resp_vld      <= '1;
                    resp_data     <= 31'h0;
                    resp_addr     <= 24'h0;
                    resp_sta_code <= 8'h11;
                    //$display("!not surport option");
                end 

            endcase
        end
        else begin
            spi_tx_trig_write_by_dtm <= '0;
            resp_vld <= '0;
        end
    end
end

logic cpol;
assign cpol = '0;
logic cpha;
assign cpha = '0;


localparam sclk_half_perid = 8'd3;
logic [7:0] iclk_cnt;// = sclk_half_perid;
logic iclk_cnt_start;
logic iclk_cnt_end;

assign iclk_cnt_start = spe && (!(|iclk_cnt)) && spi_tx_trig_r;
assign iclk_cnt_end   = spe && (|iclk_cnt) && spi_tx_trig_r;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        iclk_cnt <= sclk_half_perid;
    end else begin
        if ( iclk_cnt_start ) begin
            iclk_cnt    <= sclk_half_perid;
            spi_clk_vld <= '1;
        end
        else if (iclk_cnt_end) begin
            iclk_cnt <= iclk_cnt-8'h1;
            spi_clk_vld <= '0;
        end
        else begin
            spi_clk_vld <= '0;
            iclk_cnt    <= sclk_half_perid;
        end

        if(spi_clk_vld) begin
            sclk <= ~sclk;
        end else begin
            sclk <= cpol;
        end
    end
end

logic is_first_byte;
logic [3:0] in_b_cnt;//= 4'h7;//比特计数
logic page_inst_bit;
logic _next_bit6;
logic _next_bit5;
logic _next_bit4;
logic _next_bit3;
logic _next_bit2;
logic _next_bit1;
logic _next_bit0;


assign _next_bit0    = (in_b_cnt==7'h0)? page_inst[0]:0;
assign _next_bit1    = (in_b_cnt==7'h1)? page_inst[1]:_next_bit0;
assign _next_bit2    = (in_b_cnt==7'h2)? page_inst[2]:_next_bit1;
assign _next_bit3    = (in_b_cnt==7'h3)? page_inst[3]:_next_bit2;
assign _next_bit4    = (in_b_cnt==7'h4)? page_inst[4]:_next_bit3;
assign _next_bit5    = (in_b_cnt==7'h5)? page_inst[5]:_next_bit4;
assign _next_bit6    = (in_b_cnt==7'h6)? page_inst[6]:_next_bit5;
assign page_inst_bit = (in_b_cnt==7'h7)? page_inst[7]:_next_bit6;
assign mosi = spi_tx_trig ? (is_first_byte ? (page_inst_bit): shift_reg[7]):0;
assign csn  = spi_tx_trig ? 0:1;

//spi_byte_len is the data 的长度
always @(posedge sclk or negedge rst_n) begin
    if(~rst_n) begin
        shift_bcnt <= 12'h0;
        spi_tx_trig_write_by_inner <= '0;
        shift_reg <= 8'hff;
        is_first_byte <= '1;
	  in_b_cnt <= 4'h7;
    end else begin
        // if(spi_tx_rising) begin
        //     shift_reg  <= page_inst;
        // end 
        // else begin
            if((|in_b_cnt)) begin
                shift_reg <= {shift_reg[6:0],miso};
                in_b_cnt  <= in_b_cnt -1;
            end
            if(~(|in_b_cnt)) begin
                shift_reg_rx <= {shift_reg[6:0],miso};
                //shift_reg <= {shift_reg[6:0],miso};
                in_b_cnt   <= 4'h7; 
                shift_bcnt <= shift_bcnt + 12'h1;
                case (shift_bcnt)
                    //12'h000: shift_reg <= page_inst;
                    12'h000: begin 
                        shift_reg <= page_addr[2];
                        is_first_byte <= '0;
                    end
                    //--------------------------------------------
 			 12'h001: shift_reg <= page_addr[1];
                    12'h002: shift_reg <= page_addr[0];

                    12'h003: shift_reg <= page_ram[3];
                    12'h004: shift_reg <= page_ram[2];
                    12'h005: shift_reg <= page_ram[1];
                    12'h006: shift_reg <= page_ram[0];

                    12'h007: shift_reg <= page_ram[7];
                    12'h008: shift_reg <= page_ram[6];
                    12'h009: shift_reg <= page_ram[5];
                    12'h00a: shift_reg <= page_ram[4];

                    12'h00b: shift_reg <= page_ram[11];
                    12'h00c: shift_reg <= page_ram[10];
                    12'h00d: shift_reg <= page_ram[9];
                    12'h00e: shift_reg <= page_ram[8];

                    12'h00f: shift_reg <= page_ram[15];
                    12'h010: shift_reg <= page_ram[14];
                    12'h011: shift_reg <= page_ram[13];
                    12'h012: shift_reg <= page_ram[12];

                    12'h013: shift_reg <= page_ram[19];
                    12'h014: shift_reg <= page_ram[18];
                    12'h015: shift_reg <= page_ram[17];
                    12'h016: shift_reg <= page_ram[16];

                    12'h017: shift_reg <= page_ram[23];
                    12'h018: shift_reg <= page_ram[22];
                    12'h019: shift_reg <= page_ram[21];
                    12'h01a: shift_reg <= page_ram[20];

                    12'h01b: shift_reg <= page_ram[27];
                    12'h01c: shift_reg <= page_ram[26];
                    12'h01d: shift_reg <= page_ram[25];
                    12'h01e: shift_reg <= page_ram[24];

                    12'h01F: shift_reg <= page_ram[31];
                    12'h020: shift_reg <= page_ram[30];
                    12'h021: shift_reg <= page_ram[29];
                    12'h022: shift_reg <= page_ram[28];

                    //--------------------------------------------

                    12'h023: shift_reg <= page_ram[35];
                    12'h024: shift_reg <= page_ram[34];
                    12'h025: shift_reg <= page_ram[33];
                    12'h026: shift_reg <= page_ram[32];

                    12'h027: shift_reg <= page_ram[39];
                    12'h028: shift_reg <= page_ram[38];
                    12'h029: shift_reg <= page_ram[37];
                    12'h02A: shift_reg <= page_ram[36];

                    12'h02B: shift_reg <= page_ram[43];
                    12'h02C: shift_reg <= page_ram[42];
                    12'h02D: shift_reg <= page_ram[41];
                    12'h02E: shift_reg <= page_ram[40];

                    12'h02F: shift_reg <= page_ram[47];
                    12'h030: shift_reg <= page_ram[46];
                    12'h031: shift_reg <= page_ram[45];
                    12'h032: shift_reg <= page_ram[44];

                    12'h033: shift_reg <= page_ram[51];
                    12'h034: shift_reg <= page_ram[50];
                    12'h035: shift_reg <= page_ram[49];
                    12'h036: shift_reg <= page_ram[48];

                    12'h037: shift_reg <= page_ram[55];
                    12'h038: shift_reg <= page_ram[54];
                    12'h039: shift_reg <= page_ram[53];
                    12'h03A: shift_reg <= page_ram[52];

                    12'h03B: shift_reg <= page_ram[59];
                    12'h03C: shift_reg <= page_ram[58];
                    12'h03D: shift_reg <= page_ram[57];
                    12'h03E: shift_reg <= page_ram[56];

                    12'h03F: shift_reg <= page_ram[63];
                    12'h040: shift_reg <= page_ram[62];
                    12'h041: shift_reg <= page_ram[61];
                    12'h042: shift_reg <= page_ram[60];
                    //-------------------------------------------------
                    12'h043: shift_reg <= page_ram[67];
                    12'h044: shift_reg <= page_ram[66];
                    12'h045: shift_reg <= page_ram[65];
                    12'h046: shift_reg <= page_ram[64];

                    12'h047: shift_reg <= page_ram[71];
                    12'h048: shift_reg <= page_ram[70];
                    12'h049: shift_reg <= page_ram[69];
                    12'h04A: shift_reg <= page_ram[68];

                    12'h04B: shift_reg <= page_ram[75];
                    12'h04C: shift_reg <= page_ram[74];
                    12'h04D: shift_reg <= page_ram[73];
                    12'h04E: shift_reg <= page_ram[72];

                    12'h04F: shift_reg <= page_ram[79];
                    12'h050: shift_reg <= page_ram[78];
                    12'h051: shift_reg <= page_ram[77];
                    12'h052: shift_reg <= page_ram[76];

                    12'h053: shift_reg <= page_ram[83];
                    12'h054: shift_reg <= page_ram[82];
                    12'h055: shift_reg <= page_ram[81];
                    12'h056: shift_reg <= page_ram[80];

                    12'h057: shift_reg <= page_ram[87];
                    12'h058: shift_reg <= page_ram[86];
                    12'h059: shift_reg <= page_ram[85];
                    12'h05A: shift_reg <= page_ram[84];

                    12'h05B: shift_reg <= page_ram[91];
                    12'h05C: shift_reg <= page_ram[90];
                    12'h05D: shift_reg <= page_ram[89];
                    12'h05E: shift_reg <= page_ram[88];

                    12'h05F: shift_reg <= page_ram[95];
                    12'h060: shift_reg <= page_ram[94];
                    12'h061: shift_reg <= page_ram[93];
                    12'h062: shift_reg <= page_ram[92];

                    12'h063: shift_reg <= page_ram[99];
                    12'h064: shift_reg <= page_ram[98];
                    12'h065: shift_reg <= page_ram[97];
                    12'h066: shift_reg <= page_ram[96];

                    12'h067: shift_reg <= page_ram[103];
                    12'h068: shift_reg <= page_ram[102];
                    12'h069: shift_reg <= page_ram[101];
                    12'h06A: shift_reg <= page_ram[100];

                    12'h06b: shift_reg <= page_ram[107];
                    12'h06c: shift_reg <= page_ram[106];
                    12'h06d: shift_reg <= page_ram[105];
                    12'h06e: shift_reg <= page_ram[104];

                    12'h06f: shift_reg <= page_ram[111];
                    12'h070: shift_reg <= page_ram[110];
                    12'h071: shift_reg <= page_ram[109];
                    12'h072: shift_reg <= page_ram[108];

                    12'h073: shift_reg <= page_ram[115];
                    12'h074: shift_reg <= page_ram[114];
                    12'h075: shift_reg <= page_ram[113];
                    12'h076: shift_reg <= page_ram[112];

                    12'h077: shift_reg <= page_ram[119];
                    12'h078: shift_reg <= page_ram[118];
                    12'h079: shift_reg <= page_ram[117];
                    12'h07a: shift_reg <= page_ram[116];

                    12'h07b: shift_reg <= page_ram[123];
                    12'h07c: shift_reg <= page_ram[122];
                    12'h07d: shift_reg <= page_ram[121];
                    12'h07e: shift_reg <= page_ram[120];
                    
                    12'h07f: shift_reg <= page_ram[127];
                    12'h080: shift_reg <= page_ram[126];
                    12'h081: shift_reg <= page_ram[125];
                    12'h082: shift_reg <= page_ram[124];


                    //----------------------------------------------

                    12'h083: shift_reg <= page_ram[131];
                    12'h084: shift_reg <= page_ram[130];
                    12'h085: shift_reg <= page_ram[129];
                    12'h086: shift_reg <= page_ram[128];

                    12'h087: shift_reg <= page_ram[135];
                    12'h088: shift_reg <= page_ram[134];
                    12'h089: shift_reg <= page_ram[133];
                    12'h08a: shift_reg <= page_ram[132];

                    12'h08b: shift_reg <= page_ram[139];
                    12'h08c: shift_reg <= page_ram[138];
                    12'h08d: shift_reg <= page_ram[137];
                    12'h08e: shift_reg <= page_ram[136];

                    12'h08f: shift_reg <= page_ram[143];
                    12'h090: shift_reg <= page_ram[142];
                    12'h091: shift_reg <= page_ram[141];
                    12'h092: shift_reg <= page_ram[140];

                    12'h093: shift_reg <= page_ram[147];
                    12'h094: shift_reg <= page_ram[146];
                    12'h095: shift_reg <= page_ram[145];
                    12'h096: shift_reg <= page_ram[144];

                    12'h097: shift_reg <= page_ram[151];
                    12'h098: shift_reg <= page_ram[150];
                    12'h099: shift_reg <= page_ram[149];
                    12'h09a: shift_reg <= page_ram[148];

                    12'h09b: shift_reg <= page_ram[155];
                    12'h09c: shift_reg <= page_ram[154];
                    12'h09d: shift_reg <= page_ram[153];
                    12'h09e: shift_reg <= page_ram[152];

                    12'h09f: shift_reg <= page_ram[159];
                    12'h0a0: shift_reg <= page_ram[158];
                    12'h0a1: shift_reg <= page_ram[157];
                    12'h0a2: shift_reg <= page_ram[156];

                    //------------------------------------
                    12'h0a3: shift_reg <= page_ram[163];
                    12'h0a4: shift_reg <= page_ram[162];
                    12'h0a5: shift_reg <= page_ram[161];
                    12'h0a6: shift_reg <= page_ram[160];

                    12'h0a7: shift_reg <= page_ram[167];
                    12'h0a8: shift_reg <= page_ram[166];
                    12'h0a9: shift_reg <= page_ram[165];
                    12'h0aa: shift_reg <= page_ram[164];

                    12'h0ab: shift_reg <= page_ram[171];
                    12'h0ac: shift_reg <= page_ram[170];
                    12'h0ad: shift_reg <= page_ram[169];
                    12'h0ae: shift_reg <= page_ram[168];

                    12'h0af: shift_reg <= page_ram[175];
                    12'h0b0: shift_reg <= page_ram[174];
                    12'h0b1: shift_reg <= page_ram[173];
                    12'h0b2: shift_reg <= page_ram[172];

                    12'h0b3: shift_reg <= page_ram[179];
                    12'h0b4: shift_reg <= page_ram[178];
                    12'h0b5: shift_reg <= page_ram[177];
                    12'h0b6: shift_reg <= page_ram[176];

                    12'h0b7: shift_reg <= page_ram[183];
                    12'h0b8: shift_reg <= page_ram[182];
                    12'h0b9: shift_reg <= page_ram[181];
                    12'h0ba: shift_reg <= page_ram[180];

                    12'h0bb: shift_reg <= page_ram[187];
                    12'h0bc: shift_reg <= page_ram[186];
                    12'h0bd: shift_reg <= page_ram[185];
                    12'h0be: shift_reg <= page_ram[184];

                    12'h0bf: shift_reg <= page_ram[191];
                    12'h0c0: shift_reg <= page_ram[190];
                    12'h0c1: shift_reg <= page_ram[189];
                    12'h0c2: shift_reg <= page_ram[188];
                    //---------------------------------
                    12'h0c3: shift_reg <= page_ram[195];
                    12'h0c4: shift_reg <= page_ram[194];
                    12'h0c5: shift_reg <= page_ram[193];
                    12'h0c6: shift_reg <= page_ram[192];

                    12'h0c7: shift_reg <= page_ram[199];
                    12'h0c8: shift_reg <= page_ram[198];
                    12'h0c9: shift_reg <= page_ram[197];
                    12'h0ca: shift_reg <= page_ram[196];

                    12'h0cb: shift_reg <= page_ram[203];
                    12'h0cc: shift_reg <= page_ram[202];
                    12'h0cd: shift_reg <= page_ram[201];
                    12'h0ce: shift_reg <= page_ram[200];

                    12'h0cf: shift_reg <= page_ram[207];
                    12'h0d0: shift_reg <= page_ram[206];
                    12'h0d1: shift_reg <= page_ram[205];
                    12'h0d2: shift_reg <= page_ram[204];

                    12'h0d3: shift_reg <= page_ram[211];
                    12'h0d4: shift_reg <= page_ram[210];
                    12'h0d5: shift_reg <= page_ram[209];
                    12'h0d6: shift_reg <= page_ram[208];

                    12'h0d7: shift_reg <= page_ram[215];
                    12'h0d8: shift_reg <= page_ram[214];
                    12'h0d9: shift_reg <= page_ram[213];
                    12'h0da: shift_reg <= page_ram[212];

                    12'h0db: shift_reg <= page_ram[219];
                    12'h0dc: shift_reg <= page_ram[218];
                    12'h0dd: shift_reg <= page_ram[217];
                    12'h0de: shift_reg <= page_ram[216];

                    12'h0df: shift_reg <= page_ram[223];
                    12'h0e0: shift_reg <= page_ram[222];
                    12'h0e1: shift_reg <= page_ram[221];
                    12'h0e2: shift_reg <= page_ram[220];

                    //--------------------------------------
                    12'h0e3: shift_reg <= page_ram[227];
                    12'h0e4: shift_reg <= page_ram[226];
                    12'h0e5: shift_reg <= page_ram[225];
                    12'h0e6: shift_reg <= page_ram[224];

                    12'h0e7: shift_reg <= page_ram[231];
                    12'h0e8: shift_reg <= page_ram[230];
                    12'h0e9: shift_reg <= page_ram[229];
                    12'h0ea: shift_reg <= page_ram[228];

                    12'h0eb: shift_reg <= page_ram[235];
                    12'h0ec: shift_reg <= page_ram[234];
                    12'h0ed: shift_reg <= page_ram[233];
                    12'h0ee: shift_reg <= page_ram[232];

                    12'h0ef: shift_reg <= page_ram[239];
                    12'h0f0: shift_reg <= page_ram[238];
                    12'h0f1: shift_reg <= page_ram[237];
                    12'h0f2: shift_reg <= page_ram[236];

                    12'h0f3: shift_reg <= page_ram[243];
                    12'h0f4: shift_reg <= page_ram[242];
                    12'h0f5: shift_reg <= page_ram[241];
                    12'h0f6: shift_reg <= page_ram[240];

                    12'h0f7: shift_reg <= page_ram[247];
                    12'h0f8: shift_reg <= page_ram[246];
                    12'h0f9: shift_reg <= page_ram[245];
                    12'h0fa: shift_reg <= page_ram[244];

                    12'h0fb: shift_reg <= page_ram[251];
                    12'h0fc: shift_reg <= page_ram[250];
                    12'h0fd: shift_reg <= page_ram[249];
                    12'h0fe: shift_reg <= page_ram[248];

                    12'h0ff: shift_reg <= page_ram[255];
                    12'h100: shift_reg <= page_ram[254];
                    12'h101: shift_reg <= page_ram[253];
                    12'h102: shift_reg <= page_ram[252];
                    
                    default: begin
                        shift_reg <= 8'hf1;
                    end
                endcase
                if (shift_bcnt >= (spi_byte_len+3) ) begin
                    spi_tx_trig_write_by_inner <= '1;
                    spi_tx_trig_inner_r <= '0;
                    shift_bcnt          <= 12'h0;
                    is_first_byte       <= '1;
                    //spi_byte_len <= '0;
                end
                else begin
                    spi_tx_trig_write_by_inner <= '0;
                end
            // end 
        end
    end
end

endmodule
`endif
