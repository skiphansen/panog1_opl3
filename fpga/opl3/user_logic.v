
`uselib lib=unisims_ver
`uselib lib=proc_common_v3_00_a

module user_logic
(

  Bus2IP_Clk,                     // Bus to IP clock
  Bus2IP_Resetn,                  // Bus to IP reset
  Bus2IP_Data,                    // Bus to IP data bus
  Bus2IP_BE,                      // Bus to IP byte enables
  Bus2IP_RdCE,                    // Bus to IP read chip enable
  Bus2IP_WrCE,                    // Bus to IP write chip enable
  IP2Bus_Data,                    // IP to Bus data bus
  IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
  IP2Bus_Error,                   // IP to Bus error response
  OPL2_clk,
  Audio_left,                     // left channel output
  Audio_right,                    // right channel output
  Audio_int

);

parameter C_NUM_REG                      = 4;
parameter C_SLV_DWIDTH                   = 32;

input                                     Bus2IP_Clk;
input                                     Bus2IP_Resetn;
input      [C_SLV_DWIDTH-1 : 0]           Bus2IP_Data;
input      [C_SLV_DWIDTH/8-1 : 0]         Bus2IP_BE;
input      [C_NUM_REG-1 : 0]              Bus2IP_RdCE;
input      [C_NUM_REG-1 : 0]              Bus2IP_WrCE;
output     [C_SLV_DWIDTH-1 : 0]           IP2Bus_Data;
output                                    IP2Bus_RdAck;
output                                    IP2Bus_WrAck;
output                                    IP2Bus_Error;
input                                     OPL2_clk;
output                                    Audio_right;
output                                    Audio_left;
output                                    Audio_int;


