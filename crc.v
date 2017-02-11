module crc ( input            clk,reset,
             input            crc_en, 
             input [7:0]      data,
             output reg       crc_valid, 
             output reg [7:0] crc_o);
  
  reg [7:0] bob,t_bob,crc_d;
  integer i;
  reg [32:0]   poly; 

  always @(*) begin
    bob  = crc_o ;
    poly = 33'h1_8141_41AB; 
    for (i=0;i<8; i=i+1) begin
      bob = ((bob<<1)|data[i]) ^ (bob[7] ? poly:0);
    end
    crc_d = bob;
  end
    
  always @(posedge clk or reset)
    begin
    if (reset) begin
      crc_o <=     #1 32'hA55A_7EE7;
      crc_valid <= #1 1'b0;
    end
    else if(crc_en) begin
      crc_o     <= #1 crc_d;
      crc_valid <= #1 1'b1;
    end
    else begin
      crc_o     <= #1 crc_o;
      crc_valid <= #1 1'b0;
    end 
  end
    
endmodule
