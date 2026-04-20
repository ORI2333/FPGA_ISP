`timescale 1ns / 1ps
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
// Last modified Date:     2026/04/19 01:16:13
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/04/19 01:16:13
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              i2c_wr_16b8b.v
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\sc1336_hdmi\rtl\i2c_wr_16b8b.v
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module i2c_wr_16b8b#(
    parameter              CLK_FREQ                    = 96_000000            , //96 MHz
    parameter              I2C_FREQ                    = 400_000              //10 KHz(< 400KHz)
)(
    // global clock
    input                               clk                        ,
    input                               rst_n                      ,

    // i2c interface     
    output                              i2c_sclk                   ,//i2c clock
    input                               i2c_sdat_i                 ,
    output                              i2c_sdat_o                 ,
    output                              i2c_sdat_oe                ,

    // user interface
    input                [   7: 0]      i2c_config_size            ,//i2c config data counter
    output reg           [   7: 0]      i2c_config_index           ,//i2c config reg index, read 2 reg and write xx reg
    input                [  31: 0]      i2c_config_data            ,//i2c config data
    output                              i2c_config_done             //i2c config timing complete
);

    // delay after  1ms reset, 
    localparam             DELAY_TOP                   = CLK_FREQ/1000        ; 

//----------------------------------------
//Delay after reset
reg             [  19: 0]      delay_cnt                  ;
wire                           delay_done                 ;
always@(posedge clk or negedge rst_n)begin
        if(!rst_n)
            delay_cnt <= 0;
        else if(delay_cnt < DELAY_TOP)
            delay_cnt <= delay_cnt + 1'b1;
        else
            delay_cnt <= delay_cnt;
    end

assign     delay_done   = (delay_cnt == DELAY_TOP) ? 1'b1 : 1'b0;

//----------------------------------------
// i2c divider
    localparam             I2C_DIV                     = CLK_FREQ / I2C_FREQ  ;// 96MHz / 400KHz = 240
    localparam             I2C_DIV_Q1                  = I2C_DIV / 4          ;// 96MHz / 400KHz / 4 = 60
    localparam             I2C_DIV_Q2                  = I2C_DIV / 2          ;// 96MHz / 400KHz / 2 = 120
    localparam             I2C_DIV_Q3                  = (I2C_DIV * 3) / 4    ;// 96MHz / 400KHz * 3 / 4 = 180
    localparam             I2C_DIV_LAST                = I2C_DIV - 1          ;// 96MHz / 400KHz - 1 = 239

//I2C Control Clock generate
reg             [  15: 0]      clk_cnt                    ;//divide for i2c clock
reg                            i2c_ctrl_clk               ;//i2c control clock, H: valid; L: valid
reg                            i2c_transfer_en            ;//send i2c data before, make sure that sdat is steady when i2c_sclk is valid
reg                            i2c_capture_en             ;//capture i2c data  while sdat is steady from cmos 

always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            begin
                clk_cnt         <= 16'd0;
                i2c_ctrl_clk    <= 1'b0;
                i2c_transfer_en <= 1'b0;
                i2c_capture_en  <= 1'b0;
            end
        else if (delay_done)
            begin
                if (clk_cnt < I2C_DIV_LAST)
                    clk_cnt         <= clk_cnt + 16'd1;
                else
                    clk_cnt         <= 16'd0;
                    
                    i2c_ctrl_clk    <= (clk_cnt >= I2C_DIV_Q1) && (clk_cnt < I2C_DIV_Q3);
                    i2c_transfer_en <= (clk_cnt == 16'd0);
                    i2c_capture_en  <= (clk_cnt == (I2C_DIV_Q2 - 1));
            end
        else
            begin
                clk_cnt         <= 16'd0;
                i2c_ctrl_clk    <= 1'b0;
                i2c_transfer_en <= 1'b0;
                i2c_capture_en  <= 1'b0;
            end
    end



//I2C Timing state Parameter
    localparam             I2C_IDLE                    = 4'd0                 ;
//Write I2C: {ID_Address, REG_Address, W_REG_Data}
    localparam             I2C_WR_START                = 4'd1                 ;
    localparam             I2C_WR_IDADDR               = 4'd2                 ;
    localparam             I2C_WR_ACK1                 = 4'd3                 ;
    localparam             I2C_WR_REGADDR1             = 4'd4                 ;
    localparam             I2C_WR_ACK2                 = 4'd5                 ;
    localparam             I2C_WR_REGADDR2             = 4'd6                 ;
    localparam             I2C_WR_ACK3                 = 4'd7                 ;
    localparam             I2C_WR_REGDATA              = 4'd8                 ;
    localparam             I2C_WR_ACK4                 = 4'd9                 ;
    localparam             I2C_WR_STOP                 = 4'd10                ;
                                                          
reg             [   3: 0]      cur_state                  ;
reg             [   3: 0]      next_state                 ;
reg             [   3: 0]      i2c_stream_cnt             ;

always @(posedge clk or negedge rst_n)
    begin
        if(rst_n == 1'b0)
            cur_state <= I2C_IDLE;
        else if (i2c_transfer_en)
            cur_state <= next_state;
        else
            cur_state <= cur_state;
    end

always @( * )
    begin
        next_state = I2C_IDLE;
    case(cur_state)
        I2C_IDLE:
        begin
            if(delay_done == 1'b1)
                begin
                    if (i2c_transfer_en)
                        begin
                            if (i2c_config_index < i2c_config_size)
                                next_state = I2C_WR_START;
                            else
                                next_state = I2C_IDLE;
                        end
                    else
                        next_state = next_state;
                end
            else
                next_state = I2C_IDLE;
        end
        I2C_WR_START: 
        begin
            if (i2c_transfer_en)
                next_state = I2C_WR_IDADDR;
            else
                next_state = I2C_IDLE;
        end
        I2C_WR_IDADDR:
        begin 
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_ACK1;
            else
                next_state = I2C_WR_IDADDR;
        end
        I2C_WR_ACK1:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_REGADDR1;
            else
                next_state = I2C_WR_ACK1;
        end
        I2C_WR_REGADDR1:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_ACK2;
            else
                next_state = I2C_WR_REGADDR1;
        end
        I2C_WR_ACK2:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_REGADDR2;
            else
                next_state = I2C_WR_ACK2;
        end
        I2C_WR_REGADDR2:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_ACK3;
            else
                next_state = I2C_WR_REGADDR2;
        end
        I2C_WR_ACK3:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_REGDATA;
            else
                next_state = I2C_WR_ACK3;
        end
        I2C_WR_REGDATA:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_ACK4;
            else
                next_state = I2C_WR_REGDATA;
        end
        I2C_WR_ACK4:
        begin
            if (i2c_transfer_en && i2c_stream_cnt == 4'd8)
                next_state = I2C_WR_STOP;
            else
                next_state = I2C_WR_ACK4;
        end
        I2C_WR_STOP:
        begin
            if (i2c_transfer_en)
                next_state = I2C_IDLE;
            else
                next_state = I2C_WR_STOP;
        end     
        default:
            next_state = I2C_IDLE;  
    endcase
    end

//I2C Data shift register
reg i2c_sdat_out;
reg [7:0]   i2c_wdata;
always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                i2c_sdat_out   <= 1'b1;
                i2c_stream_cnt <= 0;
                i2c_wdata      <= 0;
            end
        else if(i2c_transfer_en)
            begin
                case (next_state)
                    I2C_IDLE: 
                        begin
                            i2c_sdat_out   <= 1'b1;
                            i2c_stream_cnt <= 0;
                            i2c_wdata      <= 0;
                        end
                    I2C_WR_START:
                        begin
                            i2c_sdat_out   <= 1'b0; //START condition: SDA goes low while SCL is high
                            i2c_stream_cnt <= 0;
                            i2c_wdata      <= i2c_config_data[31:24];    //ID_Address
                        end
                    I2C_WR_IDADDR:
                        begin
                            i2c_stream_cnt <= i2c_stream_cnt + 1'b1;
                            i2c_wdata      <= i2c_wdata[3'd7 - i2c_stream_cnt];
                        end
                    I2C_WR_ACK1:  
                        begin
                            i2c_stream_cnt <= 0;
                            i2c_wdata <= i2c_config_data[23:16];        //REG_Address  
                        end
                    I2C_WR_REGADDR1:
                        begin
                            i2c_stream_cnt <= i2c_stream_cnt + 1'b1;
                            i2c_sdat_out <= i2c_wdata[3'd7 - i2c_stream_cnt];
                        end
                    I2C_WR_ACK2:
                        begin
                            i2c_stream_cnt <= 0;
                            i2c_wdata <= i2c_config_data[15:8];         //REG_Address
                        end
                    I2C_WR_REGADDR2:
                        begin
                            i2c_stream_cnt <= i2c_stream_cnt + 1'b1;
                            i2c_sdat_out <= i2c_wdata[3'd7 - i2c_stream_cnt];
                        end
                    I2C_WR_ACK3:
                        begin
                            i2c_stream_cnt <= 0;
                            i2c_wdata <= i2c_config_data[7:0];          //REG_Data
                        end
                    I2C_WR_REGDATA:
                        begin
                            i2c_stream_cnt <= i2c_stream_cnt + 1'b1;
                            i2c_sdat_out <= i2c_wdata[3'd7 - i2c_stream_cnt];
                        end
                    I2C_WR_ACK4:
                        begin
                            i2c_stream_cnt <= 0;
                        end
                    I2C_WR_STOP:
                        begin
                            i2c_sdat_out <= 1'b0;
                        end
                    default: 
                        next_state <= I2C_IDLE;  
                endcase
            end
        else
            begin
                i2c_stream_cnt <= i2c_stream_cnt;
                i2c_sdat_out <= i2c_sdat_out;
                i2c_wdata <= i2c_wdata;
            end

    end              


// Check whether I2C configuration is complete.
wire                           i2c_transfer_end           ;
reg                            i2c_ack                    ;

assign     i2c_transfer_end= (cur_state == I2C_WR_STOP);

always @(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            i2c_config_index <= 'd0;
        else if(i2c_transfer_en)
            begin
                if (i2c_transfer_end & ~i2c_ack)
                    begin
                        if (i2c_config_index < i2c_config_size )
                            i2c_config_index <= i2c_config_index + 1'b1;
                        else
                            i2c_config_index <= i2c_config_size;
                    end
                else
                    i2c_config_index <= i2c_config_index;
            end
        else
            i2c_config_index <= i2c_config_index;
    end

assign     i2c_config_done= (i2c_config_index == i2c_config_size) ? 1'b1 : 1'b0;                         

//---------------------------------------------
//respone from slave for i2c data transfer
reg i2c_ack_1;
reg i2c_ack_2;
reg i2c_ack_3;
reg i2c_ack_4;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        i2c_ack_1 <= 1'b0;
        i2c_ack_2 <= 1'b0;
        i2c_ack_3 <= 1'b0;
        i2c_ack_4 <= 1'b0;
        i2c_ack <= 1'b1;
    end
    else if (i2c_capture_en) begin
        case (cur_state)
            I2C_IDLE: begin
                i2c_ack_1 <= 1'b0;
                i2c_ack_2 <= 1'b0;
                i2c_ack_3 <= 1'b0;
                i2c_ack_4 <= 1'b0;
                i2c_ack <= 1'b1; 
            end
            I2C_WR_ACK1: i2c_ack_1 <= i2c_sdat_i; // Capture ACK for ID_Address
            I2C_WR_ACK2: i2c_ack_2 <= i2c_sdat_i; // Capture ACK for REG_Address1
            I2C_WR_ACK3: i2c_ack_3 <= i2c_sdat_i; // Capture ACK for REG_Address2
            I2C_WR_ACK4: i2c_ack_4 <= i2c_sdat_i; // Capture ACK for REG_Data
            I2C_WR_STOP: begin
                i2c_ack <= (i2c_ack_1 | i2c_ack_2 | i2c_ack_3); 
            end
            default: begin
                i2c_ack_1 <= i2c_ack_1;
                i2c_ack_2 <= i2c_ack_2;
                i2c_ack_3 <= i2c_ack_3;
                i2c_ack_4 <= i2c_ack_4;
                i2c_ack <= i2c_ack;
            end
        endcase
    end
    else begin
        i2c_ack_1 <= i2c_ack_1;
        i2c_ack_2 <= i2c_ack_2;
        i2c_ack_3 <= i2c_ack_3;
        i2c_ack_4 <= i2c_ack_4;
        i2c_ack <= i2c_ack;
    end
end

wire bir_en;
assign bir_en = ((cur_state == I2C_WR_ACK1) || (cur_state == I2C_WR_ACK2) 
                || (cur_state == I2C_WR_ACK3) || (cur_state == I2C_WR_ACK4))? 1'b1 : 1'b0;

assign  i2c_sclk = (cur_state >= I2C_WR_IDADDR && cur_state <= I2C_WR_ACK4) ? 
                    i2c_ctrl_clk : 1'b1;

assign  i2c_sdat_o = i2c_sdat_out;
assign  i2c_sdat_oe = ~bir_en;
    

endmodule