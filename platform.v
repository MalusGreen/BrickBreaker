module platform(
	input clk,
	input resetn,
	input left,
	input right,
	input enable,
	output [9:0] x, y,
	output colour,
	output writeEn
	);
	
	wire ld_x, inc_x;
	wire finished_row;
	
	wire dx = 0 - left + right;
	
	wire [9:0] size = 10'd4;
	assign colour = 100;
	
	control c(
		.clk(clk),
		.resetn(resetn),				
		.draw(left | right),
		.finished_row(finished_row),
		.enable(enable),
		
		.ld_x(ld_x),
		.inc_x(inc_x),
		.wren(writeEn)
	);
	
	datapath d(
		.clk(clk),
		.resetn(resetn),
		.dx(),
		.size(size),
		.ld_x(ld_x),
		.inc_x(inc_x),
		
		.x_out(x),
		.y_out(y),
		.finished_row(finished_row)
	);
	
endmodule


module control(
	input clk,
	input resetn,
	input draw,
	input finished_row,
	input enable,
	output reg ld_x, inc_x,
	output reg wren
	);
	
	reg current_state, next_state;

	localparam 	S_LOAD_X			= 1'd0,
					S_INC_X   	   = 1'd1;
					
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
					ld_x  = 1'b1;
					wren  = 1'b1;
					end
				S_INC_X: begin
					inc_x = 1'b1;
					wren  = 1'b1;
					end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
	 
	 // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else if(enable)
					current_state <= next_state;
    end // state_FFS
	
endmodule


module datapath(
	input clk,
	input resetn,
	input [9:0]dx, //x_in
	input [9:0]size,
	input ld_x, inc_x,
	output reg [9:0]x_out, y_out,
	output reg finished_row
	);
	
	reg [9:0] x, qx;
	reg [9:0] y;
	
	always @ (posedge clk) begin
		if(!resetn) begin
			x  <= 10'b0;
			qx <= 10'b0;
			y  <= 10'd64;
			finished_row <= 0;
		end
		else begin
			if(ld_x)begin
				x  <= x + dx;
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
