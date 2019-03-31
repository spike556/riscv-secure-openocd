`ifndef SCR1_RISCV_ISA_DECODING_SVH
`define SCR1_RISCV_ISA_DECODING_SVH
/// Copyright by Syntacore LLC © 2016, 2017. See LICENSE for details
/// @file       <scr1_riscv_isa_decoding.svh>
/// @brief      RISC-V ISA Definitions file
///
//-------------------vector instruction decode scratch------------------------
//                        1. VR type
//  31--------26 25 24----20 19----15 14--13 12 11----7 6----2  1 0
//     funct6    imm  rs2       rs1   funct2  m    rd   opcode  1 1
//     000000     0                    00                 VOP   1 1   vadd
//     000imm     1   imm              00                 VOP   1 1   vaddi
//     001000     0                    00                 VOP   1 1   vand
//     001imm     1   imm              00                 VOP   1 1   vandi
//     010000     0                    00                 VOP   1 1   vor
//     010imm     1   imm              00                 VOP   1 1   vori
//     011000     0                    00                 VOP   1 1   vsll
//     011imm     1   imm              00                 VOP   1 1   vsli
//     100000     0                    00                 VOP   1 1   vsra
//     100imm     1   imm              00                 VOP   1 1   vsrai
//     101000     0                    00                 VOP   1 1   vsrl
//     101imm     1   imm              00                 VOP   1 1   vsrli
//     110000     0                    00                 VOP   1 1   vxor
//     110imm     1   imm              00                 VOP   1 1   vxori
//     000001     0                    00                 VOP   1 1   vseq
//     000010     0                    00                 VOP   1 1   vsne
//     000011     0                    00                 VOP   1 1   vsge
//     000100     0                    00                 VOP   1 1   vslt
//     000101     0                    00                 VOP   1 1   vmax
//     000110     0                    00                 VOP   1 1   vmin
//     000111     0                    00                 VOP   1 1   vselect
//     001001     0                    00                 VOP   1 1   vsub
//     001010     0                    00                 VOP   1 1   vdbg

//  31-----27 26 25 24----20 19----15 14--13 12 11----7 6----2  1 0
//     imm     op     scr2     scr1   func2  vp   rd    opcode
//     imm     00     0                00         vd     VMEM   1 1   vld
//     vs3     00     0                10         imm    VMEM   1 1   vst
//     imm     01     rs2              00         vd     VMEM   1 1   vlds
//     vs3     01     rs2              10         imm    VMEM   1 1   vsts
//     imm     10     vs2              00         vd     VMEM   1 1   vldx
//     vs3     10     vs2              10         imm    VMEM   1 1   vstx

//    vsetdcfg overlap other instructions
//    vsetvl encoding format not mentioned
//    so i decided use CSRRW to replace those two
//---------------------------------------------------------------------------------------

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"

//-------------------------------------------------------------------------------
// Instruction types
//-------------------------------------------------------------------------------
typedef enum logic [1:0] {
    SCR1_INSTR_RVC0     = 2'b00,
    SCR1_INSTR_RVC1     = 2'b01,
    SCR1_INSTR_RVC2     = 2'b10,
    SCR1_INSTR_RVI      = 2'b11
} type_scr1_instr_type_e;

//-------------------------------------------------------------------------------
// RV32I opcodes (bits 6:2)
//-------------------------------------------------------------------------------
typedef enum logic [6:2] {
    SCR1_OPCODE_LOAD        = 5'b00000,
    SCR1_OPCODE_MISC_MEM    = 5'b00011,
    SCR1_OPCODE_OP_IMM      = 5'b00100,
    SCR1_OPCODE_AUIPC       = 5'b00101,
    SCR1_OPCODE_STORE       = 5'b01000,
    SCR1_OPCODE_OP          = 5'b01100,
    SCR1_OPCODE_LUI         = 5'b01101,
    SCR1_OPCODE_BRANCH      = 5'b11000,
    SCR1_OPCODE_JALR        = 5'b11001,
    SCR1_OPCODE_JAL         = 5'b11011,
`ifdef SCR1_RVV_EXT
    SCR1_OPCODE_VOP         = 5'b10101,  // temp draft
    SCR1_OPCODE_VMEM        = 5'b11101,  // draft
    SCR1_OPCODE_VCRYPT      = 5'b11010,  // not standard
`endif
`ifdef SCR1_bitop
    SCR1_OPCODE_CRYPT       = 5'b00010,
`endif
    SCR1_OPCODE_SYSTEM      = 5'b11100
} type_scr1_rvi_opcode_e;


