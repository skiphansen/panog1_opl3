
module audio(
    input wire  clk25,
    input wire  reset25_,

    output wire audio_mclk,
    output wire audio_bclk,
    output reg  audio_dacdat,
    output reg  audio_daclrc,
    input  wire audio_adcdat,
    output reg  audio_adclrc,
    input  wire [15:0] audio_right_sample,
    input  wire [15:0] audio_left_sample
    );

// Mclk = 25.00 Mhz 
// (ideally should have been 49715.90 * 250 * 2 = 24.86 but we hope it's close enough
// DSP Mode, mode B, LRP=1, Slave (Figure 23), 16 bits
//    { WM8750_AUDIO_INTFC_ADDR,
//          (0<<7) |    // BCLKINV: BCLK not inverted
//          (0<<6) |    // MS     : Slave mode
//          (0<<5) |    // LRSWAP : No L/R swap
//          (1<<4) |    // LRP    : DSP mode B: MSB on first clock cycle
//          (0<<2) |    // WL     : 16 bits
//          (3<<0) },   // FORMAT : DSP mode

    assign audio_mclk = clk25;

    // In USB mode, BCLK = MCLK
    assign audio_bclk = clk25;

    reg signed [15:0] sample_left, sample_right;
    reg [31:0] sample;
    reg [8:0]  bit_cntr, bit_cntr_nxt;
    reg [15:0] phase_cntr, phase_cntr_nxt;
    reg audio_daclrc_nxt, audio_dacdat_nxt;
    reg audio_adclrc_nxt;

    //localparam max_bit_cntr = 12288/48;     // 48KHz
    localparam max_bit_cntr = 255;
    
    always @*
    begin
        bit_cntr_nxt    = bit_cntr;
        phase_cntr_nxt  = phase_cntr;
        if (bit_cntr_nxt == 0) begin
            sample_left  = audio_left_sample;
            sample_right = audio_right_sample;
            sample = { sample_left, sample_right };
        end
        bit_cntr_nxt    = bit_cntr + 1;

        audio_daclrc_nxt    = (bit_cntr == 0);
        audio_dacdat_nxt    = |bit_cntr[8:5] ? 1'b0 : sample[~bit_cntr[4:0]];

        audio_adclrc_nxt   = (bit_cntr == 0);
    end

    always @(posedge clk25) 
    begin
        bit_cntr        <= bit_cntr_nxt;
        phase_cntr      <= phase_cntr_nxt;
        audio_daclrc    <= audio_daclrc_nxt;
        audio_dacdat    <= audio_dacdat_nxt;
        audio_adclrc    <= audio_adclrc_nxt;

        if (!reset25_) begin
            bit_cntr        <= 0;
            phase_cntr      <= 0;
            audio_daclrc    <= 1'b0;
            audio_dacdat    <= 1'b0;
            audio_adclrc    <= 1'b0;
        end
    end

endmodule

