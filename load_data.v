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
	input done
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
	
	input [9:0]selection,
	
	output done,
	output [9:0]x_out, y_out,
	output [9:0]address
	);
	
	counter loadcount(
		.enable(count_enable),
		.clk(clk),
		.resetn(resetn),
		
		.c_x(count)
	);

endmodule
