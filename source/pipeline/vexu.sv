// Author:  Guozhu Xin
// Last modified : 2018/4/9
//----------------------------------------------------------------------

`include "scr1_riscv_isa_decoding.svh"
`include "scr1_csr.svh"
`include "scr1_memif.svh"

module vexu
(
    // Common
    input   logic                               rst_n,
    input   logic                               clk,

    //  IDU  -> VEXU Interface
    input  logic                                idu2vexu_req,            // vexu request
    input  type_scr1_vexu_cmd_s                 idu2vexu_cmd,
    output logic                                vexu2idu_rdy,            // vexu ready for new data
    //  CSR  -> VEXU interface
    input  type_scr1_vcfg_s                     vcfg_regs,
    // VEXU -> DMEM interface
    output  logic                               vexu2dmem_req,           // Data memory request
    output  type_scr1_mem_cmd_e                 vexu2dmem_cmd,           // Data memory command
    output  type_scr1_mem_width_e               vexu2dmem_width,         // Data memory width
    output  logic [`SCR1_DMEM_AWIDTH-1:0]       vexu2dmem_addr,          // Data memory address
    output  logic [`SCR1_DMEM_DWIDTH-1:0]       vexu2dmem_wdata,         // Data memory write data
    input   logic                               dmem2vexu_req_ack,       // Data memory request acknowledge
    input   logic [`SCR1_DMEM_DWIDTH-1:0]       dmem2vexu_rdata,         // Data memory read data
    input   type_scr1_mem_resp_e                dmem2vexu_resp,          // Data memory response

    // VEXU -> VRF interface
    output  logic [4:0]                         vexu2vrf_rs1_addr,
    output  logic [4:0]                         vexu2vrf_rs2_addr,
    input   type_scr1_vrf_e_v [`LANE-1:0]       vrf2vexu_rs1_data,
    input   type_scr1_vrf_e_v [`LANE-1:0]       vrf2vexu_rs2_data,
    input   type_scr1_vrf_e_v [`LANE-1:0]       vrf2vexu_mask_data,
    output  logic [4:0]                         vexu2vrf_rd_addr,
    output  logic [`LANE-1:0]                   vexu2vrf_rd_wreq,
    output  type_scr1_vrf_e_v [`LANE-1:0]       vexu2vrf_rd_wdata,

    //  VEXU ->  MPRF interface
    input   logic [`SCR1_XLEN-1:0]              mprf2vexu_rs1_data,
    input   logic [`SCR1_XLEN-1:0]              mprf2vexu_rs2_data
);
//-----------------------------common-----------------------------------
logic vlsu_req;
logic sha_req;
logic aes_req;

assign vlsu_req   = idu2vexu_req & (idu2vexu_cmd.vop_main  == SCR1_VOP_MEM);
assign sha_req    = idu2vexu_req & (idu2vexu_cmd.vcrypt_main == SCR1_VCRYPT_MAIN_SHA2);
assign aes_req    = idu2vexu_req & (idu2vexu_cmd.vcrypt_main == SCR1_VCRYPT_MAIN_AES);

always_comb begin
    case(idu2vexu_cmd.vop_mem_cmd)
        SCR1_VOP_MEM_CMD_ST,
        SCR1_VOP_MEM_CMD_STS,
        SCR1_VOP_MEM_CMD_STX  : begin
            vexu2vrf_rs1_addr = idu2vexu_cmd.rs3_addr;
        end
        default: vexu2vrf_rs1_addr = idu2vexu_cmd.rs1_addr;
    endcase
end
assign vexu2vrf_rs2_addr = idu2vexu_cmd.rs2_addr;
assign vexu2vrf_rd_addr  = idu2vexu_cmd.rd_addr;

//---------------------------------csr read--------------------------------
typedef struct packed {
    logic [4:0]   vshape;
    logic [4:0]   verep;
    logic [5:0]   vew;
} vtype_t;

vtype_t [`SCR1_XLEN-1:0] vtype;
logic   [31:0]           vl;

