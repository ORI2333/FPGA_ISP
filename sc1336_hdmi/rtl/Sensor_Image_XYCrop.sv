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
// Last modified Date:     2026/05/01 21:29:47
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/05/01 21:29:47
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              Sensor_Image_XYCrop.sv
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\sc1336_hdmi\rtl\Sensor_Image_XYCrop.sv
// Descriptions:           crop image to target size, the crop area is in the center of source image
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module Sensor_Image_XYCrop #(
    parameter              IMAGE_HSIZE_SOURCE          = 1280                 ,
    parameter              IMAGE_VSIZE_SOURCE          = 720                  ,
    parameter              IMAGE_HSIZE_TARGET          = 1280                 ,
    parameter              IMAGE_YSIZE_TARGET          = 720                  ,
    parameter              PIXEL_DATA_WIDTH            = 8                    
)
(
	//globel clock
    input  wire                         clk                        ,//image pixel clock
    input  wire                         rst_n                      ,
	
	//CMOS Sensor interface
    input  wire                         image_in_vsync             ,//H : Data Valid; L : Frame Sync(Set it by register)
    input  wire                         image_in_href              ,//H : Data vaild, L : Line Sync
    input  wire                         image_in_de                ,//H : Data Enable, L : Line Sync
    input  wire          [PIXEL_DATA_WIDTH-1: 0]image_in_data              ,//8 bits cmos data input
	
    output wire                         image_out_vsync            ,//H : Data Valid; L : Frame Sync(Set it by register)
    output wire                         image_out_href             ,//H : Data vaild, L : Line Sync
    output wire                         image_out_de               ,//H : Data Enable, L : Line Sync
    output wire          [PIXEL_DATA_WIDTH-1: 0]image_out_data              //8 bits cmos data input	
);

// delay one clock for timing
reg                            image_in_href_r            ;
reg                            image_in_de_r              ;
reg                            image_in_vsync_r           ;
reg             [PIXEL_DATA_WIDTH-1: 0]image_in_data_r            ;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)begin
            image_in_href_r  <= 1'b0;
            image_in_de_r    <= 1'b0;
            image_in_vsync_r <= 1'b0;
            image_in_data_r  <= {PIXEL_DATA_WIDTH{1'b0}};
        end else begin
            image_in_href_r  <= image_in_href;
            image_in_de_r    <= image_in_de;
            image_in_vsync_r <= image_in_vsync;
            image_in_data_r  <= image_in_data;
        end
    end

// --------------------------
// href negedge detect
wire                           image_in_href_negedge      ;
assign     image_in_href_negedge= image_in_href_r & ~image_in_href;

//Image Ysize Crop
reg             [  11: 0]      image_ypos                 ;
always @(posedge clk or negedge rst_n)begin
    if(!rst_n)
        image_ypos <= 12'd0;
    else if(image_in_vsync)begin
        if(image_in_href_negedge)
            image_ypos <= image_ypos + 12'd1;
        else
            image_ypos <= image_ypos;
    end else
        image_ypos <= 12'd0;
    end

//-----------------------------------
//Image Hsize Crop
reg             [  11: 0]      image_xpos                 ;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        image_xpos <= 12'd0;
    end else if (image_in_href) begin
        image_xpos <= image_xpos + image_in_de;
    end else begin
        image_xpos <= 12'd0;
    end
end

wire                           w_image_out_href           ;
assign w_image_out_href =   (image_in_href == 1'b1) && (
                            ((image_ypos >= (IMAGE_VSIZE_SOURCE - IMAGE_YSIZE_TARGET)/2) &&
                             (image_ypos <  (IMAGE_VSIZE_SOURCE - IMAGE_YSIZE_TARGET)/2 + IMAGE_YSIZE_TARGET) &&
                             (image_xpos >= (IMAGE_HSIZE_SOURCE - IMAGE_HSIZE_TARGET)/2) &&
                             (image_xpos <  (IMAGE_HSIZE_SOURCE - IMAGE_HSIZE_TARGET)/2 + IMAGE_HSIZE_TARGET))) ;



assign     image_out_vsync= image_in_vsync_r;

reg                            image_out_href_r         =0;
always @(posedge clk) begin
    image_out_href_r <= w_image_out_href;
end
assign     image_out_href= image_out_href_r;

assign     image_out_de = image_in_de_r;

assign     image_out_data= image_in_data_r;
                                                                   
endmodule