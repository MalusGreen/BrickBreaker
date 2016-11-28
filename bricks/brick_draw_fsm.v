module brick_draw_fsm(
		input clk,
		input resetn,
		input start,
		
		output reg draw, 
		output reg [9:0] x_out, y_out
	);
	
	reg [1:0] current_state, next_state;
	
	localparam S_INIT = 2'd0,
				  S_DRAW = 2'd1,
				  S_WAIT = 2'd2;
				  
	always @(*) begin
		case(current_state)
			S_INIT: next_state = (start) ? S_DRAW : S_INIT;
			S_DRAW: next_state = S_WAIT;
			S_WAIT: next_state = (y_out == 10'd20) ? S_INIT : S_DRAW;
			default: next_state = S_INIT;
			
		endcase
	end
	
	always @(*) begin
		case(current_state)
			S_INIT: begin
				x_out = 1'd0;
				y_out = 1'd0;
				
				draw = 1'd0;
			end
			S_DRAW: begin
				x_out = x_out + 10'd10;
				if(x_out == 10'd160) begin
					x_out = 10'd0;
					y_out = y_out + 10'd5;
				end
				
				draw = 1'd1;
			end
			S_WAIT: begin
				draw = 1'd0;
			end
		endcase
	end 
	
	always @(posedge clk) begin
		if(!resetn) 
			current_state = S_INIT;
		else
			current_state = next_state;
	end 
	
endmodule 
