`ifndef macros_vh
// NOTE: for Verilog 1995 `ifndef is not supported use `ifdef macros_vh `else
`define macros_vh
/**************
* your macros *
* `define ... *
***************/
`define GRIDX 10'd16
`define GRIDY 10'd4
`define BRICKNUM 20'd64
`define BRICKX 10'd4
`define BRICKY 10'd2
`define BRICKDRAW 20'd16
`define BRICKDRAWTWO 20'd32
`define PLATY 10'd64
`define PLATSIZE 10'd20
`endif

module ball_logic(
	input resetn,
	input clk,
	input logic_go,
	
	input [9:0]x, x_max,
	input [9:0]y, y_max,
	input [9:0]size,
	input [9:0]brickx_in, bricky_in, platx,
	input [1:0]health,
	
	output [9:0]memx, memy,
	output x_du, y_du,
	
	output [9:0] col_x1, col_x2, col_y1, col_y2,
	
	output collided_1, collided_2
	);
	
	reg x_dir, y_dir;
	wire plat_collided;
	
	ball_platform bp(
		.resetn(resetn),
		.clk(clk),
		.enable(logic_go),
	
		.goingdown(y_du),
		.size(size),
		.ballx(x),
		.platx(platx),
	
		.collided(plat_collided)
	);
	
	ball_collision bc(
		.resetn(resetn),
		.clk(clk),
		.enable(logic_go),
		
		.size(size),
		
		.x_du(x_du),
		.y_du(y_du),
		
		.ballx(x),
		.bally(y),
		.brickx(brickx_in),
		.bricky(bricky_in),
		
		.health(health),
		
		.memx(memx),
		.memy(memy),
		.col_x1(col_x1), 
		.col_x2(col_x2), 
		.col_y1(col_y1), 
		.col_y2(col_y2),
		.collided_1(collided_1), 
		.collided_2(collided_2)
	);
	
	reg logic_x, logic_y;
	
	always @(posedge clk)begin
		if(!resetn) begin
			x_dir <= 0;
			y_dir <= 0;
			logic_x <= 0;
			logic_y <= 0;
		end
		else begin
			if(logic_go) begin
				logic_x = 1'b1;
				logic_y = 1'b1;
			end
			case (x)
				x_max - size:	x_dir = 0;
				0				:  x_dir = 1;
				default		:  begin
					if(logic_x & collided_2) begin
						x_dir = ~x_dir;
						logic_x = 0;
					end
				end
			endcase
			case (y)
				y_max - size: y_dir = 0;
				0				: y_dir = 1;
				default		: begin 
					if(logic_y & (collided_1 | plat_collided)) begin
						y_dir = ~y_dir;
						logic_y = 0;
					end
				end
			endcase
		end
	end
	
	assign	x_du = x_dir;
	assign	y_du = y_dir;
	
endmodule

