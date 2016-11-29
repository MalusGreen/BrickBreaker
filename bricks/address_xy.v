module address_xy(
	input [9:0]x_in, y_in,
	input [9:0]address_in,
	
	output reg [9:0]y_out, x_out,
	output reg [9:0]address_out
	);
	
//	GRIDX 10'd16
//	BRICKX 10'd8
//   BRICKY 10'd4
	
	always @(*) begin
		x_out = (address_in % `GRIDX) * `BRICKX;
		y_out = (address_in / `GRIDX) * `BRICKY;
		address_out = (x_in / `BRICKX) + ((y_in / `BRICKY) * `GRIDX);
//		x_out = (address_in % 10'd16) << 10'd3;
//		y_out = (address_in >> 10'd4) << 10'd2;
//		address_out = (x_in >> 10'd3) + ((y_in >> 10'd2) << 10'd4);
	end
endmodule
