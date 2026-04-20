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
// PATH:                 
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
    // Clock outputs (map to Clocking Wizard outputs)
    output wire                         clk_out                    ,// legacy alias of clk_ctrl
    output wire                         clk_ctrl                   ,// control domain clock (e.g. 100MHz)
    output wire                         clk_video                  ,// video pixel clock (e.g. 74.25MHz)
    output wire                         clk_cmos                   ,// sensor xclk source (e.g. 24/27MHz)
    output wire                         clk_ddr_ref                ,// DDR reference clock (e.g. 200MHz)
    output wire                         clk_ila                    ,// ILA debug clock
    output wire                         clk_spare                  ,// spare clock output
    // Single reset output (active low, synchronous to clk_ctrl)
    output wire                         sys_rst_n
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
    // 2) Clocking Wizard control
    // NOTE:
    //   Use 3 independent Clocking Wizard IPs to reduce output coupling:
    //   1) sys_clk_ctrl_cmos : 100MHz(ctrl), 24/27MHz(cmos), spare
    //   2) sys_clk_video     : 74.25MHz(video)
    //   3) sys_clk_ddr_ref   : 200MHz(ddr ref)
    wire                            pll_rst                    ;
    wire                            lock_ctrl                  ;
    wire                            lock_video                 ;
    wire                            lock_ddr                   ;

    assign     pll_rst      = ~delay_done | ~ext_rst_n;

sys_clk_ctrl_cmos u_sys_clk_ctrl_cmos(
    .clk_in1                            (clk_in                    ),
    .reset                              (pll_rst                   ),
    .locked                             (lock_ctrl                 ),
    .clk_out1                           (clk_ctrl                  ),
    .clk_out2                           (clk_cmos                  ),// 24MHz
    .clk_out3                           (clk_spare                 ) // 50Mhz
);

sys_clk_video u_sys_clk_video(
    .clk_in1                            (clk_in                    ),
    .reset                              (pll_rst                   ),
    .locked                             (lock_video                ),
    .clk_out1                           (clk_video                 )
);

sys_clk_ddr_ref u_sys_clk_ddr_ref(
    .clk_in1                            (clk_in                    ),
    .reset                              (pll_rst                   ),
    .locked                             (lock_ddr                  ),
    .clk_out1                           (clk_ddr_ref               )
);

    // ILA clock reuses control domain clock by default
    assign clk_ila = clk_ctrl;

    // backward-compatible alias
    assign clk_out = clk_ctrl;

    // ============================================================
    // 3) Single reset synchronizer in clk_ctrl domain
    wire                            all_locked                 ;
    reg                             rstn_r1                    ;
    reg                             rstn_r2                    ;

    assign all_locked = lock_ctrl & lock_video & lock_ddr;

    always @(posedge clk_ctrl) begin
        if (!ext_rst_n) begin
            rstn_r1 <= 1'b0;
            rstn_r2 <= 1'b0;
        end
        else begin
            rstn_r1 <= all_locked;
            rstn_r2 <= rstn_r1;
        end
    end

    assign     sys_rst_n    = rstn_r2;

endmodule