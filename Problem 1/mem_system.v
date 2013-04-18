/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err, 
   // Inputs
   Addr, DataIn, rd_en, wr_en, createdump, clk, rst
   );
   
   input [15:0] Addr;
   input [15:0] DataIn;
   input        rd_en;
   input        wr_en;
   input        createdump;
   input        clk;
   input        rst;
   
   output [15:0] DataOut;
   output Done;
   output Stall;
   output CacheHit;
   output err;

   /* data_mem = 1, inst_mem = 0 *
    * needed for cache parameter */
   parameter mem_type = 0;
   
   
	/* internal signal */
	wire comp, write, valid_in, sel_data_cache; // for cache
	wire wr_mem, rd_mem, sel_tag_mem; // for main memory
	wire [2:0] offset_mem, offset_mem_q1, offset_mem_q2;
	wire err_ctrl;
	wire hit, dirty, valid; // from cache

	wire enable, err_cache;
	wire [7:0] index;
	wire [2:0] offset, offset_cache;
	wire [4:0] tag_in, tag_out;
	wire [15:0] data_in_cache;
	
	wire [15:0] addr_mem;
	wire [15:0] data_out_mem;
	wire [3:0] busy;
	wire Stall_mem, err_mem;

	wire [4:0] tag_mem;

	// address
	assign index = Addr[10:3];
	assign offset = Addr[2:0];
	assign tag_in = Addr[15:11];
	assign addr_mem = {tag_mem, index, offset_mem};

	// delay offset for 2 cycle for read operation
	dff offset_reg1 [2:0] (.d(offset_mem), .q(offset_mem_q1), .clk(clk), .rst(rst));
	dff offset_reg2 [2:0] (.d(offset_mem_q1), .q(offset_mem_q2), .clk(clk), .rst(rst));

	// 1 - from main mem, 0 - from primary input
	assign data_in_cache = sel_data_cache ? data_out_mem : DataIn;
    // read from memory to cache, delay offset for 2cycle to write into cache
    // write data to memroy, offsets for cache and memory are synchronous
	assign offset_cache = sel_data_cache ? offset_mem_q2 : ( sel_tag_mem ? offset_mem : offset);
	// 1 - from tag_out, 0 - from primary input
	assign tag_mem = sel_tag_mem ? tag_out : tag_in;

	assign enable = ~rst;

	mem_ctrl ctrl_unit(
	/* input */
	.rd_en(rd_en), .wr_en(wr_en), .hit(hit), .dirty(dirty), .valid(valid),
	.clk(clk), .rst(rst),
	/* output */
	.comp(comp), .write(write), .valid_in(valid_in), .sel_data_cache(sel_data_cache),
	.wr_mem(wr_mem), .rd_mem(rd_mem), .sel_tag_mem(sel_tag_mem), .offset(offset_mem),
	.Done(Done), .CacheHit(CacheHit), .Stall(Stall), .err(err_ctrl) // output Done, CacheHit, Stall
	);

	cache #(0 + mem_type) c0 (
		/* input */
		.enable(enable), .clk(clk), .rst(rst), .createdump(createdump),
		.tag_in(tag_in), .index(index), .offset(offset_cache),
		.data_in(data_in_cache), .comp(comp), .write(write), .valid_in(valid_in),
		/* output */
		.tag_out(tag_out), .data_out(DataOut), .err(err_cache), // output DataOut
		.hit(hit), .dirty(dirty), .valid(valid)
	);

	four_bank_mem main_mem(
		/* input */
		.clk(clk), .rst(rst), .createdump(createdump),
		.addr(addr_mem), .data_in(DataOut),
		.wr(wr_mem), .rd(rd_mem),
		/* output */
		.data_out(data_out_mem),
		.stall(Stall_mem), .busy(busy), .err(err_mem) // output Stall
	);

	// output err
	assign err = err_ctrl | err_cache | err_mem;
   
endmodule // mem_system

   


// DUMMY LINE FOR REV CONTROL :9:
