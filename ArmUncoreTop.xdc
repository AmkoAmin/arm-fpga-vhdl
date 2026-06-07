## Constraints fuer ArmUncoreTop auf dem Basys 3 (Artix-7 xc7a35tcpg236-1)
## Pinbelegung gemaess Digilent Basys-3 Master-XDC und Aufgabenblatt 5

## EXT_CLK - 100-MHz-Taktgeber (Pin W5)
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports EXT_CLK]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports EXT_CLK]

## EXT_RST - "unterer" Button (btnD, Pin U17)
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports EXT_RST]

## EXT_LDP - Switch 0 (Pin V17)
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports EXT_LDP]

## USB-RS232 Interface
## EXT_RXD - RXD-Leitung (FPGA-Eingang, RsRx, Pin B18)
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports EXT_RXD]
## EXT_TXD - TXD-Leitung (FPGA-Ausgang, RsTx, Pin A18)
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports EXT_TXD]

## EXT_LED - acht untere LEDs (LD0..LD7)
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[3]}]
set_property -dict { PACKAGE_PIN W18 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[4]}]
set_property -dict { PACKAGE_PIN U15 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[5]}]
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[6]}]
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports {EXT_LED[7]}]
