module pic_memory(
	input [2:0] selection,
	input resetn,
	input clk,
	
	input opening,
	input win,
	input lose,
	
	output [9:0] opening_x, opening_y, win_x, win_y, lose_x, lose_y,
	output [1:0]  opening_colour, win_colour, lose_colour
	);
	
endmodule

module mem_draw(
	input go,
	input resetn,
	input clk,
	
	output reg [14:0]address,
	output reg [9:0]x, y
	);
	
	reg count;
	always @(posedge go)begin
		if(resetn)begin
			count = 0;
		end
		else begin
			count = 1;
		end
	end
	
	always @(posedge clk)begin
		if(!resetn)begin
			address <= 0;
			x <= 0;
			y <= 0;
		end
		if(opening)
	end
	
endmodule