assign vl = vcfg_regs.csr_vl;
assign vtype[0] = vcfg_regs.csr_vcfg0[15:0];
assign vtype[1] = vcfg_regs.csr_vcfg0[31:16];
assign vtype[2] = vcfg_regs.csr_vcfg1[15:0];
assign vtype[3] = vcfg_regs.csr_vcfg1[31:16];
assign vtype[4] = vcfg_regs.csr_vcfg2[15:0];
assign vtype[5] = vcfg_regs.csr_vcfg2[31:16];
assign vtype[6] = vcfg_regs.csr_vcfg3[15:0];
assign vtype[7] = vcfg_regs.csr_vcfg3[31:16];
assign vtype[8] = vcfg_regs.csr_vcfg4[15:0];
assign vtype[9] = vcfg_regs.csr_vcfg4[31:16];
assign vtype[10] = vcfg_regs.csr_vcfg5[15:0];
assign vtype[11] = vcfg_regs.csr_vcfg5[31:16];
assign vtype[12] = vcfg_regs.csr_vcfg6[15:0];
assign vtype[13] = vcfg_regs.csr_vcfg6[31:16];
assign vtype[14] = vcfg_regs.csr_vcfg7[15:0];
assign vtype[15] = vcfg_regs.csr_vcfg7[31:16];
assign vtype[16] = vcfg_regs.csr_vcfg8[15:0];
assign vtype[17] = vcfg_regs.csr_vcfg8[31:16];
assign vtype[18] = vcfg_regs.csr_vcfg9[15:0];
assign vtype[19] = vcfg_regs.csr_vcfg9[31:16];
assign vtype[20] = vcfg_regs.csr_vcfg10[15:0];
assign vtype[21] = vcfg_regs.csr_vcfg10[31:16];
assign vtype[22] = vcfg_regs.csr_vcfg11[15:0];
assign vtype[23] = vcfg_regs.csr_vcfg11[31:16];
assign vtype[24] = vcfg_regs.csr_vcfg12[15:0];
assign vtype[25] = vcfg_regs.csr_vcfg12[31:16];
assign vtype[26] = vcfg_regs.csr_vcfg13[15:0];
assign vtype[27] = vcfg_regs.csr_vcfg13[31:16];
assign vtype[28] = vcfg_regs.csr_vcfg14[15:0];
assign vtype[29] = vcfg_regs.csr_vcfg14[31:16];
assign vtype[30] = vcfg_regs.csr_vcfg15[15:0];
assign vtype[31] = vcfg_regs.csr_vcfg15[31:16];
//-------------------------------adders inst-------------------------------
logic [7:0]      [31:0]              sum_res;
logic [7:0]                          sum_sign;

//-----------------------------valu inst----------------------------------
logic  valu_op1_sign;
logic  valu_op2_sign;
logic  valu_enable;
logic  valu_write_enable;
logic  valu_maskreg_enable;
logic  valu_op1_shape;
logic  valu_op2_shape;
type_scr1_vrf_e_v [7:0] sum_valu_op1;
type_scr1_vrf_e_v [7:0] sum_valu_op2;
logic  sum_valu_sub;
type_scr1_vrf_e_v [`LANE-1:0]       valu_res;
logic [7:0]                         valu_wreq;

assign valu_op1_sign = (vtype[vexu2vrf_rs1_addr].verep ==  `SCR1_VREP_SINT);
assign valu_op2_sign = (vtype[vexu2vrf_rs2_addr].verep ==  `SCR1_VREP_SINT);
assign valu_enable   = (vtype[vexu2vrf_rs1_addr].vew == `SCR1_VEW_32BIT) &&
                       (vtype[vexu2vrf_rs2_addr].vew == `SCR1_VEW_32BIT);
assign valu_write_enable = (vtype[vexu2vrf_rd_addr].vew == `SCR1_VEW_32BIT);
assign valu_maskreg_enable = (vtype[1].vew == `SCR1_VEW_32BIT);
assign valu_op1_shape = (vtype[vexu2vrf_rs1_addr].vshape == `SCR1_VSHAPE_VECTOR);
assign valu_op2_shape = (vtype[vexu2vrf_rs2_addr].vshape == `SCR1_VSHAPE_VECTOR);

valu valu_inst (
  .valu_cmd             (idu2vexu_cmd.vop_alu_cmd),
  .valu_mask            (idu2vexu_cmd.vop_alu_mask),
  .valu_op1             (vrf2vexu_rs1_data),
  .valu_op2             (vrf2vexu_rs2_data),
  .valu_op3             (vrf2vexu_mask_data),
  .vl                   (vl),
  .valu_op1_sign        (valu_op1_sign),
  .valu_op2_sign        (valu_op2_sign),
  .valu_enable          (valu_enable),
  .valu_write_enable    (valu_write_enable),
  .valu_maskreg_enable  (valu_maskreg_enable),
  .valu_op1_shape       (valu_op1_shape),   // 1:vector, 0:scalar
  .valu_op2_shape       (valu_op2_shape),
  // to 8 adders
  .sum_op1              (sum_valu_op1),
  .sum_op2              (sum_valu_op2),
  .sum_sub              (sum_valu_sub),
  .sum_res              (sum_res),
  .sum_sign             (sum_sign),
  // VALU output
  .valu_res             (valu_res),
  .valu_wreq            (valu_wreq)
);
//-----------------------------vlsu inst-------------------------------
logic [`SCR1_XLEN-1:0]              vexu2vlsu_addr;
logic                               vlsu2vexu_rdy;
type_scr1_vrf_e_v  [7:0]            vlsu2vexu_l_data;
logic  [7:0]                        vlsu2vexu_rd_wreq;
type_scr1_vrf_e_v [7:0] sum_vlsu_op1;
type_scr1_vrf_e_v [7:0] sum_vlsu_op2;
logic  sum_vlsu_sub;
type_scr1_vrf_e_v [1:0] sum_vlsu_op1_part0;
type_scr1_vrf_e_v [1:0] sum_vlsu_op2_part0;
type_scr1_vrf_e_v       sum_vlsu_op1_part1;
type_scr1_vrf_e_v       sum_vlsu_op2_part1;
type_scr1_vrf_e_v [4:0] sum_vlsu_op1_part2;
type_scr1_vrf_e_v [4:0] sum_vlsu_op2_part2;

