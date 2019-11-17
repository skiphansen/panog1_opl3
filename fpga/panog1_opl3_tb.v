`timescale 1 ns/1 ps

`define OPL3 1

module test;
    reg tb_clk;
    reg tb_reset;

    parameter CLK_HALF_PERIOD = 5;
    parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

    pano_top_tb DUT(
        .CLK_OSC(tb_clk),
        .PB(tb_reset)
    );

    always #CLK_HALF_PERIOD tb_clk = !tb_clk;

    task reset();
        begin
            tb_reset <= 1;
            #(10 * CLK_PERIOD); // DCM_SP needs at least 3 clock periods
            tb_reset <= 0;
        end
    endtask

    initial begin
        tb_clk <= 0;
        tb_reset <= 1;

        #CLK_PERIOD;

        reset();

        #(640*480*5 * CLK_PERIOD);
    end

endmodule

module pano_top_tb (
    // Global Clock Input
    input wire CLK_OSC,
    input wire PB,

    // WM8750 Codec
    output wire AUDIO_MCLK,
    output wire AUDIO_BCLK,
    output wire AUDIO_DACDATA,
    output wire AUDIO_DACLRCK,
    input  wire AUDIO_ADCDATA,
    output wire AUDIO_ADCLRCK,
    output wire AUDIO_SCL,
    inout  wire AUDIO_SDA
    );
    
    // ----------------------------------------------------------------------
    // Clocking
    wire clk_100;
    wire clk_25;
    wire clk_rv = clk_100;
    reg rst_rv_;
    
    IBUFG ibufg_clk_100 (
        .O(clk_100),
        .I(CLK_OSC)
    );
    
    reg [1:0] div4;
    always @(posedge clk_100)
    begin
        div4 <= div4 + 1;
        if (PB) begin
            div4 <= 2'b0;
        end
    end

    assign clk_25 = div4[1];

    wire [3:0] mem_wstrb;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire signed [15:0] opl2_channel_a;
    wire signed [15:0] opl2_channel_b;
`ifdef OPL3
    wire signed [15:0] opl2_channel_c;
    wire signed [15:0] opl2_channel_d;
`endif
    wire opl3_sample_clk;
    wire audio_bclk;

    // ----------------------------------------------------------------------
    
    // PicoRV32
    
    // Memory Map
    // 03000000 - 03000100 GPIO          See description below
    // 03000800 - 03000fff OPL2/OPL3     (2K)
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
    wire la_addr_in_opl3 = (mem_la_addr >= 32'h03000800) && (mem_la_addr < 32'h03000fff);
    wire la_addr_in_ram = (mem_la_addr >= 32'h0E000000) && (mem_la_addr < 32'h0E001000);
    
    reg addr_in_ram;
    reg addr_in_opl3;
    reg addr_in_gpio;
    
    always@(posedge clk_rv) begin
        addr_in_gpio <= la_addr_in_gpio;
        addr_in_ram <= la_addr_in_ram;
        addr_in_opl3 <= la_addr_in_opl3;
    end
    
    wire gpio_valid = (mem_valid) && (addr_in_gpio);
    wire ram_valid = (mem_valid) && (!mem_ready) && (addr_in_ram);
    wire opl3_valid = (mem_valid) && (addr_in_opl3);
    wire general_valid = mem_valid && !mem_ready;
    
    reg default_ready;
    
    always @(posedge clk_rv) begin
        default_ready <= general_valid;
    end
    
    wire uart_ready;
    assign mem_ready = default_ready;
    
    reg mem_valid_last;
    always @(posedge clk_rv) begin
        mem_valid_last <= mem_valid;
        if (mem_valid && !mem_valid_last && !(ram_valid || opl3_valid || gpio_valid))
            cpu_irq <= 1'b1;
        //else
        //    cpu_irq <= 1'b0;
        if (!rst_rv_)
            cpu_irq <= 1'b0;
    end
    
    
    reg opl3_data_rdy;
    reg opl3_data_ovfl;
    reg opl3_last_sample_clk;
    reg [31:0] gpio_rdata;
    
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
             if (mem_wstrb == 0) begin
                case (mem_addr[5:2])
                    4'd2: begin
                        gpio_rdata <= {opl2_channel_a, opl2_channel_b};
                        opl3_data_rdy <= 0;
                        opl3_data_ovfl <= 0;
                    end
                    4'hc: gpio_rdata <= {30'd0, opl3_data_ovfl, opl3_data_rdy};
                endcase
             end
         if (!rst_rv_) begin
            gpio_rdata <= 0;
            opl3_data_rdy <= 0;
            opl3_data_ovfl <= 0;
            opl3_last_sample_clk <= 0;
        end
    end
        
    reg rst_rv_pre;
    reg [5:0] pb_rst_counter;

    always @(posedge CLK_OSC)
    begin
        if (pb_rst_counter == 63)
            rst_rv_pre <= 0;
        else
            pb_rst_counter <= pb_rst_counter + 1;
        if (PB) begin
            rst_rv_pre <= 1;
            pb_rst_counter <= 6'd0;
        end
    end

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
    wire bclk;

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
      .sample_clk_128(bclk)
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
    
    
    assign mem_rdata = 
        addr_in_ram ? ram_rdata : (
        addr_in_gpio ? gpio_rdata : (
        32'hFFFFFFFF));

// Audio codec
    audio codec_interface (
        .clk25(clk_25),
        .reset25(!rst_rv_),
        .audio_bclk(audio_bclk),
        .audio_dacdat(AUDIO_DACDATA),
        .audio_daclrc(AUDIO_DACLRCK),
        .audio_adcdat(AUDIO_ADCDATA),
        .audio_adclrc(AUDIO_ADCLRCK),
        .audio_right_sample(opl2_channel_a),
        .audio_left_sample(opl2_channel_b),
        .audio_sample_clk(opl3_sample_clk)
    );

    reg [8:0] debug_cnt;
    reg bclk_last;
    always@(posedge clk_25) begin
        if (!rst_rv_) begin
            debug_cnt <= 0;
            bclk_last <= 0;
        end
        if(bclk_last != bclk) begin
            bclk_last <= bclk;
            if(bclk) begin
                if(AUDIO_DACLRCK) begin
                    debug_cnt <= 0;
                end else begin
                    debug_cnt <= debug_cnt + 1;
                end
            end
        end
     end
    
endmodule

