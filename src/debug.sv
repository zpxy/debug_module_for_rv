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
`ifndef DEBUG_SV
`define DEBUG_SV

module debug (
    input clk,
    input rst_n,
    //dtm <--> debug ,like  apb // now link to afifo
    input  req_vld,
    output logic req_rdy,
    input logic [1:0]  req_opt_code,
    input logic [6:0] req_addr,
    input logic [31:0] req_data,

    output logic resp_vld,
    input  resp_rdy,
    output logic [1:0] resp_sta_code,
    output logic [6:0] resp_addr,
    output logic [31:0] resp_data,
    
    //from and to core
    input dmactiveack,
    input core_is_in_reset,
    output logic dmactive,
    output logic ndmreset,
    output logic debug_irq,

    //tilelink 
    //sysbus as master
    input  sysbus_m_a_ready,
    output logic sysbus_m_a_valid,
    output logic [2:0] sysbus_m_a_opcode,
    output logic [31:0]sysbus_m_a_address,
    output logic [3:0] sysbus_m_a_mask,
    output logic [31:0]sysbus_m_a_data,

    output logic sysbus_m_d_ready,
    input  sysbus_m_d_valid,
    input [31:0] sysbus_m_d_data,

    //sysbus as slave 
    output logic sysbus_s_a_ready,
    input  sysbus_s_a_valid,
    input [2:0] sysbus_s_a_opcode,
    input [2:0] sysbus_s_a_size,
    input [2:0] sysbus_s_a_source,
    input [31:0] sysbus_s_a_address,
    input [3 :0] sysbus_s_a_mask,
    input [31:0] sysbus_s_a_data,
    
    input  sysbus_s_d_ready,
    output logic sysbus_s_d_valid,
    output logic [2:0]  sysbus_s_d_size,
    output logic [2:0]  sysbus_s_d_source,
    output logic [31:0] sysbus_s_d_data
);

//双地址
logic [31:0] data0;  //0x04 //0x380
logic [31:0] data0_tile;
logic data0_tile_writed;
logic [31:0] data0_dmi;
logic data0_dmi_writed;
logic [31:0] data0_r;

always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		data0_r <= 32'd0;
	end
	else begin 
		data0_r <= data0;	
	end
end

always @(*) begin
    if(~rst_n) begin
       data0 = 32'd0;
    end
    else begin
       case ({data0_tile_writed,data0_dmi_writed})
         	2'b01:data0 = data0_dmi;
         	2'b10:data0 = data0_tile;
	  	default :begin 
			data0 = data0_r;
		end
       endcase 
    end
end

logic [31:0] data1;  //0x05
logic [31:0] data1_dmi;
logic data1_dmi_writed;
logic [31:0] data1_tile;
logic data1_tile_writed;

logic [31:0] data1_r;

always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		data1_r <= 32'd0;
	end
	else begin 
		data1_r <= data1;	
	end
end

always @(*) begin
    if(~rst_n) begin
       data1 = 32'd0;
    end
    else begin
       case ({data1_tile_writed,data1_dmi_writed})
        	2'b01:data1 = data1_dmi;
         	2'b10:data1 = data1_tile;
		default:begin 
			data1 = data1_r;		
		end
       endcase 
    end
end

//only dmi write,but tile read  
logic [31:0] progbuf0;//dmi:0x20 tilelink:0x340
logic [31:0] progbuf1;
logic [31:0] progbuf2;
logic [31:0] progbuf3;
logic [31:0] progbuf4;
logic [31:0] progbuf5;
logic [31:0] progbuf6;
logic [31:0] progbuf7;
logic [31:0] progbuf8;
logic [31:0] progbuf9;
logic [31:0] progbuf10;
logic [31:0] progbuf11;
logic [31:0] progbuf12;
logic [31:0] progbuf13;
logic [31:0] progbuf14;
logic [31:0] progbuf15;//dmi:0x2f tilelink 0x37c;

logic [31:0] progbuf0_r;//dmi:0x20 tilelink:0x340
logic [31:0] progbuf1_r;
logic [31:0] progbuf2_r;
logic [31:0] progbuf3_r;
logic [31:0] progbuf4_r;
logic [31:0] progbuf5_r;
logic [31:0] progbuf6_r;
logic [31:0] progbuf7_r;
logic [31:0] progbuf8_r;
logic [31:0] progbuf9_r;
logic [31:0] progbuf10_r;
logic [31:0] progbuf11_r;
logic [31:0] progbuf12_r;
logic [31:0] progbuf13_r;
logic [31:0] progbuf14_r;
logic [31:0] progbuf15_r;//dmi:0x2f tilelink 0x37c;

logic [31:0] sbdata;     //0x3c
logic [31:0] sbdata_dmi;
logic sbdata_dmi_writed;
logic [31:0] sbdata_tile;
logic sbdata_tile_writed;

logic [31:0] sbdata_r;

always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		sbdata_r <= 32'd0;
	end
	else begin 
		sbdata_r <= sbdata;	
	end
end

always @(*) begin
    if(~rst_n) begin
       sbdata = 32'd0;
    end
    else begin
        case ({sbdata_tile_writed,sbdata_dmi_writed})
            2'b01: sbdata = sbdata_dmi;
            2'b10: sbdata = sbdata_tile;
            default: sbdata = sbdata_r;
         endcase
    end
end

//单地址
logic [31:0] dmcontrol;  //0x10
logic [31:0] dmcontrol_t;
logic [31:0] dmcontrol_r;
logic [31:0] dmstatus;   //0x11
logic [31:0] dminfo;     //0x12
assign dminfo = 32'hadca_dace;

logic [31:0] abcs;       //0x16
logic [31:0] abcs_t;
logic [31:0] abcommand;  //0x17 
logic [31:0] abcommand_dmi;
logic [31:0] abcommand_inner;
logic abcommand_dmi_writed;
logic abcommand_inner_writed;

logic [31:0] abcommand_r;

always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		abcommand_r <= 32'd0;
	end
	else begin 
		abcommand_r <= abcommand;	
	end
end

always @(*) begin
    if(~rst_n) begin
        abcommand = 32'd0;
    end
    else begin
        case ({abcommand_inner_writed,abcommand_dmi_writed})
            2'b01:abcommand = abcommand_dmi;
            2'b10:abcommand = abcommand_inner;
            default:abcommand = abcommand_r;
        endcase
    end
end

//logic [31:0] abauto;

logic [31:0] sbcs;       //0x38
logic [31:0] sbcs_t;
logic [31:0] sbcs_r;

logic [31:0] sbaddress;  //0x39
logic [31:0] sbaddress_r;

logic [31:0] abinst0;    
logic [31:0] abinst1; 
logic [31:0] abinst2; 
logic [31:0] abinst3; 
logic [31:0] abinst4;
logic [31:0] abinst5;

logic [31:0] whereto;   
logic [31:0] flags;    
logic flags_go;
logic flags_resume;
logic flags_go_r;
logic flags_resume_r;