//-------------------------------------------------------------------------------
// IALU main operands
//-------------------------------------------------------------------------------
localparam SCR1_IALU_OP_ALL_NUM_E = 2;
localparam SCR1_IALU_OP_WIDTH_E   = $clog2(SCR1_IALU_OP_ALL_NUM_E);
typedef enum logic [SCR1_IALU_OP_WIDTH_E-1:0] {
    SCR1_IALU_OP_REG_IMM,          // op1 = rs1; op2 = imm
    SCR1_IALU_OP_REG_REG           // op1 = rs1; op2 = rs2
} type_scr1_ialu_op_sel_e;

//-------------------------------------------------------------------------------
// IALU main commands
//-------------------------------------------------------------------------------
`ifdef SCR1_RVM_EXT
localparam SCR1_IALU_CMD_ALL_NUM_E    = 23;
`else // ~SCR1_RVM_EXT
localparam SCR1_IALU_CMD_ALL_NUM_E    = 15;
`endif // ~SCR1_RVM_EXT
localparam SCR1_IALU_CMD_WIDTH_E      = $clog2(SCR1_IALU_CMD_ALL_NUM_E);
typedef enum logic [SCR1_IALU_CMD_WIDTH_E-1:0] {
    SCR1_IALU_CMD_NONE  = '0,   // IALU disable
    SCR1_IALU_CMD_AND,          // op1 & op2
    SCR1_IALU_CMD_OR,           // op1 | op2
    SCR1_IALU_CMD_XOR,          // op1 ^ op2
    SCR1_IALU_CMD_ADD,          // op1 + op2
    SCR1_IALU_CMD_SUB,          // op1 - op2
    SCR1_IALU_CMD_SUB_LT,       // op1 < op2
    SCR1_IALU_CMD_SUB_LTU,      // op1 u< op2
    SCR1_IALU_CMD_SUB_EQ,       // op1 = op2
    SCR1_IALU_CMD_SUB_NE,       // op1 != op2
    SCR1_IALU_CMD_SUB_GE,       // op1 >= op2
    SCR1_IALU_CMD_SUB_GEU,      // op1 u>= op2
    SCR1_IALU_CMD_SLL,          // op1 << op2
    SCR1_IALU_CMD_SRL,          // op1 >> op2
    SCR1_IALU_CMD_SRA           // op1 >>> op2
`ifdef SCR1_RVM_EXT
    ,
    SCR1_IALU_CMD_MUL,          // low(unsig(op1) * unsig(op2))
    SCR1_IALU_CMD_MULHU,        // high(unsig(op1) * unsig(op2))
    SCR1_IALU_CMD_MULHSU,       // high(op1 * unsig(op2))
    SCR1_IALU_CMD_MULH,         // high(op1 * op2)
    SCR1_IALU_CMD_DIV,          // op1 / op2
    SCR1_IALU_CMD_DIVU,         // op1 u/ op2
    SCR1_IALU_CMD_REM,          // op1 % op2
    SCR1_IALU_CMD_REMU          // op1 u% op2
