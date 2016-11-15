module delay_counter(
	input clk,
	input resetn,
	input [20:0]delay,
	
	output d_enable
	);
	
	reg [19:0]q;
	always @ (posedge clk) begin
		if(!resetn)
//			q <= 20'd833333 - 1;
			q <= delay - 1;
		else begin
			if(q == 20'b0) begin
//				q <= 20'd833333 - 1;
				q <= delay - 1;
			end
			else
				q <= q - 1;
		end
	end
	
	assign d_enable = (q == 20'b0) ? 1 : 0;

endmodule