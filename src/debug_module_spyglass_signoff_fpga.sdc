//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//GOWIN Version: 1.9.9 Beta-4 Education
//Created Time: 2024-03-17 13:57:19
create_clock -name sysclk -period 10 -waveform {0 5} [get_ports {clk}]
create_clock -name jtag_clk -period 100 -waveform {0 50} [get_ports {jtag_tck}]
set_clock_groups -asynchronous -group [get_clocks {sysclk}] -group [get_clocks {jtag_clk}]
set_multicycle_path -from [get_clocks {sysclk}] -to [get_clocks {jtag_clk}]  -setup -end 10
set_multicycle_path -from [get_clocks {jtag_clk}] -to [get_clocks {sysclk}]  -setup -end 10
report_timing -setup -max_paths 400 -max_common_paths 1
report_max_frequency -mod_ins {u_debug_module}
set_operating_conditions -grade i -model fast -speed 6 -setup -hold -max_min
