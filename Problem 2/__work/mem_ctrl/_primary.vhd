library verilog;
use verilog.vl_types.all;
entity mem_ctrl is
    port(
        comp            : out    vl_logic;
        write           : out    vl_logic;
        valid_in        : out    vl_logic;
        sel_data_cache  : out    vl_logic;
        wr_mem          : out    vl_logic;
        rd_mem          : out    vl_logic;
        sel_tag_mem     : out    vl_logic;
        offset          : out    vl_logic_vector(2 downto 0);
        done            : out    vl_logic;
        cache_hit       : out    vl_logic;
        stall           : out    vl_logic;
        err             : out    vl_logic;
        rd_en           : in     vl_logic;
        wr_en           : in     vl_logic;
        hit             : in     vl_logic;
        dirty           : in     vl_logic;
        valid           : in     vl_logic;
        clk             : in     vl_logic;
        rst             : in     vl_logic
    );
end mem_ctrl;
