module mem_ctrl(
	            // output
	            comp, write, valid_in, sel_data_cache,
	            wr_mem, rd_mem, sel_tag_mem, offset,
	            done, cache_hit, stall, err,
	            // input
	            rd_en, wr_en, hit, dirty, valid,
	            clk, rst
	            );
	
	output comp, write, valid_in, sel_data_cache; // for cache
	output wr_mem, rd_mem, sel_tag_mem; // for main memory
	output [2:0] offset;
	output done, cache_hit, stall, err; // for top-level output

	input rd_en, wr_en; // from primary input 
	input hit, dirty, valid; // from cache
	input clk, rst;

	// one hot FSM design to achieve simple combinational logic
	// IDLE - all zero
	wire [8:0] curr_state, next_state;
	
	wire s0, s1, s2, s3, s4, s5, s6, s7, s8;
	assign {s8, s7, s6, s5, s4, s3, s2, s1, s0} = curr_state;
	wire n0, n1, n2, n3, n4, n5, n6, n7, n8;
	assign next_state = {n8, n7, n6, n5, n4, n3, n2, n1, n0};

	wire S_idle, S_access_write, S_allocate, S_access_read; 
	assign S_idle = (curr_state == 10'b0)? 1'b1 : 1'b0; // IDLE
	assign S_access_write = s3; // Access Write
	assign S_allocate = s1; // Allocate
	assign S_access_read = s5; // access read 

	wire Request; // record initial request type: 1-rd_en, 0-wr_en
	wire Access_write; // record whether state machine go through Access Write state (S3)

	// state registers
	dff state[8:0] (.d(next_state), .q(curr_state), .clk(clk), .rst(rst));
	// Request register (IDLE as enbale signal)
	dff_en Req_init_reg (.d(rd_en), .q(Request), .en(S_idle), .clk(clk), .rst(rst));
	// Access_write register
	dff Ac_write_reg (.d(S_access_write), .q(Access_write), .clk(clk), .rst(rst));
	// counter
	// IDLE as reset, write back or access write as enable
	wire [1:0] counter, counter_d;
	wire en_counter;
	dff_en counter_reg [1:0] (.d(counter_d), .q(counter), .en(en_counter), .clk(clk), .rst(rst));
	
	assign en_counter = S_allocate | S_access_read | S_idle;
	assign counter_d = {counter[1] ^ counter[0], ~counter[0]} & { 2{~S_idle} };

	// state transition
	// compare read
	assign n0 = (S_idle & rd_en) | (s3 & Request);
	// allocate
	assign n1 = ( (s0 | s4) & ((~valid) | (~hit & ~dirty)) ) | s8 | (s1 & ~(counter==2'b11));
	// wait for memory read 
	assign n2 = s1 & (counter==2'b11);
	// access write 
	assign n3 = s2;
	// compare write
	assign n4 = (S_idle & wr_en) | (s3 & ~Request);
	// access read, write back
	assign n5 = (s0 | s4) & (valid & ~hit & dirty) | (s5 & ~(counter==2'b11));
	// wait for write
	assign n6 = s5 & (counter==2'b11);
	// wair for write
	assign n7 = s6;
	// wair for write
	assign n8 = s7;

	// output
	assign comp = s0 | s4; // compare read & compare write
	assign write = s4 | s3 | s2 | (s1 & counter[1]); // compare write & access write
	assign valid_in = s3; // access write
	assign sel_data_cache = s3 | s2 | (s1 & counter[1]); // access write

	assign wr_mem = s5; // write back
	assign rd_mem = s1; // allocate
	assign sel_tag_mem = s5; // write back

	assign offset = {counter, 1'b0};

	assign Done = (s0 | s4) & valid & hit;
	assign CacheHit = Done & ~Access_write; // did not go through access write
	assign Stall = ~S_idle;	
	assign err = & curr_state;

endmodule