assign flags = {30'h0,flags_resume_r,flags_go_r};

logic [31:0] debug_rom0;
logic [31:0] debug_rom1;
logic [31:0] debug_rom2;
logic [31:0] debug_rom3;
logic [31:0] debug_rom4;
logic [31:0] debug_rom5;
logic [31:0] debug_rom6;
logic [31:0] debug_rom7;
logic [31:0] debug_rom8;
logic [31:0] debug_rom9;
logic [31:0] debug_rom10;
logic [31:0] debug_rom11;
logic [31:0] debug_rom12;
logic [31:0] debug_rom13;
logic [31:0] debug_rom14;
logic [31:0] debug_rom15;
logic [31:0] debug_rom16;
logic [31:0] debug_rom17;
logic [31:0] debug_rom18;
logic [31:0] debug_rom19;
logic [31:0] debug_rom20;
logic [31:0] debug_rom21;
logic [31:0] debug_rom22;
logic [31:0] debug_rom23;
logic [31:0] debug_rom24;
logic [31:0] debug_rom25;

assign whereto = 32'h0280_006f;
assign debug_rom0 = 32'h7b349073;   //800
assign debug_rom1 = 32'hc0006f;     //804
assign debug_rom2 = 32'h7b3494f3;   //808
assign debug_rom3 = 32'h9004a623;   //80c
assign debug_rom4 = 32'h0ff0000f;   //810
assign debug_rom5 = 32'h7b241073;   //814
assign debug_rom6 = 32'h00000497;   //818
assign debug_rom7 = 32'hfe848493;   //81c
assign debug_rom8 = 32'hf1402473;   //820
assign debug_rom9 = 32'h9084a023;   //824
assign debug_rom10 = 32'h00940433;  //828
assign debug_rom11 = 32'hc0044403;  //82c
assign debug_rom12 = 32'h00347413;  //830
assign debug_rom13 = 32'hfe0406e3;  //834
assign debug_rom14 = 32'h00147413;  //838
assign debug_rom15 = 32'h40c63;     //83c
assign debug_rom16 = 32'h7b202473;  //840
assign debug_rom17 = 32'h4848067;   //844
assign debug_rom18 = 32'h9004a223;  //848
assign debug_rom19 = 32'h7b3494f3;  //84c
assign debug_rom20 = 32'hab1ff06f;  //850
assign debug_rom21 = 32'hf1402473;  //854
assign debug_rom22 = 32'h9084a423;  //858
assign debug_rom23 = 32'h7b202473;  //85c
assign debug_rom24 = 32'h7b3024f3;  //860
assign debug_rom25 = 32'h7b200073;  //864

//-------------------------------------------
logic [31:0] halted;     //0x100
logic halted_tile_writed;

logic [31:0] going;      //0x104
logic going_tile_writed;

logic [31:0] resuming;   //0x108
logic resume_tile_writed;

logic [31:0] exception;  //0x10c
logic ebreak_tile_writed;
//-------------------------------------------
logic [1:0] state_dmi;  
logic [1:0] state_dmi_next;
//2'b00 idle
//2'b01 read
//2'b10 writw
//2'b11 toidle

//dmstatus and flags.go flags.resum and abcs.err;
logic [2:0] state_ctrl;
logic [2:0] state_ctrl_next;

localparam ctrl_runnig = 3'd1;
localparam ctrl_halted_waiting = 3'd2;
localparam ctrl_halted_cmderr  = 3'd3;
localparam ctrl_go             = 3'd4;
localparam ctrl_resume         = 3'd5;
localparam ctrl_reset          = 3'd6; 

logic [2:0] state_tilelink_master;
logic [2:0] state_tilelink_master_next;

localparam tile_master_disable = 3'h0;
localparam tile_master_idle    = 3'h1;
localparam tile_master_write_aquest = 3'h2;
localparam tile_master_read_aquest  = 3'h3;
localparam tile_master_write_ack    = 3'h4;
localparam tile_master_read_ack     = 3'h5;

logic [1:0] state_tilelink_slave;
logic [1:0] state_tilelink_slave_next;

localparam tile_slave_disable = 2'd0;
localparam tile_slave_idle    = 2'd1;
localparam tile_slave_write_ack = 2'd2;
localparam tile_slave_read_ack  = 2'd3;

logic tile_master_write_trig;//tirg之后要复位，下一周期复位
logic tile_master_read_trig; //trig之后要复位，下一周期复位

//不能重复定义
// logic dmactive;
// logic ndmreset; // 只有ndrest的时候才会变得不可达;
logic clrresethaltreq;
logic setresethaltreq;
logic [19:0] hartsel;
logic hasel;
logic ackhavereset;//当 hartisrest 拉高又拉低，这里写1清除掉reset状态
logic resumereq;
logic haltreq;
logic haltreq_dmi;
logic haltreq_inner;
logic haltreq_dmi_writed;
logic haltreq_inner_writed;

logic halt_on_rest_request;
logic haltreq_r;

always @(posedge clk or negedge rst_n) begin 
	if(~rst_n) begin 
		 haltreq_r <= 1'd0;
	end
	else begin 
		haltreq_r <= haltreq;	
	end
end

always @(*) begin
    if(~rst_n)begin
        haltreq = '0;
    end  
    else begin
        case ({haltreq_inner_writed,haltreq_dmi_writed})
            2'b01:haltreq = haltreq_dmi;
            2'b10:haltreq = haltreq_inner;
            default:haltreq = haltreq_r;
        endcase
    end   
end
// assign haltreq      = dmcontrol_t[31];
// assign halted_dmi   = dmcontrol_t[31];
assign resumereq    = dmcontrol_r[30] && ~haltreq;
assign ackhavereset = dmcontrol_r[28];
assign hasel        = '0;
assign hartsel      = 20'd0;
assign setresethaltreq = dmcontrol_r[3];
assign clrresethaltreq = dmcontrol_r[2];
assign ndmreset        = dmcontrol_r[1];
assign dmactive        = dmcontrol_r[0];

assign dmcontrol = {haltreq_r,resumereq,'0,ackhavereset,'0,hasel,hartsel,2'h0,setresethaltreq,clrresethaltreq,ndmreset,dmactive};
assign halt_on_rest_request = (setresethaltreq && ~clrresethaltreq) ? 1 : ((~setresethaltreq && clrresethaltreq) ? 0 :0);

logic [3:0] version;
logic confstrvalid;
logic hasresethaltreq;
logic authbusy;
logic authenticed;

logic anyhalted; //对于单核系统，这两个状态要时刻一致
logic allhalted;
logic anyrunning;//没有暂停,初始化就是running
logic allrunning;
logic anyunavail;//超时未应答则处于此状态
logic allunavail;
logic anynoexist;
logic allnoexist;
logic anyresumeack;//写了resuming = id == halted,就是resume ack, 此时，修改状态为running
logic allresumeack;
logic anyhavereset;//hartisrest 拉高又拉低，这里变为1
logic allhavereset;
logic imebreak;

logic anyhalted_r; 
logic allhalted_r;
logic anyrunning_r;
logic allrunning_r;
logic anyunavail_r;
logic allunavail_r;
logic anynoexist_r;
logic allnoexist_r;
logic anyresumeack_r;
logic allresumeack_r;
logic anyhavereset_r;
logic allhavereset_r;


assign imebreak     = '0;
assign confstrvalid = '0;
assign hasresethaltreq = '1;
assign authbusy = '0;
assign authenticed = '1;
assign version = 4'h2;

assign dmstatus = {9'h0,imebreak,2'd0,allhavereset_r,anyhavereset_r,allresumeack_r,anyresumeack_r,allnoexist_r,anynoexist_r,allunavail_r,anyunavail_r,allrunning_r,anyrunning_r,allhalted_r,anyhalted_r,authenticed,authbusy,hasresethaltreq,confstrvalid,version};

logic [2:0] abcs_datacnt;
logic [2:0] abcs_err;
logic [2:0] abcs_err_r;
logic abcs_busy;//写了command =1,写了ebreak清空 
logic abcs_busy_r;
logic [4:0] abcs_progbufsize;
logic abcs_err_writedclr;

assign abcs_datacnt     = 3'h2;
assign abcs_progbufsize = 5'd16;
//错误上报机制
//assign abcs_err  = ~rst_n?0:abcs_err_r;
//assign abcs_busy = ~rst_n?0:abcs_busy_r;
assign abcs      = {3'h0,abcs_progbufsize,11'h0,abcs_busy_r,abcs_err_r,4'h0,abcs_datacnt};

logic sbaccess8;
logic sbaccess16;
logic sbaccess32;
logic sbaccess64;
logic sbaccess128;
logic [6:0] sbasize;
logic [2:0] sbaerror;
logic [2:0] sbaerror_r;
logic sbareadondata;
logic sbautoinc_addr;
logic [2:0] sbaccess;
logic sbreadonaddr;
logic sbbusy;
logic sbbusyerror;
logic [2:0] sbversion;

assign sbversion = 3'h1;
assign sbasize   = 7'd32;
assign sbaccess128 = '0;
assign sbaccess64  = '0;
assign sbaccess32  = '1;
assign sbaccess16  = '1;
assign sbaccess8   = '1;

assign sbareadondata  = ~rst_n?0:sbcs_r[15];
assign sbreadonaddr   = ~rst_n?0:sbcs_r[20];
assign sbautoinc_addr = ~rst_n?0:sbcs_r[16];
assign sbaccess       = ~rst_n?0:sbcs_r[19:17];
//暂时不上报错误
assign sbaerror       = ~rst_n?0:0;
assign sbbusy         = ~rst_n?0:0;
assign sbbusyerror    = ~rst_n?0:0;

assign sbcs = {sbversion,6'h0,sbbusyerror,sbbusy,sbreadonaddr,sbaccess,sbautoinc_addr,sbareadondata,sbaerror,sbasize,sbaccess128,sbaccess64,sbaccess32,sbaccess16,sbaccess8};


logic [7:0] cmdtype;
logic [23:0] cmd_control;
assign cmdtype     = abcommand_r[31:24];
assign cmd_control = abcommand_r[23:0];
//----------------------------
logic access_register;
assign access_register = ((cmdtype == 8'h0)&& cmd_control != 24'h0);

logic [2:0] aar_size;
logic aar_post_increment;
logic postexec;
logic transfer;
logic write;

logic [15:0] regno;
logic [15:0] regno_r;
logic [4:0] regno2gprindex;
logic [4:0] reg_rd1;
logic [4:0] reg_rd2; 

assign aar_size           = cmd_control[22:20];
assign aar_post_increment = '0;
assign postexec           = cmd_control[18];
assign transfer           = cmd_control[17];
assign write              = cmd_control[16];
assign regno              = cmd_control[15:0];

assign regno2gprindex =  (regno[15:8] == 8'h10 && regno[7:0] <= 8'h1f)?regno[7:0]:8'h0;
assign reg_rd2        = regno2gprindex;
assign reg_rd1        = reg_rd2[0]?5'h8:5'h9;  
//----------------------------
logic quick_access;
assign quick_access = (cmdtype == 8'h1) && (cmd_control == 24'h0); 
//----------------------------
// not surport;
logic accsess_memory;
assign accsess_memory = (cmdtype == 8'h2);

//cmdtype==0,cmd access reg;
//cmdtype==1,this surported ,when do this , the fisrt code in abcs_inst0 is go to probuffer;
//cmdtype==2 ==> cmderror == 2 == unsurported;
always @(*) begin
    if(~rst_n) begin
        abinst0 = 32'h13;
        abinst1 = 32'h13;
        abinst2 = 32'h13;
        abinst3 = 32'h13;
        abinst4 = 32'h13;
        abinst5 = 32'h100073;
    end
    else begin
        abinst0 = quick_access ? 32'h0400_006f:32'h13;
        abinst1 = 32'h13;
        abinst2 = {12'h7b3,reg_rd1,3'h1,reg_rd1,7'h73};
        abinst3 = transfer?(write?(32'({12'hb80,reg_rd1,aar_size,reg_rd2,7'h3})):(32'({7'h5c,reg_rd2,reg_rd1,aar_size,6'h0,7'h23}))):32'h13;
        abinst4 = {12'h7b3,reg_rd1,3'h1,reg_rd1,7'h73};
        abinst5 = postexec ? 32'h13:32'h100073;
    end
    
end

//haltreq 和 resumereq 不能同时 
assign debug_irq = haltreq ? 1:0;

logic req_fire;
logic resp_fire;

assign req_fire  = req_vld && req_rdy;
assign resp_fire = resp_vld && resp_rdy;

localparam dmi_idle = 2'b00;
localparam dmi_read = 2'b01;
localparam dmi_write = 2'b10;
localparam dmi_none = 2'b11;

logic [2:0]  req_opt_code_r;
logic [6:0]  req_addr_r;
logic [31:0] req_data_r;



//state machine surport 
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state_dmi    <= 2'b00;
  
	req_opt_code_r <= 2'b00;
	req_addr_r     <= 7'd0;
	req_data_r     <= 32'd0;

	progbuf0_r <= 32'd0;//dmi:0x20 tilelink:0x340
	progbuf1_r <= 32'd0;
	progbuf2_r <= 32'd0;
	progbuf3_r <= 32'd0;
	progbuf4_r <= 32'd0;
	progbuf5_r <= 32'd0;
	progbuf6_r <= 32'd0;
	progbuf7_r <= 32'd0;
	progbuf8_r <= 32'd0;
	progbuf9_r <= 32'd0;
	progbuf10_r <= 32'd0;
	progbuf11_r <= 32'd0;
	progbuf12_r <= 32'd0;
	progbuf13_r <= 32'd0;
	progbuf14_r <= 32'd0;
	progbuf15_r <= 32'd0;//dmi:0x2f tilelink 0x37c;
	 

	sbaddress_r <= 32'd0;
	dmcontrol_r <= 32'd0;
	sbcs_r      <= 32'd0;

    end
    else  begin
       state_dmi      <= state_dmi_next;
	req_opt_code_r <= req_opt_code;
	req_addr_r     <= req_addr;
	req_data_r     <= req_data;
      

	progbuf0_r <= progbuf0;//dmi:0x20 tilelink:0x340
	progbuf1_r <= progbuf1;
	progbuf2_r <= progbuf2;
	progbuf3_r <= progbuf3;
	progbuf4_r <= progbuf4;
	progbuf5_r <= progbuf5;
	progbuf6_r <= progbuf6;
	progbuf7_r <= progbuf7;
	progbuf8_r <= progbuf8;
	progbuf9_r <= progbuf9;
	progbuf10_r <= progbuf10;
	progbuf11_r <= progbuf11;
	progbuf12_r <= progbuf12;
	progbuf13_r <= progbuf13;
	progbuf14_r <= progbuf14;
	progbuf15_r <= progbuf15;//dmi:0x2f tilelink 0x37c;

	sbaddress_r <= sbaddress;
	dmcontrol_r <= dmcontrol_t;
	sbcs_r      <= sbcs_t;

    end
end



assign dmi_write_data0 = req_fire && (req_opt_code==2'b10) && (req_addr == 7'h04);

always @(*) begin
    if(~rst_n) begin
        req_rdy  = '1;
	  resp_vld = '0;

        dmcontrol_t = 32'd0;
        abcs_t = 32'd0;
        sbcs_t = 32'd0;
        sbaddress = 32'd0;

	  haltreq_dmi   = 1'b0;
	  abcommand_dmi = 32'd0;
	  data0_dmi     = 32'd0;
	  data1_dmi     = 32'd0;
	  sbdata_dmi = 32'd0;

        sbdata_dmi_writed = '0;
        data0_dmi_writed = '0;
        data1_dmi_writed = '0; 
        tile_master_write_trig = '0;
        tile_master_read_trig  = '0;
        abcs_err_writedclr = '0;
        abcommand_dmi_writed = '0;
        haltreq_dmi_writed = '0;
	
	progbuf0  = progbuf0;//dmi:0x20 tilelink:0x340
	progbuf1  = progbuf1;
	progbuf2  = progbuf2;
	progbuf3  = progbuf3;
	progbuf4  = progbuf4;
	progbuf5  = progbuf5;
	progbuf6  = progbuf6;
	progbuf7  = progbuf7;
	progbuf8  = progbuf8;
	progbuf9  = progbuf9;
	progbuf10 = progbuf10;
	progbuf11 = progbuf11;
	progbuf12 = progbuf12;
	progbuf13 = progbuf13;
	progbuf14 = progbuf14;
	progbuf15 = progbuf15;//dmi:0x2f tilelink 0x37c;
	
      resp_sta_code = 2'b0;
      resp_addr = 7'd0;
      resp_data = 32'd0;
      state_dmi_next = 2'b00;

    end else begin
	  req_rdy  = '1;
	  resp_vld = '0;
	   
	   haltreq_dmi = haltreq_r;;
	   abcommand_dmi = abcommand_r;
	   data0_dmi = data0_r;
 	   data1_dmi= data1_r; 
          sbdata_dmi = sbdata_r;
	   sbaddress = sbaddress_r;   
		dmcontrol_t = dmcontrol_r;
		sbcs_t = sbcs_r;

	  sbdata_dmi_writed = '0;
        data0_dmi_writed = '0;
        data1_dmi_writed = '0; 
        tile_master_write_trig = '0;
        tile_master_read_trig  = '0;
        abcs_err_writedclr = '0;
        abcommand_dmi_writed = '0;
        haltreq_dmi_writed = '0;

	 resp_sta_code = 2'b0;
       resp_addr = req_addr_r;
       resp_data = 32'd0;
	state_dmi_next = 2'b00;



	progbuf0  = progbuf0_r;//dmi:0x20 tilelink:0x340
	progbuf1  = progbuf1_r;
	progbuf2  = progbuf2_r;
	progbuf3  = progbuf3_r;
	progbuf4  = progbuf4_r;
	progbuf5  = progbuf5_r;
	progbuf6  = progbuf6_r;
	progbuf7  = progbuf7_r;
	progbuf8  = progbuf8_r;
	progbuf9  = progbuf9_r;
	progbuf10 = progbuf10_r;
	progbuf11 = progbuf11_r;
	progbuf12 = progbuf12_r;
	progbuf13 = progbuf13_r;
	progbuf14 = progbuf14_r;
	progbuf15 = progbuf15_r;//dmi:0x2f tilelink 0x37c
	
        case (state_dmi)
            //idle 
            2'b00:begin
                resp_vld = '0; 
                sbdata_dmi_writed = '0;
                data0_dmi_writed = '0;
                data1_dmi_writed = '0; 
                tile_master_write_trig = '0;
                tile_master_read_trig  = '0;
                abcs_err_writedclr = '0;
                abcommand_dmi_writed = '0;
                haltreq_dmi_writed = '0;
                if(req_fire) begin
                    case (req_opt_code)
                        2'b00: state_dmi_next = 2'b11;
                        2'b01: begin 
                            state_dmi_next = 2'b01;
                            //read
                            //req_addr_r = req_addr;
                        end
                        2'b11: state_dmi_next = 2'b11;//state_next = 2'b11;
                        2'b10: begin 
                            state_dmi_next = 2'b10;
                            //write 
                            //req_addr_r = req_addr;
                            //req_data_r = req_data;
                        end
                    endcase
                end
                else begin
                    state_dmi_next = 2'b00;
                end
            end
            //read and read ack
            2'b01:begin
                resp_vld = '1;
                case (req_addr_r)     
                    7'h04:begin
                        resp_sta_code = 2'b0;
                        resp_addr = req_addr_r;
                        resp_data = data0;
                    end
                    7'h05:begin
                        resp_sta_code = 2'b0;
                        resp_addr = req_addr_r;
                        resp_data = data1;
                    end
                    7'h10:begin
                        resp_sta_code = 2'b0;
                        resp_addr = req_addr_r;
                        resp_data = dmcontrol;
                    end
                    7'h11:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = dmstatus;
                    end
                    7'h12:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = dminfo;
                    end
                    7'h16:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = abcs;
                    end
                    7'h17:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = abcommand;
                    end
                    7'h20:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf0_r;
                    end
                    7'h21:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf1_r;
                    end
                    7'h22:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf2_r;
                    end
                    7'h23:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf3_r;
                    end
                    7'h24:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf4_r;
                    end
                    7'h25:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf5_r;
                    end
                    7'h26:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf6_r;
                    end
                    7'h27:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf7_r;
                    end
                    7'h28:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf8_r;
                    end
                    7'h29:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf9_r;
                    end
                    7'h2a:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf10_r;
                    end
                    7'h2b:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf11_r;
                    end
                    7'h2c:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf12_r;
                    end
                    7'h2d:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf13_r;
                    end
                    7'h2e:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf14_r;
                    end
                    7'h2f:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = progbuf15_r;
                    end
                    7'h38:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = sbcs;
                    end
                    7'h39:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = sbaddress_r;
                    end
                    7'h3c:begin
                        resp_sta_code = 2'b00;
                        resp_addr = req_addr_r;
                        resp_data = sbdata;
                    end
                    default: begin
                        // error 
                        resp_sta_code = 2'b11;
                        resp_addr = 7'h0;
                        resp_data = 32'hffff_ffff;
                    end
                endcase
                if(resp_fire && req_fire) begin
                    case (req_opt_code)
                        2'b00: state_dmi_next = 2'b11;
                        2'b01: begin 
                            //req_addr_r = req_addr;
                            state_dmi_next = 2'b01;
                        end
                        2'b11: state_dmi_next = 2'b11;//state_next = 2'b11;
                        2'b10: begin
                            //req_addr_r = req_addr;
                            //req_data_r = req_data;
                            state_dmi_next = 2'b10;
                        end
                    endcase
                end
                else if(resp_fire && ~req_fire) begin
                    state_dmi_next = 2'b00;
                end 
                else begin
                    state_dmi_next = 2'b00;
                end
            end
            //no surpoted addr
            2'b11:begin
                resp_vld = '1;
                resp_addr = 7'd0;
                resp_data = 32'h0;
                resp_sta_code  = 2'd0;
                state_dmi_next = 2'b00;
            end
            //write and write ack
            2'b10:begin
            resp_vld = '1;
            resp_addr = req_addr_r;
            resp_data = 32'h0;
            case (req_addr_r)
                    7'h04:begin
                        resp_sta_code = 2'b00;
                        data0_dmi = req_data_r; //REG
                        data0_dmi_writed = '1;
                    end
                    7'h05:begin 
                        resp_sta_code = 2'b00;
                        data1_dmi = req_data_r;//REG
                        data1_dmi_writed = '1;
                    end
                    7'h10:begin
                        resp_sta_code = 2'b00;
                        dmcontrol_t = req_data_r;//REG
                        haltreq_dmi = dmcontrol_t[31];
                        haltreq_dmi_writed = '1;
                    end
                    7'h11:begin
                        resp_sta_code = 2'b00;
                    end
                    7'h12:begin
                        resp_sta_code = 2'b00; 
                    end
                    7'h16:begin
                        resp_sta_code = 2'b00;
                        abcs_t          = req_data_r;//REG
                        //write any bit to one would give the writed clr signal;
                        if(abcs_t[10:8] == 3'd1) begin
                            abcs_err_writedclr = '1;
                        end
                        else begin
                            abcs_err_writedclr = '0;
                        end
                    end
                    7'h17:begin
                        resp_sta_code = 2'b00;
                        abcommand_dmi  = req_data_r;//REG
                        abcommand_dmi_writed = '1;
                    end
                    7'h20:begin
                        resp_sta_code = 2'b00;
                        progbuf0 = req_data_r;//REG
                    end
                    7'h21:begin
                        resp_sta_code = 2'b00;
                        progbuf1 = req_data_r;
                    end
                    7'h22:begin
                        resp_sta_code = 2'b00;
                        progbuf2 = req_data_r;
                    end
                    7'h23:begin
                        resp_sta_code = 2'b00;
                        progbuf3 = req_data_r;
                    end
                    7'h24:begin
                        resp_sta_code = 2'b00;
                        progbuf4 = req_data_r;
                    end
                    7'h25:begin
                        resp_sta_code = 2'b00;
                        progbuf5 = req_data_r;
                    end
                    7'h26:begin
                        resp_sta_code = 2'b00;
                        progbuf6 = req_data_r;
                    end
                    7'h27:begin
                        resp_sta_code = 2'b00;
                        progbuf7 = req_data_r;
                    end
                    7'h28:begin
                        resp_sta_code = 2'b00;
                        progbuf8 = req_data_r;
                    end
                    7'h29:begin
                        resp_sta_code = 2'b00;
                        progbuf9 = req_data_r;
                    end
                    7'h2a:begin
                        resp_sta_code = 2'b00;
                        progbuf10 = req_data_r;
                    end
                    7'h2b:begin
                        resp_sta_code = 2'b00;
                        progbuf11 = req_data_r;
                    end
                    7'h2c:begin
                        resp_sta_code = 2'b00;
                        progbuf12 = req_data_r;
                    end
                    7'h2d:begin
                        resp_sta_code = 2'b00;
                        progbuf13 = req_data_r;
                    end
                    7'h2e:begin
                        resp_sta_code = 2'b00;
                        progbuf14 = req_data_r;
                    end
                    7'h2f:begin
                        resp_sta_code = 2'b00;
                        progbuf15 = req_data_r;
                    end
                    7'h38:begin
                        resp_sta_code = 2'b00;
                        sbcs_t = req_data_r;
                    end
                    7'h39:begin
                        resp_sta_code = 2'b00;
                        sbaddress = req_data_r;//REG
                        tile_master_write_trig = ~sbreadonaddr ? 1:0;
                        tile_master_read_trig  = ~tile_master_write_trig;
                    end
                    7'h3c:begin
                        resp_sta_code = 2'b00;
                        sbdata_dmi = req_data_r;//REG
                        //give a signal
                        sbdata_dmi_writed = '1;
                    end
                    default: begin
                        // error 
                        resp_sta_code = 2'b11;
                    end
                endcase
                if(resp_fire && req_fire ) begin
                    case (req_opt_code)
                        2'b00: state_dmi_next = 2'b11;
                        2'b01: begin 
                            //req_addr_r = req_addr;
                            state_dmi_next = 2'b01;
                        end
                        2'b11: state_dmi_next = 2'b11;//state_next = 2'b11;
                        2'b10: begin
                            //req_addr_r = req_addr;
                            //req_data_r = req_data;
                            state_dmi_next = 2'b10;
                        end
                    endcase
                end
                else if (resp_fire && ~req_fire)begin
                    state_dmi_next = 2'b00;
                end
                else begin
                    state_dmi_next = 2'b00; 
                end
            end
        endcase
    end
end


//------------------------------------------------------------------------------------------
logic tile_master_a_fire;
logic tile_master_d_fire;

assign tile_master_a_fire = sysbus_m_a_valid && sysbus_m_a_ready;
assign tile_master_d_fire = sysbus_m_d_ready && sysbus_m_d_valid;

//tilelink state machine master // to mmemory
// 系统总线功能 ul 级别
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state_tilelink_master <= tile_master_disable;
        //state_tilelink_master_next <= tile_master_disable;
	    
    end
    else begin
        state_tilelink_master <= state_tilelink_master_next;
    end
end

always @(*) begin
    if(~rst_n) begin
        sysbus_m_a_valid = '0;
        sysbus_m_d_ready = '1;
	  sbdata_tile = 32'd0;
        sbdata_tile_writed = '0;
	
	   sysbus_m_a_data  = 32'd0;//reg
         sysbus_m_a_address = 32'd0;//reg
         sysbus_m_a_mask = 2'h3;//reg
         sysbus_m_a_opcode = 3'h0;//reg
	  state_tilelink_master_next = tile_master_disable;

    end else begin 
	  sysbus_m_a_valid = '0;
        sysbus_m_d_ready = '1;
	  sysbus_m_a_data  = 32'd0;//reg
        sysbus_m_a_address = 32'd0;//reg
        sysbus_m_a_mask = 2'h3;//reg
        sysbus_m_a_opcode = 3'h0;//reg
		
        sbdata_tile_writed = '0;
	  sbdata_tile = 32'd0;
        state_tilelink_master_next = tile_master_disable;
        case (state_tilelink_master)
            tile_master_disable: begin
            if(dmactive) begin
                state_tilelink_master_next = tile_master_idle; 
            end 
            else begin
                    state_tilelink_master_next = tile_master_disable;
            end
            end
            tile_master_idle:begin
                sysbus_m_a_valid = '0;
                sysbus_m_d_ready = '1;
                sbdata_tile_writed = '0;
            if(tile_master_write_trig) begin
                    //tile_master_write_trig = '0;
                    state_tilelink_master_next = tile_master_write_aquest;
            end
            else if (tile_master_read_trig )begin
                    //tile_master_read_trig = '0;
                    state_tilelink_master_next = tile_master_read_aquest;
            end 
            else if(~dmactive) begin
                    state_tilelink_master_next = tile_master_disable;
            end
            else begin
                    state_tilelink_master_next = tile_master_idle;
            end
            end
            tile_master_write_aquest:begin
                sysbus_m_a_valid = '1;
                sysbus_m_a_data  = sbdata_r;//reg
                sysbus_m_a_address = sbaddress_r;//reg
                sysbus_m_a_mask = 2'h3;//reg
                sysbus_m_a_opcode = 3'h0;//reg
                if(tile_master_a_fire) begin
                    state_tilelink_master_next = tile_master_write_ack;
                end
                else begin
                    state_tilelink_master_next = tile_master_write_aquest;
                end
            end
            tile_master_write_ack:begin
            sysbus_m_a_valid = '0;
            sysbus_m_d_ready = '1;
            if(tile_master_d_fire) begin
                    state_tilelink_master_next = tile_master_idle;
            end 
            else begin
                    state_tilelink_master_next = tile_master_write_ack;
            end
            end
            tile_master_read_aquest:begin
                sysbus_m_a_valid = '1;
                sysbus_m_a_data  = 32'h0;
                sysbus_m_a_address = sbaddress;
                sysbus_m_a_mask = 2'h3;
                sysbus_m_a_opcode = 3'h4;
                if(tile_master_a_fire) begin
                    state_tilelink_master_next = tile_master_read_ack;
                    
                end
                else begin
                    state_tilelink_master_next =tile_master_read_aquest;
                end
            end
            tile_master_read_ack:begin
            sysbus_m_a_valid = '0;
            sysbus_m_d_ready = '1;
            if(tile_master_d_fire) begin
                    state_tilelink_master_next = tile_master_idle;
                    sbdata_tile = sysbus_m_d_data;//reg
                    sbdata_tile_writed = '1;
            end 
            else begin
                    state_tilelink_master_next = tile_master_read_ack;
            end
            end
            default: begin
                state_tilelink_master_next = tile_master_disable;
            end
        endcase
    end
end
//----------------------------------------------------------------------------

logic [11:0] sysbus_s_a_addr_offset;
assign sysbus_s_a_addr_offset = sysbus_s_a_address[11:0];
logic [11:0] sysbus_s_a_addr_offset_r;
logic [31:0] sysbus_s_a_data_r;

logic tile_slave_a_fire;
logic tile_slave_d_fire;
logic tile_slave_write_fire;
logic tile_slave_read_fire;

assign tile_slave_a_fire = sysbus_s_a_valid && sysbus_s_a_ready;
assign tile_slave_d_fire = sysbus_s_d_valid && sysbus_s_d_ready;
assign tile_slave_write_fire = tile_slave_a_fire && sysbus_s_a_opcode==3'd0;
assign tile_slave_read_fire  = tile_slave_a_fire && sysbus_s_a_opcode==3'd4;

//tilelink sttate machine slave // to core
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state_tilelink_slave      <= tile_slave_disable;
        //state_tilelink_slave_next <= tile_slave_disable; 
	  sysbus_s_a_addr_offset_r <= 12'h000;//reg
        sysbus_s_a_data_r        <= 32'd0;              //reg       
    end
    else begin
        state_tilelink_slave      <= state_tilelink_slave_next;
	  sysbus_s_a_addr_offset_r <= sysbus_s_a_addr_offset;//reg
        sysbus_s_a_data_r         <= sysbus_s_a_data;              //reg
    end
end




always @(*) begin
    if(~rst_n) begin
        sysbus_s_a_ready  = '1;
        sysbus_s_d_valid  = '0;
	    data0_tile = 32'd0;
	    data1_tile = 32'd0;
   
        data0_tile_writed = '0;
        data1_tile_writed = '0;
        ebreak_tile_writed = '0;
        resume_tile_writed = '0;
        going_tile_writed  = '0;
        halted_tile_writed = '0;
		
	    //sysbus_s_d_valid = '1;
        sysbus_s_d_size   = 3'd0;   //reg
        sysbus_s_d_source = 3'd0; //reg
	    sysbus_s_d_data   =32'hffff_ffff;
        state_tilelink_slave_next = tile_slave_disable;
    end else begin
	    sysbus_s_a_ready  = '1;
        sysbus_s_d_valid  = '0;
        data0_tile_writed = '0;
        data1_tile_writed = '0;
        ebreak_tile_writed = '0;
        resume_tile_writed = '0;
        going_tile_writed  = '0;
        halted_tile_writed = '0;
        data0_tile = 32'd0;
	  data1_tile = 32'd0;
        //sbdata_tile =32'd0;
	  sysbus_s_d_size   = 3'd0;   //reg
        sysbus_s_d_source = 3'd0; //reg
	 sysbus_s_d_data   =32'hffff_ffff;//reg
        state_tilelink_slave_next = tile_slave_disable;

        case (state_tilelink_slave)
            tile_slave_disable:begin
                sysbus_s_a_ready = '0;
                if(dmactive) begin
                    state_tilelink_slave_next = tile_slave_idle;
                end 
                else begin
                    state_tilelink_slave_next = tile_slave_disable;
                end
            end
            tile_slave_idle:begin
                sysbus_s_a_ready  = '1;
                sysbus_s_d_valid  = '0;
                data0_tile_writed = '0;
                data0_tile_writed = '0;
                ebreak_tile_writed = '0;
                resume_tile_writed = '0;
                going_tile_writed  = '0;
                halted_tile_writed = '0;
                // sysbus_s_d_size  = 3'd0;
                // sysbus_s_d_source = 3'd0;
                if(tile_slave_write_fire)begin
                    state_tilelink_slave_next = tile_slave_write_ack;
                    //sysbus_s_a_addr_offset_r = sysbus_s_a_addr_offset;//reg
                    //sysbus_s_a_data_r = sysbus_s_a_data;              //reg
                end
                else if(tile_slave_read_fire) begin
                    state_tilelink_slave_next = tile_slave_read_ack;
                    //sysbus_s_a_addr_offset_r = sysbus_s_a_addr_offset;//reg
                end
                else if (~dmactive) begin
                    state_tilelink_slave_next = tile_slave_disable;
                end
                else begin
                    state_tilelink_slave_next = tile_slave_idle;
                end

            end
            tile_slave_write_ack:begin
                sysbus_s_d_valid = '1;
                sysbus_s_d_size   = sysbus_s_a_size;   //reg
                sysbus_s_d_source = sysbus_s_a_source; //reg
                case (sysbus_s_a_addr_offset_r)
                    12'h100:begin 
                        halted = sysbus_s_a_data_r;// give hartid // reg
                        //give hart halted signal, and this should be macthed with resuming register
                        halted_tile_writed = '1;
                    end
                    12'h104:begin 
                        going = sysbus_s_a_data_r;//give zero     //reg
                        //reset the flags.go regfiled,go is goabstract;
                        going_tile_writed = '1;
                    end
                    12'h108:begin 
                        resuming = sysbus_s_a_data_r;//give hartid //reg
                        //reset the flags.resume regfiled,and resumeack should be set
                        resume_tile_writed = '1;
                    end
                    12'h10c:begin 
                        exception = sysbus_s_a_data_r;//give zero; //reg
                        //give an ebreak execulate signal
                        ebreak_tile_writed = '1;
                    end
                    //双地址的寄存器                
                    12'h380:begin 
                    	data0_tile = sysbus_s_a_data_r;//reg
                    	data0_tile_writed = '1; 
                    end
                    12'h384:begin 
                        data1_tile = sysbus_s_a_data_r;
                        data1_tile_writed = '1;
                    end
                    default: begin
                        // error 
                        sysbus_s_d_size   = 3'h7;
                        sysbus_s_d_source = 3'h7;
                        sysbus_s_d_data   =32'hffff_ffff;
                    end
                endcase
                if(tile_slave_d_fire) begin
                    //--> idle;
                    state_tilelink_slave_next = tile_slave_idle;
                end
                else begin
                //--> writeack 
                state_tilelink_slave_next = tile_slave_write_ack;
                end
            end
            tile_slave_read_ack:begin
                sysbus_s_d_valid = '1;
                sysbus_s_d_size  = sysbus_s_a_size;
                sysbus_s_d_source = sysbus_s_a_source;
                case (sysbus_s_a_addr_offset_r)
                    12'h300:sysbus_s_d_data = whereto;
                    12'h328:sysbus_s_d_data = abinst0;
                    12'h32c:sysbus_s_d_data = abinst1;
                    12'h330:sysbus_s_d_data = abinst2;
                    12'h334:sysbus_s_d_data = abinst3;
                    12'h338:sysbus_s_d_data = abinst4;
                    12'h33c:sysbus_s_d_data = abinst5;
                    12'h340:sysbus_s_d_data = progbuf0_r;
                    12'h344:sysbus_s_d_data = progbuf1_r;
                    12'h348:sysbus_s_d_data = progbuf2_r;
                    12'h34c:sysbus_s_d_data = progbuf3_r;
                    12'h350:sysbus_s_d_data = progbuf4_r;
                    12'h354:sysbus_s_d_data = progbuf5_r;
                    12'h358:sysbus_s_d_data = progbuf6_r;
                    12'h35c:sysbus_s_d_data = progbuf7_r;
                    12'h360:sysbus_s_d_data = progbuf8_r;
                    12'h364:sysbus_s_d_data = progbuf9_r;
                    12'h368:sysbus_s_d_data = progbuf10_r;
                    12'h36c:sysbus_s_d_data = progbuf11_r;
                    12'h370:sysbus_s_d_data = progbuf12_r;
                    12'h374:sysbus_s_d_data = progbuf13_r;
                    12'h378:sysbus_s_d_data = progbuf14_r;
                    12'h37c:sysbus_s_d_data = progbuf15_r;
                    12'h380:sysbus_s_d_data = data0;
                    12'h384:sysbus_s_d_data = data1;
                    12'h400:sysbus_s_d_data = flags;
                    12'h800:sysbus_s_d_data = debug_rom0;
                    12'h804:sysbus_s_d_data = debug_rom1;
                    12'h808:sysbus_s_d_data = debug_rom2;
                    12'h80c:sysbus_s_d_data = debug_rom3;
                    12'h810:sysbus_s_d_data = debug_rom4;
                    12'h814:sysbus_s_d_data = debug_rom5;
                    12'h818:sysbus_s_d_data = debug_rom6;
                    12'h81c:sysbus_s_d_data = debug_rom7;
                    12'h820:sysbus_s_d_data = debug_rom8;
                    12'h824:sysbus_s_d_data = debug_rom9;
                    12'h828:sysbus_s_d_data = debug_rom10;
                    12'h82c:sysbus_s_d_data = debug_rom11;
                    12'h830:sysbus_s_d_data = debug_rom12;
                    12'h834:sysbus_s_d_data = debug_rom13;
                    12'h838:sysbus_s_d_data = debug_rom14;
                    12'h83c:sysbus_s_d_data = debug_rom15;
                    12'h840:sysbus_s_d_data = debug_rom16;
                    12'h844:sysbus_s_d_data = debug_rom17;
                    12'h848:sysbus_s_d_data = debug_rom18;
                    12'h84c:sysbus_s_d_data = debug_rom19;
                    12'h850:sysbus_s_d_data = debug_rom20;
                    12'h854:sysbus_s_d_data = debug_rom21;
                    12'h858:sysbus_s_d_data = debug_rom22;
                    12'h85c:sysbus_s_d_data = debug_rom23;
                    12'h860:sysbus_s_d_data = debug_rom24;
                    12'h864:sysbus_s_d_data = debug_rom25;
                    default: begin
                        sysbus_s_d_data = 32'd0;
                    end
                endcase
                if(tile_slave_d_fire) begin
                    //--> idle;
                    state_tilelink_slave_next = tile_slave_idle;
                end
                else begin
                //--> readack 
                state_tilelink_slave_next = tile_slave_read_ack;
                end
            end
        endcase
    end
end

logic core_havereset;
// logic core_havereset;
logic core_havereset_r;
logic core_havereset_2r;

//must distingush the rst_n reset and the core_reset;
logic rst_n_r;
logic rst_n_2r;
logic platform_reset;


always @(posedge clk) begin
    rst_n_r  <= rst_n;
    rst_n_2r <= rst_n_r; 
end

always @(posedge clk) begin
    core_havereset_r  <= core_is_in_reset;
    core_havereset_2r <= core_havereset_r; 
end

always @(*) begin
    case ({core_havereset_2r,core_havereset_r})
        2'b00:core_havereset = '0;
        2'b01:core_havereset = '1;
        2'b10:core_havereset = '0;
        2'b11:core_havereset = '0;
    endcase
end

always @(*) begin
    case ({rst_n_2r,rst_n_r})
        2'b00:platform_reset = '0;
        2'b01:platform_reset = '1;
        2'b10:platform_reset = '0;
        2'b11:platform_reset = '0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        state_ctrl  <= ctrl_runnig;
        //state_ctrl_next <= ctrl_runnig;
          //----------------------------
	 abcs_busy_r <= 1'b0;
	 abcs_err_r  <= 3'd0;

	 anyhalted_r <= 1'b0; 
	 allhalted_r <= 1'b0 ;
	 anyrunning_r <= 1'b1;
	 allrunning_r <= 1'b1 ;
	 anyunavail_r <= 1'b0;
	 allunavail_r <= 1'b0;
	 anynoexist_r <= 1'b0;
	 allnoexist_r <= 1'b0;
	 anyresumeack_r <= 1'b0;
	 allresumeack_r <= 1'b0;
	 anyhavereset_r <= 1'b0;
	 allhavereset_r <= 1'b0;
	
	 flags_go_r     <= 1'b0;
        flags_resume_r <= 1'b0;
    end 
    else begin
        state_ctrl <= state_ctrl_next;
	 abcs_busy_r <= abcs_busy;
	 abcs_err_r  <= abcs_err;

	 anyhalted_r <= anyhalted; 
	 allhalted_r <= allhalted ;
	 anyrunning_r <= anyrunning;
	 allrunning_r <= allrunning ;
	 anyunavail_r <= anyunavail;
	 allunavail_r <= allunavail;
	 anynoexist_r <= anynoexist;
	 allnoexist_r <= allnoexist;
	 anyresumeack_r <= anyresumeack;
	 allresumeack_r <= allresumeack;
	 anyhavereset_r <= anyhavereset;
	 allhavereset_r <= allhavereset;
	
	 flags_go_r      <= flags_go;
       flags_resume_r  <= flags_resume;
        
    end   
end




always @(*) begin
    if(~rst_n) begin
        anyhalted  = '0; 
        allhalted  = '0;
        anyrunning = '1;
        allrunning = '1;
        anyunavail = '0;
        allunavail = '0;
        anynoexist = '0;
        allnoexist = '0;
        anyresumeack = '0;
        allresumeack = '0;
        anyhavereset = '0;
        allhavereset = '0;

        flags_go    = '0;
        flags_resume = '0;

        abcs_busy = '0;
        abcs_err  =  3'd0;

        haltreq_inner_writed = '0;
        haltreq_inner = '0;
	  abcommand_inner_writed =1'b0;
	  abcommand_inner = 32'd0;
	  state_ctrl_next = ctrl_runnig;
	
    end else begin
  	 haltreq_inner_writed = '0;
        haltreq_inner = '0;
	 abcommand_inner_writed =1'b0;
	 abcommand_inner = 32'd0;

	 abcs_busy  = abcs_busy_r;
	 abcs_err   = abcs_err_r;

	 //keep;
	 anyhalted = anyhalted_r; 
	 allhalted = allhalted_r;
	 anyrunning = anyrunning_r;
	 allrunning = allrunning_r;
	 anyunavail = anyunavail_r;
	 allunavail = allunavail_r;
	 anynoexist = anynoexist_r;
	 allnoexist = allnoexist_r;
	 anyresumeack = anyresumeack_r;
	 allresumeack = allresumeack_r;
	 anyhavereset = anyhavereset_r;
	 allhavereset = allhavereset_r;

        flags_go     = flags_go_r;
        flags_resume = flags_resume_r;
	  state_ctrl_next = ctrl_runnig;
	

        case (state_ctrl)
            ctrl_runnig:begin
                flags_go    = '0;
                flags_resume = '0;
                abcs_busy = '0;
                abcs_err  =  3'd0;

                anyhalted  = '0; 
                allhalted  = '0;
                anyrunning = '1;
                allrunning = '1;

                if (halted_tile_writed) begin
                    haltreq_inner = '0;
                    haltreq_inner_writed = '1;
                    state_ctrl_next = ctrl_halted_waiting;
                end
                else begin
                    state_ctrl_next = ctrl_runnig;
                end
            end
            ctrl_halted_waiting:begin
                abcs_busy = '0;
                abcs_err  =  3'd0;
                abcommand_inner_writed  = '0;
                haltreq_inner_writed    = '0;
                anyhalted  = '1; 
                allhalted  = '1;
                anyrunning = '0;
                allrunning = '0;
                anyunavail = '0;
                allunavail = '0;
                
                anynoexist = '0;
                allnoexist = '0;

                // anyresumeack = '0;
                // allresumeack = '0;
                // anyhavereset = '0;
                // allhavereset = '0;

                if(access_register)begin
                    flags_go =     '1;
                    flags_resume = '0; 
                    state_ctrl_next =  ctrl_go;    
                end
                else if (quick_access) begin
                    flags_go =     '1;
                    flags_resume = '0;
                    state_ctrl_next =  ctrl_go;    
                end
                else if (accsess_memory) begin
                    //unsurported
                    flags_go     = '0;
                    flags_resume = '0;
                    state_ctrl_next = ctrl_halted_cmderr;
                end
                else if (ndmreset) begin
                    flags_go =     '0;
                    flags_resume = '0;
                    state_ctrl_next = ctrl_reset;
                end
                else if (resumereq) begin
                    flags_go =     '0;
                    flags_resume = '1;
                    state_ctrl_next = ctrl_resume;   
                end
                else begin
                    flags_go =     '0;
                    flags_resume = '0;
                    state_ctrl_next = ctrl_halted_waiting;
                end
            end
            ctrl_halted_cmderr:begin
                anyhalted  = '1; 
                allhalted  = '1;
                anyrunning = '0;
                allrunning = '0;
                anyunavail = '0;
                allunavail = '0;

                anynoexist = '0;
                allnoexist = '0;

                flags_go     = '0;
                flags_resume = '0;
                abcs_busy = '0;
                abcs_err  =  3'd2;
                if(abcs_err_writedclr) begin
                    abcs_err  =  3'd0;
                    abcommand_inner = 32'd0;
                    abcommand_inner_writed = '1;
                    state_ctrl_next = ctrl_halted_waiting;
                end
                else begin
                    state_ctrl_next = ctrl_halted_cmderr;
                end
            end
            ctrl_go:begin
                if(going_tile_writed) begin
                    flags_go =     '0;
                    flags_resume = '0; 
                end else begin
                    //KEEP
                    flags_go =     flags_go;
                    flags_resume = flags_resume; 
                end
                anyhalted  = '1; 
                allhalted  = '1;
                anyrunning = '0;
                allrunning = '0;
                anyunavail = '0;
                allunavail = '0;
                anynoexist = '0;
                allnoexist = '0;
                anyresumeack = '0;
                allresumeack = '0;
                anyhavereset = '0;
                allhavereset = '0;
                abcs_busy = '1;
                abcs_err  =  3'd1;
                if(ebreak_tile_writed) begin
                    abcs_busy = '0;
                    abcs_err  =  3'd0;
                    abcommand_inner = 32'd0;
                    abcommand_inner_writed = '1;
                    state_ctrl_next = ctrl_halted_waiting;
                end
                else begin
                    state_ctrl_next = ctrl_go;
                end
            end
            ctrl_resume:begin
                anyhalted  = '1; 
                allhalted  = '1;
                anyrunning = '0;
                allrunning = '0;
                anyunavail = '0;
                allunavail = '0;
                anynoexist = '0;
                allnoexist = '0;
                anyresumeack = '0;
                allresumeack = '0;
                anyhavereset = '0;
                allhavereset = '0;

                flags_go =     '0;
                flags_resume = '1;
                abcs_busy = '0;
                abcs_err  =  3'd4;
                if(resume_tile_writed) begin
                    anyresumeack = '1;
                    allresumeack = '1;
                    abcs_err  =  3'd0;
                    flags_resume = '0;
                    abcommand_inner = 32'd0;
                    abcommand_inner_writed = '1;
                    state_ctrl_next = ctrl_runnig; 
                end
                else begin
                    state_ctrl_next = ctrl_resume;
                end
            end
            ctrl_reset:begin
                flags_go =     '0;
                flags_resume = '0;
                abcs_busy = '0;
                abcs_err  =  3'd0;

                anyhalted  = '0; 
                allhalted  = '0;

                anyrunning = '0;
                allrunning = '0;

                anyunavail = '1;
                allunavail = '1;

                anynoexist = '0;
                allnoexist = '0;
                
                anyresumeack = '0;
                allresumeack = '0;

                anyhavereset = '0;
                allhavereset = '0;

                if( core_havereset && ~haltreq) begin
                    anyhavereset = '1;
                    allhavereset = '1;
                    anyunavail = '0;
                    allunavail = '0;
                    state_ctrl_next = ctrl_runnig;
                end
                else if (core_havereset && haltreq) begin
                    anyhavereset = '1;
                    allhavereset = '1;
                    anyunavail = '0;
                    allunavail = '0;
                    state_ctrl_next = ctrl_halted_waiting;
                end
                else begin
                    state_ctrl_next = ctrl_reset;
                end
            end 
            default:begin
                state_ctrl_next = state_ctrl;
            end
        endcase
    end
    
end
endmodule

`endif
