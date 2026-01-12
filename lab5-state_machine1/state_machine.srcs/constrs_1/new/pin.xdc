set_property -dict { PACKAGE_PIN Y18 IOSTANDARD LVCMOS33 } [get_ports clk];
set_property -dict { PACKAGE_PIN R1  IOSTANDARD LVCMOS33 } [get_ports rst];
set_property -dict { PACKAGE_PIN V18 IOSTANDARD LVCMOS33 } [get_ports txo];
create_clock -period 10.000 -name sys_clk -waveform {0 5} [get_ports clk];