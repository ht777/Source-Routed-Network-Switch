
module mem_ctrl (
		input          clk, reset,lastin, firstin, pushin, read, write,
		input          write_stop,read_stop,
		input [4:0]    port_in, port_out,
  		input [63:0]   writedata,
		output         lastout_arb,firstout_arb,pushout_arb,
		output         memory_full_arb,write_stop_arb,read_stop_arb,
  		output [1:0]   req_arb,
		output [16:0]  address_arb,
  		output [63:0]  readdata_arb);
		
		// read and write inputs comes from the arbiter

		
reg [0:0] free_block,free_block_d [0:63];// high if the block is free, low otherwise
  wire [63:0] readdatamem;
  reg [8:0] write_counter, write_counter_d [0:63];// 

wire resp;
reg [0:0] write_complete, write_complete_d [0:63];//high when the write completes to a particular block or block becomes full
		
reg [5:0] block_input_port,block_input_port_d [0:63]; //useful if multiple input ports write to same output port

reg [5:0] next_block_number,next_block_number_d [0:63]; //pointer to the next block where the remaining packet data is stored

reg [5:0] block_output_port,block_output_port_d [0:63];
										

reg [5:0] next_packet_pointer,next_packet_pointer_d [0:63];

parameter s0=0,s1=1,s2=2,s3=3,s4=4,s5=5,s6=6;//for states
reg [2:0] states, states_d;

reg [8:0] read_counter, read_counter_d [0:63];// maintains the read count for particular block, acts as a pointer to the next chunk of data to be read ... also helps in determining if the read is complete and the block is free


  reg [5:0] next_free_block,next_free_block_d;//stores the next free block for the entire memory
integer i,ix;
reg memory_full,memory_full_d,firstout,firstout_d;
reg [16:0] address,address_d;		
reg write_stop_d,lastout,lastout_d;
reg read_stop_d,pushout,pushout_d;
reg [1:0] req_d,req;
  reg [63:0] readdata,readdata_d;


assign memory_full_arb = memory_full;
assign address_arb = address;
assign req_arb = req;
assign firstout_arb = firstout;
assign pushout_arb = pushout;
assign write_stop_arb = write_stop_d;
assign read_stop_arb = read_stop_d;
assign lastout_arb = lastout;
assign readdata_arb = readdata;
		
always @ (posedge clk or reset)
begin
	if(reset)
	begin
	for (i=0;i<64;i=i+1)
	begin
	free_block_d[i] = 1; 
	write_complete_d[i] = 0;
	block_input_port_d[i] = 0; 
	block_output_port_d[i] = 0;
	next_packet_pointer_d[i] = 0;
	write_counter_d[i] = 0;
	read_counter_d[i] = 0;
	end

	next_free_block = 0;
	states= 0;
	memory_full = 0;
	firstout = 0;
	address = 0;
	write_stop_d = 0;
	read_stop_d = 0;
	lastout = 0;
	pushout = 0;
	req = 0;
    readdata = 0;

	end
	else begin
	memory_full = memory_full_d;
	next_free_block = next_free_block_d;
	firstout = firstout_d;
	address = address_d;
	write_stop_d = write_stop;
	read_stop_d = read_stop;
	lastout = lastout_d;
	pushout = pushout_d;
    readdata =readdata_d;
	req = req_d;
//	write_counter = write_counter_d;

	for (i=0;i<64;i=i+1)
	begin
	free_block[i] = free_block_d[i]; 
	write_complete[i] = write_complete_d[i];
	block_input_port[i] = block_input_port_d[i]; 
	block_output_port[i] = block_output_port_d[i];
	next_packet_pointer[i] = next_packet_pointer_d[i];

	write_counter[i] = write_counter_d[i];
	read_counter[i] = read_counter_d[i];
	end
	states= states_d;

	//storing in the flip flops
	end
end
//
always @(*)
begin
memory_full_d=0;
firstout_d = 0;
write_stop_d = 0;
read_stop_d = 0;
lastout_d = 0;
pushout_d = 0;

case (states)
s0: begin
	if(write)
		begin
			address_d = 17'h00000;
			req_d = 1;
			next_free_block_d = 1;	
			block_output_port_d[port_out] = 0;          
			states_d = s5;
			//$display ("inside state 1 if block\n");	
		end
	else
		begin
					//$display ("inside state 1 else block\n");	
		states_d = s0;
		end
	end
s1: begin
			//$display ("Port in for state 1: %d\n", port_in);
			//$display ("Block for input port in state 1: %d\n", block_input_port[port_in]);
			//$display ("write counter in state 1: %d\n", write_counter[block_input_port[port_in]]);	
	if (read)
		states_d = s2;
	else if (write)
		states_d = s3;
	else
		states_d = s1;
	end
	
