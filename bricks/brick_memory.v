//`include "memory.v"
//`include "address_xy.v"
//`include "macros.v"

module brick_memory(
		input clk,
		input [9:0]x_in, y_in,
		input wren,
		input [1:0]health_in,
		
		output [1:0]health,
		output [9:0]x,
		output [9:0]y
	);
	
	wire [9:0]address;
	
	address_xy memorychange(
		.x_in(x_in),
		.x_out(x),
		.y_in(y_in),
		.y_out(y),
		.address_in(address),
		.address_out(address)
	);
	
	memory bm(
		.address(address[7:0]),
		.clock(clk),
		.data(health_in),
		.wren(wren),
		.q(health)
	);
	
endmodule
