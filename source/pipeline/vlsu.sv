`include "scr1_memif.svh"
`include "scr1_riscv_isa_decoding.svh"

module vlsu
(
    // Common
    input   logic                               rst_n,
    input   logic                               clk,

    // VEXU <-> VLSU interface
    input   logic                               vexu2vlsu_req,            // Request to LSU
    input   type_scr1_vop_mem_cmd_e             vexu2vlsu_cmd,            // LSU command
    input   logic [`SCR1_XLEN-1:0]              vexu2vlsu_addr,           // Address of DMEM
    input   type_scr1_vrf_e_v [`LANE-1:0]       vexu2vlsu_s_data,         // Data for store
    output  logic                               vlsu2vexu_rdy,            // LSU received DMEM response
    output  type_scr1_vrf_e_v  [7:0]            vlsu2vexu_l_data,         // Load data
    output  logic  [7:0]                        vlsu2vexu_rd_wreq,
    input   type_scr1_vrf_e_v [`LANE-1:0]       vexu2vlsu_vs2,
    input   logic  [31:0]                       vexu2vlsu_stride_offset,
    input   logic  [31:0]                       vl,

    // VLSU -> DMEM interface
    output  logic                               vlsu2dmem_req,           // Data memory request
    output  type_scr1_mem_cmd_e                 vlsu2dmem_cmd,           // Data memory command
    output  type_scr1_mem_width_e               vlsu2dmem_width,         // Data memory width
    output  logic [`SCR1_DMEM_AWIDTH-1:0]       vlsu2dmem_addr,          // Data memory address
    output  logic [`SCR1_DMEM_DWIDTH-1:0]       vlsu2dmem_wdata,         // Data memory write data
    input   logic                               dmem2vlsu_req_ack,       // Data memory request acknowledge
    input   logic [`SCR1_DMEM_DWIDTH-1:0]       dmem2vlsu_rdata,         // Data memory read data
    input   type_scr1_mem_resp_e                dmem2vlsu_resp,          // Data memory response

    // VLSU -> ADDERS interface
    output  type_scr1_vrf_e_v [1:0]             sum_op1,
    output  type_scr1_vrf_e_v [1:0]             sum_op2,
    output  logic                               sum_sub,
    input   logic [1:0]      [31:0]             sum_res
);

logic                     dmem_resp_ok;
logic                     dmem_resp_er;
logic                     mem_exc;
logic                     misalign;
logic                     boundary;
assign  dmem_resp_ok  = (dmem2vlsu_resp == SCR1_MEM_RESP_RDY_OK);
assign  dmem_resp_er  = (dmem2vlsu_resp == SCR1_MEM_RESP_RDY_ER);
assign  misalign      = |vexu2vlsu_addr[1:0];
assign  mem_exc       = dmem_resp_er | misalign;
assign  vlsu2vexu_rdy = boundary  &&  (dmem_resp_ok | dmem_resp_er);

// fsm logic
typedef enum logic  {
    MEM_IDLE,
    MEM_ITER
}   type_mem_fsm_e;
type_mem_fsm_e            mem_fsm;
logic   [`SCR1_XLEN-1:0]  stride_offset;
logic   [2:0]             mem_cnt;
logic   [`SCR1_XLEN-1:0]  stride_offset_new;
logic   [2:0]             mem_cnt_new;
logic   [4:0]             mem_cnt_addr;

assign  sum_sub = 0;
assign  mem_cnt_addr = (mem_cnt << 2);
assign  boundary      = (mem_cnt  ==  vl-1);

always_comb begin
    case (vexu2vlsu_cmd)
        SCR1_VOP_MEM_CMD_LD,
        SCR1_VOP_MEM_CMD_ST : begin
            sum_op1[0] = 32'(mem_cnt);
            sum_op2[0] = 32'b1;
        end
        SCR1_VOP_MEM_CMD_LDS,
        SCR1_VOP_MEM_CMD_STS: begin
            sum_op1[0] = stride_offset;
            sum_op2[0] = vexu2vlsu_stride_offset;
        end
        default : begin
            sum_op1[0] = 32'b0;
            sum_op2[0] = 32'b0;
        end
    endcase
end

assign  mem_cnt_new = boundary  ? '0 : sum_res[0][2:0];
assign  stride_offset_new = boundary  ? '0 : sum_res[0];

always_ff @(posedge clk, negedge rst_n) begin
    if (~rst_n) begin
        mem_cnt <=  '0;
        stride_offset <=  '0;
        mem_fsm <=  MEM_IDLE;
    end else begin
        case (mem_fsm)
            MEM_IDLE  : begin
                if (vexu2vlsu_req & dmem2vlsu_req_ack & ~mem_exc) begin
                    mem_fsm <= MEM_ITER;
                end
            end
            MEM_ITER  : begin
                if (dmem_resp_ok | dmem_resp_er) begin
                    mem_fsm <=  MEM_IDLE;
                    mem_cnt <=  mem_cnt_new;
                    stride_offset <=  stride_offset_new;
                end
            end
        endcase
    end
end

assign  sum_op1[1] = vexu2vlsu_addr;
always_comb begin
    case (vexu2vlsu_cmd)
        SCR1_VOP_MEM_CMD_LD,
        SCR1_VOP_MEM_CMD_ST : sum_op2[1] = mem_cnt_addr;
        SCR1_VOP_MEM_CMD_LDS,
        SCR1_VOP_MEM_CMD_STS: sum_op2[1] = stride_offset;
        SCR1_VOP_MEM_CMD_LDX,
        SCR1_VOP_MEM_CMD_STX: sum_op2[1] = vexu2vlsu_vs2[mem_cnt];
        default :             sum_op2[1] = '0;
    endcase
end
assign  vlsu2dmem_addr = sum_res[1];

assign  vlsu2dmem_req =  vexu2vlsu_req & ~mem_exc & (mem_fsm ==  MEM_IDLE);
always_comb begin
    vlsu2dmem_cmd    = SCR1_MEM_CMD_RD;
    vlsu2dmem_width  = SCR1_MEM_WIDTH_WORD;
    case (vexu2vlsu_cmd)
        SCR1_VOP_MEM_CMD_LD,
        SCR1_VOP_MEM_CMD_LDS,
        SCR1_VOP_MEM_CMD_LDX  : begin
            vlsu2dmem_cmd    = SCR1_MEM_CMD_RD;
            vlsu2dmem_width  = SCR1_MEM_WIDTH_WORD;
        end
        SCR1_VOP_MEM_CMD_ST,
        SCR1_VOP_MEM_CMD_STS,
        SCR1_VOP_MEM_CMD_STX  : begin
            vlsu2dmem_cmd    = SCR1_MEM_CMD_WR;
            vlsu2dmem_width  = SCR1_MEM_WIDTH_WORD;
        end
        default : begin end
    endcase
end

always_comb begin
    vlsu2vexu_l_data = '0;
    vlsu2vexu_rd_wreq = '0;
    case (vexu2vlsu_cmd)
        SCR1_VOP_MEM_CMD_LD,
        SCR1_VOP_MEM_CMD_LDS,
        SCR1_VOP_MEM_CMD_LDX  : begin
            vlsu2vexu_l_data[mem_cnt] = dmem2vlsu_rdata;
            vlsu2vexu_rd_wreq[mem_cnt] = 1'b1;
        end
        default  : begin end
    endcase
end

assign vlsu2dmem_wdata = vexu2vlsu_s_data[mem_cnt];

endmodule
