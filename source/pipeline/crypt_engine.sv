`include "scr1_riscv_isa_decoding.svh"
module crypt_engine
(
    input   logic                               clk,

    input   logic                               idu2crypt_req,
    input   type_scr1_crypt_cmd_s               idu2crypt_cmd,
    output  logic                               crypt2idu_rdy,

    output  logic [4:0]                         crypt2mprf_rs1_addr,
    output  logic [4:0]                         crypt2mprf_rs2_addr,
    input   logic [`SCR1_XLEN-1:0]              mprf2crypt_rs1_data,
    input   logic [`SCR1_XLEN-1:0]              mprf2crypt_rs2_data,
    output  logic [`SCR1_XLEN-1:0]              crypt2mprf_rd_data,
    output  logic [4:0]                         crypt2mprf_rd_addr,
    output  logic                               crypt2mprf_wreq
);

type_scr1_crypt_cmd_s               crypt_cmd;

`ifndef SCR1_EXU_STAGE_BYPASS
always_ff @(posedge clk) begin
    if (crypt2idu_rdy & idu2crypt_req) begin
        crypt_cmd.crypt_func <=  idu2crypt_cmd.crypt_func;
        crypt_cmd.rs1_addr   <=  idu2crypt_cmd.rs1_addr;
        crypt_cmd.rs2_addr   <=  idu2crypt_cmd.rs2_addr;
        crypt_cmd.rd_addr    <=  idu2crypt_cmd.rd_addr;
        crypt_cmd.imm        <=  idu2crypt_cmd.imm;
    end
end
`else
assign crypt_cmd.crypt_func =  idu2crypt_cmd.crypt_func;
assign crypt_cmd.rs1_addr   =  idu2crypt_cmd.rs1_addr;
assign crypt_cmd.rs2_addr   =  idu2crypt_cmd.rs2_addr;
assign crypt_cmd.rd_addr    =  idu2crypt_cmd.rd_addr;
assign crypt_cmd.imm        =  idu2crypt_cmd.imm;
`endif

assign crypt2idu_rdy = 1'b1;
assign crypt2mprf_rs1_addr = crypt_cmd.rs1_addr;
assign crypt2mprf_rs2_addr = crypt_cmd.rs2_addr;
assign crypt2mprf_rd_addr  = crypt_cmd.rd_addr;
assign crypt2mprf_wreq     = idu2crypt_req;

logic [31:0] gmul_res;
logic [31:0] bitu_res;

always_comb begin
    case (crypt_cmd.crypt_func)
        SCR1_CRYPT_FUNC_GMUL  : crypt2mprf_rd_data = gmul_res;
        SCR1_CRYPT_FUNC_GROUP : crypt2mprf_rd_data = bitu_res;
        default : crypt2mprf_rd_data = '0;
    endcase
end

gmul gmul_i1
(
    .a    (mprf2crypt_rs1_data[7:0]),
    .b    (mprf2crypt_rs2_data[7:0]),
    .m    (crypt_cmd.imm),
    .p    (gmul_res[7:0])
);
gmul gmul_i2
(
    .a    (mprf2crypt_rs1_data[15:8]),
    .b    (mprf2crypt_rs2_data[15:8]),
    .m    (crypt_cmd.imm),
    .p    (gmul_res[15:8])
);
gmul gmul_i3
(
    .a    (mprf2crypt_rs1_data[23:16]),
    .b    (mprf2crypt_rs2_data[23:16]),
    .m    (crypt_cmd.imm),
    .p    (gmul_res[23:16])
);
gmul gmul_i4
(
    .a    (mprf2crypt_rs1_data[31:24]),
    .b    (mprf2crypt_rs2_data[31:24]),
    .m    (crypt_cmd.imm),
    .p    (gmul_res[31:24])
);

bitu bitu_i1
(
    .data_in    (mprf2crypt_rs1_data),
    .bitmask    (mprf2crypt_rs2_data),
    .data_out   (bitu_res)
);

endmodule