//----------------------------------------------------------------------------
// Implementation
//----------------------------------------------------------------------------

  reg        [15 : 0]                       slv_reg0;
  reg        [7 : 0]                        slv_reg1;
  wire       [3 : 0]                        slv_reg_write_sel;
  wire       [3 : 0]                        slv_reg_read_sel;
  reg        [C_SLV_DWIDTH-1 : 0]           slv_ip2bus_data;
  wire                                      slv_read_ack;
  wire                                      slv_write_ack;
  integer                                   byte_index, bit_index;

  wire       [15:0]                         period;
  wire                                      sound_go, sound_int_en;
  wire                                      music_go, music_pause, music_int_en;
  wire                                      fifo_we;
  reg                                       fifo_we_d;
  wire                                      opl2_fifo_we;
  reg                                       opl2_fifo_we_d;
  wire       [31:0]                         fifo_din, fifo_dout, opl2_fifo_dout;
  wire                                      fifo_empty, fifo_half_full, fifo_full;
  wire                                      opl2_fifo_empty, opl2_fifo_half_full, opl2_fifo_full;
  wire                                      stop;
  reg        [15:0]                         counter;
  reg                                       fifo_rd;
  reg        [11:0]                         leftValue, rightValue;
  reg signed [15:0]                         fifo_left, fifo_right;
  wire signed [18:0]                        left_pre, right_pre;
  wire signed [15:0]                        opl2_channel_a;
  wire signed [15:0]                        opl2_channel_b;
  wire [15:0]                               left, right;

  reg [16:0]                                opl2_precounter;
  reg [15:0]                                opl2_counter;
  reg [15:0]                                opl2_delay;
  reg [7:0]                                 opl2_data;
  reg [7:0]                                 opl2_adr;
  reg                                       opl2_we;
  reg                                       opl2_fifo_paused;
  reg                                       opl2_fifo_rd;
  reg                                       opl2_fifo_valid;

  assign
    slv_reg_write_sel = Bus2IP_WrCE[3:0],
    slv_reg_read_sel  = Bus2IP_RdCE[3:0],
    slv_write_ack     = Bus2IP_WrCE[0] || Bus2IP_WrCE[1] || Bus2IP_WrCE[2] || Bus2IP_WrCE[3],
    slv_read_ack      = Bus2IP_RdCE[0] || Bus2IP_RdCE[1] || Bus2IP_RdCE[2] || Bus2IP_RdCE[3];

  always @( posedge Bus2IP_Clk )
    begin

      if ( Bus2IP_Resetn == 1'b0 )
        begin
          slv_reg0 <= 0;
          slv_reg1 <= 0;
        end
      else
        case ( slv_reg_write_sel )
          4'b1000 :
            for ( byte_index = 0; byte_index <= 1; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                slv_reg0[(byte_index*8) +: 8] <= Bus2IP_Data[(byte_index*8) +: 8];
          4'b0100 :
            for ( byte_index = 0; byte_index <= 0; byte_index = byte_index+1 )
              if ( Bus2IP_BE[byte_index] == 1 )
                slv_reg1[(byte_index*8) +: 8] <= Bus2IP_Data[(byte_index*8) +: 8];
          default :
            begin
              slv_reg0 <= slv_reg0;
              slv_reg1 <= slv_reg1;
            end
        endcase

    end

  always @ * begin
    case ( slv_reg_read_sel )
      4'b1000 : slv_ip2bus_data <= {16'd0, slv_reg0};
      4'b0100 : slv_ip2bus_data <= {24'd0, slv_reg1};
      4'b0010 : slv_ip2bus_data <= {26'd0, opl2_fifo_paused, opl2_fifo_half_full, opl2_fifo_full, 
                                           fifo_empty, fifo_half_full, fifo_full};
      4'b0001 : slv_ip2bus_data <= 32'd0;
      default : slv_ip2bus_data <= 0;
    endcase
  end

  assign IP2Bus_Data = (slv_read_ack == 1'b1) ? slv_ip2bus_data :  0 ;
  assign IP2Bus_WrAck = slv_write_ack;
  assign IP2Bus_RdAck = slv_read_ack;
  assign IP2Bus_Error = 0;

  assign fifo_we = (slv_reg_write_sel == 4'b0001) && (Bus2IP_BE[3:0] == 4'b1111);
  assign opl2_fifo_we = (slv_reg_write_sel == 4'b0010) && (Bus2IP_BE[3:0] == 4'b1111);
  assign fifo_din = Bus2IP_Data[31:0];
  assign period = slv_reg0[15:0];
  assign sound_go = slv_reg1[0];
  assign music_go = slv_reg1[1];
  assign music_pause = slv_reg1[2];
  assign sound_int_en = slv_reg1[3];
  assign music_int_en = slv_reg1[4];
  assign sound_stop = ~sound_go;
  assign music_stop = ~music_go;
  assign Audio_int = (~fifo_half_full & sound_int_en) |
                     (~opl2_fifo_half_full & music_int_en);

  always @(posedge Bus2IP_Clk) begin
    fifo_we_d <= fifo_we;
    opl2_fifo_we_d <= opl2_fifo_we;
  end
  
  syn_fifo sound_fifo(
    .clk(Bus2IP_Clk),
    .rst(sound_stop),
    .data_in(fifo_din),
    .wr_en(fifo_we & !fifo_we_d),
    .rd_en(fifo_rd),
    .data_out(fifo_dout),
    .empty(fifo_empty),
    .half_full(fifo_half_full),
    .full(fifo_full)
  );
  
  always @(posedge Bus2IP_Clk) begin
    if (sound_stop) begin
      counter <= 0;
      fifo_rd <= 0;
      fifo_left <= 0;
      fifo_right <= 0;
    end else begin
      if (counter == period) begin
        counter <= 0;
        fifo_rd <= 1;
      end else begin
        counter <= counter + 1;
        fifo_rd <= 0;
      end
      if (fifo_rd & !fifo_empty) begin
        fifo_left <= fifo_dout[15:0];
        fifo_right <= fifo_dout[31:16];
      end
    end
  end

  syn_fifo opl2_fifo(
    .clk(Bus2IP_Clk),
    .rst(music_stop),
    .data_in(fifo_din),
    .wr_en(opl2_fifo_we & !opl2_fifo_we_d),
    .rd_en(opl2_fifo_rd),
    .data_out(opl2_fifo_dout),
    .empty(opl2_fifo_empty),
    .half_full(opl2_fifo_half_full),
    .full(opl2_fifo_full)
  );

  always @(posedge Bus2IP_Clk) begin
    if (music_stop) begin
      opl2_precounter <= 17'd0;
      opl2_counter <= 16'd0;
      opl2_delay <= 16'd0;
      opl2_fifo_rd <= 1'b0;
      opl2_fifo_paused <= 1'b1;
      opl2_we <= 1'b0;
    end else begin
      opl2_we <= 1'b0;
      opl2_fifo_paused <= 1'b0;
      if (opl2_fifo_rd) begin
        opl2_we <= 1'b0;
        opl2_fifo_valid <= 1'b1;
        opl2_fifo_rd <= 1'b0;
      end else if (opl2_fifo_valid) begin
        opl2_fifo_valid <= 1'b0;
        opl2_precounter <= 17'd0;
        opl2_counter <= 16'd0;
        opl2_delay <= opl2_fifo_dout[31:16];
        opl2_data <= opl2_fifo_dout[7:0];
        opl2_adr <= opl2_fifo_dout[15:8];
        opl2_we <= 1'b1;
      end else if (opl2_counter == opl2_delay) begin
        opl2_fifo_rd <= ~music_pause & ~opl2_fifo_empty;
        opl2_fifo_paused <= music_pause;
      end else begin
        opl2_fifo_paused <= music_pause;
        opl2_precounter <= opl2_precounter + 1;
        if (opl2_precounter == 17'd99999) begin // 1 mS assuming 100 MHz system clock
          opl2_precounter <= 17'd0;
          opl2_counter <= opl2_counter + 1'b1;
        end
      end
    end
  end

  opl2 opl2(
    .clk(Bus2IP_Clk),
    .OPL2_clk(OPL2_clk),
    .reset(Bus2IP_Reset),
    .opl2_we(opl2_fifo_paused ? (opl2_fifo_we & !opl2_fifo_we_d) : opl2_we),
    .opl2_data(opl2_fifo_paused ? fifo_din[7:0] : opl2_data),
    .opl2_adr(opl2_fifo_paused ? fifo_din[15:8] : opl2_adr),
    .channel_a(opl2_channel_a),
    .channel_b(opl2_channel_b),
    .kon()
  );

  assign left_pre = fifo_left + (opl2_channel_a<<<4);
  assign left = left_pre > 32767 ? 16'hffff : left_pre < -32768 ? 16'h0000 : left_pre[15:0] ^ 16'h8000;
  
  assign right_pre = fifo_right + (opl2_channel_b<<<4);
  assign right = right_pre > 32767 ? 16'hffff : right_pre < -32768 ? 16'h0000: right_pre[15:0] ^ 16'h8000;

  
  dac left_dac(
    .DACout(Audio_left), 
    .DACin(left[15:4]), 
    .clock(Bus2IP_Clk)
  );
  
  dac right_dac(
    .DACout(Audio_right), 
    .DACin(right[15:4]), 
    .clock(Bus2IP_Clk)
  );
  
endmodule
