module ball_logic(
	input resetn,
	input clk,
	
	input [9:0]x, max_x,
	input [9:0]y, max_y,
	input [9:0]size,
	
	output x_du,
	output y_du
	);
	
	reg x_dir, y_dir;
	
	always @(posedge clk)begin
		if(!resetn) begin
			x_dir <= 0;
			y_dir <= 0;
		end
		else begin
			case (x)
				max_x - size:	x_dir <= 0;
				0				:  x_dir <= 1;
			endcase
			case (y)
				max_y - size: y_dir <= 0;
				0				: y_dir <= 1;
			endcase
		end
	end
	
	always @(*) begin
		assign x_ud = x_dir;
		assign y_ud = y_dir;
	end
	
endmodule
