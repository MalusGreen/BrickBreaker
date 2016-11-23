module address_xy(
	input [9:0]x_in, y_in,
	input [9:0]address_in,
	input [9:0]gridx, gridy, height, width
	
	output [9:0]y_out, x_out,
	output [9:0]address_out
	);
	
	always @(*) begin
		x_out = (address_in % gridx) * width;
		y_out = (address_in / gridx) * height;
	end
endmodule
