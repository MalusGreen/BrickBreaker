module lose_checker(
	input clk,
	input resetn,

	input lost_health,
	input [9:0]starting health,
	
	output loss_occurred
	);
	
	reg [9:0]health_counter;
	
	always @(posedge clk) begin
		if(!resetn) begin
			loss_occurred <= 10'd0;
			health_counter <= starting_health;
		end
		else if(lost_health) begin
			if(health_counter == 10'd0) begin
				loss_occurred <= 10'd1;
			end
			else begin
				health_counter <= health_counter - 10'd1;
			end
		end
	end
	
endmodule 