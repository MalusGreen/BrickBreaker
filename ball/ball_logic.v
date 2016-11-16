module ball_logic(
	input resetn,
	input clk,
	
	input [9:0]x, x_max,
	input [9:0]y, y_max,
	input [9:0]size,
	
	output reg x_du,
	output reg y_du
	);
	
	reg x_dir, y_dir;
	
	always @(posedge clk)begin
		if(!resetn) begin
			x_dir <= 0;
			y_dir <= 0;
		end
		else begin
			case (x)
				x_max - size:	x_dir = 0;
				0				:  x_dir = 1;
				default		:  x_dir = 0;
			endcase
			case (y)
				y_max - size: y_dir = 0;
				0				: y_dir = 1;
				default		: y_dir = 0;
			endcase
		end
	end
	
	
	always @(posedge clk)begin
		x_du <= x_dir;
		y_du <= y_dir;
	end
	
endmodule
