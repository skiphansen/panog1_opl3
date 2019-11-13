`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// panog1_opl3 top level 
// Copyright (C) 2019  Skip Hansen
//
// This file is derived from Verilogboy project:
// Copyright (C) 2019  Wenting Zhang <zephray@outlook.com>
////////////////////////////////////////////////////////////////////////////////

`define OPL3 1

module pano_top(
    // Global Clock Input
    input wire CLK_OSC,
    
    // Power LED
    output wire LED_RED,
    output wire LED_GREEN,
    output wire LED_BLUE,
    
    // Push Button
    input  wire PB,

    // SPI Flash
    output wire SPI_CS_B,
    output wire SPI_SCK,
    output wire SPI_MOSI,
    input  wire SPI_MISO,

    // WM8750 Codec
    output wire AUDIO_MCLK,
    output wire AUDIO_BCLK,
    output wire AUDIO_DACDATA,
    output wire AUDIO_DACLRCK,
    input  wire AUDIO_ADCDATA,
    output wire AUDIO_ADCLRCK,
    inout  wire AUDIO_SCL,
    inout  wire AUDIO_SDA,

    // LPDDR SDRAM
    output wire [11:0] LPDDR_A,
    output wire LPDDR_CK_P,
    output wire LPDDR_CK_N,
    output wire LPDDR_CKE,
    output wire LPDDR_WE_B,
    output wire LPDDR_CAS_B,
    output wire LPDDR_RAS_B,
    output wire [3:0] LPDDR_DM,
    output wire [1:0] LPDDR_BA,
    inout  wire [31:0] LPDDR_DQ,
    inout  wire [3:0] LPDDR_DQS,

    // VGA
    output wire VGA_CLK,
    output wire VGA_VSYNC,
    output wire VGA_HSYNC,
    output wire VGA_BLANK_B,
    inout  wire VGA_SCL,
    inout  wire VGA_SDA,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B,

    // USB
    output wire USB_CLKIN,
    output wire USB_RESET_B,
    output wire USB_CS_B,
    output wire USB_RD_B,
    output wire USB_WR_B,
    input  wire USB_IRQ,
    output wire [17:1] USB_A,
    inout  wire [15:0] USB_D,
    
    // USB HUB
    output wire USB_HUB_CLKIN,
    output wire USB_HUB_RESET_B
    );
    
    // ----------------------------------------------------------------------
    // Clocking
    wire GND_BIT;
    wire clk_100_in;       // On-board 100M clock source 
    wire clk_12_raw;       // 12MHz for USB controller and codec
    wire clk_12;
    wire clk_24_raw;       // 24MHz for on-board USB hub
    wire clk_24;
    wire clk_100_raw;      // 100MHz for PicoRV32 and LPDDR controller
    wire clk_100;
    wire clk_100_90_raw;
    wire clk_100_90;
    wire clk_100_180_raw;
    wire clk_100_180;
    wire clk_25_in;        // 25MHz clock divided from 100MHz for VGA
    wire clk_25_raw;
    wire clk_25;
    wire clk_rv = clk_100;
    wire clk_vga = clk_25;
    wire dcm_locked_24;
    wire dcm_locked_12;
    wire rst_12 = !dcm_locked_12;
    reg rst_rv_;
    assign GND_BIT = 0;
    
    IBUFG ibufg_clk_100 (
        .O(clk_100_in),
        .I(CLK_OSC)
    );
    
