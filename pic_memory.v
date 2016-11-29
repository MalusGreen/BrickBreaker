module pic_memory(
	input resetn,
	input clk,
	
	input enable,
	input [2:0]screen_select,
	
	output [9:0]x, y,
	output reg[1:0]colour
	);
	
	wire [1:0]title_colour, win_colour, lose_colour;
	wire [14:0]address;
	
	mem_draw md(
		.go(enable),
		.resetn(resetn),
		.clk(clk),
		.address(address),
		.x(x),
		.y(y)
	);
	
	title_screen title(
		.address(address),
		.clock(clk),
		.data(),
		.wren(1'd0),
		.q(title_colour)
	);
	
	win_screen win(
		.address(address),
		.clock(clk),
		.data(),
		.wren(1'd0),
		.q(win_colour)
	);
	
	game_over lose(
		.address(address),
		.clock(clk),
		.data(),
		.wren(1'd0),
		.q(lose_colour)
	);
	
	always @(posedge clk) begin
		if(!resetn) begin
			colour <= title_colour;
		end
		else begin
			case(screen_select)
				0: colour <= title_colour;
				1: colour <= win_colour;
				2: colour <= lose_colour;
			endcase
		end 
	end
	
endmodule

module mem_draw(
	input go,
	input resetn,
	input clk,
	
	output reg[14:0]address,
	output reg[9:0]x,
	output reg[9:0]y
	);
	
	reg drawing;
	reg [14:0]address_counter;
	
	always @(posedge clk) begin
		if(!resetn) begin
			drawing <= 1'd0;
			address_counter <= 14'd0;
		end
		if(go) begin
			drawing <= 1'd1;
		end
		if(drawing) begin
			address_counter <= address_counter + 14'd1;
		end
	end
	
	always @(*) begin
		address = address_counter;
		x = address_counter % 14'd160;
		y = address_counter / 14'd160;
	end
	
endmodule