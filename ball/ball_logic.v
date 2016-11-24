module ball_logic(
	input resetn,
	input clk,
	
	input [9:0]x, x_max,
	input [9:0]y, y_max,
	input [9:0]size,
	
	//Brick's info
	input [1:0]brick_hp,
	input [9:0]brick_x, brick_y,
	input [9:0]brick_width, brick_height,
	
	//Platform info
	input [9:0]plat_x, plat_y,
	input [9:0]plat_width, plat_height,
	
	output reg x_du,
	output reg y_du,
	
	//Next block's info
	output reg [9:0] next_brick_x, next_brick_y,
	
	//Whether or not a collision occured
	output reg collision
	
	//Bricks' info
//	input [1:0]lr_brick_hp, ud_brick_hp,
//	input [9:0]lr_brick_x, lr_brick_y, ud_brick_x, ud_brick_y,
//	input [9:0]lr_brick_width, lr_brick_height, ud_brick_width, ud_brick_height,
	
	//Next horizontal and vertical block info
//	output reg [9:0]next_lr_brick_x, next_lr_brick_y, 
//	output reg [9:0]next_ud_brick_x, next_ud_brick_y,
	);
	
	reg x_dir, y_dir;
	
	wire get_brick;
	
	ball_logic_control blc(
		.clk(clk),
		.resetn(resetn),
		.get_brick(get_brick)
	);
	
	always @(posedge clk)begin
		if(!resetn) begin
			x_dir <= 0;
			y_dir <= 0;
		end
		else begin
			case (x)
				x_max - size:	x_dir = 0;
				0				:  x_dir = 1;
				default		:  x_dir = x_dir;
			endcase
			case (y)
				y_max - size: y_dir = 0;
				0				: y_dir = 1;
				default		: y_dir = y_dir;
			endcase
			
			collision <= 0;
			if(brick_hp > 2'b00) begin
				collision <= 1;
				if(!get_brick)
					x_dir <= x_dir + 1;
				else
					y_dir <= y_dir + 1;
			end
			else begin
				if(y_dir) begin
				
				end
				else begin
				
				end
			end
			
			// Checking for brick collision
//			if(lr_brick_hp > 2'b00 | ud_brick_hp > 2'b00) begin
//				collision <= 1;
//				x_dir <= (lr_brick_hp > 2'b00) ? x_dir + 1 : x_dir;
//				y_dir <= (ud_brick_hp > 2'b00) ? y_dir + 1 : y_dir;
//			end 
//			else
//				collision <= 0;
		end
	end
	
	
	always @(posedge clk)begin
		x_du <= x_dir;
		y_du <= y_dir;
		
		if(!get_brick) begin //Calculate x and y of horizontal brick
			next_brick_x <= (x_dir == 1) ? x + size + 1 : x - 1;
			next_brick_y <= y;
		end
		else begin //Calculate x and y f vertical block
			next_brick_x <= x;
			next_brick_y <= (y_dir == 1) ? y + size + 1 : y - 1;
		end
		
//		//Calculate x and of y of next horizontal brick
//		if(x_dir == 1)
//			next_lr_brick_x <= x + 1;
//		else 
//			next_lr_brick_x <= x - 1;
//				
//		next_lr_brick_y <= y;
//		
//		//Calculate x and of y of next vertical brick
//		if(y_dir == 1)
//			next_du_brick_y <= y + 1;
//		else 
//			next_du_brick_y <= y - 1;
//			
//		next_du_brick_x <= x;	
	end
	
endmodule

module ball_logic_control(
	input clk,
	input resetn,
	output reg get_brick
	);
	
	reg current_state, next_state;

	localparam 	S_GET_LR_BRICK	= 1'd0, //Get horizontal brick
					S_GET_UD_BRICK = 1'd1; //Get vertical brick
					
	always @(*)
   begin: state_table 
			case (current_state)
					S_GET_LR_BRICK: next_state = S_GET_UD_BRICK;
					S_GET_UD_BRICK: next_state = S_GET_LR_BRICK;
            default:     next_state = S_GET_LR_BRICK;
        endcase
   end // state_table
	 
	 always @(*)
    begin: enable_signals
		  get_brick = 0;
        case (current_state)
				S_GET_UD_BRICK:
					get_brick = 0;
            S_GET_UD_BRICK:
					get_brick = 1;
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
	 
	 // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_GET_LR_BRICK;
        else
				current_state <= next_state;
    end // state_FFS
	
endmodule