// USB 24 Mhz clock (100 / 25 * 6)
    DCM_SP #(
        .CLKFX_DIVIDE(25),   
        .CLKFX_MULTIPLY(6),
        .CLKIN_DIVIDE_BY_2("FALSE"),          // TRUE/FALSE to enable CLKIN divide by two feature
        .CLKIN_PERIOD(10.0),                  // 100MHz input
        .CLK_FEEDBACK("1X"),
        .CLKOUT_PHASE_SHIFT("NONE"),
        .CLKDV_DIVIDE(4.0),
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
        .DLL_FREQUENCY_MODE("LOW"),           // HIGH or LOW frequency mode for DLL
        .DUTY_CYCLE_CORRECTION("TRUE"),       // Duty cycle correction, TRUE or FALSE
        .PHASE_SHIFT(0),                      // Amount of fixed phase shift from -255 to 255
        .STARTUP_WAIT("FALSE")                // Delay configuration DONE until DCM LOCK, TRUE/FALSE
    ) dcm_24 (
        .CLKIN(clk_100_in),                   // Clock input (from IBUFG, BUFG or DCM)
        .CLK0(clk_100_raw),
        .CLK90(clk_100_90_raw),
        .CLK180(clk_100_180_raw),
        .CLKFX(clk_24_raw),                    // DCM CLK synthesis out (M/D)
        .CLKDV(clk_25_in),
        .CLKFB(clk_100),                      // DCM clock feedback
        .PSCLK(1'b0),                         // Dynamic phase adjust clock input
        .PSEN(1'b0),                          // Dynamic phase adjust enable input
        .PSINCDEC(1'b0),                      // Dynamic phase adjust increment/decrement
        .RST(PB),                             // DCM asynchronous reset input
        .LOCKED(dcm_locked_24)
    );
    
    DCM_SP #(
        .CLKFX_DIVIDE(25),   
        .CLKFX_MULTIPLY(12),
        .CLKIN_DIVIDE_BY_2("FALSE"),          // TRUE/FALSE to enable CLKIN divide by two feature
        .CLKIN_PERIOD(40.0),                  // 25 MHz
        .CLK_FEEDBACK("1X"),
        .CLKOUT_PHASE_SHIFT("NONE"),
        .CLKDV_DIVIDE(6.0),
        .DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
        .DLL_FREQUENCY_MODE("LOW"),           // HIGH or LOW frequency mode for DLL
        .DUTY_CYCLE_CORRECTION("TRUE"),       // Duty cycle correction, TRUE or FALSE
        .PHASE_SHIFT(0),                      // Amount of fixed phase shift from -255 to 255
        .STARTUP_WAIT("FALSE")                // Delay configuration DONE until DCM LOCK, TRUE/FALSE
    ) dcm_12 (
        .CLKIN(clk_25_in),                    // Clock input (from IBUFG, BUFG or DCM)
        .CLK0(clk_25_raw),
        .CLKFX(clk_12_raw),                   // DCM CLK synthesis out (M/D)
        .CLKFB(clk_25),                       // DCM clock feedback
        .CLKDV(),
        .PSCLK(1'b0),                         // Dynamic phase adjust clock input
        .PSEN(1'b0),                          // Dynamic phase adjust enable input
        .PSINCDEC(1'b0),                      // Dynamic phase adjust increment/decrement
        .RST(!rst_rv_),                       // DCM asynchronous reset input
        .LOCKED(dcm_locked_12)
    );

    assign clk_24 = clk_24_raw;
    assign clk_12 = clk_12_raw;
    
    BUFG bufg_clk_100 (
        .O(clk_100),
        .I(clk_100_raw)
    );
    
    BUFG bufg_clk_100_90 (
        .O(clk_100_90),
        .I(clk_100_90_raw)
    );
    
    BUFG bufg_clk_100_180 (
        .O(clk_100_180),
        .I(clk_100_180_raw)
    );
 
    BUFG bufg_clk_25 (
        .O(clk_25),
        .I(clk_25_raw)
    );
    
    wire [3:0] mem_wstrb;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;

    // ----------------------------------------------------------------------
    // MIG
    
    wire       wait_200us;
    wire       sys_rst;
    wire       sys_rst90;
    wire       sys_rst180;
    wire [4:0] delay_sel_val_det;
    reg  [4:0] delay_sel_val;
    
    mig_infrastructure_top mig_infrastructure_top(
        .reset_in_n(!PB),
        .dcm_lock(dcm_locked_24),
        .delay_sel_val1_val(delay_sel_val_det),
        .sys_rst_val(sys_rst),
        .sys_rst90_val(sys_rst90),
        .sys_rst180_val(sys_rst180),
        .wait_200us_rout(wait_200us),
        .clk_int(clk_100),
        .clk90_int(clk_100_90)
    );
    
    wire rst_dqs_div_in;
    
    wire [24:0] ddr_addr;
    wire [31:0] ddr_wdata;
    wire [31:0] ddr_rdata;
    wire [3:0] ddr_wstrb;
    wire ddr_valid;
    wire ddr_ready;
    
    wire auto_ref_req;
    wire [63:0] user_input_data;
    wire [63:0] user_output_data;
    wire user_data_valid;
    wire [22:0] user_input_address;
    wire [2:0] user_command_register;
    wire user_cmd_ack;
    wire [7:0] user_data_mask;
    wire burst_done;
    wire init_done;
    wire ar_done;
    
    mig_top_0 mig_top_0(
        .auto_ref_req          (auto_ref_req),
        .wait_200us            (wait_200us),
        .rst_dqs_div_in        (rst_dqs_div_in),
        .rst_dqs_div_out       (rst_dqs_div_in),
        .user_input_data       (user_input_data),
        .user_output_data      (user_output_data),
        .user_data_valid       (user_data_valid),
        .user_input_address    (user_input_address),
        .user_command_register (user_command_register),
        .user_cmd_ack          (user_cmd_ack),
        .user_data_mask        (user_data_mask),
        .burst_done            (burst_done),
        .init_val              (init_done),
        .ar_done               (ar_done),
        .ddr_dqs               (LPDDR_DQS),
        .ddr_dq                (LPDDR_DQ),
        .ddr_cke               (LPDDR_CKE),
        .ddr_cs_n              (),
        .ddr_ras_n             (LPDDR_RAS_B),
        .ddr_cas_n             (LPDDR_CAS_B),
        .ddr_we_n              (LPDDR_WE_B),
        .ddr_ba                (LPDDR_BA),
        .ddr_a                 (LPDDR_A),
        //.ddr_dm                (LPDDR_DM),
/*        .ddr_ck                (),
        .ddr_ck_n              (),*/

        .clk_int               (clk_100),
        .clk90_int             (clk_100_90),
        .delay_sel_val         (delay_sel_val),
        .sys_rst_val           (sys_rst),
        .sys_rst90_val         (sys_rst90),
        .sys_rst180_val        (sys_rst180)
    );

    // always valid... due to restriction of IO CLK routing capability of S3E
    assign LPDDR_DM[3:0] = 4'b0;

    mig_picorv_bridge mig_picorv_bridge(
        .clk0(clk_100),
        .clk90(clk_100_90),
        .sys_rst180(sys_rst180),
        .ddr_addr(ddr_addr),
        .ddr_wdata(ddr_wdata),
        .ddr_rdata(ddr_rdata),
        .ddr_wstrb(ddr_wstrb),
        .ddr_valid(ddr_valid),
        .ddr_ready(ddr_ready),
        .auto_refresh_req(auto_ref_req),
        .user_input_data(user_input_data),
        .user_output_data(user_output_data),
        .user_data_valid(user_data_valid),
        .user_input_address(user_input_address),
        .user_command_register(user_command_register),
        .user_cmd_ack(user_cmd_ack),
        .user_data_mask(user_data_mask),
        .burst_done(burst_done),
        .init_done(init_done),
        .ar_done(ar_done)
    );
    
    assign LPDDR_CK_P = clk_100;
    assign LPDDR_CK_N = clk_100_180;
        
    
    // ----------------------------------------------------------------------
    // USB
    
    wire [18:0] usb_addr;
    wire [31:0] usb_wdata;
    wire [31:0] usb_rdata;
    wire [3:0] usb_wstrb;
    wire usb_valid;
    wire usb_ready;
    wire [15:0] usb_din;
    wire [15:0] usb_dout;
    wire bus_dir;
        
    assign USB_CLKIN = clk_12;
    assign USB_HUB_CLKIN = clk_24;
    
    usb_picorv_bridge usb_picorv_bridge(
        .clk(clk_rv),
        .rst(!rst_rv_),
        .sys_addr(usb_addr),
        .sys_rdata(usb_rdata),
        .sys_wdata(usb_wdata),
        .sys_wstrb(usb_wstrb),
        .sys_valid(usb_valid),
        .sys_ready(usb_ready),
        .usb_csn(USB_CS_B),
        .usb_rdn(USB_RD_B),
        .usb_wrn(USB_WR_B),
        .usb_a(USB_A),
        .usb_dout(usb_dout),
        .usb_din(usb_din),
        .bus_dir(bus_dir)
    );
    
    // Tristate bus
    // 0 - output, 1 - input 
    assign USB_D = (bus_dir) ? (16'bz) : (usb_dout);
    assign usb_din = USB_D;
    
    // ----------------------------------------------------------------------
    
    // PicoRV32
    
    // Memory Map
    // 03000000 - 03000100 GPIO          See description below
    // 03000100 - 03000100 UART          (4B)
    // 03000400 - 03000fff OPL2/OPL3     (2K)
    // 04000000 - 04080000 USB           (512KB)
    // 08000000 - 08000FFF Video RAM     (4KB)
    // 0C000000 - 0DFFFFFF LPDDR SDRAM   (32MB)
    // 0E000000 - 0E000fff Internal RAM  (4KB w/ echo)
    parameter integer MEM_WORDS = 1024;
    parameter [31:0] STACKADDR = 32'h0e000ff0;
    parameter [31:0] PROGADDR_RESET = 32'h0e000000;
    parameter [31:0] PROGADDR_IRQ = 32'h0e000ff4;
    
    wire mem_valid;
    wire mem_instr;
    wire mem_ready;
    wire [31:0] mem_rdata;
    wire [31:0] mem_la_addr;
    
    reg cpu_irq;
    
    wire la_addr_in_gpio = (mem_la_addr >= 32'h03000000) && (mem_la_addr < 32'h03000100);
    wire la_addr_in_uart = (mem_la_addr == 32'h03000100);
    wire la_addr_in_opl3 = (mem_la_addr >= 32'h03000400) && (mem_la_addr < 32'h03001000);
    wire la_addr_in_usb = (mem_la_addr >= 32'h04000000) && (mem_la_addr < 32'h04080000);
    wire la_addr_in_vram = (mem_la_addr >= 32'h08000000) && (mem_la_addr < 32'h08004000);
    wire la_addr_in_ddr = (mem_la_addr >= 32'h0C000000) && (mem_la_addr < 32'h0E000000);
    wire la_addr_in_ram = (mem_la_addr >= 32'h0E000000) && (mem_la_addr < 32'h0E001000);
    
    reg addr_in_ram;
    reg addr_in_vram;
    reg addr_in_gpio;
    reg addr_in_uart;
    reg addr_in_opl3;
    reg addr_in_usb;
    reg addr_in_ddr;
    
    always@(posedge clk_rv) begin
        addr_in_ram <= la_addr_in_ram;
        addr_in_vram <= la_addr_in_vram;
        addr_in_gpio <= la_addr_in_gpio;
        addr_in_uart <= la_addr_in_uart;
        addr_in_opl3 <= la_addr_in_opl3;
        addr_in_usb <= la_addr_in_usb;
        addr_in_ddr <= la_addr_in_ddr;
    end
    
    wire ram_valid = (mem_valid) && (!mem_ready) && (addr_in_ram);
    wire vram_valid = (mem_valid) && (!mem_ready) && (addr_in_vram);
    wire gpio_valid = (mem_valid) && (addr_in_gpio);
    wire uart_valid = (mem_valid) && (addr_in_uart);
    wire opl3_valid = (mem_valid) && (addr_in_opl3);
    assign ddr_valid = (mem_valid) && (addr_in_ddr);
    assign usb_valid = (mem_valid) && (addr_in_usb);
    wire general_valid = (mem_valid) && (!mem_ready) && (!addr_in_ddr) && (!addr_in_uart) && (!addr_in_usb);
    
    reg default_ready;
    
    always @(posedge clk_rv) begin
        default_ready <= general_valid;
    end
    
    wire uart_ready;
    assign mem_ready = uart_ready || ddr_ready || usb_ready || default_ready;
    
    reg mem_valid_last;
    always @(posedge clk_rv) begin
        mem_valid_last <= mem_valid;
        if (mem_valid && !mem_valid_last && !(ram_valid || vram_valid || gpio_valid || usb_valid || uart_valid || ddr_valid || opl3_valid))
            cpu_irq <= 1'b1;
        //else
        //    cpu_irq <= 1'b0;
        if (!rst_rv_)
            cpu_irq <= 1'b0;
    end
    
    assign ddr_addr = mem_addr[24:0];
    assign ddr_wstrb = mem_wstrb;
    assign ddr_wdata = mem_wdata;
    
    assign usb_addr = mem_addr[18:0];
    assign usb_wstrb = mem_wstrb;
    assign usb_wdata = mem_wdata;
    
    wire rst_rv_pre = !init_done;
    reg [3:0] rst_counter;
    
    always @(posedge clk_rv)
    begin
        if (rst_counter == 4'd15)
            rst_rv_ <= 1;
        else
            rst_counter <= rst_counter + 1;
        if (rst_rv_pre) begin
            rst_rv_ <= 0;
            rst_counter <= 4'd0;
        end
    end
    
    picorv32 #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(0),
        .ENABLE_IRQ_TIMER(0),
//      .COMPRESSED_ISA(1), Operation with cache is VERY flaky when defined.
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .MASKED_IRQ(32'hfffffffe),
        .LATCHED_IRQ(32'hffffffff)
    ) cpu (
        .clk(clk_rv),
        .resetn(rst_rv_),
        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_la_addr(mem_la_addr),
        .irq({31'b0, cpu_irq})
    );
        
    wire signed [15:0] opl2_channel_a;
    wire signed [15:0] opl2_channel_b;
`ifdef OPL3
    wire signed [15:0] opl2_channel_c;
    wire signed [15:0] opl2_channel_d;
`endif
    wire opl3_sample_clk;
    wire audio_bclk;

`ifdef OPL3
    // OPL3
    opl3 opl3(
      .clk(clk_100),
      .clk_opl3(clk_25),
      .reset(!rst_rv_),
      .opl3_we(opl3_valid),
      .opl3_data(mem_wdata[7:0]),
      .opl3_adr(mem_addr[10:2]),
      .channel_a(opl2_channel_a),
      .channel_b(opl2_channel_b),
      .channel_c(opl2_channel_c),
      .channel_d(opl2_channel_d),
      .sample_clk(opl3_sample_clk),
      .sample_clk_128(audio_bclk)
    );
`else
    // OPL2
    opl2 opl2(
      .clk(clk_100),
      .OPL2_clk(clk_25),
      .reset(!rst_rv_),
      .opl2_we(opl3_valid),
      .opl2_data(mem_wdata[7:0]),
      .opl2_adr(mem_addr[9:2]),
      .channel_a(opl2_channel_a),
      .channel_b(opl2_channel_b),
      .kon(),
      .sample_clk(opl3_sample_clk),
      .sample_clk_128(audio_bclk)
    );
`endif

    // Internal RAM & Boot ROM
    wire [31:0] ram_rdata;
    picosoc_mem #(
        .WORDS(MEM_WORDS)
    ) memory (
        .clk(clk_rv),
        .wen(ram_valid ? mem_wstrb : 4'b0),
        .addr({12'b0, mem_addr[11:2]}),
        .wdata(mem_wdata),
        .rdata(ram_rdata)
    );
    
    // UART
    // ----------------------------------------------------------------------
    
    simple_uart simple_uart(
        .clk(clk_rv),
        .rst(!rst_rv_),
        .wstrb(uart_valid),
        .ready(uart_ready),
        .dat(mem_wdata[7:0]),
        .txd(LED_BLUE)
    );


    // GPIO
    // ----------------------------------------------------------------------
    
    // 03000000 (0x0)  - R:  delay_sel_det / W: delay_sel_val
    // 03000004 (0x1)  - RW:  leds (0xb0: red, b1: green, b2: blue)
    // 03000008 (0x2)  - R: Opl3 output
    // 0300000c (0x3)  - W: spi_cs_n
    // 03000010 (0x4)  - W: spi_clk
    // 03000014 (0x5)  - W: spi_do
    // 03000018 (0x6)  - R: spi_di
    // 0300001c (0x7)  - W:  usb_rst_n
    // 03000020 (0x8)  - RW: Wolfson i2c_scl
    // 03000024 (0x9)  - RW: Wolfson i2c_sda
    // 03000028 (0xa)  - W:  VGA DDC i2c_scl
    // 0300002c (0xb)  - RW: VGA DDC i2c_sda
    // 03000030 (0xc)  - R: Opl3 status
    
    reg [31:0] gpio_rdata;
    reg led_green;
    reg led_red;
    reg spi_csn;
    reg spi_clk;
    reg led_blue;
    reg spi_do;
    wire spi_di;
    reg usb_rstn;
    reg codec_i2c_scl;
    reg codec_i2c_sda;
    reg vga_i2c_scl;
    reg vga_i2c_sda;
    reg opl3_data_rdy;
    reg opl3_data_ovfl;
    reg opl3_last_sample_clk;
    
    always@(posedge clk_rv) begin
        if (opl3_last_sample_clk != opl3_sample_clk) begin
            opl3_last_sample_clk <= opl3_sample_clk;
            if (opl3_sample_clk) begin
                if(opl3_data_rdy) begin
                    opl3_data_ovfl <= 1;
                 end
                 opl3_data_rdy <= 1;
            end
        end

        if (gpio_valid)
             if (mem_wstrb != 0) begin
                case (mem_addr[5:2])
                    4'd0: delay_sel_val[4:0] <= mem_wdata[4:0];
                    4'd1: begin
                        led_red <= mem_wdata[0];
                        led_green <= mem_wdata[1];
                        led_blue <= mem_wdata[2];
                    end
                    4'd3: spi_csn <= mem_wdata[0];
                    4'd4: spi_clk <= mem_wdata[0];
                    4'd5: spi_do <= mem_wdata[0];
                    4'd7: usb_rstn <= mem_wdata[0];
                    4'd8: codec_i2c_scl <= mem_wdata[0];
                    4'd9: codec_i2c_sda <= mem_wdata[0];
                    4'ha: vga_i2c_scl <= mem_wdata[0];
                    4'hb: vga_i2c_sda <= mem_wdata[0];
                endcase
             end
             else begin
                case (mem_addr[5:2])
                    4'd0: gpio_rdata <= {27'd0, delay_sel_val};
                    4'd1: gpio_rdata <= {29'd0, led_blue, led_green, led_red};
                    4'd2: begin
                        gpio_rdata <= {opl2_channel_a, opl2_channel_b};
                        opl3_data_rdy <= 0;
                        opl3_data_ovfl <= 0;
                    end
                    4'd6: gpio_rdata <= {31'd0, spi_di};
                    4'd8: gpio_rdata <= {31'd0, AUDIO_SCL};
                    4'd9: gpio_rdata <= {31'd0, AUDIO_SDA};
                    4'hb: gpio_rdata <= {31'd0, VGA_SDA};
                    4'hc: gpio_rdata <= {30'd0, opl3_data_ovfl, opl3_data_rdy};
                endcase
             end
         if (!rst_rv_) begin
            delay_sel_val[4:0] <= delay_sel_val_det[4:0];
            led_green <= 0;
            led_red <= 0;
            led_blue <= 0;
            opl3_last_sample_clk <= 0;
            opl3_data_rdy <= 0;
            opl3_data_ovfl <= 0;
        end
    end
    
        
    assign SPI_CS_B = spi_csn;
    assign SPI_SCK = spi_clk;
    assign SPI_MOSI = spi_do;
    assign spi_di = SPI_MISO;
    assign AUDIO_SCL = (codec_i2c_scl) ? 1'bz : 1'b0;
    assign AUDIO_SDA = (codec_i2c_sda) ? 1'bz : 1'b0;
    assign USB_RESET_B = usb_rstn;
    assign USB_HUB_RESET_B = usb_rstn;
    
    assign mem_rdata = 
        addr_in_ram ? ram_rdata : (
        addr_in_ddr ? ddr_rdata : (
        addr_in_gpio ? gpio_rdata : (
        addr_in_usb ? usb_rdata : (
        32'hFFFFFFFF))));

    // ----------------------------------------------------------------------
    // VGA Controller
    wire vga_hs;
    wire vga_vs;
    wire [6:0] dbg_x;
    wire [4:0] dbg_y;
    wire [6:0] dbg_char;
    wire dbg_clk;
    
    vga_mixer vga_mixer(
        .clk(clk_vga),
        .rst(rst_12),
        // GameBoy Image Input
        .gb_hs(1'b0),
        .gb_vs(1'b0),
        .gb_pclk(1'b0),
        .gb_pdat(1'b0),
        .gb_valid(1'b0),
        .gb_en(1'b0),
        // Debugger Char Input
        .dbg_x(dbg_x),
        .dbg_y(dbg_y),
        .dbg_char(dbg_char),
        .dbg_sync(dbg_clk),
        .font_fg_color(24'h00ff00),
        .font_bg_color(24'd0),
        // VGA signal Output
        .vga_hs(vga_hs),
        .vga_vs(vga_vs),
        .vga_blank(VGA_BLANK_B),
        .vga_r(VGA_R),
        .vga_g(VGA_G),
        .vga_b(VGA_B),
        .hold(1'b0)
    );
    
    assign VGA_CLK = ~clk_vga;
    assign VGA_VSYNC = vga_vs;
    assign VGA_HSYNC = vga_hs;
    
    assign VGA_SDA = 1'bz;
    //assign VGA_SCL = 1'bz;
    
    wire vram_wea = (vram_valid && (mem_wstrb != 0)) ? 1'b1 : 1'b0;
    
    wire [7:0] vram_dout;
    wire [11:0] rd_addr = dbg_y * 80 + dbg_x;
    dualport_ram vram(
        .clka(clk_rv),
        .wea(vram_wea),
        .addra(mem_addr[13:2]),
        .dina(mem_wdata[7:0]),
        .clkb(!clk_vga),
        .addrb(rd_addr[11:0]),
        .doutb(vram_dout)
    );
    assign dbg_char = vram_dout[6:0];

    wire signed [18:0] left_pre, right_pre;
    wire signed [15:0] left, right;

`ifdef OPL3
    assign left_pre = opl2_channel_a + opl2_channel_c;
    assign right_pre = opl2_channel_b + opl2_channel_d;
`else
    assign left_pre = opl2_channel_a<<<1;
    assign right_pre = opl2_channel_b<<<1;
`endif

    assign left = left_pre > 32767 ? 16'hffff : left_pre < -32768 ? 16'h0000 : left_pre[15:0];

    assign right = right_pre > 32767 ? 16'hffff : right_pre < -32768 ? 16'h0000: right_pre[15:0];

// Audio codec
    audio codec_interface (
        .clk25(clk_25),
        .reset25(!rst_rv_),
        .audio_bclk(audio_bclk),
        .audio_dacdat(AUDIO_DACDATA),
        .audio_daclrc(AUDIO_DACLRCK),
        .audio_adcdat(AUDIO_ADCDATA),
        .audio_adclrc(AUDIO_ADCLRCK),
        .audio_right_sample(right),
        .audio_left_sample(left),
        .audio_sample_clk(opl3_sample_clk)
    );

    assign AUDIO_BCLK = audio_bclk;
    assign AUDIO_MCLK = audio_bclk;

    
// synthesis translate_off
    always @(posedge clk_rv) begin
        if (vram_wea) begin
            $display("%c", mem_wdata[7:0]);
        end
    end
// synthesis translate_on
    
    // ----------------------------------------------------------------------
    // LED 
//    assign LED_BLUE = !led_blue;
    assign LED_RED = !led_red;
    assign LED_GREEN = !led_green;
    
endmodule

