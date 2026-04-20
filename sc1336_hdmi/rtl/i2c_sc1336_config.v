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
// Last modified Date:     2026/04/20 18:40:09
// Last Version:           V1.0
// Descriptions:
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/04/20 18:40:09
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              i2c_sc1336_config.v
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\sc1336_hdmi\rtl\i2c_sc1336_config.v
// Descriptions:
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module i2c_sc1336_config(
input                [   7: 0]      LUT_INDEX                  ,
output reg           [  23: 0]      LUT_DATA                   ,
output               [   7: 0]      LUT_SIZE
);
assign     LUT_SIZE     = 1'b1 + 8'd183;

//-----------------------------------------------------------------
/////////////////////   Config Data LUT   //////////////////////////
always@(*)begin
        case(LUT_INDEX)
            // --- 系统初始化与复位 ---
            0:    LUT_DATA = {16'h0103,8'h01};// 软复位使能：Bit[0]=1，触发软复位 [cite: 276]
            1:    LUT_DATA = {16'h0100,8'h00};// 软睡眠模式：Bit[0]=0，使能睡眠模式，便于后续安全配置 [cite: 266]
            
            // --- 原厂隐藏调优寄存器 (内部模拟/数字底层配置) ---
            2:    LUT_DATA = {16'h36e9,8'h80};
            3:    LUT_DATA = {16'h37f9,8'h80};
            4:    LUT_DATA = {16'h3001,8'hff};
            5:    LUT_DATA = {16'h3002,8'hf0};

            // --- 接口与时钟配置 ---
            6:    LUT_DATA = {16'h300a,8'h24};// FSYNC 输出控制：配置 FSYNC pad 的输入/输出状态 [cite: 589
            7:    LUT_DATA = {16'h3018,8'h0f};// MIPI 调整寄存器：配置 MIPI lane 数量及模式 [cite: 501]
            8:    LUT_DATA = {16'h301a,8'hf8};
            9:    LUT_DATA = {16'h301c,8'h94};
            10:   LUT_DATA = {16'h301f,8'h03};
            11:   LUT_DATA = {16'h3030,8'h01};
            12:   LUT_DATA = {16'h303f,8'h81};// MIPI 时钟设置：选择 MIPI pclk 或 DVP pclk [cite: 501]
            13:   LUT_DATA = {16'h3248,8'h04};
            14:   LUT_DATA = {16'h3249,8'h0b};

            // --- 原厂隐藏调优寄存器 (批量的底层配置) ---
            15:   LUT_DATA = {16'h3301,8'h03};
            16:   LUT_DATA = {16'h3302,8'h10};
            17:   LUT_DATA = {16'h3303,8'h10};
            18:   LUT_DATA = {16'h3304,8'h40};
            19:   LUT_DATA = {16'h3306,8'h38};
            20:   LUT_DATA = {16'h3307,8'h02};
            21:   LUT_DATA = {16'h3308,8'h08};
            22:   LUT_DATA = {16'h3309,8'h60};
            23:   LUT_DATA = {16'h330a,8'h00};
            24:   LUT_DATA = {16'h330b,8'h70};
            25:   LUT_DATA = {16'h330c,8'h16};
            26:   LUT_DATA = {16'h330d,8'h10};
            27:   LUT_DATA = {16'h330e,8'h10};
            28:   LUT_DATA = {16'h3318,8'h02};
            29:   LUT_DATA = {16'h331c,8'h01};
            30:   LUT_DATA = {16'h331e,8'h39};
            31:   LUT_DATA = {16'h331f,8'h59};
            32:   LUT_DATA = {16'h3327,8'h0a};
            33:   LUT_DATA = {16'h3333,8'h10};
            34:   LUT_DATA = {16'h3334,8'h40};
            35:   LUT_DATA = {16'h335e,8'h06};
            36:   LUT_DATA = {16'h335f,8'h0a};
            37:   LUT_DATA = {16'h3364,8'h1f};
            38:   LUT_DATA = {16'h337a,8'h02};
            39:   LUT_DATA = {16'h337b,8'h06};
            40:   LUT_DATA = {16'h337c,8'h02};
            41:   LUT_DATA = {16'h337d,8'h0e};
            42:   LUT_DATA = {16'h3390,8'h01};
            43:   LUT_DATA = {16'h3391,8'h07};
            44:   LUT_DATA = {16'h3392,8'h0f};
            45:   LUT_DATA = {16'h3393,8'h03};
            46:   LUT_DATA = {16'h3394,8'h03};
            47:   LUT_DATA = {16'h3395,8'h03};
            48:   LUT_DATA = {16'h3396,8'h48};
            49:   LUT_DATA = {16'h3397,8'h49};
            50:   LUT_DATA = {16'h3398,8'h4f};
            51:   LUT_DATA = {16'h3399,8'h02};
            52:   LUT_DATA = {16'h339a,8'h03};
            53:   LUT_DATA = {16'h339b,8'h0e};
            54:   LUT_DATA = {16'h339c,8'h90};
            55:   LUT_DATA = {16'h33a2,8'h04};
            56:   LUT_DATA = {16'h33a3,8'h04};
            57:   LUT_DATA = {16'h33ad,8'h0c};
            58:   LUT_DATA = {16'h33b1,8'h80};
            59:   LUT_DATA = {16'h33b2,8'h50};
            60:   LUT_DATA = {16'h33b3,8'h38};
            61:   LUT_DATA = {16'h33f9,8'h38};
            62:   LUT_DATA = {16'h33fb,8'h48};
            63:   LUT_DATA = {16'h33fc,8'h4b};
            64:   LUT_DATA = {16'h33fd,8'h4f};
            65:   LUT_DATA = {16'h349f,8'h03};
            66:   LUT_DATA = {16'h34a6,8'h49};
            67:   LUT_DATA = {16'h34a7,8'h4f};
            68:   LUT_DATA = {16'h34a8,8'h28};
            69:   LUT_DATA = {16'h34a9,8'h00};
            70:   LUT_DATA = {16'h34aa,8'h00};
            71:   LUT_DATA = {16'h34ab,8'h70};
            72:   LUT_DATA = {16'h34ac,8'h00};
            73:   LUT_DATA = {16'h34ad,8'h80};
           
            // --- 驱动与延迟调整 ---
            74:   LUT_DATA = {16'h3630,8'hc0};
            75:   LUT_DATA = {16'h3631,8'h84};
            76:   LUT_DATA = {16'h3632,8'h78};
            77:   LUT_DATA = {16'h3633,8'h42};
            78:   LUT_DATA = {16'h3637,8'h2a};
            79:   LUT_DATA = {16'h363a,8'h88};
            80:   LUT_DATA = {16'h363b,8'h03};
            81:   LUT_DATA = {16'h363c,8'h08};
            82:   LUT_DATA = {16'h3641,8'h3a};// PAD 驱动能力：调节接口 PAD 的驱动电流能力 [cite: 386]
            83:   LUT_DATA = {16'h3670,8'h0f};
            84:   LUT_DATA = {16'h3674,8'hb0};
            85:   LUT_DATA = {16'h3675,8'hc0};
            86:   LUT_DATA = {16'h3676,8'hc0};
            87:   LUT_DATA = {16'h367c,8'h40};
            88:   LUT_DATA = {16'h367d,8'h48};
            89:   LUT_DATA = {16'h3690,8'h33};
            90:   LUT_DATA = {16'h3691,8'h43};
            91:   LUT_DATA = {16'h3692,8'h53};
            92:   LUT_DATA = {16'h3693,8'h84};
            93:   LUT_DATA = {16'h3694,8'h88};
            94:   LUT_DATA = {16'h3695,8'h8c};
            95:   LUT_DATA = {16'h3698,8'h89};
            96:   LUT_DATA = {16'h3699,8'h92};
            97 :  LUT_DATA = {16'h369a,8'ha5};
            98 :  LUT_DATA = {16'h369b,8'hca};
            99 :  LUT_DATA = {16'h369c,8'h48};
            100:  LUT_DATA = {16'h369d,8'h4f};
            101:  LUT_DATA = {16'h369e,8'h48};
            102:  LUT_DATA = {16'h369f,8'h4b};
            103:  LUT_DATA = {16'h36a2,8'h49};
            104:  LUT_DATA = {16'h36a3,8'h4b};
            105:  LUT_DATA = {16'h36a4,8'h4f};
            106:  LUT_DATA = {16'h36a6,8'h49};
            107:  LUT_DATA = {16'h36a7,8'h4b};
            108:  LUT_DATA = {16'h36ab,8'h74};
            109:  LUT_DATA = {16'h36ac,8'h74};
            110:  LUT_DATA = {16'h36ad,8'h78};
            111:  LUT_DATA = {16'h36d0,8'h01};
            112:  LUT_DATA = {16'h370f,8'h01};
            113:  LUT_DATA = {16'h3722,8'h01};
            114:  LUT_DATA = {16'h3724,8'h41};
            115:  LUT_DATA = {16'h3725,8'hc4};
            116:  LUT_DATA = {16'h37b0,8'h01};
            117:  LUT_DATA = {16'h37b1,8'h01};
            118:  LUT_DATA = {16'h37b2,8'h01};
            119:  LUT_DATA = {16'h37b3,8'h4b};
            120:  LUT_DATA = {16'h37b4,8'h4f};
            121:  LUT_DATA = {16'h37fa,8'h0b};
            122:  LUT_DATA = {16'h37fb,8'h35};
            123:  LUT_DATA = {16'h37fc,8'h01};
            124:  LUT_DATA = {16'h37fd,8'h07};
            125:  LUT_DATA = {16'h3900,8'h0d};
            126:  LUT_DATA = {16'h3902,8'hdf};// 包含 BLC (黑电平补偿) 自动模式使能等控制 [cite: 770]
            127:  LUT_DATA = {16'h3905,8'hb8};
            128:  LUT_DATA = {16'h3908,8'h41};
            129:  LUT_DATA = {16'h391b,8'h81};
            130:  LUT_DATA = {16'h391c,8'h10};
            131:  LUT_DATA = {16'h391f,8'h30};
            132:  LUT_DATA = {16'h3933,8'h81};
            133:  LUT_DATA = {16'h3934,8'hd9};
            134:  LUT_DATA = {16'h3940,8'h70};
            135:  LUT_DATA = {16'h3941,8'h00};
            136:  LUT_DATA = {16'h3000,8'hff};// MIPI Lane 0 延时控制 [cite: 501]
            137:  LUT_DATA = {16'h3942,8'h01};
            138:  LUT_DATA = {16'h3943,8'hdc};
            139:  LUT_DATA = {16'h3952,8'h02};
            140:  LUT_DATA = {16'h3953,8'h0f};
            
            // --- 曝光与增益控制 (AEC/AGC) ---
            141:  LUT_DATA = {16'h3e01,8'h5d};// 曝光时间寄存器 [7:0] [cite: 623]
            142:  LUT_DATA = {16'h3e02,8'h80};// 曝光时间寄存器 [7:4] [cite: 623]
            143:  LUT_DATA = {16'h3e08,8'h1f};// 模拟增益 (Analog Gain) 控制寄存器，优先调节以获得更好的信噪比 [cite: 637, 642]
            144:  LUT_DATA = {16'h3e1b,8'h14};
            145:  LUT_DATA = {16'h4509,8'h1c};
            146:  LUT_DATA = {16'h4603,8'h09};// MIPI 数据使能：控制 MIPI read [cite: 501]
            
            // --- 原厂隐藏调优寄存器 (5axx 通常为 ISP 处理模块参数) ---
            147:  LUT_DATA = {16'h481f,8'h01};
            148:  LUT_DATA = {16'h4827,8'h02};
            149:  LUT_DATA = {16'h4831,8'h02};
            150:  LUT_DATA = {16'h5799,8'h06};
            151:  LUT_DATA = {16'h5ae0,8'hfe};
            152:  LUT_DATA = {16'h5ae1,8'h40};
            153:  LUT_DATA = {16'h5ae2,8'h30};
            154:  LUT_DATA = {16'h5ae3,8'h28};
            155:  LUT_DATA = {16'h5ae4,8'h20};
            156:  LUT_DATA = {16'h5ae5,8'h30};
            157:  LUT_DATA = {16'h5ae6,8'h28};
            158:  LUT_DATA = {16'h5ae7,8'h20};
            159:  LUT_DATA = {16'h5ae8,8'h3c};
            160:  LUT_DATA = {16'h5ae9,8'h30};
            161:  LUT_DATA = {16'h5aea,8'h28};
            162:  LUT_DATA = {16'h5aeb,8'h3c};
            163:  LUT_DATA = {16'h5aec,8'h30};
            164:  LUT_DATA = {16'h5aed,8'h28};
            165:  LUT_DATA = {16'h5aee,8'hfe};
            166:  LUT_DATA = {16'h5aef,8'h40};
            167:  LUT_DATA = {16'h5af4,8'h30};
            168:  LUT_DATA = {16'h5af5,8'h28};
            169:  LUT_DATA = {16'h5af6,8'h20};
            170:  LUT_DATA = {16'h5af7,8'h30};
            171:  LUT_DATA = {16'h5af8,8'h28};
            172:  LUT_DATA = {16'h5af9,8'h20};
            173:  LUT_DATA = {16'h5afa,8'h3c};
            174:  LUT_DATA = {16'h5afb,8'h30};
            175:  LUT_DATA = {16'h5afc,8'h28};
            176:  LUT_DATA = {16'h5afd,8'h3c};
            177:  LUT_DATA = {16'h5afe,8'h30};
            178:  LUT_DATA = {16'h5aff,8'h28};
            179:  LUT_DATA = {16'h36e9,8'h20};
            180:  LUT_DATA = {16'h37f9,8'h27};
            
            // --- 最终输出格式与使能 ---
            181:  LUT_DATA = {16'h3d08,8'h03};// DVP 信号极性：控制 LREF, FSYNC, PCLK 的极性 [cite: 386]
            182:  LUT_DATA = {16'h3640,8'h02};// PCLK 延迟：控制像素时钟延时，步进 2ns [cite: 391]
            183:  LUT_DATA = {16'h0100,8'h01};// 唤醒传感器：Bit[0]=1，解除睡眠模式，开始图像输出 [cite: 266]
            default:LUT_DATA    =   {16'h0000, 8'h00};
        endcase
    end

endmodule