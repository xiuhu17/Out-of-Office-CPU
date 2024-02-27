package cache_types;

    typedef enum bit [1:0] {
        hit_read_clean = 2'b00,
        hit_write_dirty = 2'b01,
        miss_replace = 2'b10 // clean
    }Sram_op_t;

endpackage