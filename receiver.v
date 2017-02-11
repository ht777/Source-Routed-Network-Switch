module receiver( clk, reset, server_port, pushin, firstin, lastin, port_enable, datain, pushout, stopout, lastout, firstout, dataout, fifo_empty, fifo_full);
 
  input             clk, reset;
  input             pushin;
  input             lastin;
  input             firstin;
  input [1:0]       server_port;
  input [00:0]      port_enable;   // Confirm if this is bi-directional
  input [7:0]       datain;

  output [00:0]     pushout;
  output [00:0]     stopout;
  output [00:0]     lastout;
  output [00:0]     firstout;
  output [7:0]      dataout;

  // Fifo Signals 
  output            fifo_empty;
  output            fifo_full ;
  wire              fifo_write;
  wire              fifo_read ;
  wire  [63:0]      fifo_data ;
  wire  [63:0]      fifo_data_out ;

  reg               fifo_write_d;
  reg               fifo_read_d ;
  reg   [63:0]      fifo_data_d ;

  // CRC signals 
  reg               crc_en; 
  wire  [07:0]      crc_o;

  // Internal Signals
  wire              pkt_okay;
  wire              data_len_okay;
  wire              pushin_okay;
  wire [15:0]       data_len; 

//--------------State definitions--------------//

 parameter IDLE             = 6'h00,
           HEADER_LEN       = 6'h01,
           PKT_LEN1         = 6'h02,
           PKT_LEN2         = 6'h03,
           DEST_ADDR0       = 6'h04, 
           DEST_ADDR1       = 6'h05, 
           DEST_ADDR2       = 6'h06, 
           DEST_ADDR3       = 6'h07, 
           DEST_ADDR4       = 6'h08, 
           DEST_ADDR5       = 6'h09, 
           DEST_ADDR6       = 6'h0A, 
           DEST_ADDR7       = 6'h0B, 
           SRC_ADDR0        = 6'h0C,
           SRC_ADDR1        = 6'h0D,
           SRC_ADDR2        = 6'h0E,
           SRC_ADDR3        = 6'h0F,
           SRC_ADDR4        = 6'h10,
           SRC_ADDR5        = 6'h11,
           SRC_ADDR6        = 6'h12,
           SRC_ADDR7        = 6'h13,
           SRC_PKT_I0       = 6'h14,
           SRC_PKT_I1       = 6'h15,
           SRC_PKT_I2       = 6'h16,
           SRC_PKT_I3       = 6'h17,
           RESP_PKT_I0      = 6'h18,
           RESP_PKT_I1      = 6'h19,
           RESP_PKT_I2      = 6'h1A,
           RESP_PKT_I3      = 6'h1B,
           CMD_CODE         = 6'h1C,
           NUM_HOPS         = 6'h1D,
           NEXT_HOP         = 6'h1E,                  
           RESP_CODE        = 6'h1F,                  
           PORT_BYTE0       = 6'h20,                  
           PORT_BYTE1       = 6'h21,                  
           PORT_BYTE2       = 6'h22,                  
           PORT_BYTE3       = 6'h23,                  
           PORT_BYTE4       = 6'h24,                  
           PORT_BYTE5       = 6'h25,                  
           PORT_BYTE6       = 6'h26,                  
           PORT_BYTE7       = 6'h27,                  
           PORT_NUM_HOPS    = 6'h28,                  
           CRC_0            = 6'h29,                  
           CRC_1            = 6'h2A,                  
           CRC_2            = 6'h2B,                  
           CRC_3            = 6'h2C,                  
           DATA_IN0         = 6'h2D,
           DATA_IN1         = 6'h2E,
           DATA_IN2         = 6'h2F,
           DATA_IN3         = 6'h30,
           DATA_IN4         = 6'h31,
           DATA_IN5         = 6'h32,
           DATA_IN6         = 6'h33,
           DATA_IN7         = 6'h34,
           WAIT_TILL_EMPTY  = 6'h35;                 // Wait till empty is cleared