`endif  // SCR1_RVM_EXT
} type_scr1_ialu_cmd_sel_e;

//-------------------------------------------------------------------------------
// IALU SUM2 operands (result is JUMP/BRANCH target, LOAD/STORE address)
//-------------------------------------------------------------------------------
localparam SCR1_SUM2_OP_ALL_NUM_E    = 2;
localparam SCR1_SUM2_OP_WIDTH_E      = $clog2(SCR1_SUM2_OP_ALL_NUM_E);
typedef enum logic [SCR1_SUM2_OP_WIDTH_E-1:0] {
    SCR1_SUM2_OP_PC_IMM,            // op1 = curr_pc; op2 = imm (AUIPC, target new_pc for JAL and branches)
    SCR1_SUM2_OP_REG_IMM,           // op1 = rs1; op2 = imm (target new_pc for JALR, LOAD/STORE address)
    SCR1_SUM2_OP_ERROR = 'x
} type_scr1_ialu_sum2_op_sel_e;

//-------------------------------------------------------------------------------
// LSU commands
//-------------------------------------------------------------------------------
localparam SCR1_LSU_CMD_ALL_NUM_E   = 9;
localparam SCR1_LSU_CMD_WIDTH_E     = $clog2(SCR1_LSU_CMD_ALL_NUM_E);
typedef enum logic [SCR1_LSU_CMD_WIDTH_E-1:0] {
    SCR1_LSU_CMD_NONE = '0,
    SCR1_LSU_CMD_LB,
    SCR1_LSU_CMD_LH,
    SCR1_LSU_CMD_LW,
    SCR1_LSU_CMD_LBU,
    SCR1_LSU_CMD_LHU,
    SCR1_LSU_CMD_SB,
    SCR1_LSU_CMD_SH,
    SCR1_LSU_CMD_SW
} type_scr1_lsu_cmd_sel_e;

//-------------------------------------------------------------------------------
// CSR operands
//-------------------------------------------------------------------------------
localparam SCR1_CSR_OP_ALL_NUM_E   = 2;
localparam SCR1_CSR_OP_WIDTH_E     = $clog2(SCR1_CSR_OP_ALL_NUM_E);
typedef enum logic [SCR1_CSR_OP_WIDTH_E-1:0] {
    SCR1_CSR_OP_IMM,
    SCR1_CSR_OP_REG
} type_scr1_csr_op_sel_e;

//-------------------------------------------------------------------------------
// CSR commands
//-------------------------------------------------------------------------------
localparam SCR1_CSR_CMD_ALL_NUM_E   = 4;
localparam SCR1_CSR_CMD_WIDTH_E     = $clog2(SCR1_CSR_CMD_ALL_NUM_E);
typedef enum logic [SCR1_CSR_CMD_WIDTH_E-1:0] {
    SCR1_CSR_CMD_NONE = '0,
    SCR1_CSR_CMD_WRITE,
    SCR1_CSR_CMD_SET,
    SCR1_CSR_CMD_CLEAR
} type_scr1_csr_cmd_sel_e;

//-------------------------------------------------------------------------------
// MPRF rd writeback source
//-------------------------------------------------------------------------------
localparam SCR1_RD_WB_ALL_NUM_E = 7;
localparam SCR1_RD_WB_WIDTH_E   = $clog2(SCR1_RD_WB_ALL_NUM_E);
typedef enum logic [SCR1_RD_WB_WIDTH_E-1:0] {
    SCR1_RD_WB_NONE = '0,
    SCR1_RD_WB_IALU,            // IALU main result
    SCR1_RD_WB_SUM2,            // IALU SUM2 result (AUIPC)
    SCR1_RD_WB_IMM,             // LUI
    SCR1_RD_WB_INC_PC,          // JAL(R)
    SCR1_RD_WB_LSU,             // Load from DMEM
    SCR1_RD_WB_CSR              // Read CSR
} type_scr1_rd_wb_sel_e;

//------------vector op definition------------------------------
`ifdef SCR1_bitop
localparam  SCR1_CRYPT_FUNC_NUM_E = 4;
localparam  SCR1_CRYPT_FUNC_WIDTH_E = $clog2(SCR1_CRYPT_FUNC_NUM_E);
typedef enum logic [SCR1_CRYPT_FUNC_WIDTH_E-1:0]  {
    SCR1_CRYPT_FUNC_NONE = '0,
    SCR1_CRYPT_FUNC_GMUL,        // implememted
    SCR1_CRYPT_FUNC_GROUP,     // implemented
    SCR1_CRYPT_FUNC_LOOKUP     // implemented
} type_scr1_crypt_func_e;

