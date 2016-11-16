module ball_logic(
	input enable,
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
		else if(enable) begin
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
	
	
	assign x_du = x_dir;
	assign y_du = y_dir;
	
endmodule
