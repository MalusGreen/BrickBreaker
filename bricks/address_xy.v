module address_xy(
	input [9:0]x_in, y_in,
	input [9:0]address_in,
	
	output reg [9:0]y_out, x_out,
	output reg [9:0]address_out
	);
	
	always @(*) begin
		x_out = (address_in % `GRIDX) * `BRICKX;
		y_out = (address_in / `GRIDX) * `BRICKY;
		address_out = (x_in / `BRICKX) + ((y_in / `BRICKY) * `GRIDX);
	end
endmodule
