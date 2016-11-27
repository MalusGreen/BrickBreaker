`include "macros.v"

module platform(
	input clk,
	input resetn,
	input left,
	input right,
	input enable,
	input draw,
	output [9:0]x, y,
	output [2:0] colour,
	output writeEn,
	
	output [9:0]d_x, d_qx
	);
	
	wire ld_x, inc_x;
	wire finished_row;
	
	wire [9:0] size = `PLATSIZE;
	assign colour = 3'b100;
	
	control c(
		.clk(clk),
		.resetn(resetn),				
		.draw(draw),
		.finished_row(finished_row),
		
		.ld_x(ld_x),
		.inc_x(inc_x),
		.wren(writeEn)
	);
	
	datapath d(
		.clk(clk),
		.resetn(resetn),
		.enable(enable),
		
		.left(left),
		.right(right),
		.size(size),
		.ld_x(ld_x),
		.inc_x(inc_x),
		
		.x_out(x),
		.y_out(y),
		.finished_row(finished_row),
		
		.x(d_x),
		.qx(d_qx)
	);
	
endmodule


module control(
	input clk,
	input resetn,
	input draw,
	input finished_row,
	output reg ld_x, inc_x,
	output reg wren
	);
	
	reg [1:0] current_state, next_state;

	localparam 	S_LOAD_X			= 2'd0,
					S_INC_X   	   = 2'd1;
					
	always @(*)
   begin: state_table 
			case (current_state)
					S_LOAD_X: next_state = draw ? S_INC_X : S_LOAD_X; // Loop in current state until value is input
					S_INC_X: next_state = finished_row ? S_LOAD_X : S_INC_X;
            default:     next_state = S_LOAD_X;
        endcase
   end // state_table
	 
	 always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  ld_x  = 0;
		  inc_x = 0;
		  wren  = 0; 

        case (current_state)
            S_LOAD_X: begin
					ld_x  = 1;
					wren = 1;
					end
				S_INC_X: begin
					inc_x = 1;
					wren  = 1;
					end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
	 
	 // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
				current_state <= next_state;
    end // state_FFS
	
endmodule


module datapath(
	input clk,
	input resetn,
	input enable,
	input left, right, //x_in
	input [9:0]size,
	input ld_x, inc_x,
	output reg [9:0]x_out, y_out,
	output reg finished_row,
	
	output reg [9:0] x, qx
	);
	
//	reg [9:0] x, qx;
	reg [9:0] y;
	
	always @ (posedge clk) begin
		if(!resetn) begin
			x  <= 10'd32;
			qx <= 10'd0;
			y  <= `PLATY;
			finished_row <= 0;
		end
		else begin
			if(enable & left & x > 10'd0) 
				x <= x - 1;
			else if(enable & right & x < 10'd159) 
				x <= x + 1;
			if(ld_x)begin
				qx <= size - 1;
				finished_row <= 0;
			end
			
			if(inc_x)begin
				qx <= qx - 1;
				if(qx == 10'd0)
					finished_row <= 1;
			end
		end
	end
	
	always @ (*) begin
		x_out = x + qx;
		y_out = y;
	end
	
endmodule
