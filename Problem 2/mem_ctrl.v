module mem_ctrl(
	/* output */
	comp, write, valid_in, sel_data_cache,
	wr_mem, rd_mem, sel_tag_mem, offset,
	Done, CacheHit, Stall, err,
	sel_cache, enable_0, enable_1,
	/* input */
	Rd, Wr, clk, rst,
	hit_0, dirty_0, valid_0,
	hit_1, dirty_1, valid_1
	);
	
	output comp, write, valid_in, sel_data_cache; // for cache
	output wr_mem, rd_mem, sel_tag_mem; // for main memory
	output [2:0] offset;
	output Done, CacheHit, Stall, err; // for top-level output
	output sel_cache;
	output enable_0, enable_1;

	input Rd, Wr; // from primary input 
	input hit_0, dirty_0, valid_0; // from cache
	input hit_1, dirty_1, valid_1; // from cache
	input clk, rst;

	// one hot FSM design to achieve simple combinational logic
	// IDLE - all zero
	wire [8:0] cur_state, next_state;
	wire s0, s1, s2, s3, s4, s5, s6, s7, s8;
	wire n0, n1, n2, n3, n4, n5, n6, n7, n8;
	assign {s8, s7, s6, s5, s4, s3, s2, s1, s0} = cur_state;
	assign next_state = {n8, n7, n6, n5, n4, n3, n2, n1, n0};

	wire S_idle, S_compare, S_access_write, S_allocate, S_access_read; 
	assign S_idle = (cur_state == 10'b0)? 1'b1 : 1'b0; // IDLE
	assign S_compare = s0 | s4; // Compare
	assign S_access_write = s3; // Access Write
	assign S_allocate = s1; // Allocate
	assign S_access_read = s5; // access read 

	wire Request; // record initial request type: 1-Rd, 0-Wr
	wire Access_write; // record whether state machine go through Access Write state (S3)
	wire [1:0] counter, counter_d;
	wire en_counter;
	wire sel_cache_pre, sel_cache_d, selected, selected_d, en_selected, victimway_d;

	// state registers
	dff state[8:0] (.d(next_state), .q(cur_state), .clk(clk), .rst(rst));
	
	// Request register (IDLE as enbale signal)
	dff_en Req_init_reg (.d(Rd), .q(Request), .en(S_idle), .clk(clk), .rst(rst));
	// Access_write register, whether from access write when Done
	dff Ac_write_reg (.d(S_access_write), .q(Access_write), .clk(clk), .rst(rst));
	// counter
	dff_en counter_reg [1:0] (.d(counter_d), .q(counter), .en(en_counter), .clk(clk), .rst(rst));
	assign en_counter = S_allocate | S_access_read | S_idle;
	assign counter_d = {counter[1] ^ counter[0], ~counter[0]} & {2{~S_idle}};

	// sel_cache register ( Compare&Read or Compare&Write as enable)
	dff_en sel_cache_reg (.d(sel_cache_d), .q(sel_cache_pre), .en(S_compare), .clk(clk), .rst(rst));
	// selected register
	dff_en selected_reg (.d(selected_d), .q(selected), .en(en_selected), .clk(clk), .rst(rst));
    assign selected_d = S_compare & ~S_idle;
    assign en_selected = S_compare | S_idle;
	// victimway register Compare & Read or Compare & Write as enable
	// flip at every read or write operation	
	dff_en victimway_reg (.d(victimway_d), .q(victimway), .en(Done), .clk(clk), .rst(rst));
	assign victimway_d = ~victimway;

	// state transition
	// compare read
	assign n0 = (S_idle & Rd) | (s3 & Request);
	// allocate
	// either one is ( invalid ) or ( valid and clean )
	assign n1 = ( (s0|s4) &
		          ( ((~valid_0|(~hit_0&~dirty_0&~victimway)) & ~(valid_1&hit_1)) |
				    ((~valid_1|(~hit_1&~dirty_1&victimway)) & ~(valid_0&hit_0)) ) ) |
		        s8 | (s1 & ~(counter==2'b11));
	// wait for memory read 
	assign n2 = s1 & (counter==2'b11);
	// access write 
	assign n3 = s2;
	// compare write
	assign n4 = (S_idle & Wr) | (s3 & ~Request);
	// access read, write back
	// both are valid and dirty
	assign n5 = ( (s0 | s4) & ( valid_0 & ~hit_0 & valid_1 & ~hit_1 & ((dirty_0 & ~victimway)|(dirty_1 & victimway)) ) ) |
		        (s5 & ~(counter==2'b11));
	// wait for write
	assign n6 = s5 & (counter==2'b11);
	// wair for write
	assign n7 = s6;
	// wair for write
	assign n8 = s7;

	// output
	assign comp = s0 | s4;                           // compare read & compare write
	assign write = s4 | s3 | s2 | (s1 & counter[1]); // compare write & access write
	assign valid_in = s3; // access write, write once
	assign sel_data_cache = s3 | s2 | (s1 & counter[1]); // access write

	assign wr_mem = s5; // write back
	assign rd_mem = s1; // allocate
	assign sel_tag_mem = s5; // write back
	assign offset = {counter, 1'b0};
	
	assign Done = (s0 | s4) & ((valid_0 & hit_0) | (valid_1 & hit_1) );
	assign CacheHit = Done & ~Access_write; // did not go through access write
	assign Stall = ~S_idle;	
	assign err = & cur_state;

	assign sel_cache_d = S_compare & (
		                 (valid_0 & ~hit_0 & ~valid_1) |
					     (valid_0 & ~hit_0 & valid_1 & victimway) |
					     (valid_1 & hit_1) );
	assign sel_cache = (sel_cache_pre & ~(S_compare & valid_0 & hit_0) ) | (S_compare & valid_1 & hit_1);

	assign enable_0 = ~selected | ~sel_cache;
	assign enable_1 = ~selected | sel_cache;

endmodule

