// 8 adders
`include "scr1_arch_types.svh"

module vadders
(
    input  type_scr1_vrf_e_v [7:0]              sum_op1,
    input  type_scr1_vrf_e_v [7:0]              sum_op2,
    input  logic                                sum_sub,
    output logic [7:0]      [31:0]              sum_res,
    output logic [7:0]                          sum_sign
);

logic [7:0]      [32:0]  sum_res_long;
always_comb begin
    for (int i = 0; i < 8; i++) begin
        sum_res_long[i] = sum_sub ? (sum_op1[i] - sum_op2[i]) : (sum_op1[i] + sum_op2[i]);
    end
end

assign sum_res[0] = sum_res_long[0][31:0];
assign sum_res[1] = sum_res_long[1][31:0];
assign sum_res[2] = sum_res_long[2][31:0];
assign sum_res[3] = sum_res_long[3][31:0];
assign sum_res[4] = sum_res_long[4][31:0];
assign sum_res[5] = sum_res_long[5][31:0];
assign sum_res[6] = sum_res_long[6][31:0];
assign sum_res[7] = sum_res_long[7][31:0];

assign sum_sign[0] = sum_res_long[0][32];
assign sum_sign[1] = sum_res_long[1][32];
assign sum_sign[2] = sum_res_long[2][32];
assign sum_sign[3] = sum_res_long[3][32];
assign sum_sign[4] = sum_res_long[4][32];
assign sum_sign[5] = sum_res_long[5][32];
assign sum_sign[6] = sum_res_long[6][32];
assign sum_sign[7] = sum_res_long[7][32];

endmodule
