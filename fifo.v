module fifo #(parameter WIDTH = 64, DEPTH = 8) (clk, rst, wr, rd, datain, full, empty, push_out, dout);

  input                 clk;
  input                 rst;
  input                 wr, rd;
  input  [WIDTH-1:0]    datain;  
  output                full, empty;
  output                push_out;
  output [WIDTH-1:0]    dout; 

  reg                   push_out_d;
  reg    [WIDTH-1:0]    dout_d; 
  reg    [WIDTH-1:0]    counter;
  reg    [03 :0]        wr_ptr;
  reg    [03 :0]        rd_ptr;
  reg    [WIDTH-1:0]    mem [DEPTH-1:0];

  // Write pointer incrementor 
  always@(posedge clk or posedge rst) begin 
    if (rst)//begin 
      wr_ptr <= #1 1'b0;
    else if(wr && ~full) begin 
      wr_ptr <= #1 wr_ptr + 1;
    end 
    else if (wr_ptr == (DEPTH))
      wr_ptr <= #1 0;
    else 
      wr_ptr <= #1 wr_ptr ;
  end 

  // Writing into FIFO Memory 
  always @(posedge clk) begin 
    if (rst) begin 
 	  mem[wr_ptr] <= #1 'h00;
	end
    else begin 
	  if (wr && ~full) begin 
 	    mem[wr_ptr] <= #1 datain;
	  end 
	end 
  end 

  // Read pointer incrementor
  always@(posedge clk or posedge rst) begin 
    if (rst)
      rd_ptr <= #1 'h0;  
    else if(rd && !empty) begin 
	  rd_ptr <= #1 rd_ptr + 1;
    end 
    else if (rd_ptr == (DEPTH))
	  rd_ptr <= #1 0;
    else 
	  rd_ptr <= #1 rd_ptr;
  end 

  // Reading from FIFO memory
  always @(posedge clk) begin 
    if (rst) begin 
      dout_d <= #1 'h00;
      push_out_d <= #1 'h0;
    end 
    else if (rd && !empty)begin 
      dout_d <= #1 mem[rd_ptr]; 
      push_out_d <= #1 'h1;
    end 
    else begin
    end 
  end 

  // Fifo counter logic 
  always@(posedge clk or posedge rst) begin 
    if (rst)
	counter <= #1 'h0;
    else if (wr && rd)
	counter <= #1 counter;
    else if (wr && !full)
	counter <= #1 counter + 1;
    else if (rd && !empty)
	counter <= #1 counter - 1;
    else                           // (wr && full) || (rd && empty)
	counter <= #1 counter;
  end 

  assign full          = ((wr_ptr[3] != rd_ptr[3]));
  assign empty         = ((wr_ptr == rd_ptr));
  assign dout          = dout_d;
  assign push_out      = push_out_d;
  // assign interrupt     = empty;

  // FIFO Error checking logic
  // always @(posedge clk) begin 
  //   if (wr && full)
  //     $display($time, "PUSHING DATA WHEN FIFO FULL");
  //   if (rd && empty)
  //     $display($time, "REQUESTING DATA WHEN FIFO EMPTY. GENERATING INTERRUPT SIGNAL");
  // end 

endmodule


