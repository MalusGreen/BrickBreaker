`include "macros.v"

module ball_logic(
	input resetn,
	input clk,
	input logic_go,
	
	input [9:0]x, x_max,
	input [9:0]y, y_max,
	input [9:0]size,
	input [9:0]brickx_in, bricky_in, platx,
	input [1:0]health,
	
	output [1:0]game_health,
	output game_write,
	output [9:0]memx, memy,
	output x_du, y_du,
	
	output [9:0] col_x1, col_x2, col_y1, col_y2,
	output [1:0] col_health1, col_health2,
	output collided_1, collided_2,
	output plat_collided
	);
	
	reg x_dir, y_dir;
	wire update;
	
	ball_platform bp(
		.resetn(resetn),
		.clk(clk),
		.enable(logic_go),
	
		.bally(y),
		.size(size),
		.ballx(x),
		.platx(platx),
	
		.collided(plat_collided)
	);
	
	ball_collision bc( 
		.resetn(resetn), 
		.clk(clk), 
		.logic_go(logic_go), 
		
		.x_du(x_du), 
		.y_du(y_du), 
		
		.ballx(x), 
		.bally(y), 
		.brickx(brickx_in), 
		.bricky(bricky_in), 
		.update(update), 
		.brick_health(health), 
		
		.game_health(game_health), 
		.game_write(game_write), 
		.memx(memx), 
		.memy(memy), 
		.col_x1(col_x1), 
		.col_x2(col_x2), 
		.col_y1(col_y1), 
		.col_y2(col_y2), 
		.col_1(collided_1), 
		.col_2(collided_2), 
		
		.col_health1(col_health1),
		.col_health2(col_health2)
	);
	
	
	always @(posedge clk)begin
		if(!resetn) begin
			x_dir <= 0;
			y_dir <= 0;
		end
		else begin
			case (x)
				x_max 		:	x_dir <= 0;
				0				:  x_dir <= 1;
				default		:  begin
					if(update & collided_2) begin
						x_dir <= ~x_dir;
					end
				end
			endcase
			case (y)
				y_max 		: y_dir <= 0;
				0				: y_dir <= 1;
				default		: begin 
					if((plat_collided)) begin
						y_dir <= 0;
					end
					else if(update & collided_1)begin
						y_dir <= ~y_dir;
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
	
	input [9:0]bally,
	
	input [9:0]size,
	input [9:0]ballx,
	input [9:0]platx,
	
	output reg collided
	);
	wire [9:0]ball_xedge, ball_yedge;
	assign ball_yedge = (bally + size);
	assign ball_xedge = (ballx + size);
	
	always @(*)begin
		collided = 0;
		if(ball_yedge == `PLATY)begin
			if(ball_xedge > platx && ballx < (platx + `PLATSIZE))begin
				collided = 1;
			end
		end
	end
endmodule

module ball_collision(
	input resetn,
	input clk,
	input logic_go,
	input [9:0]ballx, bally,
	input [9:0]brickx, bricky,
	
	input x_du, y_du,
	
	input [1:0]brick_health,
	
	output update,
	output game_write,
	output [1:0]game_health,
	output [9:0]memx, memy,
	output [9:0]col_x1, col_x2, col_y1, col_y2,
	output col_1, col_2,
	
	output [1:0] col_health1, col_health2
	);
	
	
	wire waiting,
		  ldmem1, ldmem2, ldmem3,
		  ckcol1, ckcol2, ckcol3,
		  dec1, dec2, dec3;
	
	ball_col_control bcc(
		.resetn(resetn),
		.clk(clk),
		.logic_go(logic_go),
		
		.col_1(col_1),
		.col_2(col_2),
		
		.waiting(waiting),
		.ldmem1(ldmem1), 
		.ldmem2(ldmem2), 
		.ldmem3(ldmem3), 
		.ckcol1(ckcol1), 
		.ckcol2(ckcol2), 
		.ckcol3(ckcol3), 
		.dec1(dec1), 
		.dec2(dec2), 
		.dec3(dec3),
		.update(update)
	);
	
	ball_col_datapath bcd(
		.resetn(resetn),
		.clk(clk),
		
		.waiting(waiting),
		.ldmem1(ldmem1), 
		.ldmem2(ldmem2), 
		.ldmem3(ldmem3), 
		.ckcol1(ckcol1), 
		.ckcol2(ckcol2), 
		.ckcol3(ckcol3), 
		.dec1(dec1), 
		.dec2(dec2), 
		.dec3(dec3), 
		.x_du(x_du), 
		.y_du(y_du),
		
		.ballx(ballx), 
		.bally(bally), 
		.brickx(brickx), 
		.bricky(bricky), 
		.brick_health(brick_health), 
		
		.game_health(game_health),
		.game_write(game_write),
		.memx(memx), 
		.memy(memy), 
		.col_x1(col_x1), 
		.col_x2(col_x2), 
		.col_y1(col_y1), 
		.col_y2(col_y2), 
		
		.col_health1(col_health1),
		.col_health2(col_health2),
		
		.col_1(col_1),
		.col_2(col_2)
	);
	
endmodule

module ball_col_control(
	input resetn,
	input clk,
	input logic_go,
	
	input col_1, col_2,
	
	output reg waiting,
	output reg ldmem1, ldmem2, ldmem3,
	output reg ckcol1, ckcol2, ckcol3,
	output reg dec1, dec2, dec3,
	output reg update
	);
	
	reg [3:0]current_state, next_state;
	
	localparam 	S_WAIT	= 4'd0, 
					S_LDMEM1 = 4'd1, 
					S_LDMEMW1= 4'd2,
					S_CKCOL1 = 4'd3, 
					S_DEC1	= 4'd4, 
					S_LDMEM2 = 4'd5, 
					S_LDMEMW2= 4'd6, 
					S_CKCOL2 = 4'd7, 
					S_DEC2	= 4'd8, 
					S_LDMEM3 = 4'd9, 
					S_LDMEMW3= 4'd10, 
					S_CKCOL3 = 4'd11, 
					S_DEC3	= 4'd12,
					S_UPDATE = 4'd13;

	always @(*)begin
		case (current_state)
					S_WAIT	: next_state = (logic_go) ? S_LDMEM1 : S_WAIT;
					S_LDMEM1 : next_state = S_LDMEMW1;
					S_LDMEMW1: next_state = S_CKCOL1;
					S_CKCOL1 : next_state = S_DEC1;
					S_DEC1	: next_state = S_LDMEM2;
					S_LDMEM2 : next_state = S_LDMEMW2;
					S_LDMEMW2: next_state = S_CKCOL2;
					S_CKCOL2 : next_state = S_DEC2;
					S_DEC2	: next_state = S_LDMEM3;
					S_LDMEM3 : next_state = (col_1 | col_2) ? S_UPDATE : S_LDMEMW3;
					S_LDMEMW3: next_state = S_CKCOL3;
					S_CKCOL3 : next_state = S_DEC3;
					S_DEC3	: next_state = S_UPDATE;
					S_UPDATE	: next_state = S_WAIT;
					default	: next_state = S_WAIT;
		endcase
	end
	
	always @(*)begin
		waiting= 0;
		ldmem1 = 0;
		ldmem2 = 0;
		ldmem3 = 0;
		ckcol1 = 0;
		ckcol2 = 0;
		ckcol3 = 0;
		dec1	 = 0;
		dec2	 = 0;
		dec3	 = 0;
		update = 0;
		
		case(current_state)
				S_WAIT	: waiting= 1;
				S_LDMEM1 : ldmem1 = 1;
				S_CKCOL1 : ckcol1 = 1;
				S_DEC1	: dec1	= 1;
				S_LDMEM2 : ldmem2 = 1;
				S_CKCOL2 : ckcol2 = 1;
				S_DEC2	: dec2	= 1;
				S_LDMEM3 : ldmem3 = 1;
				S_CKCOL3 : ckcol3 = 1;
				S_DEC3	: dec3	= 1;
				S_UPDATE	: update = 1;
		endcase
	end
	
	always@(posedge clk)
   begin: state_FFs
       if(!resetn) 
            current_state <= S_WAIT;
       else
				current_state <= next_state;
   end // state_FFS
					
endmodule

module ball_col_datapath(
	input resetn,
	input clk,
	
	input waiting,
	input ldmem1, ldmem2, ldmem3,
	input ckcol1, ckcol2, ckcol3,
	input dec1, dec2, dec3, 
	input x_du, y_du,

	input [9:0] ballx, bally,
	input [9:0] brickx, bricky,
	input [1:0] brick_health,
	
	output reg [1:0] game_health,
	output reg game_write,
	output reg [9:0] memx, memy,
	output reg [9:0] col_x1, col_x2, col_y1, col_y2,
	output reg col_1, col_2,
	output reg [1:0] col_health1, col_health2
	);
	
	reg [9:0] x_new, y_new;
	
	always @(posedge clk)begin
		if(!resetn)begin
			memx <= 0;
			memy <= 0;
			col_x1 <= 0;
			col_x2 <= 0;
			col_y1 <= 0;
			col_y2 <= 0;
			col_1 <= 0;
			col_2 <= 0;
			game_health <= 0;
			game_write <= 0;
			
			col_health1 <= 0;
			col_health2 <= 0;
		end
		else if(waiting)begin
			x_new <= (x_du) ? ballx + 10'd1: ballx - 10'd1;
			y_new <= (y_du) ? bally + 10'd1: bally - 10'd1;
		end
		else if(ldmem1)begin
			col_1 <= 0;
			memx <= ballx;
			memy <= y_new;
			game_write <= 0;
		end
		else if(ldmem2)begin
			col_2 <= 0;
			memx <= x_new;
			memy <= bally;
			game_write <= 0;
		end
		else if(ldmem3)begin
			memx <= x_new;
			memy <= y_new;
			game_write <= 0;
		end
		else if(ckcol1)begin
			if(brick_health[0] | brick_health[1])begin
				col_1 <= 1;
				col_x1 <= brickx;
				col_y1 <= bricky;
				game_health <= brick_health - 2'd1;
			end
		end
		else if(ckcol2)begin
			if(brick_health[0] | brick_health[1])begin
				col_2 <= 1;
				col_x2 <= brickx;
				col_y2 <= bricky;
				game_health <= brick_health - 2'd1;
			end
		end
		else if(ckcol3)begin
			if(brick_health[0] | brick_health[1])begin
				col_1 = 1;
				col_2 = 1;
				col_x1 <= brickx;
				col_y1 <= bricky;
				col_x2 <= brickx;
				col_y2 <= bricky;
				game_health <= brick_health - 2'd1;
			end
		end
		else if(dec1)	 begin
			if(col_1)begin
				game_write = 1;
				col_health1 <= game_health;
			end
		end
		else if(dec2)	 begin
			if(col_2)begin
				game_write = 1;
				col_health2 <= game_health;
			end
		end
		else if(dec3)	 begin
			if(col_1)begin
				game_write = 1;
				col_health1 <= game_health;
				col_health2 <= game_health;
			end
		end
	end

endmodule
//module ball_collision(
//	input resetn,
//	input clk,
//	input enable,
//
//	input [9:0]size,
//	input x_du,
//	input y_du,
//	input [9:0]ballx, bally,
//	input [9:0]brickx, bricky,
//	input [1:0]health,
//	
//	output update,
//	output [1:0]game_health,
//	output game_write,
//	output [9:0] memx, memy,
//	output [9:0] col_x1, col_x2, col_y1, col_y2,
//	output collided_1, collided_2,
//	output col_check_1, col_check_2
//	);
////	reg [3:0]current_state, next_state;
////	
////	localparam 	
////					S_SETUP		= 4'd0,
////					S_WAIT		= 4'd1,
////					S_LOAD_1		= 4'd2,
////					S_YLEFT		= 4'd3,
////					S_LOAD_2		= 4'd4,
////					S_YRIGHT		= 4'd5,
////					S_LOAD_3		= 4'd6,
////					S_XUP			= 4'd7,
////					S_LOAD_4		= 4'd8,
////					S_XDOWN 		= 4'd9,
////					S_CHANGE		= 4'd10;
////					
////	wire checklr, checkud;
////	
////	always @(*)
////   begin: state_table 
////			case (current_state)
////					S_SETUP		: next_state = S_WAIT;
////					S_WAIT		: next_state = (enable) ? S_LOAD_1 : S_WAIT;
////					S_LOAD_1		: next_state = (checkud) ? S_YLEFT: S_LOAD_3;
////					S_YLEFT		: next_state = S_LOAD_2;
////					S_LOAD_2		: next_state = (collided_1) ? S_LOAD_3 : S_YRIGHT;
////					S_YRIGHT		: next_state = S_LOAD_3;
////					S_LOAD_3		: next_state = (checklr) ? S_XUP : S_WAIT;
////					S_XUP			: next_state = S_LOAD_4;
////					S_LOAD_4		: next_state = (collided_2) ? S_CHANGE : S_XDOWN;
////					S_XDOWN 		: next_state = S_CHANGE;
////					S_CHANGE		: next_state = S_WAIT;
////            default:     	next_state = S_WAIT;
////        endcase
////   end // state_table
////	 // current_state registers
////   
////	wire [9:0]ball_yedge, ball_xedge;
////	wire check_twicex, check_twicey;
////	
////	assign ball_yedge = (y_du) ? (bally + size) : bally;
////	assign ball_xedge = (x_du) ? (ballx + size) : ballx;
////	
////	assign checklr = (ball_xedge % `BRICKX) == 0;
////	assign checkud = (ball_yedge % `BRICKY) == 0;
////	
////	assign check_twicex = ((ballx + size)/`BRICKX) > (ballx/`BRICKX);
////	assign check_twicey = ((bally + size)/`BRICKY) > (bally/`BRICKY);
////	
////	assign game_health = health - 1;
////	
////	always @(*)begin
////		change = 0;
////		game_write = 0;
////		case(current_state)
////				S_SETUP: begin
////					col_x1 = 0;
////					col_x2 = 0;
////					col_y1 = 0;
////					col_y2 = 0;
////					memx = 0;
////					memy = 0;
////					collided_1 = 0;
////					collided_2 = 0;
////				end
////				S_LOAD_1		:begin
////					collided_1 = 0;
////					collided_2 = 0;
////					memx <= ballx;
////					memy <= (y_du) ? ball_yedge + 1 : ball_yedge - 1;
////				end
////				S_YLEFT		:begin
////					if(|health)begin
////						collided_1 = 1;
////						col_x1 <= memx;
////						col_y1 <= memy;
////						game_write = 1;
////					end
////				end
////				S_LOAD_2		:begin
////					memx <= ballx + `BRICKX;
////				end
////				S_YRIGHT	:begin
////					if(|health & check_twicex)begin
////						collided_1 = 1;
////						col_x1 <= memx;
////						col_y1 <= memy;
////						game_write = 1;
////					end
////				end
////				S_LOAD_3		:begin
////					memx <= (x_du) ? ball_xedge + 1 : ball_xedge - 1;
////					memy <= bally;
////				end
////				S_XUP	:begin
////					if(|health)begin
////						collided_2 = 1;
////						col_x2 <= memx;
////						col_y2 <= memy;
////						game_write = 1;
////					end
////				end
////				S_LOAD_4		:begin
////					memy <= bally + `BRICKY;
////				end
////				S_XDOWN :begin
////					if(|health & check_twicey)begin
////						collided_2 = 1;
////						col_x2 <= memx;
////						col_y2 <= memy;
////						game_write = 1;
////					end
////				end
////				S_CHANGE: begin
////					change = 1;
////				end
////		endcase
////	end
////	
////	always@(posedge clk)
////   begin: state_FFs
////       if(!resetn) 
////            current_state <= S_SETUP;
////       else
////				current_state <= next_state;
////   end // state_FFS	
////
////module ball_logic_control(
////	input clk,
////	input resetn,
////	output reg get_brick
////	);
////	
////	reg current_state, next_state;
////
////	localparam 	S_GET_LR_BRICK	= 1'd0, //Get horizontal brick
////					S_GET_UD_BRICK = 1'd1; //Get vertical brick
////					
////	always @(*)
////   begin: state_table 
////			case (current_state)
////					S_GET_LR_BRICK: next_state = S_GET_UD_BRICK;
////					S_GET_UD_BRICK: next_state = S_GET_LR_BRICK;
////            default:     next_state = S_GET_LR_BRICK;
////        endcase
////   end // state_table
////	 
////	 always @(*)
////    begin: enable_signals
////		  get_brick = 0;
////        case (current_state)
////				S_GET_UD_BRICK:
////					get_brick = 0;
////            S_GET_UD_BRICK:
////					get_brick = 1;
////        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
////        endcase
////    end // enable_signals
////	 
////	 // current_state registers
////    always@(posedge clk)
////    begin: state_FFs
////        if(!resetn)
////            current_state <= S_GET_LR_BRICK;
////        else
////				current_state <= next_state;
////    end // state_FFS
////	
////endmodule		
//		wire check_twicex, check_twicey;
//		wire checkud, checklr;
//		
//		wire ldmem_1;
//		wire ldmem_2;
//		wire ldmem_3;
//		wire ldmem_4;
//		wire lddec_1;
//		wire lddec_2;
////		wire col_check_1;
////		wire col_check_2;
//		wire health_dec;
//		wire calc_health;
//	
//	ball_collision_control bcc(
//		.resetn(resetn),
//		.clk(clk),
//		.enable(enable),
//		
//		.collided_1(collided_1),
//		.collided_2(collided_2),
//		
//		.check_twicex(check_twicex),
//		.check_twicey(check_twicey),
//		
//		.checkud(checkud),
//		.checklr(checklr),
//		.ldmem_1(ldmem_1),
//		.ldmem_2(ldmem_2),
//		.ldmem_3(ldmem_3),
//		.ldmem_4(ldmem_4),
//		.lddec_1(lddec_1),
//		.lddec_2(lddec_2),
//		.col_check_1(col_check_1),
//		.col_check_2(col_check_2),
//		.update(update),
//		.health_dec(health_dec),
//		.calc_health(calc_health)
//	);
//	
//	ball_collision_datapath bcd(
//		.resetn(resetn),
//		.clk(clk),
//		
//		.size(size),
//		.ldmem_1(ldmem_1),
//		.ldmem_2(ldmem_2),
//		.ldmem_3(ldmem_3),
//		.ldmem_4(ldmem_4),
//		.lddec_1(lddec_1),
//		.lddec_2(lddec_2),
//		.col_check_1(col_check_1),
//		.col_check_2(col_check_2),
//		.calc_health(calc_health),
//		
//		.x_du(x_du),
//		.y_du(y_du),
//		.ballx(ballx), 
//		.bally(bally),
//		.brickx(brickx),
//		.bricky(bricky),
//		.brick_health(health),
//		
//		.checkud(checkud), 
//		.checklr(checklr),
//		.check_twicex(check_twicex),
//		.check_twicey(check_twicey),
//		.game_write(game_write),
//		.game_health(game_health),
//		.memx(memx), 
//		.memy(memy),
//		.col_x1(col_x1), 
//		.col_x2(col_x2), 
//		.col_y1(col_y1), 
//		.col_y2(col_y2),
//		.collided_1(collided_1), 
//		.collided_2(collided_2)
//	);
//
//endmodule
//
//module ball_collision_control(
//		input resetn,
//		input clk,
//		input enable,
//		
//		input collided_1, collided_2,
//		input check_twicex, check_twicey,
//		input checkud, checklr,
//		
//		output reg ldmem_1,
//		output reg ldmem_2,
//		output reg ldmem_3,
//		output reg ldmem_4,
//		output reg lddec_1,
//		output reg lddec_2,
//		output reg col_check_1,
//		output reg col_check_2,
//		output reg update,
//		output reg health_dec,
//		output reg calc_health
//	);
//	reg [3:0]current_state, next_state;
//	
//	localparam 	
////					S_SETUP		= 4'd0,
//					S_WAIT		= 4'd0,
//					S_LOAD_1		= 4'd1,
//					S_YLEFT		= 4'd2,
//					S_LOAD_2		= 4'd3,
//					S_YRIGHT		= 4'd4,
//					S_LOAD_3		= 4'd5,
//					S_XUP			= 4'd6,
//					S_LOAD_4		= 4'd7,
//					S_XDOWN 		= 4'd8,
//					S_CHANGE		= 4'd9,
//					S_LOADCOL_1	= 4'd10,
//					S_CALC_1		= 4'd11,
//					S_HEALTH_1	= 4'd12,
//					S_LOADCOL_2	= 4'd13,
//					S_CALC_2		= 4'd14,
//					S_HEALTH_2	= 4'd15;
//	
//	always @(*)
//   begin: state_table 
//			case (current_state)
////					S_SETUP		: next_state = S_WAIT;
//					S_WAIT		: next_state = (enable) ? S_LOAD_1 : S_WAIT;
//					S_LOAD_1		: next_state = (checkud) ? S_YLEFT: S_LOAD_3;
//					S_YLEFT		: next_state = S_LOAD_2;
//					S_LOAD_2		: next_state = (collided_1 | ~check_twicex) ? S_LOAD_3 : S_YRIGHT;
//					S_YRIGHT		: next_state = S_LOAD_3;
//					S_LOAD_3		: next_state = (checklr) ? S_XUP : S_CHANGE;
//					S_XUP			: next_state = S_LOAD_4;
//					S_LOAD_4		: next_state = (collided_2 | ~check_twicey) ? S_CHANGE : S_XDOWN;
//					S_XDOWN 		: next_state = S_CHANGE;
//					S_CHANGE		: next_state = S_CALC_1;
//					S_CALC_1		: next_state = S_LOADCOL_1;
//					S_LOADCOL_1	: next_state = S_HEALTH_1;
//					S_HEALTH_1	: next_state = S_CALC_2;
//					S_CALC_2		: next_state = S_LOADCOL_2;
//					S_LOADCOL_2	: next_state = S_HEALTH_2;
//					S_HEALTH_2	: next_state = S_WAIT;
//            default:     	next_state = S_WAIT;
//        endcase
//   end // state_table
//	 // current_state registers
//	
//	always @(*)begin
//		ldmem_1 = 0;
//		ldmem_2 = 0;
//		ldmem_3 = 0;
//		ldmem_4 = 0;
//		lddec_1 = 0;
//		lddec_2 = 0;
//		update = 0;
//		col_check_1 = 0;
//		col_check_2 = 0;
//		health_dec = 0;
//		calc_health = 0;
//		case(current_state)
////					S_SETUP		:
//					S_LOAD_1		:
//						ldmem_1 = 1;
//					S_YLEFT		:
//						col_check_1 = 1;
//					S_LOAD_2		:
//						ldmem_2 = 1;
//					S_YRIGHT		:
//						col_check_1 = 1;
//					S_LOAD_3		:
//						ldmem_3 = 1;
//					S_XUP			:
//						col_check_2 = 1;
//					S_LOAD_4		:
//						ldmem_4 = 1;
//					S_XDOWN 		:
//						col_check_2 = 1;
//					S_CHANGE	:begin
//						update = 1;
//					end
//					S_LOADCOL_1	:begin
//						lddec_1 = 1;
//					end
//					S_CALC_1:
//						calc_health = 1;
//					S_HEALTH_1	:begin
//						if(collided_1)
//							health_dec = 1;
//					end
//					S_LOADCOL_2	:
//						lddec_2 = 1;
//					S_CALC_2:
//						calc_health = 1;
//					S_HEALTH_2	:begin
//						if(collided_2)
//							health_dec = 1;
//					end
//		endcase
//	end
//	
//	always@(posedge clk)
//   begin: state_FFs
//       if(!resetn) 
//            current_state <= S_WAIT;
//       else
//				current_state <= next_state;
//   end // state_FFS
//endmodule

//module ball_collision_datapath(
//	input resetn,
//	input clk,
//	
//	input ldmem_1,
//	input ldmem_2,
//	input ldmem_3,
//	input ldmem_4,
//	input lddec_1,
//	input lddec_2,
//	input col_check_1,
//	input col_check_2,
//	input calc_health,
//	
//	input [9:0]size,
//	input x_du, y_du,
//	input [9:0]ballx, bally,
//	input [9:0]brickx, bricky,
//	input [1:0]brick_health,
//	
//	output reg game_write,
//	output checkud, checklr,
//	output reg [1:0]game_health,
//	output reg [9:0] memx, memy,
//	output reg [9:0] col_x1, col_x2, col_y1, col_y2,
//	output reg collided_1, collided_2,
//	output check_twicex, check_twicey
//	);
//
//	wire [9:0] ball_xedge, ball_yedge;
//	
//	
//	assign ball_yedge = (y_du) ? (bally + size) : bally;
//	assign ball_xedge = (x_du) ? (ballx + size) : ballx;
//	
//			
//	assign checkud = 1;
////	(ball_xedge % `BRICKX) == 0;
//	assign checklr = 1;
////	(ball_yedge % `BRICKY) == 0;
//	assign check_twicex = ((ballx + size)/`BRICKX) > (ballx/`BRICKX);
//	assign check_twicey = ((bally + size)/`BRICKY) > (bally/`BRICKY);
//		
//	
//	always @(posedge clk) begin
//		if(!resetn)begin
//			game_write <= 0;
//			game_health <= 0;
//			memx <= 0;
//			memy <= 0;
//			col_x1 <= 0;
//			col_x2 <= 0;
//			col_y1 <= 0;
//			col_y2 <= 0;
//			collided_1 <= 0;
//			collided_2 <= 0;
//		end
//		else begin
//			if(ldmem_1)begin
//					collided_1 = 0;
//					memx <= ballx;
//					memy <= (y_du) ? ball_yedge + 1 : ball_yedge - 1;
//			end
//			if(ldmem_2)begin
//					collided_1 = 0;
//					memx <= ballx + `BRICKX;
//					memy <= (y_du) ? ball_yedge + 1 : ball_yedge - 1;
//			end
//			if(ldmem_3)begin
//					collided_2 = 0;
//					memx <= (x_du) ? ball_xedge + 1 : ball_xedge - 1;
//					memy <= bally;
//			end
//			if(ldmem_4)begin
//					collided_2 = 0;
//					memx <= (x_du) ? ball_xedge + 1 : ball_xedge - 1;
//					memy <= bally + `BRICKY;
//			end
//			if(calc_health)begin
//				game_health <= brick_health - 1;
//			end
//			if(lddec_1)begin
//				col_x1 <= memx;
//				col_y1 <= memy;
//			end
//			if(lddec_2)begin
//				col_x2 <= memx;
//				col_y2 <= memy;
//			end
//			if(col_check_1)begin
//				if(|brick_health)begin
//					collided_1 = 1;
//					col_x1 <= brickx;
//					col_y1 <= bricky;
//				end
//			end
//			if(col_check_2)begin
//				if(|brick_health)begin
//					collided_2 = 1;
//					col_x2 <= brickx;
//					col_y2 <= bricky;
//				end
//			end
//		end
//	end
//endmodule

//	reg [3:0]current_state, next_state;
//	
//	localparam 	
//					S_SETUP		= 4'd0,
//					S_WAIT		= 4'd1,
//					S_LOAD_1		= 4'd2,
//					S_YLEFT		= 4'd3,
//					S_LOAD_2		= 4'd4,
//					S_YRIGHT		= 4'd5,
//					S_LOAD_3		= 4'd6,
//					S_XUP			= 4'd7,
//					S_LOAD_4		= 4'd8,
//					S_XDOWN 		= 4'd9,
//					S_CHANGE		= 4'd10;
//					
//	wire checklr, checkud;
//	
//	always @(*)
//   begin: state_table 
//			case (current_state)
//					S_SETUP		: next_state = S_WAIT;
//					S_WAIT		: next_state = (enable) ? S_LOAD_1 : S_WAIT;
//					S_LOAD_1		: next_state = (checkud) ? S_YLEFT: S_LOAD_3;
//					S_YLEFT		: next_state = S_LOAD_2;
//					S_LOAD_2		: next_state = (collided_1) ? S_LOAD_3 : S_YRIGHT;
//					S_YRIGHT		: next_state = S_LOAD_3;
//					S_LOAD_3		: next_state = (checklr) ? S_XUP : S_WAIT;
//					S_XUP			: next_state = S_LOAD_4;
//					S_LOAD_4		: next_state = (collided_2) ? S_CHANGE : S_XDOWN;
//					S_XDOWN 		: next_state = S_CHANGE;
//					S_CHANGE		: next_state = S_WAIT;
//            default:     	next_state = S_WAIT;
//        endcase
//   end // state_table
//	 // current_state registers
//   
//	wire [9:0]ball_yedge, ball_xedge;
//	wire check_twicex, check_twicey;
//	
//	assign ball_yedge = (y_du) ? (bally + size) : bally;
//	assign ball_xedge = (x_du) ? (ballx + size) : ballx;
//	
//	assign checklr = (ball_xedge % `BRICKX) == 0;
//	assign checkud = (ball_yedge % `BRICKY) == 0;
//	
//	assign check_twicex = ((ballx + size)/`BRICKX) > (ballx/`BRICKX);
//	assign check_twicey = ((bally + size)/`BRICKY) > (bally/`BRICKY);
//	
//	assign game_health = health - 1;
//	
//	always @(*)begin
//		change = 0;
//		game_write = 0;
//		case(current_state)
//				S_SETUP: begin
//					col_x1 = 0;
//					col_x2 = 0;
//					col_y1 = 0;
//					col_y2 = 0;
//					memx = 0;
//					memy = 0;
//					collided_1 = 0;
//					collided_2 = 0;
//				end
//				S_LOAD_1		:begin
//					collided_1 = 0;
//					collided_2 = 0;
//					memx <= ballx;
//					memy <= (y_du) ? ball_yedge + 1 : ball_yedge - 1;
//				end
//				S_YLEFT		:begin
//					if(|health)begin
//						collided_1 = 1;
//						col_x1 <= memx;
//						col_y1 <= memy;
//						game_write = 1;
//					end
//				end
//				S_LOAD_2		:begin
//					memx <= ballx + `BRICKX;
//				end
//				S_YRIGHT	:begin
//					if(|health & check_twicex)begin
//						collided_1 = 1;
//						col_x1 <= memx;
//						col_y1 <= memy;
//						game_write = 1;
//					end
//				end
//				S_LOAD_3		:begin
//					memx <= (x_du) ? ball_xedge + 1 : ball_xedge - 1;
//					memy <= bally;
//				end
//				S_XUP	:begin
//					if(|health)begin
//						collided_2 = 1;
//						col_x2 <= memx;
//						col_y2 <= memy;
//						game_write = 1;
//					end
//				end
//				S_LOAD_4		:begin
//					memy <= bally + `BRICKY;
//				end
//				S_XDOWN :begin
//					if(|health & check_twicey)begin
//						collided_2 = 1;
//						col_x2 <= memx;
//						col_y2 <= memy;
//						game_write = 1;
//					end
//				end
//				S_CHANGE: begin
//					change = 1;
//				end
//		endcase
//	end
//	
//	always@(posedge clk)
//   begin: state_FFs
//       if(!resetn) 
//            current_state <= S_SETUP;
//       else
//				current_state <= next_state;
//   end // state_FFS	

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
