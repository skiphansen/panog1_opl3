
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

// The sampling rate for real opl3 is 14.31818MHz/288 = 49715.2777.
// The Wolfson codec supports sample rates of 8kHz, 11.025kHz, 12kHz,
// 16kHz, 22.05kHz, 24kHz, 32kHz, 44.1kHz, 48kHz, 88.2kHz and 96kHz.
// The codec will be configured for the closest available sampling rate 
// of 48 Khz.
// 
// The codec requires a MCLK that is a multiple of the sampling rate(fs).  
// When using a 48Khz sampling rate the choices are 250fs, 256fs or 384fs.
// 
// Considering the above and after much experimentation it was decided to
// use a sampling rate of 50 Khz (25 MHz/500) which is 57% faster than ideal.
// MCLK and BCLK are 250fs (25 Mhz / 2).

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

