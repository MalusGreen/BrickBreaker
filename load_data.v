`include "macros.v"

module load_data(
	input resetn,
	input clk,
	input [9:0]selection,
	
	output load_draw,
	output loading,
	output [9:0]x_out, y_out,
	output [9:0]address,
	output [1:0]health,
	output [9:0]total_health,
	output writeEn
	);
	
	wire done_all, done_draw;
	wire inc_count, count_enable;
	
	load_control loadcontrol(
		.resetn(resetn),
		.clk(clk),
		.done_all(done_all),
		.done_draw(done_draw),
		
		.inc_count(inc_count),
		.count_enable(count_enable),
		.writeEn(writeEn),
		.draw(load_draw),
		.done(loading)
	);
	
	load_datapath loaddatapath(
		.resetn(resetn),
		.clk(clk),
		
		.count_enable(count_enable),
		.inc_count(inc_count),
		.draw_delay(`BRICKDRAW),
		.brick_count(`BRICKNUM),
		.selection(selection),
		
		.done_all(done_all),
		.done_draw(done_draw),
		.x_out(x_out),
		.y_out(y_out),
		.address(address),
		.health(health),
		.total_health(total_health)
	);
	
endmodule

module load_control(
	input resetn,
	input clk,
	input done_all,
	input done_draw,
	
	output reg inc_count,
	output reg count_enable,
	output reg writeEn,
	output reg draw,
	output reg done
	);
	
	reg [1:0]current_state, next_state;
	
	localparam  S_DRAWPREP	= 2'd0,
					S_DRAW		= 2'd1,
					S_LOAD	 	= 2'd2,
					S_DONE		= 2'd3;
					
	always @(*)begin
		case(current_state)
				S_DRAWPREP: next_state = S_DRAW;
				S_DRAW:		next_state = (done_draw) ? S_LOAD : S_DRAW;
				S_LOAD:		next_state = (done_all)  ? S_DONE : S_DRAWPREP;
				S_DONE:		next_state = S_DONE;
				default:		next_state = S_DONE;
		endcase
	end
	
	always @(*)begin
		inc_count = 0;
		count_enable = 0;
		draw = 0;
		writeEn = 0;
		done = 0;
		case(current_state)
				S_DRAWPREP:
						draw = 1;
				S_DRAW:
						count_enable = 1;
				S_LOAD:begin
						inc_count = 1;
						writeEn = 1;
				end
				S_DONE:
						done = 1;
		endcase
	end
	
	// current_state registers
   always@(posedge clk)
   begin: state_FFs
       if(!resetn)
           current_state <= S_DRAWPREP;
       else
           current_state <= next_state;
   end // state_FFS
endmodule

module load_datapath(
	input resetn,
	input clk,
	input count_enable,
	input inc_count,
	
	input [19:0] draw_delay,
	input [19:0] brick_count,
	input [9:0]selection,
	
	output done_all,
	output done_draw,
	output [9:0]x_out, y_out,
	output [9:0]address,
	output [1:0]health,
	output [9:0]total_health
	);
	
	wire [19:0]draw_count;
	wire [19:0]load_count;
	
	wire reset_draw;
	//reset when resetn is 0 or when inc count is high.
	assign reset_draw = (resetn & ~inc_count);
	
	counter drawcount(
		.enable(count_enable),
		.clk(clk),
		.resetn(reset_draw),
		
		.c_x(draw_count)
	);
	
	counter loadcount(
		.enable(inc_count),
		.clk(clk),
		.resetn(resetn),
		
		.c_x(load_count)
	);
	
	assign done_all  = (load_count == brick_count);
	assign done_draw = (draw_count == draw_delay);
	
	load_mux lm(
		.selection(selection),
		.count(load_count),
		.x_out(x_out),
		.y_out(y_out),
		.address(address),
		.health(health),
		.total_health(total_health)
	);
	
endmodule

module load_mux(
		input [9:0]selection,
		input [19:0]count,
		
		output [9:0]x_out, y_out,
		output [9:0]address,
		output reg [1:0]health,
		output reg [9:0]total_health
	);
	
	wire [1:0]health_1, health_2, health_3;
	
	level_one l1(
		.count(count),
		.health(health_1)
	);
	
	level_two l2(
		.count(count),
		.health(health_2)
	);
	
	level_three l3(
		.count(count),
		.health(health_3)
	);
	
	always @(*)begin
		case(selection)
			10'd0: begin
				health = health_1;
				total_health = `LV1HP;
			end
			10'd1: begin
				health = health_2;
				total_health = `LV2HP;
			end
			10'd2: begin
				health = health_3;
				total_health = `LV3HP;
			end
		default: begin
			health = health_1;
			total_health = `LV1HP;
		end 
		endcase
	end
	
	address_xy loadchanger(
		.x_in(),
		.y_in(),
		.address_in(count[9:0]),
		.x_out(x_out),
		.y_out(y_out),
		.address_out()
	);
	
	assign address = count[9:0];
	
endmodule

module level_one(
	input [19:0]count,
	
	output reg [1:0]health
	);
	
	always @(*)begin
		case (count)
			20'd17:
				health = 2'd1;
			20'd18:
				health = 2'd2;
			20'd19:
				health = 2'd3;
			20'd20:
				health = 2'd1;
			20'd21:
				health = 2'd2;
			20'd22:
				health = 2'd3;
			20'd23:
				health = 2'd1;
			20'd24:
				health = 2'd2;
			20'd25:
				health = 2'd3;
			20'd26:
				health = 2'd1;
			20'd27:
				health = 2'd2;
			20'd28:
				health = 2'd3;
			20'd29:
				health = 2'd1;
			20'd30:
				health = 2'd2;
			20'd31:
				health = 2'd3;
			20'd49:
				health = 2'd1;
			default:
				health = 2'd0;
		endcase
	end
		
endmodule

module level_two(
	input [19:0]count,
	
	output reg [1:0]health
	);
	
	always @(*)begin
		case (count)
			20'd1:
				health = 2'd1;
			20'd17:
				health = 2'd1;
			20'd33:
				health = 2'd1;
			20'd49:
				health = 2'd1;
			20'd65:
				health = 2'd1;
			20'd81:
				health = 2'd1;
			20'd97:
				health = 2'd1;
			20'd113:
				health = 2'd1;
			default:
				health = 2'd0;
		endcase
	end
		
endmodule

module level_three(
	input [19:0]count,
	
	output reg [1:0]health
	);
	
	always @(*)begin
		case(count)
			default: health = 2'd2;
		endcase
	end
	
endmodule
