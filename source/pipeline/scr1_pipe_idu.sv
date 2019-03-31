/// Copyright by Syntacore LLC © 2016, 2017. See LICENSE for details
/// @file       <scr1_pipe_idu.sv>
/// @brief      Instruction Decoder Unit
///

`include "scr1_memif.svh"
`include "scr1_arch_types.svh"
`include "scr1_riscv_isa_decoding.svh"
`include "scr1_arch_description.svh"

module scr1_pipe_idu
(
`ifdef SCR1_SIM_ENV
    input   logic                           rst_n,
    input   logic                           clk,
`endif // SCR1_SIM_ENV

    // IFU <-> IDU interface
    output  logic                           idu2ifu_rdy,            // IDU ready for new data
    input   logic [`SCR1_IMEM_DWIDTH-1:0]   ifu2idu_instr,          // IFU instruction
    input   logic                           ifu2idu_imem_err,       // Instruction access fault exception
    input   logic                           ifu2idu_err_rvi_hi,     // 1 - imem fault when trying to fetch second half of an unaligned RVI instruction
    input   logic                           ifu2idu_vd,             // IFU request

    // IDU <-> EXU interface
    output  logic                           idu2exu_req,            // IDU request
    output  type_scr1_exu_cmd_s             idu2exu_cmd,            // IDU command
    output  logic                           idu2exu_use_rs1,        // Instruction uses rs1
    output  logic                           idu2exu_use_rs2,        // Instruction uses rs2
    output  logic                           idu2exu_use_rd,         // Instruction uses rd
    output  logic                           idu2exu_use_imm,        // Instruction uses immediate
    input   logic                           exu2idu_rdy,            // EXU ready for new data

`ifdef SCR1_RVV_EXT
    //  IDU  -> VUNIT Interface
    output  logic                           idu2vexu_req,            // vunit request
    output  type_scr1_vexu_cmd_s            idu2vexu_cmd,
    input   logic                           vexu2idu_rdy,            // vunit ready for new data
    output  logic                           rvv_inc_flag,
    output  logic                           rvv_pc_inc,             // to exu
    output  logic                           vdbg_req,
`endif

`ifdef SCR1_bitop
    output  logic                           idu2crypt_req,
    output  type_scr1_crypt_cmd_s           idu2crypt_cmd,
    input   logic                           crypt2idu_rdy,            // vunit ready for new data
    output  logic                           crypt_pc_inc,             // to exu
`endif

    output  logic                           idu_busy                // IDU busy
);

//-------------------------------------------------------------------------------
// Local parameters declaration
//-------------------------------------------------------------------------------
localparam [SCR1_GPR_FIELD_WIDTH-1:0] SCR1_MPRF_ZERO_ADDR   = 5'd0;
localparam [SCR1_GPR_FIELD_WIDTH-1:0] SCR1_MPRF_RA_ADDR     = 5'd1;
localparam [SCR1_GPR_FIELD_WIDTH-1:0] SCR1_MPRF_SP_ADDR     = 5'd2;

//-------------------------------------------------------------------------------
// Local signals declaration
//-------------------------------------------------------------------------------

logic [`SCR1_IMEM_DWIDTH-1:0]       instr;
type_scr1_instr_type_e              instr_type;
type_scr1_rvi_opcode_e              rvi_opcode;
logic                               rvi_illegal;
logic [2:0]                         funct3;
logic [6:0]                         funct7;
logic [11:0]                        funct12;
logic [4:0]                         shamt;
`ifdef SCR1_RVC_EXT
logic                               rvc_illegal;
`endif  // SCR1_RVC_EXT
`ifdef SCR1_RVE_EXT
logic                               rve_illegal;
`endif  // SCR1_RVE_EXT
//--------------------------------------------------------------------------
// vector extension
`ifdef SCR1_RVV_EXT
logic                               rvv_illegal;
logic                               rvv_imm_flag;
logic [4:0]                         rvv_mem_func;

assign  rvv_pc_inc    = vexu2idu_rdy & idu2vexu_req;
assign  rvv_imm_flag  = instr[25];
assign  rvv_mem_func  = {instr[26:25],  instr[14:12]};

// security extension
`ifdef SCR1_RVY_EXT
logic [2:0]                         algm_ptr;
logic [3:0]                         funct4;
logic [7:0]                   [7:0] algm_table;

assign  algm_ptr      = instr[27:25];
assign  funct4        = instr[31:28];

assign algm_table[0] = 4;    //  SHA256
assign algm_table[1] = 0;    //  AES
assign algm_table[7:2] =  48'hffff_ffffffff;  //  not implemented

`endif

`endif  // SCR1_RVV_EXT

`ifdef SCR1_bitop
logic  crypt_inc_flag;
assign  crypt_pc_inc    = crypt2idu_rdy & idu2crypt_req;
`endif
//--------------------------------------------------------------------------

//-------------------------------------------------------------------------------
// Decode
//-------------------------------------------------------------------------------
`ifdef SCR1_RVV_EXT
assign idu2ifu_rdy  = rvv_inc_flag  ? vexu2idu_rdy : exu2idu_rdy;
assign idu2exu_req  = ~rvv_inc_flag & ifu2idu_vd;
assign idu2vexu_req = rvv_inc_flag  & ifu2idu_vd;
assign idu_busy     = rvv_inc_flag  ? idu2vexu_req : idu2exu_req;
`else
`ifdef SCR1_bitop
assign idu2ifu_rdy  = crypt_inc_flag  ? crypt2idu_rdy : exu2idu_rdy;
assign idu2exu_req  = ~crypt_inc_flag & ifu2idu_vd;
assign idu2crypt_req = crypt_inc_flag  & ifu2idu_vd;
assign idu_busy     = crypt_inc_flag  ? idu2crypt_req : idu2exu_req;
`else
assign idu2ifu_rdy  = exu2idu_rdy;
assign idu2exu_req  = ifu2idu_vd;
assign idu_busy     = idu2exu_req;
`endif
`endif

assign instr        = ifu2idu_instr;

// RVI / RVC
assign instr_type   = type_scr1_instr_type_e'(instr[1:0]);

// RVI / RVC fields
assign rvi_opcode   = type_scr1_rvi_opcode_e'(instr[6:2]);                          // RVI
assign funct3       = (instr_type == SCR1_INSTR_RVI) ? instr[14:12] : instr[15:13]; // RVI / RVC
assign funct7       = instr[31:25];                                                 // RVI
assign funct12      = instr[31:20];                                                 // RVI (SYSTEM)
assign shamt        = instr[24:20];                                                 // RVI

// RV32I(MC) decode
always_comb begin
    // Defaults
    idu2exu_cmd.instr_rvc   = 1'b0;
    idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
    idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_NONE;
    idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
    idu2exu_cmd.lsu_cmd     = SCR1_LSU_CMD_NONE;
    idu2exu_cmd.csr_op      = SCR1_CSR_OP_REG;
    idu2exu_cmd.csr_cmd     = SCR1_CSR_CMD_NONE;
    idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_NONE;
    idu2exu_cmd.jump_req    = 1'b0;
    idu2exu_cmd.branch_req  = 1'b0;
    idu2exu_cmd.mret_req    = 1'b0;
    idu2exu_cmd.fencei_req  = 1'b0;
    idu2exu_cmd.wfi_req     = 1'b0;
    idu2exu_cmd.rs1_addr    = '0;
    idu2exu_cmd.rs2_addr    = '0;
    idu2exu_cmd.rd_addr     = '0;
    idu2exu_cmd.imm         = '0;
    idu2exu_cmd.exc_req     = 1'b0;
    idu2exu_cmd.exc_code    = SCR1_EXC_CODE_INSTR_MISALIGN;
`ifdef SCR1_RVV_EXT
    rvv_inc_flag               = 1'b0;
    idu2vexu_cmd.vop_main      = SCR1_VOP_NONE;
    idu2vexu_cmd.vop_alu_cmd   = SCR1_VOP_ALU_CMD_NONE;
    idu2vexu_cmd.vop_mem_cmd   = SCR1_VOP_MEM_CMD_NONE;
    idu2vexu_cmd.vop_alu_mask  = 1'b0;
    vdbg_req                   = 1'b0;
    idu2vexu_cmd.rs1_addr      = '0;
    idu2vexu_cmd.rs2_addr      = '0;
    idu2vexu_cmd.rs3_addr      = '0;
    idu2vexu_cmd.rd_addr       = '0;
    idu2vexu_cmd.imm           = '0;
`ifdef SCR1_RVY_EXT
    idu2vexu_cmd.vcrypt_main     = SCR1_VCRYPT_MAIN_NONE;
    idu2vexu_cmd.vcrypt_func     = SCR1_VCRYPT_FUNC_NONE;
    idu2vexu_cmd.vcrypt_length   = SCR1_VCRYPT_128BIT;
`endif
`endif
`ifdef SCR1_bitop
    crypt_inc_flag                = 1'b0;
    idu2crypt_cmd.crypt_func      = SCR1_CRYPT_FUNC_NONE;
    idu2crypt_cmd.rs1_addr    = '0;
    idu2crypt_cmd.rs2_addr    = '0;
    idu2crypt_cmd.rd_addr     = '0;
    idu2crypt_cmd.imm         = '0;
`endif
    // Clock gating
    idu2exu_use_rs1         = 1'b0;
    idu2exu_use_rs2         = 1'b0;
    idu2exu_use_rd          = 1'b0;
    idu2exu_use_imm         = 1'b0;

    rvi_illegal             = 1'b0;
`ifdef SCR1_RVE_EXT
    rve_illegal             = 1'b0;
`endif  // SCR1_RVE_EXT
`ifdef SCR1_RVC_EXT
    rvc_illegal             = 1'b0;
`endif  // SCR1_RVC_EXT
`ifdef SCR1_RVV_EXT
    rvv_illegal             = 1'b0;
`endif  // SCR1_RVV_EXT
    // Check for IMEM access fault
    if (ifu2idu_imem_err) begin
        idu2exu_cmd.exc_req     = 1'b1;
        idu2exu_cmd.exc_code    = SCR1_EXC_CODE_INSTR_ACCESS_FAULT;
        idu2exu_cmd.instr_rvc   = ifu2idu_err_rvi_hi;
    end else begin  // no imem fault
        case (instr_type)
            SCR1_INSTR_RVI  : begin
                idu2exu_cmd.rs1_addr    = instr[19:15];
                idu2exu_cmd.rs2_addr    = instr[24:20];
                idu2exu_cmd.rd_addr     = instr[11:7];
`ifdef SCR1_RVV_EXT
                idu2vexu_cmd.rs1_addr   = instr[19:15];
                idu2vexu_cmd.rs2_addr   = instr[24:20];
                idu2vexu_cmd.rs3_addr   = instr[31:27];
                idu2vexu_cmd.rd_addr    = instr[11:7];
`endif
`ifdef SCR1_bitop
                idu2crypt_cmd.rs1_addr    = instr[19:15];
                idu2crypt_cmd.rs2_addr    = instr[24:20];
                idu2crypt_cmd.rd_addr     = instr[11:7];
                idu2crypt_cmd.imm         = {instr[31:25], funct3[0]};
`endif
                case (rvi_opcode)
`ifdef SCR1_bitop
                    SCR1_OPCODE_CRYPT          : begin
                        crypt_inc_flag    = 1'b1;
                        case (funct3[2:1])
                            2'b00  : begin
                                idu2crypt_cmd.crypt_func = SCR1_CRYPT_FUNC_GMUL;
                            end
                            2'b01  : begin
                                idu2crypt_cmd.crypt_func = SCR1_CRYPT_FUNC_GROUP;
                            end
                            default : begin  end
                        endcase
                    end
`endif
`ifdef SCR1_RVV_EXT
`ifdef SCR1_RVY_EXT
                    SCR1_OPCODE_VCRYPT          : begin
                        rvv_inc_flag     = 1'b1;
                        case (algm_table[algm_ptr])
                            8'h00     : begin
                                idu2vexu_cmd.vcrypt_main     = SCR1_VCRYPT_MAIN_AES;
                                case (funct4)
                                    4'h1    : idu2vexu_cmd.vcrypt_func     = SCR1_VCRYPT_FUNC_ENCRYPT;
                                    4'h2    : idu2vexu_cmd.vcrypt_func     = SCR1_VCRYPT_FUNC_DECRYPT;
                                    4'hd    : idu2vexu_cmd.vcrypt_func     = SCR1_VCRYPT_FUNC_KEY_EXPAN;       // key gen
                                    default : rvv_illegal = 1'b1;
                                endcase
                                case (funct3[1:0])
                                    2'h0    : idu2vexu_cmd.vcrypt_length   = SCR1_VCRYPT_128BIT;
                                    2'h2    : idu2vexu_cmd.vcrypt_length   = SCR1_VCRYPT_256BIT;
                                    default : rvv_illegal = 1'b1;
                                endcase
                            end
                            8'h04     : begin                                     // SHA2
                                idu2vexu_cmd.vcrypt_main     = SCR1_VCRYPT_MAIN_SHA2;
                                case (funct4)
                                    4'h0    : idu2vexu_cmd.vcrypt_func     = SCR1_VCRYPT_FUNC_INIT;
                                    4'h3    : idu2vexu_cmd.vcrypt_func     = SCR1_VCRYPT_FUNC_HASH;
                                    default : rvv_illegal = 1'b1;
                                endcase
                            end
                            default   : rvv_illegal = 1'b1;
                        endcase
                    end
`endif
                    SCR1_OPCODE_VOP             : begin
                        rvv_inc_flag     = 1'b1;
                        case (funct3[2:1])
                            2'b00  : begin
                                idu2vexu_cmd.vop_alu_mask = funct3[0];
                                case (rvv_imm_flag)
                                    1'b0  : begin
                                        idu2vexu_cmd.vop_main  = SCR1_VOP_REG_REG;
                                        case (funct7[6:1])
                                            6'b000000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_ADD;
                                            6'b001000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_AND;
                                            6'b010000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_OR;
                                            6'b011000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SLL;
                                            6'b100000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SRA;
                                            6'b101000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SRL;
                                            6'b110000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_XOR;
                                            6'b000001 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SEQ;
                                            6'b000010 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SNE;
                                            6'b000011 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SGE;
                                            6'b000100 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SLT;
                                            6'b000101 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_MAX;
                                            6'b000110 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_MIN;
                                            6'b000111 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SELECT;
                                            6'b001001 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SUB;
                                            6'b001010 :  begin
                                                vdbg_req                    = 1'b1;
                                                rvv_inc_flag                = 1'b0;
                                                // CSRRW
                                                idu2exu_use_rd              = 1'b1;
                                                idu2exu_use_rs1             = 1'b1;
                                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_WRITE;
                                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_REG;
                                            end
                                            default   :  rvv_illegal  = 1'b1;
                                        endcase
                                    end
                                    1'b1  : begin
                                        idu2vexu_cmd.vop_main  = SCR1_VOP_REG_IMM;
                                        idu2vexu_cmd.imm       = {{25{instr[28]}}, instr[27:26], instr[24:20]};
                                        case (funct7[6:1])
                                            6'b000000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_ADD;
                                            6'b001000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_AND;
                                            6'b010000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_OR;
                                            6'b011000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SLL;
                                            6'b100000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SRA;
                                            6'b101000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_SRL;
                                            6'b110000 :  idu2vexu_cmd.vop_alu_cmd = SCR1_VOP_ALU_CMD_XOR;
                                            default   :  rvv_illegal  = 1'b1;
                                        endcase
                                    end
                                endcase
                            end
                            default : rvv_illegal = 1'b1;
                        endcase
                    end
                    SCR1_OPCODE_VMEM            : begin
                        rvv_inc_flag     = 1'b1;
                        idu2vexu_cmd.vop_main  = SCR1_VOP_MEM;
                        case (rvv_mem_func)
                            5'b00000  : begin
                                idu2vexu_cmd.vop_mem_cmd = SCR1_VOP_MEM_CMD_LD;
                                idu2vexu_cmd.imm         = {{28{instr[31]}}, instr[30:27]};
                            end
                            5'b00100  : begin
                                idu2vexu_cmd.vop_mem_cmd = SCR1_VOP_MEM_CMD_ST;
                                idu2vexu_cmd.imm         = {{28{instr[11]}}, instr[10:7]};
                            end
                            5'b01000  : begin
                                idu2vexu_cmd.vop_mem_cmd = SCR1_VOP_MEM_CMD_LDS;
                                idu2vexu_cmd.imm         = {{28{instr[31]}}, instr[30:27]};
                            end
                            5'b01100  : begin
                                idu2vexu_cmd.vop_mem_cmd = SCR1_VOP_MEM_CMD_STS;
                                idu2vexu_cmd.imm         = {{28{instr[11]}}, instr[10:7]};
                            end
                            5'b10000  : begin
                                idu2vexu_cmd.vop_mem_cmd = SCR1_VOP_MEM_CMD_LDX;
                                idu2vexu_cmd.imm         = {{28{instr[31]}}, instr[30:27]};
                            end
                            5'b10100  : begin
                                idu2vexu_cmd.vop_mem_cmd = SCR1_VOP_MEM_CMD_STX;
                                idu2vexu_cmd.imm         = {{28{instr[11]}}, instr[10:7]};
                            end
                            default   : rvv_illegal = 1'b1;
                        endcase
                    end
`endif  // SCR1_RVV_EXT
                    SCR1_OPCODE_AUIPC           : begin
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_SUM2;
                        idu2exu_cmd.imm         = {instr[31:12], 12'b0};
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_AUIPC

                    SCR1_OPCODE_LUI             : begin
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IMM;
                        idu2exu_cmd.imm         = {instr[31:12], 12'b0};
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_LUI

                    SCR1_OPCODE_JAL             : begin
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_INC_PC;
                        idu2exu_cmd.jump_req    = 1'b1;
                        idu2exu_cmd.imm         = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_JAL

                    SCR1_OPCODE_LOAD            : begin
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_LSU;
                        idu2exu_cmd.imm         = {{21{instr[31]}}, instr[30:20]};
                        case (funct3)
                            3'b000  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_LB;
                            3'b001  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_LH;
                            3'b010  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_LW;
                            3'b100  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_LBU;
                            3'b101  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_LHU;
                            default : rvi_illegal = 1'b1;
                        endcase // funct3
`ifdef SCR1_RVE_EXT
                        if (instr[11] | instr[19])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_LOAD

                    SCR1_OPCODE_STORE           : begin
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                        idu2exu_cmd.imm         = {{21{instr[31]}}, instr[30:25], instr[11:7]};
                        case (funct3)
                            3'b000  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_SB;
                            3'b001  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_SH;
                            3'b010  : idu2exu_cmd.lsu_cmd = SCR1_LSU_CMD_SW;
                            default : rvi_illegal = 1'b1;
                        endcase // funct3
`ifdef SCR1_RVE_EXT
                        if (instr[19] | instr[24])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_STORE

                    SCR1_OPCODE_OP              : begin
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                        case (funct7)
                            7'b0000000 : begin
                                case (funct3)
                                    3'b000  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_ADD;
                                    3'b001  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SLL;
                                    3'b010  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SUB_LT;
                                    3'b011  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SUB_LTU;
                                    3'b100  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_XOR;
                                    3'b101  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SRL;
                                    3'b110  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_OR;
                                    3'b111  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_AND;
                                endcase // funct3
                            end // 7'b0000000

                            7'b0100000 : begin
                                case (funct3)
                                    3'b000  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SUB;
                                    3'b101  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SRA;
                                    default : rvi_illegal = 1'b1;
                                endcase // funct3
                            end // 7'b0100000
`ifdef SCR1_RVM_EXT
                            7'b0000001 : begin
                                case (funct3)
                                    3'b000  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_MUL;
                                    3'b001  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_MULH;
                                    3'b010  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_MULHSU;
                                    3'b011  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_MULHU;
                                    3'b100  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_DIV;
                                    3'b101  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_DIVU;
                                    3'b110  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_REM;
                                    3'b111  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_REMU;
                                endcase // funct3
                            end // 7'b0000001
`endif  // SCR1_RVM_EXT
                            default : rvi_illegal = 1'b1;
                        endcase // funct7
`ifdef SCR1_RVE_EXT
                        if (instr[11] | instr[19] | instr[24])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_OP

                    SCR1_OPCODE_OP_IMM          : begin
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.imm         = {{21{instr[31]}}, instr[30:20]};
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                        case (funct3)
                            3'b000  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_ADD;        // ADDI
                            3'b010  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SUB_LT;     // SLTI
                            3'b011  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_SUB_LTU;    // SLTIU
                            3'b100  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_XOR;        // XORI
                            3'b110  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_OR;         // ORI
                            3'b111  : idu2exu_cmd.ialu_cmd  = SCR1_IALU_CMD_AND;        // ANDI
                            3'b001  : begin
                                case (funct7)
                                    7'b0000000  : begin
                                        // SLLI
                                        idu2exu_cmd.imm         = `SCR1_XLEN'(shamt);   // zero-extend
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SLL;
                                    end
                                    default     : rvi_illegal   = 1'b1;
                                endcase // funct7
                            end
                            3'b101  : begin
                                case (funct7)
                                    7'b0000000  : begin
                                        // SRLI
                                        idu2exu_cmd.imm         = `SCR1_XLEN'(shamt);   // zero-extend
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SRL;
                                    end
                                    7'b0100000  : begin
                                        // SRAI
                                        idu2exu_cmd.imm         = `SCR1_XLEN'(shamt);   // zero-extend
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SRA;
                                    end
                                    default     : rvi_illegal   = 1'b1;
                                endcase // funct7
                            end
                        endcase // funct3
`ifdef SCR1_RVE_EXT
                        if (instr[11] | instr[19])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_OP_IMM

                    SCR1_OPCODE_MISC_MEM    : begin
                        case (funct3)
                            3'b000  : begin
                                if (~|{instr[31:28], instr[19:15], instr[11:7]}) begin
                                    // FENCE = NOP
                                end
                                else rvi_illegal = 1'b1;
                            end
                            3'b001  : begin
                                if (~|{instr[31:15], instr[11:7]}) begin
                                    // FENCE.I
                                    idu2exu_cmd.fencei_req    = 1'b1;
                                end
                                else rvi_illegal = 1'b1;
                            end
                            default : rvi_illegal = 1'b1;
                        endcase // funct3
                    end // SCR1_OPCODE_MISC_MEM

                    SCR1_OPCODE_BRANCH          : begin
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.imm         = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
                        idu2exu_cmd.branch_req  = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                        case (funct3)
                            3'b000  : idu2exu_cmd.ialu_cmd = SCR1_IALU_CMD_SUB_EQ;
                            3'b001  : idu2exu_cmd.ialu_cmd = SCR1_IALU_CMD_SUB_NE;
                            3'b100  : idu2exu_cmd.ialu_cmd = SCR1_IALU_CMD_SUB_LT;
                            3'b101  : idu2exu_cmd.ialu_cmd = SCR1_IALU_CMD_SUB_GE;
                            3'b110  : idu2exu_cmd.ialu_cmd = SCR1_IALU_CMD_SUB_LTU;
                            3'b111  : idu2exu_cmd.ialu_cmd = SCR1_IALU_CMD_SUB_GEU;
                            default : rvi_illegal = 1'b1;
                        endcase // funct3
`ifdef SCR1_RVE_EXT
                        if (instr[19] | instr[24])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_BRANCH

                    SCR1_OPCODE_JALR        : begin
                        idu2exu_use_rs1     = 1'b1;
                        idu2exu_use_rd      = 1'b1;
                        idu2exu_use_imm     = 1'b1;
                        case (funct3)
                            3'b000  : begin
                                // JALR
                                idu2exu_cmd.sum2_op   = SCR1_SUM2_OP_REG_IMM;
                                idu2exu_cmd.rd_wb_sel = SCR1_RD_WB_INC_PC;
                                idu2exu_cmd.jump_req  = 1'b1;
                                idu2exu_cmd.imm       = {{21{instr[31]}}, instr[30:20]};
                            end
                            default : rvi_illegal = 1'b1;
                        endcase
`ifdef SCR1_RVE_EXT
                        if (instr[11] | instr[19])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end // SCR1_OPCODE_JALR

                    SCR1_OPCODE_SYSTEM      : begin
                        idu2exu_use_rd      = 1'b1;
                        idu2exu_use_imm     = 1'b1;
                        idu2exu_cmd.imm     = `SCR1_XLEN'({funct3, instr[31:20]});      // {funct3, CSR address}
                        case (funct3)
                            3'b000  : begin
                                idu2exu_use_rd    = 1'b0;
                                idu2exu_use_imm   = 1'b0;
                                case ({instr[19:15], instr[11:7]})
                                    10'd0 : begin
                                        case (funct12)
                                            12'h000 : begin
                                                // ECALL
                                                idu2exu_cmd.exc_req     = 1'b1;
                                                idu2exu_cmd.exc_code    = SCR1_EXC_CODE_ECALL_M;
                                            end
                                            12'h001 : begin
                                                // EBREAK
                                                idu2exu_cmd.exc_req     = 1'b1;
                                                idu2exu_cmd.exc_code    = SCR1_EXC_CODE_BREAKPOINT;
                                            end
                                            12'h302 : begin
                                                // MRET
                                                idu2exu_cmd.mret_req    = 1'b1;
                                            end
                                            12'h105 : begin
                                                // WFI
                                                idu2exu_cmd.wfi_req     = 1'b1;
                                            end
                                            default : rvi_illegal = 1'b1;
                                        endcase // funct12
                                    end
                                    default : rvi_illegal = 1'b1;
                                endcase // {instr[19:15], instr[11:7]}
                            end
                            3'b001  : begin
                                // CSRRW
                                idu2exu_use_rs1             = 1'b1;
                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_WRITE;
                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_REG;
`ifdef SCR1_RVE_EXT
                                if (instr[11] | instr[19])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                            3'b010  : begin
                                // CSRRS
                                idu2exu_use_rs1             = 1'b1;
                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_SET;
                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_REG;
`ifdef SCR1_RVE_EXT
                                if (instr[11] | instr[19])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                            3'b011  : begin
                                // CSRRC
                                idu2exu_use_rs1             = 1'b1;
                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_CLEAR;
                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_REG;
`ifdef SCR1_RVE_EXT
                                if (instr[11] | instr[19])  rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                            3'b101  : begin
                                // CSRRWI
                                idu2exu_use_rs1             = 1'b1;             // zimm
                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_WRITE;
                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_IMM;
`ifdef SCR1_RVE_EXT
                                if (instr[11])              rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                            3'b110  : begin
                                // CSRRSI
                                idu2exu_use_rs1             = 1'b1;             // zimm
                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_SET;
                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_IMM;
`ifdef SCR1_RVE_EXT
                                if (instr[11])              rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                            3'b111  : begin
                                // CSRRCI
                                idu2exu_use_rs1             = 1'b1;             // zimm
                                idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_CSR;
                                idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_CLEAR;
                                idu2exu_cmd.csr_op          = SCR1_CSR_OP_IMM;
`ifdef SCR1_RVE_EXT
                                if (instr[11])              rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                            default : rvi_illegal = 1'b1;
                        endcase // funct3
                    end // SCR1_OPCODE_SYSTEM

                    default : begin
                        rvi_illegal = 1'b1;
                    end
                endcase // rvi_opcode
            end // SCR1_INSTR_RVI

`ifdef SCR1_RVC_EXT

            // Quadrant 0
            SCR1_INSTR_RVC0 : begin
                idu2exu_cmd.instr_rvc   = 1'b1;
                idu2exu_use_rs1         = 1'b1;
                idu2exu_use_imm         = 1'b1;
                case (funct3)
                    3'b000  : begin
                        if (~|instr[12:5])      rvc_illegal = 1'b1;
                        // C.ADDI4SPN
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_ADD;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                        idu2exu_cmd.rs1_addr    = SCR1_MPRF_SP_ADDR;
                        idu2exu_cmd.rd_addr     = {2'b01, instr[4:2]};
                        idu2exu_cmd.imm         = {22'd0, instr[10:7], instr[12:11], instr[5], instr[6], 2'b00};
                    end
                    3'b010  : begin
                        // C.LW
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                        idu2exu_cmd.lsu_cmd     = SCR1_LSU_CMD_LW;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_LSU;
                        idu2exu_cmd.rs1_addr    = {2'b01, instr[9:7]};
                        idu2exu_cmd.rd_addr     = {2'b01, instr[4:2]};
                        idu2exu_cmd.imm         = {25'd0, instr[5], instr[12:10], instr[6], 2'b00};
                    end
                    3'b110  : begin
                        // C.SW
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                        idu2exu_cmd.lsu_cmd     = SCR1_LSU_CMD_SW;
                        idu2exu_cmd.rs1_addr    = {2'b01, instr[9:7]};
                        idu2exu_cmd.rs2_addr    = {2'b01, instr[4:2]};
                        idu2exu_cmd.imm         = {25'd0, instr[5], instr[12:10], instr[6], 2'b00};
                    end
                    default : begin
                        rvc_illegal = 1'b1;
                    end
                endcase // funct3
            end // Quadrant 0

            // Quadrant 1
            SCR1_INSTR_RVC1 : begin
                idu2exu_cmd.instr_rvc   = 1'b1;
                idu2exu_use_rd          = 1'b1;
                idu2exu_use_imm         = 1'b1;
                case (funct3)
                    3'b000  : begin
                        // C.ADDI / C.NOP
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_ADD;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                        idu2exu_cmd.rs1_addr    = instr[11:7];
                        idu2exu_cmd.rd_addr     = instr[11:7];
                        idu2exu_cmd.imm         = {{27{instr[12]}}, instr[6:2]};
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end
                    3'b001  : begin
                        // C.JAL
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_INC_PC;
                        idu2exu_cmd.jump_req    = 1'b1;
                        idu2exu_cmd.rd_addr     = SCR1_MPRF_RA_ADDR;
                        idu2exu_cmd.imm         = {{21{instr[12]}}, instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
                    end
                    3'b010  : begin
                        // C.LI
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IMM;
                        idu2exu_cmd.rd_addr     = instr[11:7];
                        idu2exu_cmd.imm         = {{27{instr[12]}}, instr[6:2]};
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end
                    3'b011  : begin
                        if (~|{instr[12], instr[6:2]}) rvc_illegal = 1'b1;
                        if (instr[11:7] == SCR1_MPRF_SP_ADDR) begin
                            // C.ADDI16SP
                            idu2exu_use_rs1         = 1'b1;
                            idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_ADD;
                            idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                            idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                            idu2exu_cmd.rs1_addr    = SCR1_MPRF_SP_ADDR;
                            idu2exu_cmd.rd_addr     = SCR1_MPRF_SP_ADDR;
                            idu2exu_cmd.imm         = {{23{instr[12]}}, instr[4:3], instr[5], instr[2], instr[6], 4'd0};
                        end else begin
                            // C.LUI
                            idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IMM;
                            idu2exu_cmd.rd_addr     = instr[11:7];
                            idu2exu_cmd.imm         = {{15{instr[12]}}, instr[6:2], 12'd0};
`ifdef SCR1_RVE_EXT
                            if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                        end
                    end
                    3'b100  : begin
                        idu2exu_cmd.rs1_addr    = {2'b01, instr[9:7]};
                        idu2exu_cmd.rd_addr     = {2'b01, instr[9:7]};
                        idu2exu_cmd.rs2_addr    = {2'b01, instr[4:2]};
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rd          = 1'b1;
                        case (instr[11:10])
                            2'b00   : begin
                                if (instr[12])          rvc_illegal = 1'b1;
                                // C.SRLI
                                idu2exu_use_imm         = 1'b1;
                                idu2exu_cmd.imm         = {27'd0, instr[6:2]};
                                idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SRL;
                                idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                                idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                            end
                            2'b01   : begin
                                if (instr[12])          rvc_illegal = 1'b1;
                                // C.SRAI
                                idu2exu_use_imm         = 1'b1;
                                idu2exu_cmd.imm         = {27'd0, instr[6:2]};
                                idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SRA;
                                idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                                idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                            end
                            2'b10   : begin
                                // C.ANDI
                                idu2exu_use_imm         = 1'b1;
                                idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_AND;
                                idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                                idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                idu2exu_cmd.imm         = {{27{instr[12]}}, instr[6:2]};
                            end
                            2'b11   : begin
                                idu2exu_use_rs2         = 1'b1;
                                case ({instr[12], instr[6:5]})
                                    3'b000  : begin
                                        // C.SUB
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SUB;
                                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                    end
                                    3'b001  : begin
                                        // C.XOR
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_XOR;
                                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                    end
                                    3'b010  : begin
                                        // C.OR
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_OR;
                                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                    end
                                    3'b011  : begin
                                        // C.AND
                                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_AND;
                                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                    end
                                    default : begin
                                        rvc_illegal = 1'b1;
                                    end
                                endcase // {instr[12], instr[6:5]}
                            end
                        endcase // instr[11:10]
                    end // funct3 == 3'b100
                    3'b101  : begin
                        // C.J
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.jump_req    = 1'b1;
                        idu2exu_cmd.imm         = {{21{instr[12]}}, instr[8], instr[10:9], instr[6], instr[7], instr[2], instr[11], instr[5:3], 1'b0};
                    end
                    3'b110  : begin
                        // C.BEQZ
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SUB_EQ;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.branch_req  = 1'b1;
                        idu2exu_cmd.rs1_addr    = {2'b01, instr[9:7]};
                        idu2exu_cmd.rs2_addr    = SCR1_MPRF_ZERO_ADDR;
                        idu2exu_cmd.imm         = {{24{instr[12]}}, instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};
                    end
                    3'b111  : begin
                        // C.BNEZ
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SUB_NE;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_PC_IMM;
                        idu2exu_cmd.branch_req  = 1'b1;
                        idu2exu_cmd.rs1_addr    = {2'b01, instr[9:7]};
                        idu2exu_cmd.rs2_addr    = SCR1_MPRF_ZERO_ADDR;
                        idu2exu_cmd.imm         = {{24{instr[12]}}, instr[6:5], instr[2], instr[11:10], instr[4:3], 1'b0};
                    end
                endcase // funct3
            end // Quadrant 1

            // Quadrant 2
            SCR1_INSTR_RVC2 : begin
                idu2exu_cmd.instr_rvc   = 1'b1;
                idu2exu_use_rs1         = 1'b1;
                case (funct3)
                    3'b000  : begin
                        if (instr[12])          rvc_illegal = 1'b1;
                        // C.SLLI
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.rs1_addr    = instr[11:7];
                        idu2exu_cmd.rd_addr     = instr[11:7];
                        idu2exu_cmd.imm         = {27'd0, instr[6:2]};
                        idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_SLL;
                        idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_IMM;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end
                    3'b010  : begin
                        if (~|instr[11:7])      rvc_illegal = 1'b1;
                        // C.LWSP
                        idu2exu_use_rd          = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                        idu2exu_cmd.lsu_cmd     = SCR1_LSU_CMD_LW;
                        idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_LSU;
                        idu2exu_cmd.rs1_addr    = SCR1_MPRF_SP_ADDR;
                        idu2exu_cmd.rd_addr     = instr[11:7];
                        idu2exu_cmd.imm         = {24'd0, instr[3:2], instr[12], instr[6:4], 2'b00};
`ifdef SCR1_RVE_EXT
                        if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end
                    3'b100  : begin
                        if (~instr[12]) begin
                            if (|instr[6:2]) begin
                                // C.MV
                                idu2exu_use_rs2         = 1'b1;
                                idu2exu_use_rd          = 1'b1;
                                idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_ADD;
                                idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                                idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                idu2exu_cmd.rs1_addr    = SCR1_MPRF_ZERO_ADDR;
                                idu2exu_cmd.rs2_addr    = instr[6:2];
                                idu2exu_cmd.rd_addr     = instr[11:7];
`ifdef SCR1_RVE_EXT
                                if (instr[11]|instr[6]) rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end else begin
                                if (~|instr[11:7])      rvc_illegal = 1'b1;
                                // C.JR
                                idu2exu_use_imm         = 1'b1;
                                idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                                idu2exu_cmd.jump_req    = 1'b1;
                                idu2exu_cmd.rs1_addr    = instr[11:7];
                                idu2exu_cmd.imm         = 0;
`ifdef SCR1_RVE_EXT
                                if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                        end else begin  // instr[12] == 1
                            if (~|instr[11:2]) begin
                                // C.EBREAK
                                idu2exu_cmd.exc_req     = 1'b1;
                                idu2exu_cmd.exc_code    = SCR1_EXC_CODE_BREAKPOINT;
                            end else if (~|instr[6:2]) begin
                                // C.JALR
                                idu2exu_use_rs1         = 1'b1;
                                idu2exu_use_rd          = 1'b1;
                                idu2exu_use_imm         = 1'b1;
                                idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                                idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_INC_PC;
                                idu2exu_cmd.jump_req    = 1'b1;
                                idu2exu_cmd.rs1_addr    = instr[11:7];
                                idu2exu_cmd.rd_addr     = SCR1_MPRF_RA_ADDR;
                                idu2exu_cmd.imm         = 0;
`ifdef SCR1_RVE_EXT
                                if (instr[11])          rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end else begin
                                // C.ADD
                                idu2exu_use_rs1         = 1'b1;
                                idu2exu_use_rs2         = 1'b1;
                                idu2exu_use_rd          = 1'b1;
                                idu2exu_cmd.ialu_cmd    = SCR1_IALU_CMD_ADD;
                                idu2exu_cmd.ialu_op     = SCR1_IALU_OP_REG_REG;
                                idu2exu_cmd.rd_wb_sel   = SCR1_RD_WB_IALU;
                                idu2exu_cmd.rs1_addr    = instr[11:7];
                                idu2exu_cmd.rs2_addr    = instr[6:2];
                                idu2exu_cmd.rd_addr     = instr[11:7];
`ifdef SCR1_RVE_EXT
                                if (instr[11]|instr[6]) rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                            end
                        end // instr[12] == 1
                    end
                    3'b110  : begin
                        // C.SWSP
                        idu2exu_use_rs1         = 1'b1;
                        idu2exu_use_rs2         = 1'b1;
                        idu2exu_use_imm         = 1'b1;
                        idu2exu_cmd.sum2_op     = SCR1_SUM2_OP_REG_IMM;
                        idu2exu_cmd.lsu_cmd     = SCR1_LSU_CMD_SW;
                        idu2exu_cmd.rs1_addr    = SCR1_MPRF_SP_ADDR;
                        idu2exu_cmd.rs2_addr    = instr[6:2];
                        idu2exu_cmd.imm         = {24'd0, instr[8:7], instr[12:9], 2'b00};
`ifdef SCR1_RVE_EXT
                        if (instr[6])           rve_illegal = 1'b1;
`endif  // SCR1_RVE_EXT
                    end
                    default : begin
                        rvc_illegal = 1'b1;
                    end
                endcase // funct3
            end // Quadrant 2

            default         : begin
            end
`else   // SCR1_RVC_EXT
            default         : begin
                idu2exu_cmd.instr_rvc   = 1'b1;
                rvi_illegal             = 1'b1;
            end
`endif  // SCR1_RVC_EXT
        endcase // instr_type
    end // no imem fault

    // At this point the instruction is fully decoded
    // given that no imem fault has happened

    // Check illegal instruction
    if (
    rvi_illegal
`ifdef SCR1_RVC_EXT
    | rvc_illegal
`endif
`ifdef SCR1_RVE_EXT
    | rve_illegal
`endif
`ifdef SCR1_RVV_EXT
    | rvv_illegal
`endif
    ) begin
        idu2exu_cmd.ialu_cmd        = SCR1_IALU_CMD_NONE;
        idu2exu_cmd.lsu_cmd         = SCR1_LSU_CMD_NONE;
        idu2exu_cmd.csr_cmd         = SCR1_CSR_CMD_NONE;
        idu2exu_cmd.rd_wb_sel       = SCR1_RD_WB_NONE;
        idu2exu_cmd.jump_req        = 1'b0;
        idu2exu_cmd.branch_req      = 1'b0;
        idu2exu_cmd.mret_req        = 1'b0;
        idu2exu_cmd.fencei_req      = 1'b0;
        idu2exu_cmd.wfi_req         = 1'b0;

        idu2exu_use_rs1             = 1'b0;
        idu2exu_use_rs2             = 1'b0;
        idu2exu_use_rd              = 1'b0;

`ifndef SCR1_MTVAL_ILLEGAL_INSTR_EN
        idu2exu_use_imm             = 1'b0;
`else // SCR1_MTVAL_ILLEGAL_INSTR_EN
        idu2exu_use_imm             = 1'b1;
        idu2exu_cmd.imm             = instr;
`endif // SCR1_MTVAL_ILLEGAL_INSTR_EN
`ifdef SCR1_RVV_EXT
        idu2vexu_cmd.vop_main      = SCR1_VOP_NONE;
        idu2vexu_cmd.vop_alu_cmd   = SCR1_VOP_ALU_CMD_NONE;
        idu2vexu_cmd.vop_mem_cmd   = SCR1_VOP_MEM_CMD_NONE;
        idu2vexu_cmd.vop_alu_mask  = 1'b0;
        idu2vexu_cmd.vcrypt_main   = SCR1_VCRYPT_MAIN_NONE;
        idu2vexu_cmd.vcrypt_func   = SCR1_VCRYPT_FUNC_NONE;
        rvv_inc_flag               = 1'b0;
`endif

        idu2exu_cmd.exc_req         = 1'b1;
        idu2exu_cmd.exc_code        = SCR1_EXC_CODE_ILLEGAL_INSTR;
    end

end // RV32I(MC) decode

`ifdef SCR1_SIM_ENV
//-------------------------------------------------------------------------------
// Assertion
//-------------------------------------------------------------------------------

// X checks

SCR1_SVA_IDU_XCHECK : assert property (
    @(negedge clk) disable iff (~rst_n)
    !$isunknown({ifu2idu_vd, exu2idu_rdy})
    ) else $error("IDU Error: unknown values");

SCR1_SVA_IDU_XCHECK2 : assert property (
    @(negedge clk) disable iff (~rst_n)
    ifu2idu_vd |-> !$isunknown({ifu2idu_imem_err, (ifu2idu_imem_err ? 0 : ifu2idu_instr)})
    ) else $error("IDU Error: unknown values");

// Behavior checks

SCR1_SVA_IDU_IALU_CMD_RANGE : assert property (
    @(negedge clk) disable iff (~rst_n)
    (ifu2idu_vd & ~ifu2idu_imem_err) |->
    ((idu2exu_cmd.ialu_cmd >= SCR1_IALU_CMD_NONE) &
    (idu2exu_cmd.ialu_cmd <=
`ifdef SCR1_RVM_EXT
                            SCR1_IALU_CMD_REMU
`else
                            SCR1_IALU_CMD_SRA
`endif // SCR1_RVM_EXT
        ))
    ) else $error("IDU Error: IALU_CMD out of range");

`endif // SCR1_SIM_ENV

endmodule : scr1_pipe_idu
