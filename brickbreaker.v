//`include "ball_pos.v"
//`include "ball_draw.v"
//`include "ball_logic.v"
//`include "delay_counter.v"
//`include "vga_pll.v"
//`include "vga_controller.v"
//`include "vga_address_translator.v"
//`include "vga_adapter.v"
//`include "platform.v"
//`include "load_data.v"
//`include "brick_memory.v"
//`include "brick_draw.v"
//`include "address_xy.v"
//`include "memory_bb.v"

//HOME
`include "ball/ball_pos.v"
`include "ball/ball_draw.v"
`include "ball/ball_logic.v"
`include "delay_counter.v"
//`include "vga_pll.v"
//`include "vga_controller.v"
//`include "vga_address_translator.v"
//`include "vga_adapter.v"
`include "platform.v"
`include "load_data.v"
`include "bricks/brick_memory.v"
`include "bricks/brick_draw.v"
`include "bricks/address_xy.v"
`include "memory.v"
`include "macros.v"


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
	wire left, right;
	
	assign resetn = KEY[0];
	assign left = ~KEY[3];
	assign right = ~KEY[2];
	
	//Constants and connective wires.
	wire enable, inc_enable;
	wire [9:0]ball_x, screen_x, grid_x, brick_x;
	wire [9:0]ball_y, screen_y, grid_y, brick_y;
	wire [9:0]size;
	wire [39:0]delay;
	
	wire go_ball, go_bricks_fsm, go_plat;
	wire [1:0]draw_mux;
	wire iscolour;
	
	assign screen_x = 10'd320 - 1;
	assign screen_y = 10'd240 - 1;
//	assign delay = 40'd833333;
//	assign delay = 40'd1666666;
	assign delay = 40'd200;
	assign size = `BALLSIZE;
	
	//draw fsm
	
	draw_fsm FSM(
		.enable(enable),
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.go_ball(go_ball),
		.go_bricks(go_bricks_fsm),
		.go_plat(go_plat),
		
		.draw_mux(draw_mux),
		.iscolour(iscolour),
		.inc_enable(inc_enable)
	);
	
	wire go_bricks, load_draw, game_write, load_select, fsm_brick_draw;
	wire [9:0]load_x, game_mx, game_my, load_y;
	wire [9:0]load_address;
	wire [1:0]load_health, game_health;
	
	wire [9:0]platx_for_real;
	
	load_data ld(
		.resetn(resetn),
		.clk(CLOCK_50),
		.selection(SW[9:0]),
		
		.load_draw(load_draw),
		.select(load_select),
		.x_out(load_x),
		.y_out(load_y),
		.address(load_address),
		.health(load_health)
	);
	
	//* LOAD DATA LOGIC AREA *//
	
	wire [9:0]mem_x_in, mem_y_in, mem_x_out, mem_y_out;
	wire [1:0]mem_in_health, mem_out_health, brick_health;
	wire mem_write;
	
	wire [9:0]fsm_brick_x, fsm_brick_y;
//			.go(go_brick),
//			.health(health),
//			.x_in(brick_x),
//			.y_in(brick_y),
	
	//temp assign gamehealth and gamewrite
	
	assign mem_x_in  			= (load_select) ? game_mx : load_x;
	assign mem_y_in  			= (load_select) ? game_my : load_y;
	assign mem_in_health 	= (load_select) ? game_health : load_health;
	assign mem_write 			= (load_select) ? game_write: load_draw;
	
	//FIX LOAD
	assign go_bricks 		= (load_select) ? fsm_brick_draw : load_draw;
	assign brick_health 	= (load_select) ? mem_out_health : load_health;
	assign brick_x			= (load_select) ? fsm_brick_x : load_x;
	assign brick_y			= (load_select) ? fsm_brick_y : load_y;
	
	//* LOAD DATA LOGIC AREA *//
	
	
	//game_logic
	brick_memory bm(
		.clk(CLOCK_50),
		.resetn(resetn),
		.x_in(mem_x_in),
		.y_in(mem_y_in),
		.wren(mem_write),
		.health_in(mem_in_health),
		
		.health(mem_out_health),
		.x(mem_x_out),
		.y(mem_y_out)
	);
	
	wire [9:0] col_x1, col_x2, col_y1, col_y2;
	wire col_1, col_2;
	
	ball_logic balllogic(
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.x_du(x_du),
		.y_du(y_du),
		.logic_go(inc_enable),
		
		.x(ball_x),
		.x_max(screen_x),
		.y(ball_y),
		.y_max(screen_y),
		.size(size),
		.brickx_in(mem_x_out),
		.bricky_in(mem_y_out),
		.platx(platx_for_real),
		.health(brick_health),
		
		.game_health(game_health),
		.game_write(game_write),
		.memx(game_mx),
		.memy(game_my),
	
		.col_x1(col_x1),
		.col_x2(col_x2),
		.col_y1(col_y1),
		.col_y2(col_y2),
	
		.collided_1(col_1),
		.collided_2(col_2)
	);
	
	ball_pos ballpos(
		.enable(inc_enable),
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.x_du(x_du),
		.y_du(y_du),
		.x(ball_x),
		.y(ball_y)
	);
	
	//Wires for draw values.
	wire [9:0]ball_dx,brick_dx,plat_dx,ball_dy,brick_dy,plat_dy;
	wire [2:0]ball_colour,brick_colour,plat_colour;
	wire ball_en, brick_en, plat_en;
	
	wire [9:0]x_vga,y_vga;
	wire [2:0]colour_vga;
	wire writeEn_vga;
	
	//drawfunctions
	ball_draw balldraw(
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.go(go_ball),
		.x_in(ball_x),
		.y_in(ball_y),
		.size(size),
		
		.writeEn(ball_en),
		.x_out(ball_dx),
		.y_out(ball_dy),
		.colour(ball_colour)
	);
	
	/*  BRICK MODULE LOCATION  */
	
	brick_fsm bfsm(
		.resetn(resetn),
		.clk(CLOCK_50),
		.go(go_bricks_fsm),
		
		.col_x1(col_x1), 
		.col_x2(col_x2), 
		.col_y1(col_y1), 
		.col_y2(col_y2),
		
		.collided_1(col_1), 
		.collided_2(col_2),
		
		.brickx(fsm_brick_x), 
		.bricky(fsm_brick_y),
		.go_draw(fsm_brick_draw)
	);
	
		brick_draw bd(
			.resetn(resetn),
			.clk(CLOCK_50),
			.go(go_bricks),
			.health(brick_health),
			.x_in(brick_x),
			.y_in(brick_y),
			
			
			.writeEn(brick_en),
			.x_out(brick_dx),
			.y_out(brick_dy),
			.color(brick_colour)
		);
	
	platform platlog(
		.clk(CLOCK_50),
		.resetn(resetn),
		.left(left),
		.right(right),
		.enable(inc_enable),
		.draw(go_plat),
		
		.x(plat_dx),
		.y(plat_dy),
		.colour(plat_colour),
		.writeEn(plat_en),
		
		.d_x(platx_for_real)
	);
	
	//MUX
	draw_mux drawmux(
		.ball_x(ball_dx),
		.brick_x(brick_dx),
		.plat_x(plat_dx),
		.ball_y(ball_dy),
		.brick_y(brick_dy),
		.plat_y(plat_dy),
		
		.ball_colour(ball_colour),
		.brick_colour(brick_colour),
		.plat_colour(plat_colour),
		
		.ball_en(ball_en), 
		.brick_en(brick_en), 
		.plat_en(plat_en),
		
		.draw_mux(draw_mux),
		
		.iscolour(iscolour),
		
		.x(x_vga),
		.y(y_vga),
		.writeEn(writeEn_vga),
		.colour(colour_vga)
	);
	
	//draw
	draw draw(
		.resetn(resetn),
		.clk(CLOCK_50),
		
		.x(x_vga),
		.y(y_vga),
		.writeEn(writeEn_vga),
		.colour(colour_vga),
		
		// The ports below are for the VGA output.  Do not change.
		.VGA_CLK(VGA_CLK),   						//	VGA Clock
		.VGA_HS(VGA_HS),							//	VGA H_SYNC
		.VGA_VS(VGA_VS),							//	VGA V_SYNC
		.VGA_BLANK_N(VGA_BLANK_N),						//	VGA BLANK
		.VGA_SYNC_N(VGA_SYNC_N),						//	VGA SYNC
		.VGA_R(VGA_R),   						//	VGA Red[9:0]
		.VGA_G(VGA_G),	 						//	VGA Green[9:0]
		.VGA_B(VGA_B)   						   //	VGA Blue[9:0]
	);
	
	//delay
	delay_counter delaycounter(
		.clk(CLOCK_50),
		.resetn(resetn & load_select),
		.delay(delay),
		
		.d_enable(enable)
	);
	