s2: begin
			//$display ("write counter %d\n", write_counter[block_output_port[port_out]]);	
		//	$display ("write counter %d\n", write_counter[block_input_port[port_in]]);	

			//$display ("block for output port %d\n", block_output_port[port_out]);	
		//	$display ("port out %d\n", port_out);	
			

	if (write_counter[block_output_port[port_out]]!=0 && !read_stop && (write_counter[block_output_port[port_out]] > read_counter[block_output_port[port_out]]))
	//check if data exist in the block using counter...also check if write counter > read counter...so as not to read unwritten memory locations
		begin
					//$display ("inside state 2 if block\n");	

			req_d = 2;//in test bench req=2 is used for reading
			address_d = {2'b00,block_output_port[port_out],read_counter[block_output_port[port_out]]};
			states_d=s4;//wait for read response from memory
		end
	else
	begin
					//$display ("inside state 2 else block\n");	

		if (read_stop)
			begin
				states_d=s1;
				//	$display ("inside state 2 else->if block\n");	

			end
		else
		begin
				//	$display ("inside state 2 else->else\n");	
			states_d =s2;
			end
	end
	end
		
s3: begin
//assuming start of packet signal
if (firstin && !write_stop)
	begin
		if (free_block[next_free_block]==1)
			begin
				//$display ("inside state 3 if->if block\n");	

				block_input_port_d[port_in]=next_free_block;
				free_block_d[next_free_block] = 0;
				address_d = {2'b00,next_free_block,write_counter[next_free_block]};
					if (free_block[block_output_port[port_out]]==0 && block_output_port[port_out]!= next_free_block) //if there exist another packet to the same o/p port already
					begin
						next_packet_pointer_d[block_output_port[port_out]] = next_free_block;
					end
					else
						block_output_port_d[port_out] = next_free_block;
							
				req_d=1;//memory write has req=1 in testbench
				states_d = s5;
			end
		else
			begin
				//				$display ("inside state 3 if->else block\n");	
			ix = 0;
			states_d = s6;
			end
			//find among all the 32 blocks which is free and if none free, send out the stop signal
		end
else if (write_stop)
	begin
	//	$display ("inside state 3 else if block\n");	
		states_d=s1;
	end
		
else
	begin
	
		if (write_complete[block_input_port[port_in]]!=1)	
		begin
		//	$display ("inside state 3 else->if block\n");	
			address_d = {block_input_port[port_in],write_counter[block_input_port[port_in]]};
			req_d=1;//memory write has req=1 in testbench
		//	$display ("inside last else\n");
			states_d = s5;
		end
		
	end
	
end
	
s4: begin
		if (resp)
			begin
				readdata_d = readdatamem;//should be equal to data from memory
				read_counter_d[block_output_port[port_out]] = read_counter[block_output_port[port_out]] + 1;
				states_d = s1;
				if ((read_counter[block_output_port[port_out]]+1)==write_counter[block_output_port[port_out]] && write_complete[block_output_port[port_out]]==1)
					begin
						free_block_d[block_output_port[port_out]]=1;
						next_free_block_d = block_output_port[port_out];
						write_counter_d[block_output_port[port_out]]=0;
						read_counter_d[block_output_port[port_out]]=0;
						write_complete_d[block_output_port[port_out]]=0;
						block_output_port_d[port_out]= next_packet_pointer[block_output_port[port_out]];
						pushout_d=1;
						lastout_d=1;
					//	$display ("inside state 4 if->if\n");	
						//else
						//block_output_port[port_out] = 0;		
					end
				else
					begin
					//	$display ("inside state 4 if->else block\n");	
						if (read_counter==1)
							begin
								pushout_d=1;
								firstout_d=1;
							end
						else
							pushout_d=1;
					end
				
			end 
		else
		begin
			states_d = s4;
			//$display ("inside state 4 else block\n");	

		end
	end
		
s5: begin
	if (resp)
		begin
			write_counter_d[block_input_port[port_in]] = write_counter[block_input_port[port_in]]+1;
			//$display ("Port in state 5: %d\n", port_in);
			//$display ("Block for input port  state 5: %d\n", block_input_port[port_in]);
			//$display ("write counter inside state 5: %d\n", write_counter_d[block_input_port[port_in]]);
			if (lastin)
				begin
					write_complete_d[block_input_port[port_in]]=1;
					//$display ("inside state 5 if->if block\n");	
				end
			
			else
			begin
				write_complete_d[block_input_port[port_in]]=0;
				//$display ("inside state 5 if->else block\n");	
			end
			//resp = 0;
			states_d = s1;
		end
		
	else 
	begin
		states_d = s5;
		//$display ("inside state 5 else block\n");
	end

	
end


s6: begin //finds the free block
	if (free_block[i]==1)
		states_d = s3;
	else if (ix<31)
	begin
		ix=ix+1;
		states_d=s6;
		end
	else
	begin
		memory_full_d=1;
		states_d = s1;
		end
end
		


endcase
			
end			
  
 // memory m1 ( .read(req[1]),.write(req[0]),.clk(clk), .address(address), .writedata(writedata),.resp(resp), .readdata(readdatamem));			

endmodule


module memory (
  input read,write,clk,
  input [16:0] address,
  input [63:0] writedata,
  output resp,
  output [63:0] readdata);
  
  reg [63:0] mainmemory [32767:0];
  reg resp_reg;
  reg [63:0] readdata_reg;
  
 assign resp=resp_reg;
  assign readdata=readdata_reg;
  
  always @(posedge clk)
    if (write)
      begin
      mainmemory[address[14:0]] = writedata;
  	  resp_reg = 1;
      end
  else if (read)
    begin
    readdata_reg = mainmemory[address[14:0]];
  	resp_reg=1;
    end
endmodule


  
  
  
  
  
  
  
