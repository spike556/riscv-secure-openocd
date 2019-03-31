/// Copyright by Syntacore LLC © 2016, 2017. See LICENSE for details
/// @file       <scr1_pipe_mprf.sv>
/// @brief      Multi Port Register File
///

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"

module scr1_pipe_mprf (
    // Common
    input   logic                               rst_n,
    input   logic                               clk,

    // EXU <-> MPRF interface
    input   logic [`SCR1_MPRF_ADDR_WIDTH-1:0]   exu2mprf_rs1_addr,       // MPRF rs1 read address
    output  logic [`SCR1_XLEN-1:0]              mprf2exu_rs1_data,       // MPRF rs1 read data
    input   logic [`SCR1_MPRF_ADDR_WIDTH-1:0]   exu2mprf_rs2_addr,       // MPRF rs2 read address
    output  logic [`SCR1_XLEN-1:0]              mprf2exu_rs2_data,       // MPRF rs2 read data
    input   logic                               exu2mprf_w_req,          // MPRF write request
    input   logic [`SCR1_MPRF_ADDR_WIDTH-1:0]   exu2mprf_rd_addr,        // MPRF rd write address
    input   logic [`SCR1_XLEN-1:0]              exu2mprf_rd_data         // MPRF rd write data

);


//-------------------------------------------------------------------------------
// Local types declaration
//-------------------------------------------------------------------------------
`ifdef SCR1_RVE_EXT
type_scr1_mprf_v [1:15]     mprf_int;
`else // ~SCR1_RVE_EXT
type_scr1_mprf_v [1:31]     mprf_int;
`endif // ~SCR1_RVE_EXT

//-------------------------------------------------------------------------------
// Read MPRF
//-------------------------------------------------------------------------------
assign mprf2exu_rs1_data = (|exu2mprf_rs1_addr) ? mprf_int[unsigned'(exu2mprf_rs1_addr)] : '0;
assign mprf2exu_rs2_data = (|exu2mprf_rs2_addr) ? mprf_int[unsigned'(exu2mprf_rs2_addr)] : '0;

//-------------------------------------------------------------------------------
// Write MPRF
//-------------------------------------------------------------------------------
always_ff @(negedge rst_n, posedge clk) begin
    if (~rst_n) begin
        mprf_int <= '0;
    end else begin
        if (exu2mprf_w_req) begin
            if (|exu2mprf_rd_addr) begin
                mprf_int[unsigned'(exu2mprf_rd_addr)] <= exu2mprf_rd_data;
            end
        end
   end
end


`ifdef SCR1_SIM_ENV
//-------------------------------------------------------------------------------
// Assertion
//-------------------------------------------------------------------------------

SCR1_SVA_MPRF_WRITEX : assert property (
    @(negedge clk) disable iff (~rst_n)
    exu2mprf_w_req |-> !$isunknown({exu2mprf_rd_addr, (|exu2mprf_rd_addr ? exu2mprf_rd_data : `SCR1_XLEN'd0)})
    ) else $error("MPRF error: unknown values");

`endif // SCR1_SIM_ENV

endmodule : scr1_pipe_mprf
