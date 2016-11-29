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
	
	output [15:0]address,
	output [9:0]x,
	output [9:0]y
	);
	
	
	
endmodule
