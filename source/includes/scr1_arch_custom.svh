`ifndef SCR1_ARCH_CUSTOM_SVH
`define SCR1_ARCH_CUSTOM_SVH

`define SCR1_TARGET_FPGA_INTEL      TERASIC_DE10
`define SCR1_bitop
//------------------------------------------------
// vector extension (BASE)
//------------------------------------------------
//`define SCR1_RVV_EXT
//`define SCR1_RVY_EXT

`ifdef  SCR1_RVV_EXT
`define SCR1_ELEN           32
`define SCR1_VLEN           8
`define LANE                8
//`define LANE_NUM_WIDTH      2
// -----------------vtype----------------------
`define SCR1_VSHAPE_SCALAR  5'b00000
`define SCR1_VSHAPE_VECTOR  5'b00100
`define SCR1_VREP_UINT      5'b00000
`define SCR1_VREP_SINT      5'b00001

`define SCR1_VEW_DISABLED   6'b000000
// `define SCR1_VEW_8BIT       6'b001000
// `define SCR1_VEW_16BIT      6'b010000
`define SCR1_VEW_32BIT      6'b011000
//`define VEW_64BIT     6'b100000     //(RV64,RV128,RV32D)
//`define VEW_128BIT    6'b101000     //(RV128,RV64Q)
`define SCR1_VTYPE_INIT_VAL {`SCR1_VSHAPE_VECTOR, `SCR1_VREP_UINT, `SCR1_VEW_32BIT}
`endif
//------------------------------------------------

//`define SCR1_RVE_EXT                // enables RV32E base integer instruction set
`define SCR1_RVM_EXT                // enables standard extension for integer mul/div
`define SCR1_RVC_EXT                // enables standard extension for compressed instructions

//`define SCR1_IFU_QUEUE_BYPASS       // enables bypass between IFU and IDU stages
//`define SCR1_EXU_STAGE_BYPASS       // enables bypass between IDU and EXU stages

//`define SCR1_FAST_MUL               // enables one-cycle multiplication

//`define SCR1_CLKCTRL_EN             // enables global clock gating

`define SCR1_DBGC_EN                // enables debug controller
`define SCR1_BRKM_EN                // enables breakpoint module
`define SCR1_IPIC_EN                // enables interrupt controller
`define SCR1_IPIC_SYNC_EN           // enables IPIC synchronizer
//`define SCR1_TCM_EN                 // enables tightly-coupled memory

//`define SCR1_VECT_IRQ_EN            // enables vectored interrupts
`define SCR1_CSR_MCOUNTEN_EN        // enables custom MCOUNTEN CSR
parameter int unsigned SCR1_CSR_MTVEC_BASE_RW_BITS = 26;    // number of writable high-order bits in MTVEC BASE field
                                                            // legal values are 0 to 26
                                                            // read-only bits are hardwired to reset value

`define SCR1_IMEM_AHB_IN_BP         // bypass instruction memory AHB bridge input register
`define SCR1_IMEM_AHB_OUT_BP        // bypass instruction memory AHB bridge output register
`define SCR1_DMEM_AHB_IN_BP         // bypass data memory AHB bridge input register
`define SCR1_DMEM_AHB_OUT_BP        // bypass data memory AHB bridge output register

`define SCR1_IMEM_AXI_REQ_BP        // bypass instruction memory AXI bridge request register
`define SCR1_IMEM_AXI_RESP_BP       // bypass instruction memory AXI bridge response register
`define SCR1_DMEM_AXI_REQ_BP        // bypass data memory AXI bridge request register
`define SCR1_DMEM_AXI_RESP_BP       // bypass data memory AXI bridge response register

`ifdef SCR1_TCM_EN
parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TCM_ADDR_MASK          = 'hFFFF0000;
//parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TCM_ADDR_PATTERN       = 'h00480000;
parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TCM_ADDR_PATTERN       = 'hF0000000;
`endif // SCR1_TCM_EN

parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TIMER_ADDR_MASK        = 'hFFFFFFE0;
//parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TIMER_ADDR_PATTERN     = 'h00490000;
parameter bit [`SCR1_DMEM_AWIDTH-1:0]   SCR1_TIMER_ADDR_PATTERN     = 'hF0040000;

// CSR parameters:
parameter bit [`SCR1_XLEN-1:0]                              SCR1_ARCH_RST_VECTOR                = 32'hFFFFFF00;   //FPGA bootloader
parameter bit [`SCR1_XLEN-1:SCR1_CSR_MTVEC_BASE_ZERO_BITS]  SCR1_ARCH_CSR_MTVEC_BASE_RST_VAL    = SCR1_CSR_MTVEC_BASE_VAL_BITS'(`SCR1_XLEN'hFFFFFF80 >> SCR1_CSR_MTVEC_BASE_ZERO_BITS);

`endif
