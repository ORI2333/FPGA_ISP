`timescale 1ns / 1ns
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE     
// VSCODE plug-in version: Verilog-Hdl-Format-4.3.20260413
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            ORI2333
// All rights reserved     
// File name:              
// Last modified Date:     2026/04/16 22:53:11
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/04/16 22:53:11
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              hdmi_display.sv
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\hdmi_display\rtl\hdmi_display.sv
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module hdmi_display(
    // global clock
    input                               clk                        ,
    input                               rst_n                      ,

    //lcd interface
    output                              lcd_dclk                   ,
    output                              lcd_hs                     ,
    output                              lcd_vs                     ,
    output                              lcd_de                     ,

    output               [   7: 0]      lcd_red                    ,
    output               [   7: 0]      lcd_green                  ,
    output               [   7: 0]      lcd_blue                    
);

//****************************************************************************************//
`include "lcd_para.v"

`ifdef VGA_640_480_60FPS_25MHz
localparam int CLOCK_MAIN = 25_000000;
`elsif VGA_800_600_60FPS_40MHz
localparam int CLOCK_MAIN = 40_000000;
`elsif VGA_1280_720_60FPS_74_25MHz
localparam int CLOCK_MAIN = 74_2500000;
`elsif VGA_1920_1080_60FPS_148_5MHz
localparam int CLOCK_MAIN = 148_5000000;
`else
localparam int CLOCK_MAIN = 74_2500000;
`endif

// clock and reset
wire                           clk_ref                    ;
wire                           sys_rst_n                  ;

sys_clk_ctrl#(
    // Parameter to set power-on delay duration (in clock cycles)
    .SYS_DELAY_TOP                      (24'd2500_000              ) // ~50ms delay @50MHz
)u_sys_clk_ctrl(
    // Clock and reset inputs
    .clk_in                             (clk                       ),
    .ext_rst_n                          (rst_n                     ),
    // Clock and reset outputs
    .clk_out                            (clk_ref                   ),// 74.25MHz 
    .sys_rst_n                          (sys_rst_n                 ) 
);

//****************************************************************************************//
// LCD Driver
wire                           lcd_clk                    ;
assign     lcd_clk      = clk_ref      ;

wire            [  11: 0]      lcd_xpos                   ;
wire            [  11: 0]      lcd_ypos                   ;
wire            [  23: 0]      lcd_data                   ;
wire                           lcd_dclk_reg               ;

lcd_driver u_lcd_driver(
    .clk                                (lcd_clk                   ),
    .rst_n                              (sys_rst_n                 ),
    // LCD interface
    .lcd_clk                            (lcd_dclk_reg              ),
    .lcd_blank                          (                          ),
    .lcd_sync                           (                          ),
    .lcd_hs                             (lcd_hs                    ),
    .lcd_vs                             (lcd_vs                    ),
    .lcd_en                             (lcd_de                    ),
    .lcd_rgb                            ({lcd_red, lcd_green, lcd_blue}),

    // User interface
    .lcd_data                           (lcd_data                  ),
    .lcd_request                        (                          ),
    .lcd_xpos                           (lcd_xpos                  ),
    .lcd_ypos                           (lcd_ypos                  ) 
);


// Generate LCD pixel clock using ODDR
ODDR #(
    .DDR_CLK_EDGE                       ("OPPOSITE_EDGE"           ),// "OPPOSITE_EDGE" or "SAME_EDGE" 
    .INIT                               (1'b0                      ),// Initial value of Q: 1'b0 or 1'b1
    .SRTYPE                             ("SYNC"                    ) // Set/Reset type: "SYNC" or "ASYNC" 
) ODDR_inst (
    .Q                                  (lcd_dclk                  ),// 1-bit DDR output
    .C                                  (lcd_dclk_reg              ),// 1-bit clock input
    .CE                                 (1'b1                      ),// 1-bit clock enable input
    .D1                                 (1'b1                      ),// 1-bit data input (positive edge)
    .D2                                 (1'b0                      ),// 1-bit data input (negative edge)
    .R                                  (1'b0                      ),// 1-bit reset
    .S                                  (1'b0                      ) // 1-bit set
);
//lcd data simulation
lcd_display_test
#(
    .DELAY_TOP                          (CLOCK_MAIN                ) 
)
u_lcd_display_test
(
	//global clock
    .clk                                (lcd_clk                   ),
    .rst_n                              (sys_rst_n                 ),
	
    .lcd_xpos                           (lcd_xpos                  ),
    .lcd_ypos                           (lcd_ypos                  ),
    .lcd_data                           (lcd_data                  ) 
);
                                              
endmodule