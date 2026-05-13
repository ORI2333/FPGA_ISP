`timescale 1ns / 1ps
//****************************************Copyright (c)***********************************//
// Copyright(C)            ORI2333
// All rights reserved     
// File name:              
// Last modified Date:     2026/05/01 22:58:26
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             ORI2333
// Created date:           2026/05/01 22:58:26
// mail      :             ori2333.zh@gmail.com
// Version:                V1.0
// TEXT NAME:              axi4_ctrl.sv
// PATH:                   E:\E_EngineeringWarehouse\FPGA_ISP\FPGA_ISP\sc1336_hdmi\rtl\axi4_ctrl.sv
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module axi4_ctrl #(
    parameter              ID_LEN                      = 8                    ,
    parameter              ADDR_LEN                    = 32                   ,
    parameter              DATA_LEN                    = 256                  ,
    parameter              DATA_SIZE                   = 5                    ,// 2^5=32B = 256-bit
    parameter              STRB_LEN                    = DATA_LEN/8           ,
    parameter              BURST_LEN                   = 16                   ,
    parameter              ADDR_INC                    = BURST_LEN * STRB_LEN ,// Address increment for each burst (number of bytes per burst)
    parameter              W_WIDTH                     = 8                    ,
    parameter              R_WIDTH                     = 8                    ,
    parameter              BUF_SIZE                    = 22                   , //Allocate 2^22 bytes (4MB) by default. The module takes 4*4MB by default. 
    parameter              RD_END_ADDR                 = 1280*720             ,
    parameter              BASE_ADDR                   = 32'h0000_0000        


)(
    input  wire                         axi4_clk                   ,// AXI4 clock signal
    input  wire                         axi4_rst_n                 ,// Active low reset signal for AXI4 interface

    // AW - Write Address Channel
    output wire          [ID_LEN-1: 0]  axi4_awid                  ,
    output wire          [ADDR_LEN-1: 0]axi4_awaddr                ,// 32 or 64 bits address
    output wire          [   7: 0]      axi4_awlen                 ,// Burst length (number of data beats - 1)
    output wire          [   2: 0]      axi4_awsize                ,// Burst size (number of bytes per beat, encoded as log2(bytes))
    output wire          [   1: 0]      axi4_awburst               ,// Burst type
    output wire          [   1: 0]      axi4_awlock                ,// Lock type
    output wire          [   3: 0]      axi4_awcache               ,// Cache type
    output wire          [   2: 0]      axi4_awprot                ,// Protection type
    output wire          [   3: 0]      axi4_awqos                 ,// Quality of Service
    output wire          [   3: 0]      axi4_awregion              ,// Region identifier
    output reg                          axi4_awvalid               ,// Write address valid signal    
    input  wire                         axi4_awready               ,// Write address ready signal

    // W - Write Data Channel
    output wire          [DATA_LEN-1: 0]axi4_wdata                 ,// Write data bus
    output wire          [STRB_LEN-1: 0]axi4_wstrb                 ,// Write strobes (indicates which bytes of the data bus are valid)
    output wire                         axi4_wlast                 ,// Write last signal (indicates the last data beat in a burst)
    output reg                          axi4_wvalid                ,// Write data valid signal
    input  wire                         axi4_wready                ,// Write data ready signal

    // B - Write Response Channel
    input  wire          [ID_LEN-1: 0]  axi4_bid                   ,// Write response ID (should match the AWID of the corresponding write address)
    input  wire          [   1: 0]      axi4_bresp                 ,// Write response (indicates the status of the write transaction)
    input  wire                         axi4_bvalid                ,// Write response valid signal
    output reg                          axi4_bready                ,// Write response ready signal

    // AR - Read Address Channel
    output wire          [ID_LEN-1: 0]  axi4_arid                  ,// Read address ID (used to identify different read transactions)
    output wire          [ADDR_LEN-1: 0]axi4_araddr                ,// 32 or 64 bits address
    output wire          [   7: 0]      axi4_arlen                 ,// Burst length (number of data beats - 1)
    output wire          [   2: 0]      axi4_arsize                ,// Burst size (number of bytes per beat, encoded as log2(bytes))
    output wire          [   1: 0]      axi4_arburst               ,// Burst type
    output wire          [   1: 0]      axi4_arlock                ,// Lock type
    output wire          [   3: 0]      axi4_arcache               ,// Cache type
    output wire          [   2: 0]      axi4_arprot                ,// Protection type
    output wire          [   3: 0]      axi4_arqos                 ,// Quality of Service
    output wire          [   3: 0]      axi4_arregion              ,// Region identifier
    output reg                          axi4_arvalid               ,// Read address valid signal
    input  wire                         axi4_arready               ,// Read address ready signal

    // R - Read Data Channel
    input  wire          [ID_LEN-1: 0]  axi4_rid                   ,// Read response ID (should match the ARID of the corresponding read address)
    input  wire          [DATA_LEN-1: 0]axi4_rdata                 ,// Read data from slave (payload of read response)
    input  wire          [   1: 0]      axi4_rresp                 ,// Read response (indicates the status of the read transaction)
    input  wire                         axi4_rlast                 ,// Last flag (indicates the last data beat in a burst)
    input  wire                         axi4_rvalid                ,// Read data valid signal
    output wire                         axi4_rready              ,// Read data ready signal

    // Write Frame Interface
    input  wire                         wframe_pclk                ,// Write frame pixel clock
    input  wire                         wframe_vsync               ,// Write frame vertical sync signal
    input  wire                         wframe_data_en             ,// Write frame data enable signal
    input  wire          [W_WIDTH-1: 0] wframe_data                ,// Write frame pixel data

    // Read Frame Interface
    input  wire                         rframe_pclk                ,// Read frame pixel clock
    input  wire                         rframe_vsync               ,// Read frame vertical sync signal
    input  wire                         rframe_data_en             ,// Read frame data enable signal
    output wire          [R_WIDTH-1: 0] rframe_data                ,// Read frame pixel data output

    // Debug port for ILA
    output wire          [  31: 0]      dbg_wr                     ,// write channel internal state
    output wire          [  15: 0]      dbg_rd                      // read channel internal state
);
// initialize control signals
initial begin
    axi4_awvalid <= 1'b0;
    axi4_wvalid  <= 1'b0;
    axi4_arvalid <= 1'b0;
end

assign     axi4_awid    = {ID_LEN{1'b0}};// Default ID = 0
assign     axi4_awlen   = BURST_LEN - 1'b1;// Burst length (number of data beats - 1)
assign     axi4_awsize  = DATA_SIZE    ;// Burst size (number of bytes per beat, encoded as log2(bytes))
assign     axi4_awburst = 2'b01        ;// INCR burst type (incrementing address)
assign     axi4_awlock  = 2'b00        ;// Normal, non-exclusive access   
assign     axi4_awcache = 4'b0000      ;// Cacheable, bufferable, read/write allocate
assign     axi4_awprot  = 3'b000       ;// Secure, privileged, data access
assign     axi4_awqos   = 4'b0000      ;// Default QoS
assign     axi4_awregion= 4'b0000      ;// Default region
assign     axi4_wstrb   = {STRB_LEN{1'b1}};// All bytes are valid
assign     axi4_bready  = 1'b1         ;

assign     axi4_arid    = {ID_LEN{1'b0}};// Default ID = 0
assign     axi4_arlen   = BURST_LEN - 1'b1;// Burst length (number of data beats - 1)
assign     axi4_arsize  = DATA_SIZE    ;// Burst size (number of bytes per beat, encoded as log2(bytes))
assign     axi4_arburst = 2'b01        ;// INCR burst type (incrementing address)
assign     axi4_arlock  = 2'b00        ;// Normal, non-exclusive
assign     axi4_arcache = 4'b0000      ;// Cacheable, bufferable, read/write allocate
assign     axi4_arprot  = 3'b000       ;// Secure, privileged, data access
assign     axi4_arqos   = 4'b0000      ;// Default QoS
assign     axi4_arregion= 4'b0000      ;// Default region
assign     axi4_rready= 1'b1         ;

// --------------------------------------------------------------------------------
// Write and Read Frame Index Management
// Frame Buffer Read/Write Scheduler
reg             [   1: 0]      rc_wframe_index            ;
reg             [   1: 0]      rc_rframe_index            ;

// 4 data buffers for write and read operations
wire            [   1: 0]      w_wframe_index_r1          ;
wire            [   1: 0]      w_wframe_index_next        ;
reg             [   1: 0]      r_wframe_index_last        ;
reg                            r_wframe_inc               ;
reg                            r_rframe_inc               ;
reg                            wframe_done                ;// set when a frame write completes

assign     w_wframe_index_r1= rc_wframe_index + 2'd1;
assign  w_wframe_index_next = (w_wframe_index_r1 == rc_rframe_index)
                            ? (rc_wframe_index + 2'd2)
                            : (rc_wframe_index + 2'd1);

always @(posedge axi4_clk) begin
    if(!axi4_rst_n)begin
        rc_wframe_index <= 2'd0;
        rc_rframe_index <= 2'd2;        // start read 2 buffers away from write
        r_wframe_index_last <= 2'd0;
        wframe_done       <= 1'b0;
    end else begin
            rc_wframe_index <= rc_wframe_index;
            rc_rframe_index <= rc_rframe_index;

        case ({r_rframe_inc,r_wframe_inc})
            2'b01: begin
                // write completes a frame
                rc_wframe_index <= w_wframe_index_next;
                r_wframe_index_last <= rc_wframe_index;
                wframe_done <= 1'b1;
            end
            2'b10: begin
                // only advance read if write has completed at least one frame
                if (wframe_done)
                    rc_rframe_index <= r_wframe_index_last;
            end
            2'b11: begin
                rc_wframe_index <= w_wframe_index_next;
                rc_rframe_index <= rc_wframe_index;
                wframe_done <= 1'b1;
            end
            default: begin
                rc_wframe_index <= rc_wframe_index;
                rc_rframe_index <= rc_rframe_index;
            end
        endcase
    end
end

// -----------------------------------------------------------------------------
// AXI4 Writer

// fifo
wire                           w_wfifo_pempty             ;
wire                           w_wfifo_empty              ;
wire                           w_wfifo_ren                ;
wire            [DATA_LEN-1: 0]w_wfifo_rdata              ;

// write state machine
reg             [   1: 0]      state_write                ;
    localparam             WS_W_IDLE                   = 2'b00                ;// Idle state, waiting for write frame data
    localparam             WS_W_WDATA                  = 2'b01                ;// Write data state, sending write data to AXI4 bus
    localparam             WS_W_WINC                   = 2'b10                ;// Write increment state
    localparam             WS_W_EOF                    = 2'b11                ;// End of frame state

// wirte pointer and counter
reg             [BUF_SIZE-1: 0]rc_w_ptr                   ;
reg                            rc_w_eof                   ;
reg                            r_w_rst_n                  ;

// burst
reg             [   7: 0]      rc_burst                   ;

// EOF Monitor
reg             [   1: 0]      r_wframe_sync              ;
reg                            r_weof_pending             ;

always @(posedge axi4_clk or negedge axi4_rst_n) begin
    if(!axi4_rst_n) begin
        state_write <= WS_W_IDLE;
        rc_w_ptr <= {BUF_SIZE{1'b0}};
        rc_w_eof <= 1'b0;
        r_w_rst_n <= 1'b0;
        rc_burst <= 8'd0;
        r_wframe_sync <= 2'b00;
        r_weof_pending <= 1'b0;

        axi4_awvalid <= 1'b0;
        axi4_wvalid <= 1'b0;
        r_wframe_inc <= 1'b0;
    end else begin
        rc_w_eof <= 1'b0;                                           // Clear EOF flag by default
        r_wframe_inc <= 1'b0;                                       // Clear write increment flag by default

        r_wframe_sync <= {r_wframe_sync[0], wframe_vsync};          // Synchronize vsync to axi4_clk domain
        if(r_wframe_sync == 2'b10) begin
            r_weof_pending <= 1'b1;                                 // Set EOF pending flag on vsync falling edge
        end else begin
            r_weof_pending <= r_weof_pending;                       // Hold EOF pending flag until it's cleared in the state machine
        end

        if(axi4_awvalid && axi4_awready) begin
            axi4_awvalid <= 1'b0;
        end else begin
            axi4_awvalid <= axi4_awvalid;
        end

        case (state_write)
            WS_W_IDLE: begin                                       // 2'b00
                rc_burst <= 8'd0;
                r_w_rst_n <= 1'b1;

                if(~w_wfifo_pempty || (r_weof_pending && ~w_wfifo_empty)) begin
                    axi4_awvalid <= 1'b1;
                    axi4_wvalid <= 1'b1;
                    state_write <= WS_W_WDATA;
                end else if(r_weof_pending) begin
                    r_w_rst_n <= 1'b0;
                    r_wframe_inc <= 1'b1;
                    state_write <= WS_W_EOF;
                end
            end

            WS_W_WDATA: begin                                      // 2'b01
                rc_burst <= rc_burst + axi4_wready;

                if(axi4_wlast && axi4_wready) begin
                    axi4_wvalid <= 1'b0;
                    state_write <= WS_W_WINC;
                end
            end

            WS_W_WINC: begin                                       // 2'b10
                rc_w_ptr <= rc_w_ptr + ADDR_INC;
                state_write <= WS_W_IDLE;
            end

            WS_W_EOF: begin                                        // 2'b11
                r_weof_pending <= 1'b0;
                rc_w_ptr <= 1'b0;
                state_write <= WS_W_IDLE;
            end

            default: begin
                state_write <= WS_W_IDLE;
            end
        endcase
    end
end

// writer address generation
assign     axi4_awaddr   = BASE_ADDR + {rc_wframe_index, rc_w_ptr};
assign     axi4_wdata   = w_wfifo_rdata;
assign     axi4_wlast   = (rc_burst >= (BURST_LEN - 1)) ? 1'b1 : 1'b0;

// fifo enables
assign     w_wfifo_ren  = axi4_wvalid && axi4_wready;

// Shift register to align incoming write frame data with the AXI4 data bus width
reg             [DATA_LEN-1: 0]r_wfifo_wdata              ;
wire            [DATA_LEN-1: 0]w_wfifo_wdata              ;
assign     w_wfifo_wdata= {wframe_data, r_wfifo_wdata[DATA_LEN-1:W_WIDTH]};// Shift in new data from the write frame, while keeping the remaining data in the register

    localparam             WFIFO_CNT_SIZE              = (W_WIDTH == 8) ? 5 : (W_WIDTH == 16) ? 4 : (W_WIDTH == 32) ? 3 : 2; // Calculate the number of bits needed for the counter based on W_WIDTH
reg             [WFIFO_CNT_SIZE-1: 0]rc_wfifo_we                ;// Counter to track how many data beats have been collected for the current burst

// Write frame data collection and burst formation
always @(posedge wframe_pclk) begin
    if(!r_w_rst_n) begin
        r_wfifo_wdata <= {DATA_LEN{1'b0}};       // flush shift register at frame end
    end else if(wframe_data_en) begin
        r_wfifo_wdata <= w_wfifo_wdata;
    end
end

// Counter to track the number of data beats collected for the current burst
always @(posedge wframe_pclk) begin
    if(!r_w_rst_n) begin
        rc_wfifo_we <= 'd0;
    end else begin
        rc_wfifo_we <= rc_wfifo_we + wframe_data_en;
    end
end


// Write side: Pixel clock domain; data is written after concatenating to a full 256-bit width.
// Read side: AXI clock domain, reads on demand
W0_FIFO_256 u_W0_FIFO_256(
    .rst                                (~r_w_rst_n                ),// input wire rst
    .wr_clk                             (wframe_pclk               ),// input wire wr_clk
    .rd_clk                             (axi4_clk                  ),// input wire rd_clk
    .din                                (w_wfifo_wdata             ),// input wire [255 : 0] din
    .wr_en                              (wframe_data_en && (&rc_wfifo_we)),// input wire wr_en
    .rd_en                              (w_wfifo_ren               ),// input wire rd_en
    .dout                               (w_wfifo_rdata             ),// output wire [255 : 0] dout
    .full                               (                          ),// output wire full
    .empty                              (w_wfifo_empty             ),// output wire empty
    .prog_full                          (                          ),// output wire prog_full
    .prog_empty                         (w_wfifo_pempty            ) // output wire prog_empty
);

// ---------------------------------------------------------------------------------
// AXI4 Reader

// vsnyc delay
reg                            rframe_vsync_dly           ;
always @(posedge rframe_pclk) begin
    if(!axi4_rst_n) begin
        rframe_vsync_dly <= 1'b0;
    end else begin
        rframe_vsync_dly <= rframe_vsync;
    end
end

// vsnyc negedge detection
wire                           rframe_vsync_negedge       ;
assign     rframe_vsync_negedge= rframe_vsync_dly && ~rframe_vsync;

// reset wait counter  31 cycles
reg             [   4: 0]      rc_rfifo                   ;
always @(posedge rframe_pclk) begin
    if(!axi4_rst_n) begin
        rc_rfifo <= 5'h1f;                                          // Initialize counter to maximum value (31) on reset
    end else if(rframe_vsync_negedge) begin
        rc_rfifo <= 5'h1f;
    end else if(rc_rfifo != 0) begin
        rc_rfifo <= rc_rfifo - 1'b1;
    end else begin
        rc_rfifo <= 5'b0;
    end
end

// read fifo reset signal, active low, reset is released 31 cycles after vsync negedge
reg                            rfifo_rst_n                ;
always @(posedge rframe_pclk) begin
    if(!axi4_rst_n) begin
        rfifo_rst_n <= 1'b0;
    end else begin
        if (rc_rfifo == 5'b0) begin
            rfifo_rst_n <= 1'b1;
        end else begin
            rfifo_rst_n <= 1'b0;
        end
    end
end

// final reset signal for read fifo, active high
wire                           w_rfifo_rst                ;
assign     w_rfifo_rst = (~axi4_rst_n) || (~rfifo_rst_n);

// read fifo instance
reg                            rfifo_wenb                 ;// Write enable for read FIFO
reg             [DATA_LEN-1: 0]rfifo_wdata                ;// Write data for read FIFO 
wire            [   9: 0]      rfifo_wcnt                 ;// Write counter for read FIFO
wire                           rfifo_wfull                ;// Full flag for read FIFO
wire                           rfifo_wr_rst_busy          ;// Write reset busy flag for read FIFO
wire                           w_rfifo_aempty             ;// Almost empty flag for read FIFO
wire                           w_rfifo_empty              ;// Empty flag for read FIFO

wire                           w_rframe_data_en_gen       ;// Generated data enable signal for read frame, used to trigger read operations from the FIFO
wire            [ 255: 0]      w_rframe_data_gen          ;// Generated read frame data, which will be sent to the read frame interface

// Read frame data generation logic
R0_FIFO_256 u_R0_FIFO_256 (
    .rst                                (w_rfifo_rst              ),// input wire rst (active high)
    .wr_clk                             (axi4_clk                  ),// AXI clock domain (write side)
    .wr_en                              (rfifo_wenb                ),// write enable from AXI read
    .din                                (rfifo_wdata               ),// AXI read data GOES IN
    .full                               (                          ),// output wire full
    .prog_full                          (rfifo_wfull               ),// output wire prog_full

    .rd_clk                             (rframe_pclk               ),// pixel clock domain (read side)
    .rd_en                              (w_rframe_data_en_gen      ),// read enable from unpacker
    .dout                               (w_rframe_data_gen         ),// 256-bit data OUT to unpacker
    .empty                              (w_rfifo_empty             ),// output wire empty
    .prog_empty                         (w_rfifo_aempty            ) // output wire prog_empty
);

// Sync R0_FIFO reset to axi4_clk domain (active high, matches reference)
reg                            r_rfifo_rst               ;
always @(posedge axi4_clk) begin
    r_rfifo_rst <= w_rfifo_rst;
end

// Sync R0_FIFO reset to rframe_pclk domain (active high)
reg                            r_rfifo_rst_rclk          ;
always @(posedge rframe_pclk) begin
    r_rfifo_rst_rclk <= w_rfifo_rst;
end

// Read-side unpack counter (reset by FIFO reset, counts on data enable)
localparam             RFIFO_CNT_SIZE = (R_WIDTH == 8) ? 5 : ((R_WIDTH == 16) ? 4 : ((R_WIDTH == 32) ? 3 : 2));
reg             [RFIFO_CNT_SIZE-1: 0]rc_rfifo_rd;

always @(posedge rframe_pclk or posedge r_rfifo_rst_rclk) begin
    if (r_rfifo_rst_rclk) begin
        rc_rfifo_rd <= 'd0;
    end else if (rframe_data_en) begin
        rc_rfifo_rd <= rc_rfifo_rd + 1'b1;
    end
end

assign w_rframe_data_en_gen = rframe_data_en && (rc_rfifo_rd == 0) && !w_rfifo_empty;

// Data unpack: load 256-bit word from FIFO, shift out 8 bits at a time.
// Requires R0_FIFO to be FWFT (First-Word Fall-Through) mode.
// If FIFO is standard mode, reconfigure the IP to FWFT.
reg             [ 255: 0]      r_rframe_data_gen = 256'b0;
always @(posedge rframe_pclk) begin
    if (w_rframe_data_en_gen) begin
        r_rframe_data_gen <= w_rframe_data_gen;          // load FIFO data directly
    end else if (rframe_data_en) begin
        r_rframe_data_gen <= r_rframe_data_gen >> R_WIDTH;
    end
end
assign rframe_data = w_rfifo_empty ? {R_WIDTH{1'b0}} : r_rframe_data_gen[R_WIDTH-1:0];

// Reset-busy delay: fill shift register with 1s after FIFO reset releases
reg             [  15: 0]      rfifo_wr_rst_busy_dly = 'd0;
always @(posedge axi4_clk or posedge r_rfifo_rst) begin
    if (r_rfifo_rst) begin
        rfifo_wr_rst_busy_dly <= 'd0;
    end else begin
        rfifo_wr_rst_busy_dly <= {rfifo_wr_rst_busy_dly[14:0], 1'b1};
    end
end

wire rfifo_wr_rst_busy_neg;
assign rfifo_wr_rst_busy_neg = (rfifo_wr_rst_busy_dly[1:0] == 2'b01);

// Read DDR delay counter: wait 31 cycles after FIFO reset released
reg             [   4: 0]      read_ddr_delay_cnt;
always @(posedge axi4_clk or posedge r_rfifo_rst) begin
    if (r_rfifo_rst) begin
        read_ddr_delay_cnt <= 5'b0;
    end else begin
        if (rfifo_wr_rst_busy_neg) begin
            read_ddr_delay_cnt <= 5'd31;
        end else if (read_ddr_delay_cnt > 5'b0) begin
            read_ddr_delay_cnt <= read_ddr_delay_cnt - 1'b1;
        end else begin
            read_ddr_delay_cnt <= 5'b0;
        end
    end
end

// r_rframe_inc: fires once after each FIFO reset release
always @(posedge axi4_clk or posedge r_rfifo_rst) begin
    if (r_rfifo_rst) begin
        r_rframe_inc <= 1'b0;
    end else begin
        r_rframe_inc <= rfifo_wr_rst_busy_neg;
    end
end

wire read_ddr_init_flag;
assign read_ddr_init_flag = (read_ddr_delay_cnt == 5'd1);


localparam [1:0] S_READ_IDLE = 2'd0,
                 S_READ_ADDR = 2'd1,
                 S_READ_DATA = 2'd2;

reg             [   1: 0]      rd_state                   ;
reg             [   1: 0]      rd_next_state              ;
reg             [   8: 0]      rdata_cnt                  ;
reg             [BUF_SIZE-1: 0]araddr                     ;
reg                            r_rd_pend                =0;
// Read state machine for AXI4 read operations
always @(posedge axi4_clk or posedge r_rfifo_rst) begin
    if(r_rfifo_rst) begin
        rd_state <= S_READ_IDLE;
    end else begin
        rd_state <= rd_next_state;
    end
end
// Next state logic for the read state machine
always @(*) begin
    rd_next_state = rd_state;
    case (rd_state)
        S_READ_IDLE: begin
            if (rfifo_wr_rst_busy_dly[15] && (araddr < RD_END_ADDR) && (~rfifo_wfull)) begin
                rd_next_state = S_READ_ADDR;
            end
        end
        S_READ_ADDR: begin
            rd_next_state = S_READ_DATA;
        end
        S_READ_DATA: begin
            if((~axi4_arvalid) && (~r_rd_pend)) begin
                rd_next_state = S_READ_IDLE;
            end
        end 
        default: begin
            rd_next_state = rd_state;
        end
    endcase
end
// Read operation logic based on the current state of the read state machine
always @(posedge axi4_clk or posedge r_rfifo_rst) begin
    if(r_rfifo_rst) begin
        axi4_arvalid <= 1'b0;
        r_rd_pend <= 1'b0;
    end else begin
        if(rd_state == S_READ_IDLE && rd_next_state == S_READ_ADDR)begin
            axi4_arvalid <= 1'b1;
        end else if (axi4_arvalid && axi4_arready) begin
            axi4_arvalid <= 1'b0;
        end

        if(rd_state == S_READ_IDLE && rd_next_state == S_READ_ADDR)begin
            r_rd_pend <= 1'b1;
        end else if (axi4_rvalid && axi4_rlast) begin
            r_rd_pend <= 1'b0;
        end
    end
end

 
always @(posedge axi4_clk or posedge r_rfifo_rst) begin
    if(r_rfifo_rst)begin
        araddr <= '0;
    end else begin
        if (axi4_arvalid && axi4_arready) begin
            araddr <= araddr + ADDR_INC;
        end
    end
end

assign axi4_araddr = BASE_ADDR + {rc_rframe_index,araddr};

reg             [   8: 0]      rdata_cnt_dly              ;

always @(posedge axi4_clk) begin
    rdata_cnt_dly <= rdata_cnt;
end

always @(*) begin
    if(rd_state == S_READ_DATA) begin
        if(axi4_rvalid && axi4_rready)begin
            rdata_cnt = rdata_cnt + 1'b1;
        end else begin
            rdata_cnt = rdata_cnt_dly;
        end
    end else begin
        rdata_cnt = 9'b0;
    end
end

always @(posedge axi4_clk) begin
    if(!axi4_rst_n) begin
        rfifo_wenb <= 1'b0;
    end else begin
        if(axi4_rvalid && axi4_rready) begin
            rfifo_wenb <= 1'b1;
        end else begin
            rfifo_wenb <= 1'b0;
        end
    end
end

always @(posedge axi4_clk) begin
    rfifo_wdata <= axi4_rdata;
end

// --------------------------------------------------------------------------------
// Debug outputs for ILA
// dbg_wr[31:0] â€? write channel internal state
wire [4:0] dbg_wfifo_we = rc_wfifo_we;               // pad to 5 bits
assign dbg_wr = {
    3'b0,                       // [31:29]
    dbg_wfifo_we,               // [28:24] FIFO write counter (0~31)
    rc_burst,                   // [23:16] burst beat counter (0~15)
    8'b0,                       // [15:8]
    r_weof_pending,             // [7]     frame-end pending
    w_wfifo_empty,              // [6]     FIFO empty
    r_wframe_inc,               // [5]     write frame increment
    rc_wframe_index,            // [4:3]   write frame index
    1'b0,                       // [2]
    state_write                 // [1:0]   write FSM state
};

// dbg_rd[15:0] â€? read channel internal state
assign dbg_rd = {
    4'b0,                       // [15:12]
    r_rframe_inc,               // [11]
    read_ddr_init_flag,         // [10]
    rc_rframe_index,            // [9:8]   read frame index
    6'b0,                       // [7:2]
    rd_state                    // [1:0]   read FSM state
};

endmodule
