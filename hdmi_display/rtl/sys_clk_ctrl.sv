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
// Last modified Date:     2026/04/16 23:59:50
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/04/16 23:59:50
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              sys_clk_ctrl.sv
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\hdmi_display\rtl\sys_clk_ctrl.sv
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sys_clk_ctrl#(
    // Parameter to set power-on delay duration (in clock cycles)
    parameter              SYS_DELAY_TOP               = 24'd2500_000         // ~50ms delay @50MHz
)(
    // Clock and reset inputs
    input  wire                         clk_in                     ,// 50MHz physical clock
    input  wire                         ext_rst_n                  ,// External reset (active low)
    // Clock and reset outputs
    output wire                         clk_out                    ,// Stable PLL clock output
    output wire                         sys_rst_n                   // Glitch-free sync reset (active low)
);

    // ============================================================
    // 1) Power-on delay
    reg              [  23: 0]      delay_cnt                ;
    wire                            delay_done                 ;

    initial delay_cnt = 24'd0;

    always @(posedge clk_in) begin
        if (delay_cnt < SYS_DELAY_TOP - 1'b1)
            delay_cnt <= delay_cnt + 1'b1;
        else
            delay_cnt <= SYS_DELAY_TOP - 1'b1;
    end

    assign     delay_done   = (delay_cnt == SYS_DELAY_TOP - 1'b1);

    // ============================================================
    // 2) PLL control
    wire                            pll_rst                    ;
    wire                            locked                     ;

    assign     pll_rst      = ~delay_done  ;

sys_clk u_sys_clk(
    .clk_in1                            (clk_in                    ),
    .reset                              (pll_rst                   ),
    .locked                             (locked                    ),
    .clk_out1                           (clk_out                   ) 
);

 // ============================================================
    // 3) Reset synchronizer in clk_out domain
    reg                             rst_nr1                    ;
    reg                             rst_nr2                    ;

    always @(posedge clk_out) begin
        if (!ext_rst_n) begin
            rst_nr1 <= 1'b0;
            rst_nr2 <= 1'b0;
        end
        else begin
            rst_nr1 <= 1'b1;
            rst_nr2 <= rst_nr1;
        end
    end

    assign     sys_rst_n    = rst_nr2 & locked;

endmodule