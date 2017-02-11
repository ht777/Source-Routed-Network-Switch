module sroute(clk, reset, serverports, pushin, lastin, firstin, datain, pushout, stopout, lastout, firstout, dataout, enabled, memaddr, req, resp, readdata, writedata );

input                   clk;
input                   reset;
input           [063:0] serverports;
input           [31:0]  pushin,lastin,firstin;
input           [255:0] datain;
output          [31:0]  pushout,lastout,firstout;
output          [255:0] dataout;
output wire     [31:0]  stopout;
input           [31:0]  enabled;
output          [16:0]  memaddr;
output          [01:0]  req;
output wire     [63:0]  readdata;
input                   resp;
output          [63:0]  writedata;

wire            [31:0]  request; 
wire            [31:0]  ack ; 
wire            [31:0]  empty; 
wire            [31:0]  full ; 
wire            [31:0]  lastin , 
                        firstin,
                        pushin; 
wire                    read, write; 
wire            [4:0]   port_in, port_out;
wire            [63:0]  write_data;

wire            [31:0]  lastout, 
                        firstout, 
                        pushout; 
wire                    memory_full, 
                        write_stop, 
                        read_stop;
wire            [16:0]  address; 
  
  genvar c ;
  generate 
    for (c =0; c< 32; c=c+1) begin: receiver_block 
      receiver rec_inst(clk, reset, serverports[(2*c)+1:(2*c)], pushin[c], firstin[c], lastin[c], enabled[c], datain[(7*c)+7:(7*c)], pushout[c], stopout[c], lastout[c], firstout[c], dataout[(7*c)+7:(7*c)], empty[c], full[c]); 

      assign   request[c]  = pushin[c] && enabled[c] && empty[c];
      arbiter  arb_inst(clk, reset, enabled, request, ack);

      mem_ctrl mem_inst( clk, reset, lastin[c], firstin[c], pushin[c], read, write, write_stop, read_stop, port_in, port_out, write_data, lastout[c], firstout[c], pushout[c], memory_full, write_stop, read_stop, req, address, readdata );
    end 
  endgenerate 


endmodule 
