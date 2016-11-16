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
	
	//Inputs
	wire resetn;
	wire x_du, y_du;
	wire plat_move;
	
	assign resetn = KEY[0];
	assign x_du = SW[9];
	assign y_du = SW[8];
	assign plat_move = SW[0];
	
	//Constants and connective wires.
	wire enable;
	wire [9:0]ball_x, screen_x;
	wire [9:0]ball_y, screen_y;
	wire [9:0]size;
	wire [20:0]delay;
	
	assign screen_x = 10'd640 - 1;
	assign screen_y = 10'd480 - 1;
	assign delay = 20'd833333;
	assign size = 10'd4;
	
	//draw fsm
	
	//game_logic
	ball_logic(
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.x(ball_x),
		.x_max(screen_x),
		.y(ball_y)
		.y_max(screen_y),
		.size(size)
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
	
	//delay
	delay_counter delaycounter(
		.clk(CLOCK_50),
		.resetn(resetn),
		.delay(delay),
		
		.d_enable(enable),
	);
	
endmodule

module draw_fsm(
	input enable,
	input resetn,
	input clk,
	
	output reg go_ball, go_bricks, go_plat,
	output reg [1:0] draw_mux,
	output reg iscolor,
	output reg inc_enable;
	);
	
	reg [2:0] current_state, next_state;
	
	localparam	S_BALL_LOAD 	= 'd0,
					S_BALL_DRAW 	= 'd1,
					S_BRICKS_LOAD	= 'd2,
					S_BRICKS_DRAW	= 'd3,
					S_PLAT_LOAD		= 'd4,
					S_PLAT_DRAW		= 'd5,
					S_INC				= 'd6,
					S_CHANGE			= 'd7;
					
	
	wire delay_enable
	wire reg delay_reset;
	wire [20:0] ball_delay, brick_delay, plat_delay;
	wire reg [20:0] delay;
	
	assign ball_delay 	= 20'd16;
	assign brick_delay	= 20'd0;
	assign plat_delay 	= 20'd4;
	
	delay_counter drawdelay(
		.clk(clk),
		.resetn(delay_reset),
		.delay(delay),
		
		.d_enable(delay_enable)
	);
	
	always @(*)begin
		case (current_state)
				S_BALL_LOAD: next_state = (enable | iscolor) ? S_BALL_DRAW : S_BALL_LOAD;
				S_BALL_DRAW: next_state = (delay_enable) ? S_BRICKS_LOAD : S_BALL_DRAW;
				S_BRICKS_LOAD: next_state = S_BRICKS_DRAW;
				S_BRICKS_DRAW: next_state = (delay_enable) ? S_PLAT_LOAD : S_PLAT_DRAW;
				S_PLAT_LOAD: next_state = S_PLAT_DRAW;
				S_PLAT_DRAW: next_state = (delay_enable) ? S_PLAT_DRAW : S_INC;
				S_INC: next_state = S_CHANGE;
				S_CHANGE: next_state = S_BALL_LOAD;
		endcase
	end
	
	always @(*)begin
		go_ball = 0;
		go_bricks = 0;
		go_plat = 0;
		draw_mux = 0;
		
		delay = 0;
		delay_reset = 0;
		
		case (current_state)
			S_BALL_LOAD: begin 
				go_ball = 1;
				draw_mux = 2'd1;
			end
			S_BALL_DRAW: begin 
				delay_reset = 1;
				delay = ball_delay;
				draw_mux = 2'd1;
			end
			S_BRICKS_LOAD: begin 
				go_bricks = 1;
				draw_mux = 2'd2;
			end
			S_BRICKS_DRAW: begin 
				delay_reset = 1;
				delay = brick_delay;
				draw_mux = 2'd2;
			end
			S_PLAT_LOAD: begin 
				go_plat = 1;
				draw_mux = 2'd3;
			end
			S_PLAT_DRAW: begin 
				delay_reset = 1;
				delay = plat_delay;
				draw_mux = 2'd3;
			end
			S_CHANGE: begin
				if(iscolor)
				iscolor <= ~iscolor;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if(!resetn)
			iscolor <= 0;
	end
	 	 
   // current_state registers
   always@(posedge clk)
   begin: state_FFs
       if(!resetn)
           current_state <= S_LOAD_XY;
       else
           current_state <= next_state;
   end // state_FFS
	
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