//---------------------------------------------//

  // Internal Signals. 
  reg [7:0]   pkt_type;
  reg [7:0]   header_len;
  reg [15:0]  pkt_len;
  reg [7:0]   cmd_code ;
  reg [7:0]   num_hops ;
  reg [7:0]   next_hop ;
  reg [7:0]   resp_code;


  reg         start_flag;
  integer     start_cnt; 
  wire [31:0] start_cnt_d; 

  // Signals used for flag. 
  reg         dest_flag;
  integer     dest_cnt ;
  integer    dest_cnt_d ;
  reg [63:0]  dest_addr;

  reg         src_flag;
  integer     src_cnt ;
  integer     src_cnt_d ;
  reg [63:0]  src_addr;

  reg         src_pkt_i_flag;
  integer     src_pkt_i_cnt ;
  integer    src_pkt_i_cnt_d ;
  reg [31:0]  src_pkt_i;

  reg         dort_num_flag;
  integer     dort_num_cnt ;
  wire[31:0]  dort_num_cnt_d ;
  reg [31:0]  dort_num;

  reg         resp_pkt_i_flag;
  integer     resp_pkt_i_cnt ;
  integer    resp_pkt_i_cnt_d ;
  reg [31:0]  resp_pkt_i;

  reg         cort_num_flag;
  integer     cort_num_cnt ;
  wire[31:0]  cort_num_cnt_d ;
  reg [31:0]  cort_num;

  reg         port_0_num_flag;
  integer     port_0_num_cnt ;
  integer    port_0_num_cnt_d ;
  reg [15:0]  port_0_num;

  reg         bort_num_flag;
  integer     bort_num_cnt ;
  wire[31:0]  bort_num_cnt_d ;
  reg [31:0]  bort_num;

  reg         port_1_num_flag;
  integer     port_1_num_cnt ;
  integer    port_1_num_cnt_d ;
  reg [15:0]  port_1_num;

  reg         sort_num_flag;
  integer     sort_num_cnt ;
  wire[31:0]  sort_num_cnt_d ;
  reg [31:0]  sort_num;

  reg         port_2_num_flag;
  integer     port_2_num_cnt ;
  integer    port_2_num_cnt_d ;
  reg [15:0]  port_2_num;

  reg         aort_num_flag;
  integer     aort_num_cnt ;
  wire[31:0]  aort_num_cnt_d ;
  reg [31:0]  aort_num;

  reg         qort_num_flag;
  integer     qort_num_cnt ;
  wire[31:0]  qort_num_cnt_d ;
  reg [31:0]  qort_num;

  reg         wort_num_flag;
  integer     wort_num_cnt ;
  wire[31:0]  wort_num_cnt_d ;
  reg [31:0]  wort_num;

  reg         rort_num_flag;
  integer     rort_num_cnt ;
  wire[31:0]  rort_num_cnt_d ;
  reg [31:0]  rort_num;

  reg         xort_num_flag;
  integer     xort_num_cnt ;
  wire[31:0]  xort_num_cnt_d ;
  reg [31:0]  xort_num;

  reg         fort_num_flag;
  integer     fort_num_cnt ;
  wire[31:0]  fort_num_cnt_d ;
  reg [31:0]  fort_num;

  reg         gort_num_flag;
  integer     gort_num_cnt ;
  wire[31:0]  gort_num_cnt_d ;
  reg [31:0]  gort_num;

  reg         hort_num_flag;
  integer     hort_num_cnt ;
  wire[31:0]  hort_num_cnt_d ;
  reg [31:0]  hort_num;

  reg         jort_num_flag;
  integer     jort_num_cnt ;
  wire[31:0]  jort_num_cnt_d ;
  reg [31:0]  jort_num;

  reg         kort_num_flag;
  integer     kort_num_cnt ;
  wire[31:0]  kort_num_cnt_d ;
  reg [31:0]  kort_num;

  reg         port_3_num_flag;
  integer     port_3_num_cnt ;
  integer     port_3_num_cnt_d ;
  reg [15:0]  port_3_num;
  reg [15:0]  port_addr ;

  reg         port_num_flag;
  integer     port_num_cnt ;
  wire[31:0]  port_num_cnt_d ;
  reg [31:0]  port_num;

  reg         crc_flag;
  integer     crc_cnt ;
  integer    crc_cnt_d ;
  reg [31:0]  crc;

  reg         port_data_flag;
  integer     port_data_cnt ;
  wire [31:0] port_data_cnt_d ;
  reg [63:0]  port_data;

  reg         write_enable;   // Flag to signify that RTL has received 32 bits data.


  reg [5:0]   cur_state ;
  reg [5:0]   next_state;

  fifo fifo_inst( .clk     (clk), 
                  .rst     (reset), 
                  .wr      (fifo_write), 
                  .rd      (fifo_read), 
                  .datain  (fifo_data),      
                  .full    (fifo_full), 
                  .empty   (fifo_empty), 
                  .push_out(pushout), 
                  .dout    (fifo_data_out)
                );

  crc crc_inst ( .clk(clk),
                 .reset(reset),
                 .crc_en(crc_en),
                 .data(datain),
                 .crc_valid(crc_valid),
                 .crc_o(crc_o)
                );

  always@(posedge clk) 
  begin 
    if(reset) 
      cur_state <= #1 IDLE;
    else 
      cur_state <= #1 next_state;
  end 
  
  // Next State Logic
  // always@(cur_state, reset, pushin, lastin, firstin, server_port, port_enable, datain ) begin
  always@(*) begin
    next_state = IDLE;
    case(cur_state)
      IDLE          : begin
                        if(pushin) begin
                          if(pkt_okay) begin
                            crc_en       = 1'b1;
                              pkt_type   = datain;
                              next_state = HEADER_LEN;
                              fifo_data_d[7:0] = datain;
                          end
                          else begin  
                            next_state = IDLE ; 
                          end 
                        end
                        else begin 
                          next_state = IDLE ; 
                        end 
                      end
      HEADER_LEN    : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            header_len  = datain ;
                            next_state  = PKT_LEN1;
                            fifo_data_d[15:8] = datain;
                          end
                          else begin
                            next_state  = IDLE ;   
                          end 
                        end 
                        else begin 
                          next_state  = HEADER_LEN; 
                        end 
                      end 
      PKT_LEN1      : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            pkt_len[15:8] = datain;
                            next_state = PKT_LEN2 ; 
                            fifo_data_d[23:16] = datain;
                          end
                          else begin  
                            next_state  = IDLE ;   
                          end 
                        end 
                        else begin 
                          next_state  = PKT_LEN1 ; 
                        end 
                      end
      PKT_LEN2      : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            pkt_len[7:0] = datain;
                            if(((4*header_len) + pkt_len) <= 16'h1000) begin 
                              next_state = DEST_ADDR0; 
                              fifo_data_d[31:24] = datain;
                            end 
                            else begin
                              next_state = IDLE  ;   
                            end 
                          end
                          else begin 
                            next_state  = IDLE ;  
                          end 
                        end 
                        else begin
                          next_state  = PKT_LEN2 ; 
                        end 
                      end
      DEST_ADDR0    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            if(data_len_okay) begin
                              dest_addr[7:0] = datain;
                              fifo_data_d[39:32] = datain ; 
                              next_state = DEST_ADDR1 ;  
                            end 
                            else begin 
                              next_state = IDLE ; 
                              fifo_data_d[63:00] = 'h00 ; // 63:32];
                            end 
                          end
                          else begin
                            next_state  = IDLE  ;   
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR0; 
                        end 
                      end 
      DEST_ADDR1    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[15:8] = datain;
                            fifo_data_d[47:40] = datain ; 
                            next_state = DEST_ADDR2 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR1; 
                        end 
                      end 
      DEST_ADDR2    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[23:16]= datain;
                            fifo_data_d[55:48] = datain ; 
                            next_state = DEST_ADDR3 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR2; 
                        end 
                      end 
      DEST_ADDR3    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[31:24]   = datain;
                            fifo_data_d[63:56] = datain ; 
                            fifo_write_d       = 1'b1;
                            next_state         = DEST_ADDR4 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                            fifo_write_d       = 1'b0;
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR3; 
                        end 
                      end 
      DEST_ADDR4    : begin 
                        fifo_write_d       = 1'b0;
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[39:32]= datain;
                            fifo_data_d[07:00] = datain ; 
                            next_state = DEST_ADDR5 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR4; 
                        end 
                      end 
      DEST_ADDR5    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[47:40]= datain;
                            fifo_data_d[15:08] = datain ; 
                            next_state = DEST_ADDR6 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR5; 
                        end 
                      end 
      DEST_ADDR6    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[55:48]= datain;
                            fifo_data_d[23:16] = datain ; 
                            next_state = DEST_ADDR7 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR6; 
                        end 
                      end 
      DEST_ADDR7    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            dest_addr[63:56]= datain;
                            fifo_data_d[31:24] = datain ; 
                            next_state = SRC_ADDR0 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = DEST_ADDR7; 
                        end 
                      end 
      SRC_ADDR0     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[07:00]= datain;
                            fifo_data_d[39:32] = datain ; 
                            next_state = SRC_ADDR1 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR0; 
                        end 
                      end 
      SRC_ADDR1     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[15:08]= datain;
                            fifo_data_d[47:40] = datain ; 
                            next_state = SRC_ADDR2 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR1; 
                        end 
                      end 
      SRC_ADDR2     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[23:16]= datain;
                            fifo_data_d[55:48] = datain ; 
                            next_state = SRC_ADDR3 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR2; 
                        end 
                      end 
      SRC_ADDR3     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[31:24]    = datain;
                            fifo_data_d[63:56] = datain ; 
                            next_state         = SRC_ADDR4 ;  
                            fifo_write_d       = 1'b1;
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                            fifo_write_d       = 1'b0;
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR3; 
                        end 
                      end 
      SRC_ADDR4     : begin 
                        fifo_write_d       = 1'b0;
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[39:32]      = datain;
                            fifo_data_d[07:00]   = datain ; 
                            next_state           = SRC_ADDR5 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR4; 
                        end 
                      end 
      SRC_ADDR5     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[47:40]= datain;
                            fifo_data_d[15:08] = datain ; 
                            next_state = SRC_ADDR6 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR5; 
                        end 
                      end 
      SRC_ADDR6     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[55:48]= datain;
                            fifo_data_d[23:16] = datain ; 
                            next_state = SRC_ADDR7 ;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR6; 
                        end 
                      end 
      SRC_ADDR7     : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_addr[63:56]= datain;
                            fifo_data_d[31:24] = datain ; 
                            next_state = SRC_PKT_I0;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_ADDR7; 
                        end 
                      end 
      SRC_PKT_I0    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_pkt_i[07:00]= datain;
                            fifo_data_d[39:32] = datain ; 
                            next_state = SRC_PKT_I1;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_PKT_I0;
                        end 
                      end 
      SRC_PKT_I1    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_pkt_i[15:08]= datain;
                            fifo_data_d[47:40] = datain ; 
                            next_state = SRC_PKT_I2;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_PKT_I1;
                        end 
                      end 
      SRC_PKT_I2    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_pkt_i[23:16]   = datain;
                            fifo_data_d[55:48] = datain ; 
                            next_state         = SRC_PKT_I3;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = SRC_PKT_I2;
                        end 
                      end 
      SRC_PKT_I3    : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            src_pkt_i[31:24]    = datain;
                            fifo_data_d[63:56]  = datain ; 
                            next_state          = RESP_PKT_I0; 
                            fifo_write_d        = 1'b1;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                            fifo_write_d        = 1'b0;  
                          end 
                        end 
                        else begin 
                          next_state  = SRC_PKT_I3;
                        end 
                      end 
      RESP_PKT_I0   : begin 
                        fifo_write_d        = 1'b0;  
                        if(pushin) begin 
                          if(pushin_okay) begin
                            resp_pkt_i[07:00]   = datain;
                            fifo_data_d[07:00]  = datain ; 
                            next_state          = RESP_PKT_I1; 
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = RESP_PKT_I0;
                        end 
                      end 
      RESP_PKT_I1   : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            resp_pkt_i[15:08]   = datain;
                            fifo_data_d[15:08]  = datain ; 
                            next_state          = RESP_PKT_I2; 
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = RESP_PKT_I1;
                        end 
                      end 
      RESP_PKT_I2   : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            resp_pkt_i[23:16]   = datain;
                            fifo_data_d[23:16]  = datain ; 
                            next_state          = RESP_PKT_I3; 
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = RESP_PKT_I2;
                        end 
                      end 
      RESP_PKT_I3   : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            resp_pkt_i[31:24]   = datain;
                            fifo_data_d[31:24]  = datain ; 
                            next_state          = CMD_CODE ; 
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = RESP_PKT_I3;
                        end 
                      end 
      CMD_CODE      : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            cmd_code = datain;
                            next_state = NUM_HOPS;  
                            fifo_data_d[39:32] = cmd_code;
                          end
                          else begin
                            next_state  = IDLE ;   
                            fifo_data_d[63:00] = 00 ; // ;
                          end 
                        end
                        else begin
                          next_state  = CMD_CODE;
                        end 
                      end
      NUM_HOPS      : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                              if(datain < 'hff) begin 
                                num_hops = datain;
                                next_state = NEXT_HOP;  
                                fifo_data_d[47:40] = num_hops;
                              end 
                              else begin 
                                next_state = IDLE;  
                                fifo_data_d[63:00] = 00; 
                              end 
                          end
                          else  begin 
                            next_state  =  IDLE ;   
                            fifo_data_d[63:00] = 00; 
                          end 
                        end
                        else  begin 
                          next_state  =  NUM_HOPS ;   
                        end 
                      end
      NEXT_HOP      : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            if(datain < num_hops) begin
                              next_hop = datain;
                              next_state = RESP_CODE; 
                              fifo_data_d[55:48] = next_hop;
                            end
                            else begin 
                              next_state = IDLE;  
                              fifo_data_d[63:00] = 00; 
                            end 
                          end
                          else begin 
                            next_state  = IDLE ;   
                            fifo_data_d[63:00] = 00; 
                          end 
                        end
                        else begin 
                          next_state  = NEXT_HOP ;   
                        end 
                      end
      RESP_CODE     : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            resp_code  = datain;
                            next_state = PORT_BYTE0;
                            fifo_data_d[63:56] = resp_code;
                            fifo_write_d = 1'b1;
                          end
                          else begin
                            next_state  = IDLE ;   
                            fifo_data_d[63:00] = 00; // de;
                          end 
                        end
                        else begin  
                          next_state  = RESP_CODE; 
                        end 
                      end
      PORT_BYTE0    : begin
                        fifo_write_d  = 1'b0;
                        if(pushin) begin
                          if(pushin_okay) begin
                            port_num_flag     = 1'b1;          // Port number Counter
                            port_0_num[7:0]   = datain;                 
                            next_state        = PORT_BYTE1;
                            fifo_data_d[07:00] = datain ;
                          end
                          else begin
                            next_state    = IDLE ;   // Either firstin or lastin asserted
                            port_num_flag = 1'b0;          // Port number Counter
                            fifo_data_d[63:00] = 00; // ;
                          end 
					    end
                        else begin  
                          next_state  = PORT_BYTE0 ;   // Please check this condition with Prof.
                        end 
                      end 
      PORT_BYTE1    : begin
                        if(pushin) begin
                          if(pushin_okay) begin
                            port_num_flag = 1'b1;          // Port number Counter
                            if(port_num_cnt_d == next_hop) begin 
                              port_0_num[15:8] = datain;
                              fifo_data_d[15:08] = datain ;
                              if(cmd_code == 0) begin
                                port_addr = {14'h0000, dest_addr[1:0]};
                                fifo_data_d[15:00] = {14'h0000, dest_addr[1:0]}; // datain ;
                              end 
                              else if((port_0_num <  16'd32) || ({port_0_num[7:0], datain} < 16'd32)) begin
                                port_addr   = port_0_num; 
                                next_state  = PORT_BYTE2 ;
                                fifo_data_d[15:00] = port_0_num ;
                              end
                              else begin
                                port_num_flag = 1'b0;          // Port number Counter
                                port_addr   = 'hxxxx;  // Bad Address 
                                next_state  = IDLE ; 
                                fifo_data_d[63:00] = 00; // datain ;
                              end 
							end
                            else begin 
                              next_state  = PORT_BYTE2 ;
                              fifo_data_d[15:08] = datain ;
                              port_0_num[15:8] = datain;
                            end
						  end 
                          else begin
                            next_state      = IDLE ;
                            port_num_flag   = 1'b0;          // Port number Counter
                            fifo_data_d[63:00] = 00; 
                          end 
						end
                        else begin
                          next_state      = PORT_BYTE1 ;
                        end 
                      end
      PORT_BYTE2    : begin
                        if(pushin_okay) begin
                          if(pushin_okay) begin
                            port_num_flag = 1'b1;         
                            if(num_hops[0] != 0) begin 
                              port_1_num[7:0]  = 'hFF  ;                 
                              next_state       = PORT_BYTE3   ;
                              fifo_data_d[23:16] = 'hFF; 
                            end 
                            else begin 
                              port_1_num[7:0]  = datain;          
                              next_state       = PORT_BYTE3   ;
                              fifo_data_d[23:16] = datain; 
                            end 
                          end
                          else  begin                         
                            next_state    = IDLE ;   
                            port_num_flag = 1'b0;          
                            fifo_data_d[63:00] = 00 ; 
                          end
						end
                        else begin 
                          next_state    = PORT_BYTE2  ;    
                        end 
                      end 
      PORT_BYTE3    : begin
                        if(pushin) begin
						  if (pushin_okay) begin            // Firstin == 0 && lastin == 0;
                            port_num_flag = 1'b1;          // Port number Counter
                            if(num_hops[0] == 0) begin 
                              port_1_num[15:8] = datain;
                              fifo_data_d[32:24] = datain ; 
                              if(port_num_cnt_d == next_hop) begin 
                                if(cmd_code == 0) begin
                                  port_addr = {14'h0000, dest_addr[1:0]};
                                  fifo_data_d[31:16] = port_addr ; 
                                end 
                                else if((port_1_num <  16'd32) || ({port_1_num[7:0], datain} < 16'd32)) begin
                                  port_addr   = port_1_num; 
                                  next_state  = PORT_BYTE4 ;
                                  fifo_data_d[31:16] = port_addr ; 
                                end
                                else begin
                                  port_num_flag = 1'b0;          
                                  port_addr     = 'hxxxx;  // Bad Address. Dropping packet
                                  next_state    = IDLE ; 
                                  fifo_data_d[63:00] = 00; // datain ; 
                                end 
							  end 
                              else begin
                                port_addr   = 'hxxxx;  
                                next_state  = PORT_BYTE4 ; 
                                fifo_data_d[31:24] = datain ; 
                              end 
							end   // num_hops[0]
                            else begin  
                              next_state       = CRC_0;
                              port_1_num[15:8] = 'hFF ;
                              fifo_data_d[31:24] = 'hFF ; 
							end 
						  end    // pushin_okay
                          else begin  
                            port_num_flag   = 1'b0;      
                            next_state      = IDLE;
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin
                          next_state      = PORT_BYTE3 ;
                        end 
                      end
      PORT_BYTE4    : begin
                        if(pushin) begin
                          if(pushin_okay) begin
                            port_num_flag     = 1'b1;       
                            port_2_num[7:0]   = datain;                 
                            next_state       = PORT_BYTE5   ;
                            fifo_data_d[39:32] = datain; 
                          end
                          else begin
                            next_state  = IDLE ;   // Either firstin or lastin asserted
                            port_num_flag = 1'b0;          // Port number Counter
                            fifo_data_d[63:00] = 00; //  
                          end 
					    end
                        else begin 
                          next_state  = PORT_BYTE4 ;   // Please check this condition with Prof.
                        end 
                      end 
      PORT_BYTE5    : begin
                        if(pushin) begin
                          if(pushin_okay) begin
                            port_num_flag = 1'b1;          // Port number Counter
                            if(port_num_cnt_d == next_hop) begin 
                              port_2_num[15:8] = datain;
                              if(cmd_code == 0) begin
                                port_addr = {14'h0000, dest_addr[1:0]};
                                fifo_data_d[47:32] = port_addr ; 
                              end 
                              else if((port_2_num <  16'd32) || ({port_2_num[7:0], datain} < 16'd32)) begin
                                port_addr   = port_2_num; 
                                next_state  = PORT_BYTE6 ;
                                fifo_data_d[47:32] = port_2_num; 
                              end
                              else begin
                                port_addr   = 'hxx_xxxx;  // Bad Address 
                                next_state  = IDLE ; 
                                port_num_flag = 1'b0;          // Port number Counter
                                fifo_data_d[63:00] = 00 ; // um; 
                              end 
							end
                            else begin 
                                port_addr   = 'hXXXX; 
                                next_state  = PORT_BYTE6; 
                                fifo_data_d[47:32] = datain ; 
							end 
						  end 
                          else begin
                            next_state      = IDLE ;
                            port_num_flag = 1'b0;          // Port number Counter
                            fifo_data_d[63:00] = 00 ; // um; 
                          end 
						end
                        else begin
                          next_state      = PORT_BYTE5 ;
                        end 
                      end
      PORT_BYTE6    : begin
                        if(pushin_okay) begin
                          if(pushin_okay) begin
                            port_num_flag = 1'b1;        
                            if(num_hops[0] == 0) begin 
                              port_3_num[7:0]  = datain;                 
                              fifo_data_d[55:48] = datain ; 
                              next_state       = PORT_BYTE7   ;
                            end 
                            else begin 
                              port_3_num[7:0]  = 'hFF ;                 
                              next_state       = PORT_BYTE7   ;
                              fifo_data_d[55:48] = 'hFF   ; 
                            end 
                          end
                          else  begin 
                            next_state  = IDLE ;   
                            port_num_flag = 1'b0;        
                            fifo_data_d[55:48] = 'h00; 
                          end 
						end
                        else begin 
                          next_state    = PORT_BYTE6  ;    
                        end 
                      end 
      PORT_BYTE7    : begin
                        if(pushin) begin
						  if (pushin_okay) begin            // Firstin == 0 && lastin == 0;
                            port_num_flag = 1'b1;        
                            fifo_write_d  = 1'b1;
                            if(num_hops[0] == 0) begin 
                              port_3_num[15:8] = datain;
                              fifo_data_d[63:56] = datain ; 
                              if(port_num_cnt_d == next_hop) begin 
                                if(cmd_code == 0) begin
                                  port_addr = {14'h0000, dest_addr[1:0]};
                                  fifo_data_d[63:48] = port_addr ; 
                                end 
                                else if((port_3_num <  16'd32) || ({port_3_num[7:0], datain} < 16'd32)) begin
                                  port_addr   = port_3_num; 
                                  next_state  = PORT_NUM_HOPS ;    // ???
                                  fifo_data_d[63:48] = port_addr ; 
                                end
                                else begin
                                  port_addr   = 'hxx_xxxx;  // Bad Address. Dropping packet
                                  next_state  = IDLE ; 
                                  port_num_flag = 1'b0;        
                                  fifo_data_d[63:00] = 'h0000_0000;
                                end 
							  end 
                              else begin
                                port_addr   = 'hxx_xxxx;  
                                next_state  = PORT_NUM_HOPS ; 
                                fifo_data_d[63:56] = datain ; 
                              end 
							end   // num_hops[0]
                            else begin
                              next_state       = CRC_0;
                              port_1_num[15:8] = 'hFF ;
                              fifo_data_d[63:56] = 'hFF ;
							end 
                            if(port_num_cnt_d == num_hops) begin 
                              next_state       = CRC_0;
							end 
							else begin
                              next_state       = PORT_BYTE0 ;
							end 
						  end    // pushin_okay
                          else begin  
                            next_state      = IDLE;
                            port_num_flag = 1'b0;        
                            fifo_data_d[63:56] = 00 ;
                          end 
                        end 
                        else begin
                          next_state      = PORT_BYTE7 ;
                        end 
                      end
      PORT_NUM_HOPS : begin
                        if(pushin) begin 
                          if(pushin_okay) begin
                            fifo_write_d  = 1'b0;
                            port_num_flag = 1'b0;      
                            if(num_hops > port_num_cnt_d) begin 
                              next_state      = PORT_BYTE0 ;
                            end
                            else begin 
                              next_state      = CRC_0 ;
                            end 
                          end
                          else begin 
                            next_state  = IDLE ;   
                          end 
                        end 
                        else begin  
                          next_state  = PORT_NUM_HOPS ;   
                        end 
                      end 
      CRC_0         : begin 
                        crc_flag = 1'b0;
                        fifo_write_d  = 1'b0;
                        if(pushin) begin 
                          if(pushin_okay) begin
                            fifo_data_d[07:00]  = datain ; 
                            next_state          = CRC_1 ; 
                            fifo_write_d        = 1'b0;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = CRC_0;
                        end 
                      end 
      CRC_1         : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            fifo_data_d[15:08]  = datain ; 
                            next_state          = CRC_2 ; 
                            fifo_write_d        = 1'b0;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = CRC_1;
                        end 
                      end 
      CRC_2         : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            fifo_data_d[23:16]  = datain ; 
                            next_state          = CRC_3 ; 
                            fifo_write_d        = 1'b0;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = CRC_2;
                        end 
                      end 
      CRC_3         : begin 
                        if(pushin) begin 
                          if(pushin_okay) begin
                            fifo_data_d[31:24]  = datain ; 
                            next_state          = DATA_IN0;
                            fifo_write_d        = 1'b0;  
                          end
                          else begin
                            next_state  = IDLE  ;   
                            fifo_data_d[63:00] = 'h00 ; 
                          end 
                        end 
                        else begin 
                          next_state  = CRC_3;
                        end 
                      end 
      DATA_IN0       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           fifo_write_d  = 1'b0;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:8] = 'h000_0000;
                             port_data[7:0] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN1;  
                           end
                           else begin 
                             next_state     = DATA_IN1;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN0 ;   
                         end 
                       end 
      DATA_IN1       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:16] = 'h00_0000;
                             port_data[15:8]  = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN2;  
                           end
                           else begin 
                             next_state     = DATA_IN2;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN1 ;   
                         end 
                       end 
      DATA_IN2       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:24] = 'h0_0000;
                             port_data[23:16] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN3;  
                           end
                           else begin 
                             next_state     = DATA_IN3;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN2 ;   
                         end 
                       end 
      DATA_IN3       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:32] = 'h0000;
                             port_data[31:24] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN4;  
                           end
                           else begin 
                             next_state     = DATA_IN4;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN3 ;   
                         end 
                       end 
      DATA_IN4       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:40] = 'h000;
                             port_data[39:32] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN5;  
                           end
                           else begin 
                             next_state     = DATA_IN5;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN4 ;   
                         end 
                       end 
      DATA_IN5       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:48] = 'h000;
                             port_data[47:40] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN6;  
                           end
                           else begin 
                             next_state     = DATA_IN6;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN5 ;   
                         end 
                       end 
      DATA_IN6       : begin
                         if(pushin) begin 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:56] = 'h00;
                             port_data[55:48] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN7;  
                           end
                           else begin 
                             next_state     = DATA_IN7;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN6 ;   
                         end 
                       end 
      DATA_IN7       : begin
                         if(pushin) begin 
                           fifo_write_d   = 1; 
                           port_data_flag = 1'b1;
                           if (lastin && !firstin ) begin 
                             port_data_flag = 1'b0;
                             port_data[63:56] = datain;
                             fifo_write_d   = 1; 
                             next_state     = IDLE ;  
                           end 
                           else if (lastin == 1 ) begin 
                             next_state     = IDLE ;  
                           end
                           else if (lastin == 0 ) begin 
                             next_state     = DATA_IN0;  
                           end
                           else begin 
                             next_state     = DATA_IN0;  
                           end 
                         end 
                         else begin 
                           next_state  = DATA_IN7 ;   
                         end 
                       end 
      WAIT_TILL_EMPTY: begin
                         if(!fifo_empty)
                           next_state = WAIT_TILL_EMPTY;
                         else 
                           next_state = IDLE;
                       end 
    endcase 
  end 


  // Add data received and length received check logic. 

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      start_flag = #1 1'b0;
      start_cnt  = #1 1'b0;
    end
    else if (firstin && !start_flag) begin
      start_cnt = #1 0 ; // start_cnt + 1;
    end
    else if (start_flag && firstin) begin
      start_cnt = #1 start_cnt + 1;
    end 
    else begin
      start_cnt = #1 start_cnt + 1;
    end
  end 

  assign    start_cnt_d = start_cnt ; 

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      dort_num_cnt = #1 3;
      dort_num_flag = #1 1'b0;
    end
    else begin
      if(dort_num_flag)
        dort_num_cnt = #1 dort_num_cnt+1;
      else 
        dort_num_cnt = #1 3;
    end
  end 

  assign  dort_num_cnt_d = dort_num_cnt;
        
  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      dest_cnt = #1 7;
      dest_flag = #1 1'b0;
    end
    else begin
      if(dest_flag)
        dest_cnt = #1 dest_cnt+1;
      else 
        dest_cnt = #1 7;
    end
  end 

  // assign  dest_cnt_d = dest_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      cort_num_cnt = #1 3;
      cort_num_flag = #1 1'b0;
    end
    else begin
      if(cort_num_flag)
        cort_num_cnt = #1 cort_num_cnt+1;
      else 
        cort_num_cnt = #1 3;
    end
  end 
        
  assign  cort_num_cnt_d = cort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      src_cnt = #1 7;
      src_flag = #1 1'b0;
    end
    else begin
      if(src_flag)
        src_cnt = #1 src_cnt+1;
      else 
        src_cnt = #1 7;
    end
  end 

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      bort_num_cnt = #1 3;
      bort_num_flag = #1 1'b0;
    end
    else begin
      if(bort_num_flag)
        bort_num_cnt = #1 bort_num_cnt+1;
      else 
        bort_num_cnt = #1 3;
    end
  end 
        
  assign  bort_num_cnt_d = bort_num_cnt;

  // assign  src_cnt_d = src_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      src_pkt_i_cnt = #1 3;
      src_pkt_i_flag = #1 1'b0;
    end
    else begin
      if(src_pkt_i_flag)
        src_pkt_i_cnt = #1 src_pkt_i_cnt+1;
      else 
        src_pkt_i_cnt = #1 3;
    end
  end 
        
  // assign  src_pkt_i_cnt_d = src_pkt_i_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      aort_num_cnt = #1 3;
      aort_num_flag = #1 1'b0;
    end
    else begin
      if(aort_num_flag)
        aort_num_cnt = #1 aort_num_cnt+1;
      else 
        aort_num_cnt = #1 3;
    end
  end 
        
  assign  aort_num_cnt_d = aort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      sort_num_cnt = #1 3;
      sort_num_flag = #1 1'b0;
    end
    else begin
      if(sort_num_flag)
        sort_num_cnt = #1 sort_num_cnt+1;
      else 
        sort_num_cnt = #1 3;
    end
  end 

  assign  sort_num_cnt_d = sort_num_cnt;
        
  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      resp_pkt_i_cnt = #1 3;
      resp_pkt_i_flag = #1 1'b0;
    end
    else begin
      if(resp_pkt_i_flag)
        resp_pkt_i_cnt = #1 resp_pkt_i_cnt+1;
      else 
        resp_pkt_i_cnt = #1 3;
    end
  end 

  // assign  resp_pkt_i_cnt_d = resp_pkt_i_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      qort_num_cnt = #1 3;
      qort_num_flag = #1 1'b0;
    end
    else begin
      if(qort_num_flag)
        qort_num_cnt = #1 qort_num_cnt+1;
      else 
        qort_num_cnt = #1 3;
    end
  end 
        
  assign  qort_num_cnt_d = qort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      wort_num_cnt = #1 3;
      wort_num_flag = #1 1'b0;
    end
    else begin
      if(wort_num_flag)
        wort_num_cnt = #1 wort_num_cnt+1;
      else 
        wort_num_cnt = #1 3;
    end
  end 
        
  assign  wort_num_cnt_d = wort_num_cnt;

  // Initializing to 0, since value depends on num_hop variable
  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      port_num_cnt <= #1 0;
      port_num_flag <= #1 1'b0;
    end
    else begin
      if(port_num_flag && pushin && pushin_okay)
        port_num_cnt <= #1 port_num_cnt+1;
      else 
        port_num_cnt <= #1 port_num_cnt;
    end
  end 

  assign  port_num_cnt_d = port_num_cnt[7:1];   // For every 2 bytes, port_num_cnt_d will increment.

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      xort_num_cnt = #1 3;
      xort_num_flag = #1 1'b0;
    end
    else begin
      if(xort_num_flag)
        xort_num_cnt = #1 xort_num_cnt+1;
      else 
        xort_num_cnt = #1 3;
    end
  end 
        
  assign  xort_num_cnt_d = xort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      fort_num_cnt = #1 3;
      fort_num_flag = #1 1'b0;
    end
    else begin
      if(fort_num_flag)
        fort_num_cnt = #1 fort_num_cnt+1;
      else 
        fort_num_cnt = #1 3;
    end
  end 
        
  assign  fort_num_cnt_d = fort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      gort_num_cnt = #1 3;
      gort_num_flag = #1 1'b0;
    end
    else begin
      if(gort_num_flag)
        gort_num_cnt = #1 gort_num_cnt+1;
      else 
        gort_num_cnt = #1 3;
    end
  end 
        
  assign  gort_num_cnt_d = gort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      hort_num_cnt = #1 3;
      hort_num_flag = #1 1'b0;
    end
    else begin
      if(hort_num_flag)
        hort_num_cnt = #1 hort_num_cnt+1;
      else 
        hort_num_cnt = #1 3;
    end
  end 
        
  assign  hort_num_cnt_d = hort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      jort_num_cnt = #1 3;
      jort_num_flag = #1 1'b0;
    end
    else begin
      if(jort_num_flag)
        jort_num_cnt = #1 jort_num_cnt+1;
      else 
        jort_num_cnt = #1 3;
    end
  end 
        
  assign  jort_num_cnt_d = jort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      kort_num_cnt = #1 3;
      kort_num_flag = #1 1'b0;
    end
    else begin
      if(kort_num_flag)
        kort_num_cnt = #1 kort_num_cnt+1;
      else 
        kort_num_cnt = #1 3;
    end
  end 
        
  assign  kort_num_cnt_d = kort_num_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      rort_num_cnt = #1 3;
      rort_num_flag = #1 1'b0;
    end
    else begin
      if(rort_num_flag)
        rort_num_cnt = #1 rort_num_cnt+1;
      else 
        rort_num_cnt = #1 3;
    end
  end 

  assign  rort_num_cnt_d = rort_num_cnt;


  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      crc_cnt = #1 3;
      crc_flag = #1 1'b0;
    end
    else begin
      if(crc_flag)
        crc_cnt = #1 crc_cnt+1;
      else 
        crc_cnt = #1 3;
    end
  end 

  // assign  crc_cnt_d = crc_cnt;

  always@(posedge clk or posedge reset)
  begin
    if(reset) begin
      port_data_cnt = #1 0;
      port_data_flag = #1 1'b0;
    end
    else begin
      if(port_data_flag)
        port_data_cnt = #1 port_data_cnt+1;
      else 
        port_data_cnt = #1 3;
    end
  end 

  assign  port_data_cnt_d = port_data_cnt;

  assign  pkt_okay      = (firstin && datain[7:0]==8'hA0) ? 1'b1 : 1'b0;
  assign  data_len_okay = (((4*header_len) + pkt_len) <= 16'h1000)? 1'b1 : 1'b0;
  assign  pushin_okay   = (!firstin && !lastin) ? 1'b1 : 1'b0;
  assign  data_len      = ((4*header_len) + pkt_len);
  assign  fifo_write    = fifo_write_d; 
  assign  fifo_data     = fifo_data_d; 

endmodule 

