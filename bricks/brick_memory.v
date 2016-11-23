module brick_memory(
		input clk,
		input resetn,
		input [9:0]x_in, y_in,
		input wren,
		input [9:0]gridx, gridy, height, width,
		
		output reg [1:0]health,
		output reg [9:0]x,
		output reg [9:0]y
	);
	
	wire [1:0]data;
	
	memory bm(
		.address(address),
		.clock(clk),
		.data(health - 1),
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
