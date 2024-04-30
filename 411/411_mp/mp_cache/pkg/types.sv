package cache_types;

    typedef enum bit [1:0] {
        Hit_Read_Clean = 2'b00, // valid, clean
        Hit_Write_Dirty = 2'b01, // valid, dirty
        Miss_Replace = 2'b10 // valid, clean
    }Sram_op_t;

    typedef enum bit [1:0] {
        Way_A = 2'b11,
        Way_B = 2'b10,
        Way_C = 2'b01,
        Way_D = 2'b00
    }PLRU_Way_t;

    typedef enum bit [3:0] {
        Way_A_4 = 4'b1000,
        Way_B_4 = 4'b0100,
        Way_C_4 = 4'b0010,
        Way_D_4 = 4'b0001
    }PLRU_Way_4_t;

    typedef enum bit [1:0] {
        Hit = 2'b11,
        Dirty_Miss = 2'b10,
        Clean_Miss = 2'b01
    }Hit_Miss_t;


endpackage