module delay_counter(
	input clk,
	input resetn,
	input [39:0]delay,
	
	output d_enable
	);
	
	reg [39:0]q;
	always @ (posedge clk) begin
		if(!resetn)
//			q <= 20'd833333 - 1;
			q <= delay - 1;
		else begin
			if(q == 40'b0) begin
//				q <= 20'd833333 - 1;
				q <= delay - 1;
			end
			else
				q <= q - 1;
		end
	end
	
	assign d_enable = (q == 40'b0) ? 1 : 0;

endmodule

module counter(
	input enable,
	input clk,
	input resetn,
	
	output reg [19:0]c_x
	);
	
	always @ (posedge clk) begin
		if(!resetn)
			c_x <= 20'b0;
			
		else
			if(enable)begin 
				c_x = c_x + 1;
			end
	end

endmodule