assign sum_vlsu_op1_part1 = mprf2vexu_rs1_data;
assign sum_vlsu_op2_part1 = idu2vexu_cmd.imm;
assign sum_vlsu_op1_part2 = '0;
assign sum_vlsu_op2_part2 = '0;
assign sum_vlsu_op1 = {sum_vlsu_op1_part2, sum_vlsu_op1_part1, sum_vlsu_op1_part0};
assign sum_vlsu_op2 = {sum_vlsu_op2_part2, sum_vlsu_op2_part1, sum_vlsu_op2_part0};
assign vexu2vlsu_addr = sum_res[2];

vlsu vlsu_inst
(
    // Common
    .rst_n                    (rst_n),
    .clk                      (clk),

    // VEXU <-> VLSU interface
    .vexu2vlsu_req            (vlsu_req),            // Request to LSU
    .vexu2vlsu_cmd            (idu2vexu_cmd.vop_mem_cmd),            // LSU command
    .vexu2vlsu_addr           (vexu2vlsu_addr),           // Address of DMEM
    .vexu2vlsu_s_data         (vrf2vexu_rs1_data),         // Data for store
    .vlsu2vexu_rdy            (vlsu2vexu_rdy),            // LSU received DMEM response
    .vlsu2vexu_l_data         (vlsu2vexu_l_data),         // Load data
    .vlsu2vexu_rd_wreq        (vlsu2vexu_rd_wreq),
    .vexu2vlsu_vs2            (vrf2vexu_rs2_data),
    .vexu2vlsu_stride_offset  (mprf2vexu_rs2_data),
    .vl                       (vl),

    // VLSU -> DMEM interface
    .vlsu2dmem_req            (vexu2dmem_req),           // Data memory request
    .vlsu2dmem_cmd            (vexu2dmem_cmd),           // Data memory command
    .vlsu2dmem_width          (vexu2dmem_width),         // Data memory width
    .vlsu2dmem_addr           (vexu2dmem_addr),          // Data memory address
    .vlsu2dmem_wdata          (vexu2dmem_wdata),         // Data memory write data
    .dmem2vlsu_req_ack        (dmem2vexu_req_ack),       // Data memory request acknowledge
    .dmem2vlsu_rdata          (dmem2vexu_rdata),         // Data memory read data
    .dmem2vlsu_resp           (dmem2vexu_resp),          // Data memory response

    // VLSU -> ADDERS interface
    .sum_op1                  (sum_vlsu_op1_part0),
    .sum_op2                  (sum_vlsu_op2_part0),
    .sum_sub                  (sum_vlsu_sub),
    .sum_res                  (sum_res[1:0])
);
//-------------------------SHA inst--------------------------------------
logic                                sha2vexu_rdy;
type_scr1_vrf_e_v [7:0]              sha_res;
logic [7:0]                          sha_wreq;
type_scr1_vrf_e_v [7:0]              sum_sha_op1;
type_scr1_vrf_e_v [7:0]              sum_sha_op2;
logic                                sum_sha_sub;

