package cache_types;

    typedef enum bit [1:0] {
        Hit_Read_Clean = 2'b00,
        Hit_Write_Dirty = 2'b01,
        Miss_Replace = 2'b10 // clean
    }Sram_op_t;


    typedef enum bit [1:0] {
        Way_A = 2'b11,
        Way_B = 2'b10,
        Way_C = 2'b01,
        Way_D = 2'b00
    }PLRU_Way_t;

    typedef enum bit [1:0] {
        Hit = 2'b11,
        Dirty_Miss = 2'b10,
        Clean_Miss = 2'b01
    }Hit_Miss_t;


endpackage