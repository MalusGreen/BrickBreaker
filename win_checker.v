module win_checker(
	input clk,
	input resetn,
	
	input game_write,
	input [9:0]total_health,
		
	output reg win_occurred,
	output reg [9:0]health_counter
	);
	
	//reg [9:0]health_counter;
	
	always @(posedge game_write, negedge resetn)begin
		if(!resetn) begin
			health_counter <= total_health;
		end
		else if(game_write) begin
			health_counter <= health_counter - 10'd1;
//				health_counter <= total_health;
		end
	end
	
	always @(posedge clk)begin
		if(!resetn)begin
			win_occurred <= 1'd0;
		end
		if(health_counter == 10'd0) begin
			win_occurred <= 1'd1;
		end
	end
		
endmodule
