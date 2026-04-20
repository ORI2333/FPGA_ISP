#==============================================================
# Timing Constraints for sc1336_hdmi (non-DDR part)
#==============================================================

# 1) Primary board clock
create_clock -name SYS_CLK_50M -period 20.000 [get_ports clk_50m]

# 2) CMOS sensor pixel clock input domain
#    Current setting uses 24MHz equivalent period.
#    If your sensor mode outputs another pclk, update this period.
create_clock -name CMOS_PCLK -period 41.667 [get_ports cmos_pclk]

# 3) Asynchronous clock groups
#    Internal clocks generated from SYS_CLK_50M are related to SYS_CLK_50M.
#    Sensor pclk is external asynchronous domain.
set_clock_groups -asynchronous \
	-group [get_clocks -include_generated_clocks SYS_CLK_50M] \
	-group [get_clocks CMOS_PCLK]

# 4) External reset false path (asynchronous assertion path)
set_false_path -from [get_ports rst_n] -to [all_registers]

# 5) Bitstream / configuration options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

# 6) Optional templates (enable when you have interface timing numbers)
# set_input_delay  -clock [get_clocks CMOS_PCLK] -max <value_ns> [get_ports {cmos_data[*] cmos_vsync cmos_href}]
# set_input_delay  -clock [get_clocks CMOS_PCLK] -min <value_ns> [get_ports {cmos_data[*] cmos_vsync cmos_href}]
# set_output_delay -clock [get_clocks SYS_CLK_50M] -max <value_ns> [get_ports {cmos_sclk cmos_xclk cmos_sdat}]
# set_output_delay -clock [get_clocks SYS_CLK_50M] -min <value_ns> [get_ports {cmos_sclk cmos_xclk cmos_sdat}]