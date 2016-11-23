module load_data(
	input resetn,
	input clk,
	input [9:0]selection,
	
	output load,
	output [9:0]x_out, y_out,
	output [9:0]address
	);
	
	
	
endmodule

module load_control(
	input resetn,
	input clk,
	input done,
	
	output reg count_enable
	);
	
	reg current_state, next_state;
	
	localparam  S_LOADING 	= 1'd0,
					S_DONE		= 1'd1;
					
	always @(*)begin
		case(current_state)
				S_LOADING:	next_state = (done) ? S_DONE : S_LOADING;
				S_DONE:		next_state = S_DONE;
		endcase
	end
	
	always @(*)begin
		count_enable = 0;
		if(!current_state)begin
			count_enable = 1;
		end
	end
	
	// current_state registers
   always@(posedge clk)
   begin: state_FFs
       if(!resetn)
           current_state <= S_LOADING;
       else
           current_state <= next_state;
   end // state_FFS
endmodule

module load_datapath(
	input resetn,
	input clk,
	input count_enable,
	
	input [39:0] delay,
	input [9:0]selection,
	
	output done,
	output [9:0]x_out, y_out,
	output [9:0]address
	);
	
	
	
	delaycounter loaddrawdelay(
		.clk(clk),
		.resetn(resetn),
		.[39:0]delay(delay),
	
		.d_enable()
	);
	
	counter loadcount(
		.enable(count_enable),
		.clk(clk),
		.resetn(resetn),
		
		.c_x(count)
	);

endmodule
