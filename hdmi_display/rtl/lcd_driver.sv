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
// Last modified Date:     2026/04/17 18:17:22
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/04/17 18:17:22
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              lcd_driver.sv
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\hdmi_display\rtl\lcd_driver.sv
// Descriptions:           LCD Driver VGAÇý¶¯
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//
`include "lcd_para.v"                                               // include LCD parameters (resolution, timing, etc.)
module lcd_driver(
    input  wire                         clk                        ,
    input  wire                         rst_n                      ,

// LCD interface
    output wire                         lcd_clk                    ,
    output wire                         lcd_blank                  ,
    output wire                         lcd_sync                   ,
    output wire                         lcd_hs                     ,
    output wire                         lcd_vs                     ,
    output wire                         lcd_en                     ,
    output wire          [  23: 0]      lcd_rgb                    ,

// User interface
    input  wire          [  23: 0]      lcd_data                   ,
    output wire                         lcd_request                ,
    output               [  11: 0]      lcd_xpos                   ,//lcd horizontal coordinate
    output               [  11: 0]      lcd_ypos                    //lcd vertical coordinate
);

// LCD request signal generation
assign lcd_clk = clk;

// h_sync
reg             [  11: 0]      h_cnt                 ;
always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            h_cnt <= 'd0;
        else
            begin
                if(h_cnt < `H_TOTAL - 1'b1)
                    h_cnt <= h_cnt + 1'b1;
                else
                    h_cnt <= 'd0;
            end
    end

assign     lcd_hs       = (h_cnt < `H_SYNC - 1'b1) ? 1'b0 : 1'b1;// h_sync pulse

// v_sync
reg             [  11: 0]      v_cnt                 ;
always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            v_cnt <= 'd0;
        else
            begin
                if(h_cnt == `H_TOTAL - 1'b1)
                    begin
                        if(v_cnt < `V_TOTAL - 1'b1)
                            v_cnt <= v_cnt + 1'b1;
                        else
                            v_cnt <= 'd0;
                    end
            end
    end

assign     lcd_vs       = (v_cnt < `V_SYNC - 1'b1) ? 1'b0 : 1'b1;// v_sync pulse

// Blanking and sync signals
assign lcd_blank = lcd_hs & lcd_vs; // blanking signal
assign lcd_sync  = 1'b0;    // No separate sync signal, set to 0

// Calculate the current pixel coordinates
assign lcd_en    = ((h_cnt >= `H_SYNC + `H_BACK ) && (h_cnt < `H_SYNC + `H_BACK + `H_DISP)) && 
                   ((v_cnt >= `V_SYNC + `V_BACK ) && (v_cnt < `V_SYNC + `V_BACK + `V_DISP))
                    ? 1'b1 : 1'b0; // enable signal for active display area

assign lcd_rgb   = lcd_en ? lcd_data : 24'h000000; // output pixel data or black

// Generate LCD request signal and calculate pixel coordinates
assign lcd_request = ((h_cnt >= `H_SYNC + `H_BACK - 'd1 ) && (h_cnt < `H_SYNC + `H_BACK + `H_DISP - 'd1)) && 
                    ((v_cnt >= `V_SYNC + `V_BACK ) && (v_cnt < `V_SYNC + `V_BACK + `V_DISP))
                    ? 1'b1 : 1'b0;
assign lcd_xpos    = lcd_request ? (h_cnt - (`H_SYNC + `H_BACK - 'd1)) : 11'd0; 
assign lcd_ypos    = lcd_request ? (v_cnt - (`V_SYNC + `V_BACK)) : 11'd0;

endmodule