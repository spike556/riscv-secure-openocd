// Author:  Guozhu Xin
// Last modified : 2018/4/4
//----------------------------------------------------------------------
`include "scr1_arch_types.svh"

module vrf
(
    // Common
    input   logic                               rst_n,
    input   logic                               clk,

    //  VEXU ->  VRF interface
    input  logic [4:0]                          vexu2vrf_rs1_addr,
    input  logic [4:0]                          vexu2vrf_rs2_addr,
    output  type_scr1_vrf_e_v [`LANE-1:0]       vrf2vexu_rs1_data,
    output  type_scr1_vrf_e_v [`LANE-1:0]       vrf2vexu_rs2_data,
    output  type_scr1_vrf_e_v [`LANE-1:0]       vrf2vexu_mask_data,
    input  logic [4:0]                          vexu2vrf_rd_addr,
    input  logic [`LANE-1:0]                    vexu2vrf_rd_wreq,
    input  type_scr1_vrf_e_v [`LANE-1:0]        vexu2vrf_rd_wdata
);

type_scr1_vrf_e_v [`SCR1_XLEN-1:0] [`SCR1_VLEN-1:0] vreg;

assign vrf2vexu_rs1_data = vreg[vexu2vrf_rs1_addr];
assign vrf2vexu_rs2_data = vreg[vexu2vrf_rs2_addr];
assign vrf2vexu_mask_data = vreg[5'b1];

always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        vreg  <=  '0;
    end else begin
        if (vexu2vrf_rd_wreq[0]) vreg[vexu2vrf_rd_addr][0]  <=  vexu2vrf_rd_wdata[0];
        if (vexu2vrf_rd_wreq[1]) vreg[vexu2vrf_rd_addr][1]  <=  vexu2vrf_rd_wdata[1];
        if (vexu2vrf_rd_wreq[2]) vreg[vexu2vrf_rd_addr][2]  <=  vexu2vrf_rd_wdata[2];
        if (vexu2vrf_rd_wreq[3]) vreg[vexu2vrf_rd_addr][3]  <=  vexu2vrf_rd_wdata[3];
        if (vexu2vrf_rd_wreq[4]) vreg[vexu2vrf_rd_addr][4]  <=  vexu2vrf_rd_wdata[4];
        if (vexu2vrf_rd_wreq[5]) vreg[vexu2vrf_rd_addr][5]  <=  vexu2vrf_rd_wdata[5];
        if (vexu2vrf_rd_wreq[6]) vreg[vexu2vrf_rd_addr][6]  <=  vexu2vrf_rd_wdata[6];
        if (vexu2vrf_rd_wreq[7]) vreg[vexu2vrf_rd_addr][7]  <=  vexu2vrf_rd_wdata[7];
    end
end

endmodule
