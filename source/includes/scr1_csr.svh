`ifndef SCR1_CSR_SVH
`define SCR1_CSR_SVH
/// Copyright by Syntacore LLC © 2016, 2017. See LICENSE for details
/// @file       <scr1_csr.svh>
/// @brief      CSR mapping/description file
///

`include "scr1_arch_description.svh"
`include "scr1_arch_types.svh"
`include "scr1_ipic.svh"

`ifdef SCR1_RVE_EXT
`define SCR1_CSR_REDUCED_CNT
`endif // SCR1_RVE_EXT

`ifdef SCR1_CSR_REDUCED_CNT
`undef SCR1_CSR_MCOUNTEN_EN
`endif // SCR1_CSR_REDUCED_CNT

//-------------------------------------------------------------------------------
// CSR addresses (standard)
//-------------------------------------------------------------------------------

// Machine Information Registers (read-only)
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MVENDORID     = 'hF11;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MARCHID       = 'hF12;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MIMPID        = 'hF13;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MHARTID       = 'hF14;

// Machine Trap Setup (read-write)
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MSTATUS       = 'h300;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MISA          = 'h301;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MIE           = 'h304;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MTVEC         = 'h305;

// Machine Trap Handling (read-write)
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MSCRATCH      = 'h340;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MEPC          = 'h341;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MCAUSE        = 'h342;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MTVAL         = 'h343;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MIP           = 'h344;

// Machine Counters/Timers (read-write)
`ifndef SCR1_CSR_REDUCED_CNT
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MCYCLE        = 'hB00;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MINSTRET      = 'hB02;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MCYCLEH       = 'hB80;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MINSTRETH     = 'hB82;
`endif // SCR1_CSR_REDUCED_CNT

// Shadow Counters/Timers (read-only)
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_TIME          = 'hC01;
`ifndef SCR1_CSR_REDUCED_CNT
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_CYCLE         = 'hC00;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_INSTRET       = 'hC02;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_TIMEH         = 'hC81;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_CYCLEH        = 'hC80;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_INSTRETH      = 'hC82;
`endif // SCR1_CSR_REDUCED_CNT

`ifdef SCR1_DBGC_EN
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_DBGC_SCRATCH  = 'h7C8;
`endif // SCR1_DBGC_EN

//-------------------------------------------------------------------------------
// CSR addresses (non-standard)
//-------------------------------------------------------------------------------
`ifdef SCR1_CSR_MCOUNTEN_EN
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_MCOUNTEN      = 'h7E0;
`endif // SCR1_CSR_MCOUNTEN_EN

`ifdef SCR1_BRKM_EN
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_BRKM_MBASE    = 'h7C0;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_BRKM_MSPAN    = 'h008;    // must be power of 2
`endif // SCR1_BRKM_EN

`ifdef SCR1_IPIC_EN
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_BASE     = 'hBF0;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_CISV     = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_CISV );
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_CICSR    = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_CICSR);
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_IPR      = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_IPR  );
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_ISVR     = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_ISVR );
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_EOI      = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_EOI  );
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_SOI      = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_SOI  );
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_IDX      = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_IDX  );
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_IPIC_ICSR     = (SCR1_CSR_ADDR_IPIC_BASE + SCR1_IPIC_ICSR );
`endif // SCR1_IPIC_EN

//-------------------------------------------------------------------
// vector extension CSRs address (non-standard)
`ifdef SCR1_RVV_EXT
//parameter bit SCR1_CSR_ADDR_VCS     = 'h800  // (alias of vl,vxrm,vxsat)
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VL      = 'h801;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VXRM    = 'h802;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VXSAT   = 'h803;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VMAXEW  = 'h804;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG0   = 'h805;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG1   = 'h806;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG2   = 'h807;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG3   = 'h808;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG4   = 'h809;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG5   = 'h80A;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG6   = 'h80B;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG7   = 'h80C;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG8   = 'h80D;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG9   = 'h80E;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG10  = 'h80F;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG11  = 'h810;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG12  = 'h811;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG13  = 'h812;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG14  = 'h813;
parameter bit [SCR1_CSR_ADDR_WIDTH-1:0] SCR1_CSR_ADDR_VCFG15  = 'h814;
// vcs reg alias
typedef struct packed {
    logic [`SCR1_XLEN-1:0]                              csr_vl;
    logic [2:0]                                         csr_vxrm;  // not supported in current design
    logic                                               csr_vxsat;
    logic [5:0]                                         csr_vmaxew;
    logic [31:0]                                        csr_vcfg0;
    logic [31:0]                                        csr_vcfg1;
    logic [31:0]                                        csr_vcfg2;
    logic [31:0]                                        csr_vcfg3;
    logic [31:0]                                        csr_vcfg4;
    logic [31:0]                                        csr_vcfg5;
    logic [31:0]                                        csr_vcfg6;
    logic [31:0]                                        csr_vcfg7;
    logic [31:0]                                        csr_vcfg8;
    logic [31:0]                                        csr_vcfg9;
    logic [31:0]                                        csr_vcfg10;
    logic [31:0]                                        csr_vcfg11;
    logic [31:0]                                        csr_vcfg12;
    logic [31:0]                                        csr_vcfg13;
    logic [31:0]                                        csr_vcfg14;
    logic [31:0]                                        csr_vcfg15;
} type_scr1_vcfg_s;
`endif
//-------------------------------------------------------------------

//-------------------------------------------------------------------------------
// CSR definitions
//-------------------------------------------------------------------------------

// General
parameter bit [`SCR1_XLEN-1:0] SCR1_RST_VECTOR      = SCR1_ARCH_RST_VECTOR;

// Reset values TBD
parameter bit SCR1_CSR_MIE_MSIE_RST_VAL             = 1'b0;
parameter bit SCR1_CSR_MIE_MTIE_RST_VAL             = 1'b0;
parameter bit SCR1_CSR_MIE_MEIE_RST_VAL             = 1'b0;

parameter bit SCR1_CSR_MIP_MSIP_RST_VAL             = 1'b0;
parameter bit SCR1_CSR_MIP_MTIP_RST_VAL             = 1'b0;
parameter bit SCR1_CSR_MIP_MEIP_RST_VAL             = 1'b0;

parameter bit SCR1_CSR_MSTATUS_MIE_RST_VAL          = 1'b0;
parameter bit SCR1_CSR_MSTATUS_MPIE_RST_VAL         = 1'b1;

// MISA
`define SCR1_RVC_ENC                                `SCR1_XLEN'h0004
`define SCR1_RVE_ENC                                `SCR1_XLEN'h0010
`define SCR1_RVI_ENC                                `SCR1_XLEN'h0100
`define SCR1_RVM_ENC                                `SCR1_XLEN'h1000
`define SCR1_RVV_ENC                                `SCR1_XLEN'h200000
parameter bit [1:0]             SCR1_MISA_MXL_32    = 2'd1;
parameter bit [`SCR1_XLEN-1:0]  SCR1_CSR_MISA       = (SCR1_MISA_MXL_32 << (`SCR1_XLEN-2))
`ifdef SCR1_RVI_EXT
                                                    | `SCR1_RVI_ENC
`elsif SCR1_RVE_EXT
                                                    | `SCR1_RVE_ENC
`endif
`ifdef SCR1_RVC_EXT
                                                    | `SCR1_RVC_ENC
`endif
`ifdef SCR1_RVM_EXT
                                                    | `SCR1_RVV_ENC
`endif
//------------------------------------------------------------------
//  vector extension
`ifdef SCR1_RVV_EXT
                                                    | `SCR1_RVM_ENC
`endif
//------------------------------------------------------------------
                                                    ;

// MVENDORID
parameter bit [`SCR1_XLEN-1:0] SCR1_CSR_MVENDORID   = '0;

// MARCHID
parameter bit [`SCR1_XLEN-1:0] SCR1_CSR_MARCHID     = '0;

// MIMPID
parameter bit [`SCR1_XLEN-1:0] SCR1_CSR_MIMPID      = `SCR1_MIMPID;

// MSTATUS
parameter bit [1:0] SCR1_CSR_MSTATUS_MPP            = 2'b11;
parameter int unsigned SCR1_CSR_MSTATUS_MIE_OFFSET  = 3;
parameter int unsigned SCR1_CSR_MSTATUS_MPIE_OFFSET = 7;
parameter int unsigned SCR1_CSR_MSTATUS_MPP_OFFSET  = 11;

// MTVEC
// bits [5:0] are always zero
parameter bit [`SCR1_XLEN-1:SCR1_CSR_MTVEC_BASE_ZERO_BITS] SCR1_CSR_MTVEC_BASE_RST_VAL  = SCR1_ARCH_CSR_MTVEC_BASE_RST_VAL;

parameter bit SCR1_CSR_MTVEC_MODE_DIRECT            = 1'b0;
`ifdef SCR1_VECT_IRQ_EN
parameter bit SCR1_CSR_MTVEC_MODE_VECTORED          = 1'b1;
`endif // SCR1_VECT_IRQ_EN

// MIE, MIP
parameter int unsigned SCR1_CSR_MIE_MSIE_OFFSET     = 3;
parameter int unsigned SCR1_CSR_MIE_MTIE_OFFSET     = 7;
parameter int unsigned SCR1_CSR_MIE_MEIE_OFFSET     = 11;

`ifdef SCR1_CSR_MCOUNTEN_EN
// MCOUNTEN
parameter int unsigned SCR1_CSR_MCOUNTEN_CY_OFFSET  = 0;
parameter int unsigned SCR1_CSR_MCOUNTEN_IR_OFFSET  = 2;
`endif // SCR1_CSR_MCOUNTEN_EN

// MCAUSE
typedef logic [`SCR1_XLEN-2:0]      type_scr1_csr_mcause_ec_v;

// MCYCLE, MINSTRET
`ifdef SCR1_CSR_REDUCED_CNT
parameter int unsigned SCR1_CSR_COUNTERS_WIDTH      = 32;
`else // ~SCR1_CSR_REDUCED_CNT
parameter int unsigned SCR1_CSR_COUNTERS_WIDTH      = 64;
`endif // ~SCR1_CSR_REDUCED_CNT

// HPM
parameter bit [6:0] SCR1_CSR_ADDR_HPMCOUNTER_MASK   = 7'b1100000;
parameter bit [6:0] SCR1_CSR_ADDR_HPMCOUNTERH_MASK  = 7'b1100100;
parameter bit [6:0] SCR1_CSR_ADDR_MHPMCOUNTER_MASK  = 7'b1011000;
parameter bit [6:0] SCR1_CSR_ADDR_MHPMCOUNTERH_MASK = 7'b1011100;
parameter bit [6:0] SCR1_CSR_ADDR_MHPMEVENT_MASK    = 7'b0011001;

//-------------------------------------------------------------------------------
// Types declaration
//-------------------------------------------------------------------------------
typedef enum logic {
    SCR1_CSR_RESP_OK,
    SCR1_CSR_RESP_ER,
    SCR1_CSR_RESP_ERROR = 'x
} type_scr1_csr_resp_e;

`endif // SCR1_CSR_SVH
