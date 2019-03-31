/** @file

	Syntacore RISC-V targets common methods

	@copyright Syntacore 2016, 2017
	@author sps (https://github.com/aka-sps)

	@defgroup SC_RV32 Syntacore RISC-V target
*/
#ifndef TARGET_SC_RV32_COMMON_H_
#define TARGET_SC_RV32_COMMON_H_

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "target/target.h"
#include "target/register.h"
#include "target/breakpoints.h"
#include "jimtcl/jim.h"

#include <stdbool.h>

/// Bit operation macros
/// @{

/// Simple mask with only single bit 'bit_num' is set
#define BIT_MASK(bit_num) (1u << (bit_num))

/// Bit mask value with low 'n' bits set
#define LOW_BITS_MASK(n) (~(~0u << (n)))

/// @}

typedef struct target target;
typedef struct reg reg;
typedef struct breakpoint breakpoint;
typedef struct watchpoint watchpoint;
typedef struct command_context command_context;
typedef struct target_type target_type;
typedef uint8_t reg_num_type;
typedef uint16_t csr_num_type;
typedef enum target_register_class target_register_class;
typedef int error_code;
typedef uint32_t rv_instruction32_type;
typedef uint32_t rv32_address_type;

enum {
	/// Marker of invalid value of Debug Access Port multiplexer control
	DAP_CTRL_value_INVALID_CODE = 0xFFu,
};

struct sc_riscv32__Arch_constants
{
	/// Debug controller related parameters
	bool use_ir_select_cache;             ///< Don't make irscan if IR is the same
	bool use_queuing_for_dr_scans;        ///< DR scan queuing instead separate
	bool use_separate_items;
	bool use_dap_control_cache;           ///< Don't write to DAP_CONTROL if it has same value
	bool use_verify_dap_control;          ///< Verify value of DAP_CONTROL after write
	bool use_verify_hart_regtrans_write;  ///< Verify values of HART REGTRANS after write
	bool use_verify_core_regtrans_write;  ///< Verify values of CORE REGTRANS after write
	
	uint32_t expected_dbg_id;             ///< Lowest required DBG_ID.
	
	csr_num_type debug_scratch_CSR;       ///< Syntacore Debug controller CSR (design-dependent)

	unsigned mstatus_FS_offset;           ///< FS bits offsets in `mstatus` CSR (Privileged ISA version-specific)

	/// Privileged ISA version-specific virtual to physical address translation virtual method
	error_code
	(*virt_to_phis)(target* p_target, rv32_address_type address, target_addr_t* p_physical, uint32_t* p_bound, bool const instruction_space);

	/// Syntacore architecture extensions
	/// @{

	/// Generate custom instruction opcode to combine values from two integer 32-bit registers into single 64-bit FPU register
	rv_instruction32_type
	(*opcode_FMV_D_2X)(reg_num_type rd_fp, reg_num_type rs_hi, reg_num_type rs_lo);

	/// Generate custom instruction opcode to split single 64-bit FPU register value to two different integer 32-bit registers
	rv_instruction32_type
	(*opcode_FMV_2X_D)(reg_num_type rd_hi, reg_num_type rd_lo, reg_num_type rs1_fp);

	/// @}
};
typedef struct sc_riscv32__Arch_constants sc_riscv32__Arch_constants;

struct sc_riscv32__Arch {
	error_code error_code;                       ///< stored sub-operations error_code
	uint8_t last_DAP_ctrl;                       ///< DAP_CTRL cache
	sc_riscv32__Arch_constants const* constants;
	uint32_t misa;
};
typedef struct sc_riscv32__Arch sc_riscv32__Arch;

error_code
sc_riscv32__poll(target* const p_target);

error_code
sc_riscv32__arch_state(target* const p_target);

error_code
sc_riscv32__halt(target* const p_target);

error_code
sc_riscv32__resume(target* const p_target, int const current, target_addr_t const address, int const handle_breakpoints, int const debug_execution);

error_code
sc_riscv32__step(target* const p_target, int const current, target_addr_t const address, int const handle_breakpoints);

error_code
sc_riscv32__assert_reset(target* const p_target);

error_code
sc_riscv32__deassert_reset(target* const p_target);

error_code
sc_riscv32__soft_reset_halt(target* const p_target);

error_code
sc_riscv32__get_gdb_reg_list(target* const p_target, reg** reg_list[], int* const reg_list_size, target_register_class const reg_class);

error_code
sc_riscv32__read_memory(target* const p_target, target_addr_t address, uint32_t const size, uint32_t count, uint8_t* buffer);

error_code
sc_riscv32__write_memory(target* const p_target, target_addr_t address, uint32_t const size, uint32_t count, uint8_t const* buffer);

error_code
sc_riscv32__add_breakpoint(target* const p_target, breakpoint* const p_breakpoint);

error_code
sc_riscv32__add_breakpoint_v2(target* const p_target, breakpoint* const p_breakpoint);

error_code
sc_riscv32__remove_breakpoint(target* const p_target, breakpoint* const p_breakpoint);

error_code
sc_riscv32__add_watchpoint(target* const p_target, watchpoint *const p_watchpoint);

error_code
sc_riscv32__remove_watchpoint(target* const p_target, watchpoint *const p_watchpoint);

error_code
sc_riscv32__hit_watchpoint(target *const p_target, watchpoint **const pp_hit_watchpoint);

error_code
sc_riscv32__target_create(target* const p_target, Jim_Interp* interp);

error_code
sc_riscv32__examine(target* const p_target);

void
sc_riscv32__deinit_target(target* const p_target);

error_code
sc_riscv32__read_phys_memory(target* const p_target, target_addr_t address, uint32_t const size, uint32_t count, uint8_t* buffer);

error_code
sc_riscv32__write_phys_memory(target* const p_target, target_addr_t address, uint32_t const size, uint32_t count, uint8_t const* buffer);

void
sc_riscv32__init_regs_cache(target* const p_target);

error_code
sc_riscv32__virt2phys(target* p_target, target_addr_t address, target_addr_t* p_physical);

/// Old Syntacore opcode extensions
/// @{
rv_instruction32_type
sc_RISCV_opcode_S_FMV_2X_D(reg_num_type rd_hi, reg_num_type rd_lo, reg_num_type rs1_fp);

rv_instruction32_type
sc_RISCV_opcode_S_FMV_D_2X(reg_num_type rd_fp, reg_num_type rs_hi, reg_num_type rs_lo);
/// @}

/// New Syntacore opcode extensions
/// @{
rv_instruction32_type
sc_RISCV_opcode_D_FMV_2X_D(reg_num_type rd_hi, reg_num_type rd_lo, reg_num_type rs1_fp);

rv_instruction32_type
sc_RISCV_opcode_D_FMV_D_2X(reg_num_type rd_fp, reg_num_type rs_hi, reg_num_type rs_lo);
/// @}

error_code
sc_rv32__mmu_1_7(target* p_target, int* p_mmu_enabled);

error_code
sc_rv32__mmu_1_9(target* p_target, int* p_mmu_enabled);

error_code
sc_rv32__virt_to_phis_direct_map(target* p_target, rv32_address_type address, target_addr_t* p_physical, uint32_t* p_bound, bool const instruction_space);

error_code
sc_rv32__virt_to_phis_1_7(target* p_target, rv32_address_type address, target_addr_t* p_physical, uint32_t* p_bound, bool const instruction_space);

error_code
sc_rv32__virt_to_phis_1_9(target* p_target, rv32_address_type address, target_addr_t* p_physical, uint32_t* p_bound, bool const instruction_space);

#endif  // TARGET_SC_RV32_COMMON_H_
