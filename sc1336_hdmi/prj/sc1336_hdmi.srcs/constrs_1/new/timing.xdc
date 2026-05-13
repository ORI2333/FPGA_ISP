#==============================================================
# Timing Constraints for sc1336_hdmi
#==============================================================
# Constraint reference:
#   create_clock        : define a clock (period, source port/net/pin)
#   set_input_delay     : external device data-to-clock skew (INPUT)
#   set_output_delay    : external device required setup/hold (OUTPUT)
#   set_clock_groups    : declare clock domains as mutually async
#   set_false_path      : disable timing analysis on a path
#
# Rule of thumb:
#   - Clock outputs (cmos_xclk, lcd_dclk) do NOT get set_output_delay.
#     They ARE the timing reference for the external device.
#   - set_input_delay references the CLOCK that launches data into the FPGA.
#   - set_output_delay references the CLOCK that captures data at the receiver.
#==============================================================

# ------------------------------------------------------------------
# 1) Primary board clock (50MHz, 20ns)
# ------------------------------------------------------------------
create_clock -period 20.000 [get_ports clk_50m]

# ------------------------------------------------------------------
# 2) CMOS sensor pixel clock input
#    SC1336 DVP pclk = 24MHz (41.667ns)
#    This is an externally generated clock — need to tell Vivado it exists
# ------------------------------------------------------------------
create_clock -name CMOS_PCLK -period 41.667 [get_ports cmos_pclk]

# ------------------------------------------------------------------
# 3) Asynchronous clock groups
#    Group A: clk_50m + all MMCM-derived clocks (auto-traced by Vivado)
#             clk_ctrl(100M), clk_video(74.25M), clk_cmos(24M),
#             clk_ddr_ref(250M), clk_ddr_ref_200m(200M)
#    Group B: CMOS_PCLK     — external sensor source, independent
#    Group C: MIG ui_clk    — MIG OOC breaks auto-derivation chain
#    Cross-group data goes through async FIFOs — no timing analysis needed
# ------------------------------------------------------------------
set_clock_groups -asynchronous \
    -group [get_clocks -include_generated_clocks -of_objects [get_ports clk_50m]] \
    -group [get_clocks CMOS_PCLK] \
    -group [get_clocks -of_objects [get_pins ddr3/ui_clk]]

# ------------------------------------------------------------------
# 4) External reset false path
#    rst_n is async to all domains; actual synchronizers handle it
# ------------------------------------------------------------------
set_false_path -from [get_ports rst_n] -to [all_registers]

# ------------------------------------------------------------------
# 5) Disable recovery/removal timing on async reset pins
#    Our design uses reset synchronizers — these paths are safe
# ------------------------------------------------------------------
set_false_path -to [all_registers -async_pins]

# ------------------------------------------------------------------
# 6) DVP sensor INPUT delays
#    cmos_pclk is the launch clock (sensor outputs data on pclk edge).
#    These tell Vivado: "data arrives 2~8ns after the pclk edge at the FPGA pin."
# ------------------------------------------------------------------
set_input_delay -clock [get_clocks CMOS_PCLK] -max 8.000 \
    [get_ports {cmos_data[*] cmos_vsync cmos_href}]
set_input_delay -clock [get_clocks CMOS_PCLK] -min 2.000 \
    [get_ports {cmos_data[*] cmos_vsync cmos_href}]

# ------------------------------------------------------------------
# 7) HDMI OUTPUT delays (placeholder — enable when trace delays are known)
#    lcd_dclk is the capture clock (74.25MHz via ODDR).
#    These tell Vivado: "the monitor needs data valid N ns before dclk edge."
# ------------------------------------------------------------------
# set_output_delay -clock [get_clocks -of_objects [get_ports lcd_dclk]] -max <value> \
#     [get_ports {lcd_hs lcd_vs lcd_de lcd_red[*] lcd_green[*] lcd_blue[*]}]
# set_output_delay -clock [get_clocks -of_objects [get_ports lcd_dclk]] -min <value> \
#     [get_ports {lcd_hs lcd_vs lcd_de lcd_red[*] lcd_green[*] lcd_blue[*]}]

# ------------------------------------------------------------------
# 8) UART debug pins (Bank 15, 3.3V)
# ------------------------------------------------------------------
set_property PACKAGE_PIN D16 [get_ports uart_rxd]
set_property PACKAGE_PIN D15 [get_ports uart_txd]
set_property IOSTANDARD LVCMOS33 [get_ports {uart_rxd uart_txd}]

# ------------------------------------------------------------------
# 9) Bitstream / configuration options
# ------------------------------------------------------------------
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
