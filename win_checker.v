module win_checker(
	input clk,
	input resetn,
	
	input game_write,
	input [9:0]total_health,
		
	output regwin_occurred,
	output reg [9:0]health_counter
	);
	
	//reg [9:0]health_counter;
	
	always @(posedge clk) begin
		if(!resetn) begin
			win_occurred <= 1'd0;
			health_counter <= total_health;
		end
		else if(game_write) begin
			health_counter <= health_counter - 10'd1;
			if(health_counter == 10'd0) begin
				win_occurred <= 1'd1;
				health_counter <= total_health;
			end
		end
	end
		
endmodule