typedef struct packed {
    type_scr1_crypt_func_e              crypt_func;
    logic [4:0]                         rs1_addr;
    logic [4:0]                         rs2_addr;
    logic [4:0]                         rd_addr;
    logic [7:0]                         imm;
} type_scr1_crypt_cmd_s;
`endif

//--------------------------------------------------------------
`ifdef SCR1_RVV_EXT
localparam  SCR1_VOP_MAIN_NUM_E   = 4;
localparam  SCR1_VOP_MAIN_WIDTH_E = $clog2(SCR1_VOP_MAIN_NUM_E);
typedef enum logic [SCR1_VOP_MAIN_WIDTH_E-1:0]  {
    SCR1_VOP_NONE     = '0,
    SCR1_VOP_REG_REG,
    SCR1_VOP_REG_IMM,
    SCR1_VOP_MEM
} type_scr1_vop_main_e;

localparam  SCR1_VOP_ALU_CMD_NUM_E   = 16;
localparam  SCR1_VOP_ALU_CMD_WIDTH_E = $clog2(SCR1_VOP_ALU_CMD_NUM_E);
typedef enum logic [SCR1_VOP_ALU_CMD_WIDTH_E-1:0]  {
    SCR1_VOP_ALU_CMD_NONE = '0,
    SCR1_VOP_ALU_CMD_ADD,
    SCR1_VOP_ALU_CMD_AND,
    SCR1_VOP_ALU_CMD_OR,
    SCR1_VOP_ALU_CMD_SLL,
    SCR1_VOP_ALU_CMD_SRA,
    SCR1_VOP_ALU_CMD_SRL,
    SCR1_VOP_ALU_CMD_XOR,
    SCR1_VOP_ALU_CMD_SEQ,
    SCR1_VOP_ALU_CMD_SNE,
    SCR1_VOP_ALU_CMD_SGE,
    SCR1_VOP_ALU_CMD_SLT,
    SCR1_VOP_ALU_CMD_MAX,
    SCR1_VOP_ALU_CMD_MIN,
    SCR1_VOP_ALU_CMD_SELECT,
    SCR1_VOP_ALU_CMD_SUB
} type_scr1_vop_alu_cmd_e;

localparam  SCR1_VOP_MEM_CMD_NUM_E   = 7;
localparam  SCR1_VOP_MEM_CMD_WIDTH_E = $clog2(SCR1_VOP_MEM_CMD_NUM_E);
typedef enum logic [SCR1_VOP_MEM_CMD_WIDTH_E-1:0]  {
    SCR1_VOP_MEM_CMD_NONE = '0,
    SCR1_VOP_MEM_CMD_LD,
    SCR1_VOP_MEM_CMD_ST,
    SCR1_VOP_MEM_CMD_LDS,
    SCR1_VOP_MEM_CMD_STS,
    SCR1_VOP_MEM_CMD_LDX,
    SCR1_VOP_MEM_CMD_STX
} type_scr1_vop_mem_cmd_e;


