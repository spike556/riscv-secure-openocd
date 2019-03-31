`include "scr1_riscv_isa_decoding.svh"

module valu
(
    input   type_scr1_vop_alu_cmd_e             valu_cmd,
    input   logic                               valu_mask,     //mask
    input   type_scr1_vrf_e_v [`LANE-1:0]       valu_op1,
    input   type_scr1_vrf_e_v [`LANE-1:0]       valu_op2,
    input   type_scr1_vrf_e_v [`LANE-1:0]       valu_op3,
    input   logic  [31:0]                       vl,
    input   logic                               valu_op1_sign,
    input   logic                               valu_op2_sign,
    input   logic                               valu_enable,
    input   logic                               valu_write_enable,
    input   logic                               valu_maskreg_enable,
    input   logic                               valu_op1_shape,   // 1:vector, 0:scalar
    input   logic                               valu_op2_shape,
    // to 8 adders
    output  type_scr1_vrf_e_v [7:0]             sum_op1,
    output  type_scr1_vrf_e_v [7:0]             sum_op2,
    output  logic                               sum_sub,
    input   logic [7:0]      [31:0]             sum_res,
    input   logic [7:0]                         sum_sign,
    // VALU output
    output  type_scr1_vrf_e_v [`LANE-1:0]       valu_res,
    output  logic [7:0]                         valu_wreq
);

assign valu_wreq = valu_write_enable  ? 8'hFF : 8'h0;

typedef struct packed {
    logic       z;      // Zero
    logic       s;      // Sign
    logic       o;      // Overflow
    logic       c;      // Carry
} type_scr1_valu_flags_s;
type_scr1_valu_flags_s  [`LANE-1:0]  sum_flags;

