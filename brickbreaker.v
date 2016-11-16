module brickbreaker(
		CLOCK_50,						//	On Board 50 MHz
	// Your inputs and outputs here
	  KEY,
	  SW,
	// The ports below are for the VGA output.  Do not change.
	VGA_CLK,   						//	VGA Clock
	VGA_HS,							//	VGA H_SYNC
	VGA_VS,							//	VGA V_SYNC
	VGA_BLANK_N,						//	VGA BLANK
	VGA_SYNC_N,						//	VGA SYNC
	VGA_R,   						//	VGA Red[9:0]
	VGA_G,	 						//	VGA Green[9:0]
	VGA_B   						//	VGA Blue[9:0]
	);
	
	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	wire x_du, y_du plat_move;
	assign x_du = SW[9];
	assign y_du = SW[8];
	assign plat_move = SW[0];
	
	wire enable;
	wire [9:0]ball_x, screen_x;
	wire [9:0]ball_y, screen_y;
	
	assign screen_x = 10'd640 - 1;
	assign screen_y = 10'd480 - 1;
	//delay
	delay_counter delaycounter(
		.clk(CLOCK_50),
		.resetn(resetn),
		.delay(20'd833333),
		
		.d_enable(enable),
	);
	
	//game_logic
	ball_logic(
		.resetn(resetn),
		.clk(CLOCK_50),
		.x(ball_x),
		.x_max(screen_x),
		.y(ball_y)
		.y_max(screen_y),
	);
	
	ball_pos ballpos(
		.enable(enable),
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.x_du(x_du),
		.y_du(y_du),
		
		.x(ball_x),
		.y(ball_y)
	);
	
	//drawfunctions
	ball_draw balldraw(
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.go(),
		.x_in(ball_x),
		.y_in(ball_y),
	);
	
	//draw
	draw();
	
endmodule

module draw(
	input resetn,
	input clk,

	input [9:0]x,
	input [9:0]y,
	input [2:0]colour,
	input writeEn,
	
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	);
	
	
	vga_adapter VGA(
		.resetn(resetn),
		.clock(clk),
		.colour(colour),
		.x(x),
		.y(y),
		.plot(writeEn),
		
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK));
	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
endmodule
