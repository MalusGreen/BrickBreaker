module brick_memory(
		input clk,
		input resetn,
		input [9:0]x_in, y_in,
		input wren,
		input [1:0]health_in,
		
		output reg [1:0]health,
		output reg [9:0]x,
		output reg [9:0]y
	);
	
	wire [1:0]data;
	
	wire [9:0]address;
	
	address_xy memorychange(
		.x_in(x_in),
		.x_out(),
		.y_in(y_in),
		.y_out(),
		.address_in(),
		.address_out(address)
	);
	
	memory bm(
		.address(address[7:0]),
		.clock(clk),
		.data(health_in),
		.wren(wren),
		.q(data)
	);
	
	always @ (posedge clk)begin
		if(!resetn)begin
			health <= 0;
			x <= 0;
			y <= 0;
		end
		else begin
			health <= data;
		end
	end
	
endmodule
