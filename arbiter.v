module arbiter( clk, reset, enabled, req, ack );
  
  input               clk;
  input               reset;
  input       [31:0]  enabled; 
  input       [31:0]  req;

  output wire [31:0]  ack;

  reg         [31:0]  ack_d;
  reg         [31:0]  cnt_d;
  wire        [31:0]  cnt; 
  reg         [31:0]  ring_cntr;

  always@(*) begin 
    case(cnt)
      32'h0000_0001   : if (req[0] && enabled[0]) begin
                          ack_d = 32'h0000_0001;
                        end 
      32'h0000_0002   : if (req[1] && enabled[1]) begin
                          ack_d = 32'h0000_0002;
                        end
      32'h0000_0004   : if (req[2] && enabled[2]) begin
                          ack_d = 32'h0000_0004;
                        end
      32'h0000_0008   : if (req[3] && enabled[3]) begin 
                          ack_d = 32'h0000_0008;
                        end
      32'h0000_0010   : if (req[4] && enabled[4]) begin
                          ack_d = 32'h0000_0010;
                        end 
      32'h0000_0020   : if (req[5] && enabled[5]) begin
                          ack_d = 32'h0000_0020; 
                        end
      32'h0000_0040   : if (req[6] && enabled[6]) begin
                          ack_d = 32'h0000_0040 ; 
                        end
      32'h0000_0080   : if (req[7] && enabled[7]) begin 
                          ack_d = 32'h0000_0080;       
                        end
      32'h0000_0100   : if (req[8] && enabled[8]) begin
                          ack_d = 32'h0000_0100;
                        end 
      32'h0000_0200   : if (req[9] && enabled[9]) begin
                          ack_d = 32'h0000_0200;
                        end
      32'h0000_0400   : if (req[10] && enabled[10]) begin
                          ack_d = 32'h0000_0400;
                        end
      32'h0000_0800   : if (req[11] && enabled[11]) begin 
                          ack_d = 32'h0000_0800;
                        end
      32'h0000_1000   : if (req[12] && enabled[12]) begin
                          ack_d = 32'h0000_1000;
                        end 
      32'h0000_2000   : if (req[13] && enabled[13]) begin
                          ack_d = 32'h0000_2000; 
                        end
      32'h0000_4000   : if (req[14] && enabled[14]) begin
                          ack_d = 32'h0000_4000 ; 
                        end
      32'h0000_8000   : if (req[15] && enabled[15]) begin 
                          ack_d = 32'h0000_8000;       
                        end
      32'h0001_0000   : if (req[16] && enabled[16]) begin
                          ack_d = 32'h0001_0000;
                        end 
      32'h0002_0000   : if (req[17] && enabled[17]) begin
                          ack_d = 32'h0002_0000;
                        end
      32'h0004_0000   : if (req[18] && enabled[18]) begin
                          ack_d = 32'h0004_0000;
                        end
      32'h0008_0000   : if (req[19] && enabled[19]) begin 
                          ack_d = 32'h0008_0000;
                        end
      32'h0010_0000   : if (req[20] && enabled[20]) begin
                          ack_d = 32'h0010_0000;
                        end 
      32'h0020_0000   : if (req[21] && enabled[21]) begin
                          ack_d = 32'h0020_0000; 
                        end
      32'h0040_0000   : if (req[22] && enabled[22]) begin
                          ack_d = 32'h0040_0000 ; 
                        end
      32'h0080_0000   : if (req[23] && enabled[23]) begin 
                          ack_d = 32'h0080_0000;       
                        end
      32'h0100_0000   : if (req[24] && enabled[24]) begin
                          ack_d = 32'h0100_0000;
                        end 
      32'h0200_0000   : if (req[25] && enabled[25]) begin
                          ack_d = 32'h0200_0000;
                        end
      32'h0400_0000  : if (req[26] && enabled[26]) begin
                          ack_d = 32'h0400_0000;
                        end
      32'h0800_0000   : if (req[27] && enabled[27]) begin 
                          ack_d = 32'h0800_0000;
                        end
      32'h1000_0000   : if (req[28] && enabled[28]) begin
                          ack_d = 32'h1000_0000;
                        end 
      32'h2000_0000   : if (req[29] && enabled[29]) begin
                          ack_d = 32'h2000_0000; 
                        end
      32'h4000_0000   : if (req[30] && enabled[30]) begin
                          ack_d = 32'h4000_0000 ; 
                        end
      32'h8000_0000   : if (req[31] && enabled[31]) begin 
                          ack_d = 32'h8000_0000;       
                        end
      // default : ack[0] = 1'b1;
    endcase 
  end 

  always@(posedge clk or posedge reset) begin 
    if(reset) begin
      cnt_d   <= #1 32'h0000_0001;
      ack_d   <= #1 32'h0000_0000;
    end 
    else begin 
      if ( ring_cntr[2:0] == 3'b000) begin 
      cnt_d     <= #1 cnt_d << 1;
      cnt_d[0]  <= #1 cnt_d[31];
      end 
      else begin 
      cnt_d     <= #1 cnt_d ;
      end 
    end 
  end 

  always@(posedge clk or posedge reset) begin 
    if(reset) begin
      ring_cntr <= #1 32'h0000_0000;
    end 
    else begin 
      ring_cntr <= #1 ring_cntr + 1;
    end 
  end 

  assign   cnt = cnt_d;
  assign   ack = ack_d;

  
endmodule 

// module arbiter_tb();
// 
//   reg          clk;
//   reg          rst;
//   reg  [31:0]  req;
//   reg  [31:0]  enabled; 
//   wire [31:0]  ack;
// 
//   integer      i;
//   reg  [31:0]  j;
//   reg  [0:0]   rst_inst;
//   reg  [2:0]   rst_cnt ;
// 
//   arbiter arb_inst(clk, rst, enabled, req, ack);
// 
//   initial begin 
//     clk = 0;
//     rst = 1'b1;
//     i   = 0;
//     j   = 0;
//     enabled = 32'hf0ff_fff0;
//     #20;
//     rst = 1'b0;
//     
//     // $monitor(" ");
//   end 
// 
//   initial begin
//     for (rst_cnt=0; rst_cnt < 8; rst_cnt=rst_cnt+1) begin
//       // rst_inst = $urandom_range(0,1);
//       #25;
//     end 
//   end 
// 
//   always 
//     # 5 clk = ! clk;
// 
//   initial begin
//     for (i=0; i<64; i=i+1) begin
//       wait(!rst)
//       @(posedge clk);
//       if(j==0) j=1;
//       req = j;
//       j  = j<<1;
//       // rst = rst_inst;
//     end 
//     #100 $finish;
//   end 
// 
//   initial begin
//     $dumpfile("round_robin.vcd");
//     $dumpvars(0, arbiter_tb);
//   end 
// endmodule
