# =============================================================================
# File   : physical.xdc
# Project: qmtech-workspace / ram_test (ram)
# Board  : QMTECH Artix-7 (xc7a100tfgg676-1)
# =============================================================================
set_property -dict { PACKAGE_PIN U22   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name sys_clk_pin -period 20.00 -waveform {0 10} [get_ports { clk }]

set_property -dict { PACKAGE_PIN P4    IOSTANDARD LVCMOS33 } [get_ports { we }]
set_property PULLUP true [get_ports { we }]

set_property -dict { PACKAGE_PIN B5    IOSTANDARD LVCMOS33 } [get_ports { addr[0] }]
set_property -dict { PACKAGE_PIN A5    IOSTANDARD LVCMOS33 } [get_ports { addr[1] }]
set_property -dict { PACKAGE_PIN A3    IOSTANDARD LVCMOS33 } [get_ports { addr[2] }]
set_property -dict { PACKAGE_PIN A2    IOSTANDARD LVCMOS33 } [get_ports { addr[3] }]

set_property -dict { PACKAGE_PIN A4    IOSTANDARD LVCMOS33 } [get_ports { din[0] }]
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { din[1] }]
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { din[2] }]
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { din[3] }]
set_property -dict { PACKAGE_PIN E5    IOSTANDARD LVCMOS33 } [get_ports { din[4] }]
set_property -dict { PACKAGE_PIN D5    IOSTANDARD LVCMOS33 } [get_ports { din[5] }]
set_property -dict { PACKAGE_PIN C1    IOSTANDARD LVCMOS33 } [get_ports { din[6] }]
set_property -dict { PACKAGE_PIN B1    IOSTANDARD LVCMOS33 } [get_ports { din[7] }]

set_property -dict { PACKAGE_PIN R23   IOSTANDARD LVCMOS33 } [get_ports { dout[0] }]
set_property -dict { PACKAGE_PIN T23   IOSTANDARD LVCMOS33 } [get_ports { dout[1] }]
set_property -dict { PACKAGE_PIN E26   IOSTANDARD LVCMOS33 } [get_ports { dout[2] }]
set_property -dict { PACKAGE_PIN D26   IOSTANDARD LVCMOS33 } [get_ports { dout[3] }]
set_property -dict { PACKAGE_PIN E25   IOSTANDARD LVCMOS33 } [get_ports { dout[4] }]
set_property -dict { PACKAGE_PIN D25   IOSTANDARD LVCMOS33 } [get_ports { dout[5] }]
set_property -dict { PACKAGE_PIN H26   IOSTANDARD LVCMOS33 } [get_ports { dout[6] }]
set_property -dict { PACKAGE_PIN G26   IOSTANDARD LVCMOS33 } [get_ports { dout[7] }]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