`ifdef SCR1_RVY_EXT
localparam  SCR1_VCRYPT_MAIN_NUM_E = 7;
localparam  SCR1_VCRYPT_MAIN_WIDTH_E = $clog2(SCR1_VCRYPT_MAIN_NUM_E);
typedef enum logic [SCR1_VCRYPT_MAIN_WIDTH_E-1:0]  {
    SCR1_VCRYPT_MAIN_NONE = '0,
    SCR1_VCRYPT_MAIN_AES,       // implemented
    SCR1_VCRYPT_MAIN_DES,
    SCR1_VCRYPT_MAIN_3DES,
    SCR1_VCRYPT_MAIN_SHA1,
    SCR1_VCRYPT_MAIN_SHA2,      // implemented
    SCR1_VCRYPT_MAIN_SHA3
} type_scr1_vcrypt_main_e;

localparam  SCR1_VCRYPT_FUNC_NUM_E = 8;
localparam  SCR1_VCRYPT_FUNC_WIDTH_E = $clog2(SCR1_VCRYPT_FUNC_NUM_E);
typedef enum logic [SCR1_VCRYPT_FUNC_WIDTH_E-1:0]  {
    SCR1_VCRYPT_FUNC_NONE = '0,
    SCR1_VCRYPT_FUNC_INIT,        // implememted
    SCR1_VCRYPT_FUNC_ENCRYPT,     // implemented
    SCR1_VCRYPT_FUNC_DECRYPT,     // implemented
    SCR1_VCRYPT_FUNC_HASH,        // implemented
    SCR1_VCRYPT_FUNC_PAD,
    SCR1_VCRYPT_FUNC_LOOKUP,
    //SCR1_VCRYPT_FUNC_HANDLE_MSG,   // custom  12
    SCR1_VCRYPT_FUNC_KEY_EXPAN     // custom  13
} type_scr1_vcrypt_func_e;

localparam  SCR1_VCRYPT_LENGTH_NUM_E = 2;
localparam  SCR1_VCRYPT_LENGTH_WIDTH_E = $clog2(SCR1_VCRYPT_LENGTH_NUM_E);
typedef enum logic [SCR1_VCRYPT_LENGTH_WIDTH_E-1:0]  {
    SCR1_VCRYPT_128BIT = '0,
    SCR1_VCRYPT_256BIT
} type_scr1_vcrypt_length_e;

`endif

typedef struct packed {
    type_scr1_vop_main_e                vop_main;
    type_scr1_vop_alu_cmd_e             vop_alu_cmd;
    logic                               vop_alu_mask;
    type_scr1_vop_mem_cmd_e             vop_mem_cmd;
`ifdef SCR1_RVY_EXT
    type_scr1_vcrypt_main_e             vcrypt_main;
    type_scr1_vcrypt_func_e             vcrypt_func;
    type_scr1_vcrypt_length_e           vcrypt_length;
`endif
    logic [4:0]                         rs1_addr;
    logic [4:0]                         rs2_addr;
    logic [4:0]                         rs3_addr;
    logic [4:0]                         rd_addr;
    logic [`SCR1_XLEN-1:0]              imm;
} type_scr1_vexu_cmd_s;

`endif

//----------------------------------------------------------------

//-------------------------------------------------------------------------------
// IDU to EXU full command structure
//-------------------------------------------------------------------------------
localparam SCR1_GPR_FIELD_WIDTH = 5;

typedef struct packed {
    logic                               instr_rvc;      // used with a different meaning for IFU access fault exception
    type_scr1_ialu_op_sel_e             ialu_op;
    type_scr1_ialu_cmd_sel_e            ialu_cmd;
    type_scr1_ialu_sum2_op_sel_e        sum2_op;
    type_scr1_lsu_cmd_sel_e             lsu_cmd;
    type_scr1_csr_op_sel_e              csr_op;
    type_scr1_csr_cmd_sel_e             csr_cmd;
    type_scr1_rd_wb_sel_e               rd_wb_sel;
    logic                               jump_req;
    logic                               branch_req;
    logic                               mret_req;
    logic                               fencei_req;
    logic                               wfi_req;
    logic [SCR1_GPR_FIELD_WIDTH-1:0]    rs1_addr;       // used as zimm for CSRRxI instructions
    logic [SCR1_GPR_FIELD_WIDTH-1:0]    rs2_addr;
    logic [SCR1_GPR_FIELD_WIDTH-1:0]    rd_addr;
    logic [`SCR1_XLEN-1:0]              imm;            // used as {funct3, CSR address} for CSR instructions
                                                        // used as instruction field for illegal instruction exception
    logic                               exc_req;
    type_scr1_exc_code_e                exc_code;
} type_scr1_exu_cmd_s;

`endif // SCR1_RISCV_ISA_DECODING_SVH