// FLAGS1 - flags for comparation (result of subtraction)
always_comb begin
    for (int i = 0; i < 8; i++) begin
        sum_flags[i].c  = sum_sign[i];
        sum_flags[i].z  = ~|sum_res[i];
        sum_flags[i].s  = sum_res[i][`SCR1_XLEN-1];
        sum_flags[i].o  = (~sum_op1[i][`SCR1_XLEN-1] &  sum_op2[i][`SCR1_XLEN-1] &  sum_res[i][`SCR1_XLEN-1]) |
                          ( sum_op1[i][`SCR1_XLEN-1] & ~sum_op2[i][`SCR1_XLEN-1] & ~sum_res[i][`SCR1_XLEN-1]);
    end
end

// TO 8 adders
assign sum_sub    = (valu_cmd != SCR1_VOP_ALU_CMD_ADD);
always_comb begin
    case (valu_op1_shape)
        1'b0  : sum_op1 = {8{valu_op1[0]}};
        1'b1  : sum_op1    = valu_op1;
    endcase
end
always_comb begin
    case (valu_op2_shape)
        1'b0  : sum_op2 = {8{valu_op2[0]}};
        1'b1  : sum_op2    = valu_op2;
    endcase
end
//-------------------------------------------------------------------------------
// SHIFT
//-------------------------------------------------------------------------------
logic signed [7:0] [31:0]                   shft_op1;       // SHIFT operand 1
logic [7:0] [4:0]                           shft_op2;       // SHIFT operand 2
logic [7:0] [31:0]                          shft_res;       // SHIFT result
logic [1:0] shft_cmd;

always_comb begin
    shft_op1    = sum_op1;
    for (int i = 0; i < 8; i++) begin
        shft_op2[i] = sum_op2[i][4:0];
    end
    case (shft_cmd)
        2'b10   : begin
            for (int i = 0; i < 8; i++) begin
                shft_res[i] = shft_op1[i]  >> shft_op2[i];
            end
        end
        2'b11   : begin
            for (int i = 0; i < 8; i++) begin
                shft_res[i] = shft_op1[i] >>> shft_op2[i];
            end
        end
        default : begin
            for (int i = 0; i < 8; i++) begin
                shft_res[i] = shft_op1[i] << shft_op2[i];
            end
        end
    endcase
end

// main logic
type_scr1_vrf_e_v [`LANE-1:0]       valu_res_tmp;

always_comb begin
    valu_res_tmp    = '0;
    shft_cmd        = 2'b0;
    if (valu_enable) begin
        case (valu_cmd)
            SCR1_VOP_ALU_CMD_SUB,
            SCR1_VOP_ALU_CMD_ADD  : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = sum_res[i];
                end
            end
            SCR1_VOP_ALU_CMD_AND  : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = sum_op1[i] & sum_op2[i];
                end
            end
            SCR1_VOP_ALU_CMD_OR   : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = sum_op1[i] | sum_op2[i];
                end
            end
            SCR1_VOP_ALU_CMD_XOR  : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = sum_op1[i] ^ sum_op2[i];
                end
            end
            SCR1_VOP_ALU_CMD_SEQ  : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = `SCR1_XLEN'(sum_flags[i].z);
                end
            end
            SCR1_VOP_ALU_CMD_SNE  : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = `SCR1_XLEN'(~sum_flags[i].z);
                end
            end
            SCR1_VOP_ALU_CMD_SGE  : begin
                case ({valu_op1_sign, valu_op2_sign})
                    2'b00   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = `SCR1_XLEN'(~sum_flags[i].c);
                        end
                    end
                    2'b11   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = `SCR1_XLEN'(~(sum_flags[i].s ^ sum_flags[i].o));
                        end
                    end
                    default : begin end
                endcase
            end
            SCR1_VOP_ALU_CMD_SLT  : begin
                case ({valu_op1_sign, valu_op2_sign})
                    2'b00   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = `SCR1_XLEN'(sum_flags[i].c);
                        end
                    end
                    2'b11   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = `SCR1_XLEN'(sum_flags[i].s ^ sum_flags[i].o);
                        end
                    end
                    default : begin end
                endcase
            end
            SCR1_VOP_ALU_CMD_SLL,
            SCR1_VOP_ALU_CMD_SRL,
            SCR1_VOP_ALU_CMD_SRA  : begin
                shft_cmd     = {(valu_cmd != SCR1_VOP_ALU_CMD_SLL), (valu_cmd == SCR1_VOP_ALU_CMD_SRA)};
                valu_res_tmp = shft_res;
            end
            SCR1_VOP_ALU_CMD_MAX  : begin
                case ({valu_op1_sign, valu_op2_sign})
                    2'b00   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = (~sum_flags[i].c) ? sum_op1[i]  : sum_op2[i];
                        end
                    end
                    2'b11   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = (~(sum_flags[i].s ^ sum_flags[i].o))  ? sum_op1[i]  : sum_op2[i];
                        end
                    end
                    default : begin end
                endcase
            end
            SCR1_VOP_ALU_CMD_MIN  : begin
                case ({valu_op1_sign, valu_op2_sign})
                    2'b00   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = (sum_flags[i].c)  ? sum_op1[i]  : sum_op2[i];
                        end
                    end
                    2'b11   : begin
                        for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                            valu_res_tmp[i] = (sum_flags[i].s ^ sum_flags[i].o) ? sum_op1[i]  : sum_op2[i];
                        end
                    end
                    default : begin end
                endcase
            end
            SCR1_VOP_ALU_CMD_SELECT : begin
                for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
                    valu_res_tmp[i] = sum_op1[sum_op2[i][2:0]];
                end
            end
            default : begin end
        endcase
    end
end

always_comb begin
    for (int unsigned i = 0; i < `SCR1_VLEN; i++) begin
        if (i < vl) begin
            case (valu_mask)
                1'b0 : valu_res[i] = valu_res_tmp[i];
                1'b1 : begin
                    if (valu_maskreg_enable) begin
                        valu_res[i] = valu_op3[i][0]  ? valu_res_tmp[i] : '0;
                    end else begin
                        valu_res[i] = '0;
                    end
                end
            endcase
        end else begin
            valu_res[i] = '0;
        end
    end
end

endmodule
