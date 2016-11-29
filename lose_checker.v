`include "macros.v"

module lose_checker(
	input clk,
	input resetn,

	input [9:0]ball_y,
	input [9:0]starting_health,
	
	output reg loss_occurred
	);
	
	reg [9:0]health_counter;
	reg [9:0]previous_y;
	
	always @(posedge clk) begin
		if(!resetn) begin
			loss_occurred <= 10'd0;
			health_counter <= starting_health;
			previous_y <= `BALLY;
		end
		else if(ball_y > `PLATY & previous_y <= `PLATY) begin
			if(health_counter == 10'd0) begin
				loss_occurred <= 10'd1;
			end
			else begin
				health_counter <= health_counter - 10'd1;
			end
		end
		
		previous_y <= ball_y;
	end
	
endmodule 