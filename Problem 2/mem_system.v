/* $Author: karu $ */
/* $LastChangedDate: 2009-04-24 09:28:13 -0500 (Fri, 24 Apr 2009) $ */
/* $Rev: 77 $ */

module mem_system(/*AUTOARG*/
   // Outputs
   DataOut, Done, Stall, CacheHit, err, 
   // Inputs
   Addr, DataIn, Rd, Wr, createdump, clk, rst
   );
   
   input [15:0] Addr;
   input [15:0] DataIn;
   input        Rd;
   input        Wr;
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

	
	wire comp, write, sel_data_cache;
    wire valid_in;	
    wire wr_mem, rd_mem, sel_tag_mem;
	wire [2:0] offset_mem, offset_mem_q1, offset_mem_q2;
	wire err_ctrl;
	wire hit_0, hit_1, dirty_0, dirty_1, valid_0, valid_1;

	wire enable_0, enable_1;
	wire sel_cache;

	wire err_cache_0, err_cache_1;
	wire [7:0] index;
	wire [2:0] offset, offset_cache;
	wire [4:0] tag_in, tag_out, tag_out_0, tag_out_1;
	wire [15:0] data_in_cache, data_out_cache_0, data_out_cache_1;
	
	wire [15:0] addr_mem;
	wire [15:0] data_out_mem;
	wire [3:0] busy;
	wire Stall_mem, err_mem;

	wire [4:0] tag_mem;

	assign tag_out = sel_cache ? tag_out_1 : tag_out_0;
	assign DataOut = sel_cache ? data_out_cache_1 : data_out_cache_0; 

	assign index = Addr[10:3];
	assign offset = Addr[2:0];
	assign tag_in = Addr[15:11];
	assign addr_mem = {tag_mem, index, offset_mem};

	dff offset_reg1 [2:0] (.d(offset_mem), .q(offset_mem_q1), .clk(clk), .rst(rst));
	dff offset_reg2 [2:0] (.d(offset_mem_q1), .q(offset_mem_q2), .clk(clk), .rst(rst));

	assign data_in_cache = sel_data_cache ? data_out_mem : DataIn;
    
	assign offset_cache = sel_data_cache ? offset_mem_q2 : ( sel_tag_mem ? offset_mem : offset);
	
	assign tag_mem = sel_tag_mem ? tag_out : tag_in;

	mem_ctrl ctrl_unit(.rd_en(Rd), 
	                    .wr_en(Wr), 
	                    .clk(clk), 
	                    .rst(rst),
	                    .hit_0(hit_0), 
	                    .dirty_0(dirty_0), 
	                    .valid_0(valid_0),
	                    .hit_1(hit_1), 
	                    .dirty_1(dirty_1), 
	                    .valid_1(valid_1),
	                    .comp(comp), 
	                    .write(write), 
	                    .valid_in(valid_in), 
	                    .sel_data_cache(sel_data_cache),
	                    .wr_mem(wr_mem), .rd_mem(rd_mem), 
	                    .sel_tag_mem(sel_tag_mem), 
	                    .offset(offset_mem),
	                    .done(Done), 
	                    .cache_hit(CacheHit), 
	                    .stall(Stall), 
	                    .err(err_ctrl),
	                    .sel_cache(sel_cache), 
	                    .enable_0(enable_0), 
	                    .enable_1(enable_1));

	cache #(0 + mem_type) c0 (.enable(enable_0), 
	                            .clk(clk), 
	                            .rst(rst), 
	                            .createdump(createdump),
	                            .tag_in(tag_in), 
	                            .index(index), 
	                            .offset(offset_cache),
	                            .data_in(data_in_cache), 
	                            .comp(comp), .write(write), 
	                            .valid_in(valid_in),
	                            .tag_out(tag_out_0), 
	                            .data_out(data_out_cache_0), 
	                            .err(err_cache_0),
	                            .hit(hit_0), 
	                            .dirty(dirty_0), 
	                            .valid(valid_0));
	                            
	cache #(2 + mem_type) c1 (.enable(enable_1), 
	                            .clk(clk), 
	                            .rst(rst), 
	                            .createdump(createdump),
	                            .tag_in(tag_in), 
	                            .index(index), 
	                            .offset(offset_cache),
	                            .data_in(data_in_cache), 
	                            .comp(comp), 
	                            .write(write), 
	                            .valid_in(valid_in),
	                            .tag_out(tag_out_1), 
	                            .data_out(data_out_cache_1), 
	                            .err(err_cache_1),
	                            .hit(hit_1), 
	                            .dirty(dirty_1), 
	                            .valid(valid_1));

	four_bank_mem main_mem(.clk(clk), 
	                        .rst(rst), 
	                        .createdump(createdump),
	                        .addr(addr_mem), 
	                        .data_in(DataOut),
	                        .wr(wr_mem), 
	                        .rd(rd_mem),
	                        .data_out(data_out_mem),
	                        .stall(Stall_mem), 
	                        .busy(busy), 
	                        .err(err_mem));

	// output err
	assign err = err_ctrl | err_cache_0 | err_cache_1 | err_mem;

endmodule // mem_system