endmodule

//MAIN FSM
module draw_fsm(
	input enable,
	input resetn,
	input clk,
	
	output reg go_ball, go_bricks, go_plat,
	output reg [1:0] draw_mux,
	output reg iscolour,
	output reg inc_enable
	);
	
	reg [3:0] current_state, next_state;
	
	localparam	S_FSM_WAIT		= 4'd0,
					S_BALL_LOAD 	= 4'd1,
					S_BALL_DRAW 	= 4'd2,
					S_BRICKS_LOAD	= 4'd3,
					S_BRICKS_DRAW	= 4'd4,
					S_PLAT_LOAD		= 4'd5,
					S_PLAT_DRAW		= 4'd6,
					S_INC				= 4'd7,
					S_INC_DELAY		= 4'd8,
					S_CHANGE			= 4'd9;
					
	//CONSTANTS AND COUNTER VARIABLES
	reg delay_reset, changecolour;
	wire [19:0] ball_delay, brick_delay, plat_delay, logic_delay;
	reg [19:0] delay;
	
	assign ball_delay 	= 20'd30;
	assign brick_delay	= `BRICKDRAWTWO;
	assign plat_delay 	= 20'd10;
	assign logic_delay  	= 20'd12;
	
	wire [19:0]count;
	
	counter drawdelay(
		.enable(1'b1),
		.clk(clk),
		.resetn(delay_reset),
		
		.c_x(count)
	);
	
	always @(*)begin
		case (current_state)
				S_FSM_WAIT: next_state = (enable | iscolour) ? S_BALL_LOAD : S_FSM_WAIT;
				S_BALL_LOAD: next_state = S_BALL_DRAW;
				S_BALL_DRAW: next_state = (count == delay) ? S_BRICKS_LOAD : S_BALL_DRAW;
				S_BRICKS_LOAD: next_state = (iscolour) ? S_BRICKS_DRAW : S_PLAT_LOAD;
				S_BRICKS_DRAW: next_state = (count == delay) ? S_PLAT_LOAD : S_BRICKS_DRAW;
				S_PLAT_LOAD: next_state = S_PLAT_DRAW;
				S_PLAT_DRAW: next_state = (count == delay) ? S_INC : S_PLAT_DRAW;
				S_INC: next_state = S_INC_DELAY;
				S_INC_DELAY: next_state = ((count == delay)| iscolour) ? S_CHANGE : S_INC_DELAY;
				S_CHANGE: next_state = S_FSM_WAIT;
				default: next_state = S_FSM_WAIT;
		endcase
	end
	
	always @(*)begin
		go_ball = 0;
		go_bricks = 0;
		go_plat = 0;
		draw_mux = 0;
		
		delay = 20'd0 - 20'd1;
		delay_reset = 1;
		
		inc_enable = 0;
		changecolour = 0;
		
		case (current_state)
			S_BALL_LOAD: begin 
				go_ball = 1;
				draw_mux = 2'd1;
				delay_reset = 0;
				delay = ball_delay;
			end
			S_BALL_DRAW: begin 
				delay = ball_delay;
				draw_mux = 2'd1;
			end
			S_BRICKS_LOAD: begin 
				go_bricks = 1;
				draw_mux = 2'd0;
				delay_reset = 0;
				delay = brick_delay;
			end
			S_BRICKS_DRAW: begin 
				delay = brick_delay;
				draw_mux = 2'd0;
			end
			S_PLAT_LOAD: begin 
				go_plat = 1;
				draw_mux = 2'd2;
				delay_reset = 0;
			end
			S_PLAT_DRAW: begin 
				delay = plat_delay;
				draw_mux = 2'd2;
			end
			S_INC: begin
				if(~iscolour)
					inc_enable = 1;
				delay_reset = 0;
			end
			S_INC_DELAY:begin
				if(~iscolour)
					delay = logic_delay;
			end
			S_CHANGE: begin
				changecolour = 1;
			end
		endcase
	end
	
	always @(posedge clk) begin
		if(!resetn)
			iscolour <= 0;
		if(changecolour)
			iscolour <= ~iscolour;
	end
	 	 
   // current_state registers
   always@(posedge clk)
   begin: state_FFs
       if(!resetn)
           current_state <= S_FSM_WAIT;
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
	
	output			VGA_CLK,   				//	VGA Clock
	output			VGA_HS,					//	VGA H_SYNC
	output			VGA_VS,					//	VGA V_SYNC
	output			VGA_BLANK_N,				//	VGA BLANK
	output			VGA_SYNC_N,				//	VGA SYNC
	output	[9:0]	VGA_R,   				//	VGA Red[9:0]
	output	[9:0]	VGA_G,	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B   					//	VGA Blue[9:0]
	);
	
	
//	vga_adapter VGA(
//		.resetn(resetn),
//		.clock(clk),
//		.colour(colour),
//		.x(x),
//		.y(y),
//		.plot(writeEn),
//		
//		/* Signals for the DAC to drive the monitor. */
//		.VGA_R(VGA_R),
//		.VGA_G(VGA_G),
//		.VGA_B(VGA_B),
//		.VGA_HS(VGA_HS),
//		.VGA_VS(VGA_VS),
//		.VGA_BLANK(VGA_BLANK_N),
//		.VGA_SYNC(VGA_SYNC_N),
//		.VGA_CLK(VGA_CLK));
//	defparam VGA.RESOLUTION = "160x120";
//	defparam VGA.MONOCHROME = "FALSE";
//	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
//	defparam VGA.BACKGROUND_IMAGE = "black.mif";
	
endmodule

module draw_mux(
	input [9:0]ball_x,brick_x,plat_x,ball_y,brick_y,plat_y,
	input [2:0]ball_colour,brick_colour,plat_colour,
	input ball_en, brick_en, plat_en,
	input [1:0]draw_mux,
	input iscolour,
	
	output reg [9:0]x,y,
	output reg [2:0]colour,
	output reg writeEn
	);
	
	localparam BLACK = 3'b000;
	
	always @(*)begin
		case(draw_mux)
			2'd1:begin 
				x = ball_x;
				y = ball_y;
				colour = (iscolour) ? ball_colour : BLACK;
				writeEn = ball_en;
			end
			2'd0:begin 
				x = brick_x;
				y = brick_y;
				colour = (iscolour) ? brick_colour : BLACK;
				writeEn = brick_en;
			end
			2'd2:begin 
				x = plat_x;
				y = plat_y;
				colour = (iscolour) ? plat_colour : BLACK;
				writeEn = plat_en;
			end
			default: begin
				x = brick_x;
				y = brick_y;
				colour = (iscolour) ? brick_colour : BLACK;
				writeEn = brick_en;
			end
		endcase
	end
	
endmodule