sha sha_inst
(
    // Common
    .rst_n            (rst_n),
    .clk              (clk),

    //  VEXU  -> SHA Interface
    .vexu2sha_req     (sha_req),            // vexu request
    .vexu2sha_func    (idu2vexu_cmd.vcrypt_func),           // init, hash
    .sha2vexu_rdy     (sha2vexu_rdy),
    .sha_op1          (vrf2vexu_rs1_data),                // data low  part
    .sha_op2          (vrf2vexu_rs2_data),                // data high part
    .sha_res          (sha_res),
    .sha_wreq         (sha_wreq),

    // SHA  -> ADDER Interface
    .sum_op1          (sum_sha_op1),
    .sum_op2          (sum_sha_op2),
    .sum_sub          (sum_sha_sub),
    .sum_res          (sum_res)
);
//---------------------------aes inst------------------------------------
logic                                aes2vexu_rdy;
type_scr1_vrf_e_v [3:0]              aes_res;
type_scr1_vrf_e_v [7:0]              aes_res_wback;
logic [7:0]                          aes_wreq;

assign aes_res_wback = {128'b0, aes_res};

aes aes_inst
(
    // Common
    .rst_n                (rst_n),
    .clk                  (clk),

    //  VEXU  -> AES Interface
    .vexu2aes_req         (aes_req),            // vexu request
    .vexu2aes_func        (idu2vexu_cmd.vcrypt_func),
    .vexu2aes_length      (idu2vexu_cmd.vcrypt_length),
    .aes2vexu_rdy         (aes2vexu_rdy),
    .aes_op1              (vrf2vexu_rs1_data[3:0]),                // encrypt:msg  decrypt:cipher
    .aes_op2              (vrf2vexu_rs2_data),                // key
    .aes_res              (aes_res),
    .aes_wreq             (aes_wreq)
);
//-------------------------------adders inst-------------------------------
type_scr1_vrf_e_v [7:0]              sum_op1;
type_scr1_vrf_e_v [7:0]              sum_op2;
logic                                sum_sub;

always_comb begin
    case (1'b1)
        vlsu_req  : begin
            sum_op1 = sum_vlsu_op1;
            sum_op2 = sum_vlsu_op2;
            sum_sub = sum_vlsu_sub;
        end
        sha_req   : begin
            sum_op1 = sum_sha_op1;
            sum_op2 = sum_sha_op2;
            sum_sub = sum_sha_sub;
        end
        default   : begin
            sum_op1 = sum_valu_op1;
            sum_op2 = sum_valu_op2;
            sum_sub = sum_valu_sub;
        end
    endcase
end

vadders vadders_inst
(
    .sum_op1        (sum_op1),
    .sum_op2        (sum_op2),
    .sum_sub        (sum_sub),
    .sum_res        (sum_res),
    .sum_sign       (sum_sign)
);
//-------------------------------output------------------------------------------
always_comb begin
    if (idu2vexu_cmd.vop_main  ==  SCR1_VOP_MEM) begin
        vexu2idu_rdy = vlsu2vexu_rdy;
    end
`ifdef SCR1_RVY_EXT
    else if (idu2vexu_cmd.vcrypt_main  ==  SCR1_VCRYPT_MAIN_SHA2) begin
        vexu2idu_rdy = sha2vexu_rdy;
    end else if (idu2vexu_cmd.vcrypt_main  ==  SCR1_VCRYPT_MAIN_AES) begin
        vexu2idu_rdy = aes2vexu_rdy;
    end
`endif
    else begin
        vexu2idu_rdy = 1;
    end
end

always_comb begin
    case (1'b1)
        vlsu_req  : begin
            vexu2vrf_rd_wdata = vlsu2vexu_l_data;
            vexu2vrf_rd_wreq  = vlsu2vexu_rd_wreq;
        end
        sha_req   : begin
            vexu2vrf_rd_wdata = sha_res;
            vexu2vrf_rd_wreq  = sha_wreq;
        end
        aes_req   : begin
            vexu2vrf_rd_wdata = aes_res_wback;
            vexu2vrf_rd_wreq  = aes_wreq;
        end
        default   : begin
            vexu2vrf_rd_wdata = valu_res;
            vexu2vrf_rd_wreq  = idu2vexu_req  ? valu_wreq : 8'b0;
        end
    endcase
end

endmodule