module ball_platform(
	input resetn,
	input clk,
	input enable,
	
	input goingdown,
	
	input [9:0]size,
	input [9:0]ballx,
	input [9:0]platx,
	
	output reg collided
	);
	wire [9:0]ball_xedge;
	assign ball_xedge = (ballx + size);
	
	always @(*)begin
		collided = 0;
		if(goingdown)begin
			if(ballx < (platx + `PLATSIZE))begin
				collided = 1;
			end
			
			if(ball_xedge > platx)begin
				collided = 1;
			end
		end
	end
	
endmodule

module ball_collision(
	input resetn,
	input clk,
	input enable,

	input [9:0]size,
	input x_du,
	input y_du,
	input [9:0]ballx, bally,
	input [9:0]brickx, bricky,
	input [1:0]health,
	
	output reg [9:0] memx, memy,
	output reg [9:0] col_x1, col_x2, col_y1, col_y2,
	output reg collided_1, collided_2
	);

	reg [3:0]current_state, next_state;
	
	localparam 	
					S_SETUP		= 4'd0,
					S_WAIT		= 4'd1,
					S_LOAD_1		= 4'd2,
					S_YLEFT		= 4'd3,
					S_LOAD_2		= 4'd4,
					S_YRIGHT		= 4'd5,
					S_LOAD_3		= 4'd6,
					S_XUP			= 4'd7,
					S_LOAD_4		= 4'd8,
					S_XDOWN 		= 4'd9;
					
	always @(*)
   begin: state_table 
			case (current_state)
					S_SETUP		: next_state = S_WAIT;
					S_WAIT		: next_state = (enable) ? S_LOAD_1 : S_WAIT;
					S_LOAD_1		: next_state = S_YLEFT;
					S_YLEFT		: next_state = S_LOAD_2;
					S_LOAD_2		: next_state = (collided_1) ? S_LOAD_3 : S_YRIGHT;
					S_YRIGHT		: next_state = S_LOAD_3;
					S_LOAD_3		: next_state = S_XUP;
					S_XUP			: next_state = S_LOAD_4;
					S_LOAD_4		: next_state = (collided_2) ? S_WAIT : S_XDOWN;
					S_XDOWN 		: next_state = S_WAIT;
            default:     	next_state = S_WAIT;
        endcase
   end // state_table
	 // current_state registers
   
	wire ball_yedge, ball_xedge;
	
	assign ball_yedge = (y_du) ? (bally + size) : bally;
	assign ball_xedge = (x_du) ? (ballx + size) : ballx;
	
	always @(*)begin
		memx = 0;
		memy = 0;
		case(current_state)
				S_SETUP: begin
					col_x1 = 0;
					col_x2 = 0;
					col_y1 = 0;
					col_y2 = 0;
					
					collided_1 = 0;
					collided_2 = 0;
				end
				S_LOAD_1		:begin
					memx <= ballx;
					memy <= ball_yedge;
				end
				S_YLEFT		:begin
					if(|health)begin
						collided_1 = 1;
						col_x1 <= brickx;
						col_y1 <= bricky;
					end
				end
				S_LOAD_2		:begin
					memx <= ballx + `BRICKX;
					memy <= ball_yedge;
				end
				S_YRIGHT	:begin
					if(|health)begin
						collided_1 = 1;
						col_x1 <= brickx;
						col_y1 <= bricky;
					end
				end
				S_LOAD_3		:begin
					memx <= ball_xedge;
					memy <= bally;
				end
				S_XUP	:begin
					if(|health)begin
						collided_2 = 1;
						col_x2 <= brickx;
						col_y2 <= bricky;
					end
				end
				S_LOAD_4		:begin
					memx <= ball_xedge;
					memy <= bally + `BRICKY;
				end
				S_XDOWN :begin
					if(|health)begin
						collided_2 = 1;
						col_x2 <= brickx;
						col_y2 <= bricky;
					end
				end
		endcase
	end
	
	always@(posedge clk)
   begin: state_FFs
       if(!resetn) 
            current_state <= S_SETUP;
       else
				current_state <= next_state;
   end // state_FFS	
endmodule



//module ball_logic_control(
//	input clk,
//	input resetn,
//	output reg get_brick
//	);
//	
//	reg current_state, next_state;
//
//	localparam 	S_GET_LR_BRICK	= 1'd0, //Get horizontal brick
//					S_GET_UD_BRICK = 1'd1; //Get vertical brick
//					
//	always @(*)
//   begin: state_table 
//			case (current_state)
//					S_GET_LR_BRICK: next_state = S_GET_UD_BRICK;
//					S_GET_UD_BRICK: next_state = S_GET_LR_BRICK;
//            default:     next_state = S_GET_LR_BRICK;
//        endcase
//   end // state_table
//	 
//	 always @(*)
//    begin: enable_signals
//		  get_brick = 0;
//        case (current_state)
//				S_GET_UD_BRICK:
//					get_brick = 0;
//            S_GET_UD_BRICK:
//					get_brick = 1;
//        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
//        endcase
//    end // enable_signals
//	 
//	 // current_state registers
//    always@(posedge clk)
//    begin: state_FFs
//        if(!resetn)
//            current_state <= S_GET_LR_BRICK;
//        else
//				current_state <= next_state;
//    end // state_FFS
//	
//endmodule
