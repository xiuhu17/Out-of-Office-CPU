package cache_types;

    typedef enum bit [1:0] {
        hit_read_clean = 2'b00,
        hit_write_dirty = 2'b01,
        miss_read_clean = 2'b10,
        miss_write_dirty = 2'b11
    }Sram_op_t;

endpackage