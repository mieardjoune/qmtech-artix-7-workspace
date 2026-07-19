# =============================================================================
# File   : physical.xdc
# Project: qmtech-workspace / sv_test (led_blinker)
# Board  : QMTECH Artix-7 (xc7a100tfgg676-1)
# =============================================================================
set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports { clk }]

set_property -dict { PACKAGE_PIN P4    IOSTANDARD LVCMOS33 } [get_ports { rst_n }]
set_property PULLUP true [get_ports { rst_n }]

set_property -dict { PACKAGE_PIN R23   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN T23   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
