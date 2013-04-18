// DFF with enable port
module dff_en(q, d, clk, rst, en);

	input d, en;
	input clk, rst;
	output q;

	wire inner_d;

	assign inner_d = en ? d : q;

	// instantiate DFF with inner_d being sent to d
	dff dff_with_en(.q(q), .d(inner_d), .clk(clk), .rst(rst));

endmodule
