
module audio(
    input wire  clk25,
    input wire  reset25,

    input wire audio_bclk,
    output reg  audio_dacdat,
    output reg  audio_daclrc,
    input  wire audio_adcdat,
    output reg  audio_adclrc,
    input  wire [15:0] audio_right_sample,
    input  wire [15:0] audio_left_sample,
    input  wire audio_sample_clk
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


// There are 503 25 Mhz clocks per sample for a sampling rate 49701.79 hz.
// We need 250 bclk cycles during this time for the Codec.
// bclk is clk25 / 2 so each bclk each bclk is 2 clocks except the high
// period is 4 cycles
// 


    reg [5:0]  bit_cntr;
    reg last_audio_sample_clk;
    reg start_cycle;
    reg last_bclk;

    always @(posedge clk25) 
    begin
        last_bclk <= audio_bclk;
        if (last_audio_sample_clk != audio_sample_clk) begin
            last_audio_sample_clk <= audio_sample_clk;
        // rising edge of sample clock, start new cycle
            if (audio_sample_clk) begin
                start_cycle <= 1;
            end
        end

        if(audio_bclk && !last_bclk) begin
        end
        else if(!audio_bclk && last_bclk) begin
            audio_daclrc    <= 0;
            if(start_cycle) begin
                start_cycle <= 0;
                bit_cntr     <= 1;
                audio_daclrc <= 1;
                audio_dacdat <= audio_left_sample[15];
            end
            else if (bit_cntr < 16) begin
                bit_cntr <= bit_cntr + 1;
                audio_dacdat <= audio_left_sample[~bit_cntr[3:0]];
            end
            else if (bit_cntr < 32) begin
                bit_cntr <= bit_cntr + 1;
                audio_dacdat <= audio_right_sample[~bit_cntr[3:0]];
            end
        end

        if (reset25) begin
            bit_cntr        <= 6'd32;
            audio_adclrc    <= 0;
            last_audio_sample_clk <= 0;
            start_cycle <= 0;
            last_bclk <= 0;
        end
    end

endmodule

