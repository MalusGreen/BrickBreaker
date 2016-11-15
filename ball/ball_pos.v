module ball_pos(
	input enable,
	input clk,
	input resetn,
	
	input x_du,
	input y_du,
	
	output reg [7:0]x,
	output reg [6:0]y
	);
	
	x_counter(
		.enable(enable),
		.clk(clk),
		.resetn(resetn),
		
		.updown(x_du),
		.c_x(x)
	);
	
	y-counter(
		.enable(enable),
		.clk(clk),
		.resetn(resetn),
		
		.updown(y_du),
		.c_y(y)
		);
	
endmodule

module x_counter(
	input enable,
	input clk,
	input resetn,
	input updown,
	
	output reg [7:0]c_x
	);
	
	always @ (posedge clk) begin
		if(!resetn)
			counter <= 8'b0;
			
		else
			if(updown)
				counter = counter + 1;
			else
				counter = counter - 1;
	end

endmodule

module y_counter(
	input enable,
	input clk,
	input resetn,
	input updown,
	
	output reg [6:0]c_y
	);
	
	always @ (posedge clk) begin
		if(!resetn)
			counter <= 7'b0;
			
		else
			if(updown)
				counter = counter + 1;
			else
				counter = counter - 1;
	end

endmodule
