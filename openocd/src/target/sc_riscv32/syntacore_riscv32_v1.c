/** @file

	syntacore_riscv32_v1 target.

	syntacore_riscv32_v1 is RISC-V compatible MCU core, designed by Syntacore.

	@copyright Syntacore 2016, 2017
	@author sps (https://github.com/aka-sps)
*/
#include "sc_rv32_common.h"

#include "target/target_type.h"
#include "helper/log.h"

static sc_riscv32__Arch_constants const scr_constants = {
	.use_ir_select_cache = true,
	.use_dap_control_cache = true,
	.use_verify_dap_control = false,
	.use_verify_hart_regtrans_write = false,
	.use_verify_core_regtrans_write = false,
	.use_queuing_for_dr_scans = true,
	.use_separate_items = false,
	.expected_dbg_id = 0x00810100u,
	.debug_scratch_CSR = 0x7C8u,
	.mstatus_FS_offset = 13u,
	.opcode_FMV_D_2X = &sc_RISCV_opcode_D_FMV_D_2X,
	.opcode_FMV_2X_D = &sc_RISCV_opcode_D_FMV_2X_D,
	.virt_to_phis = &sc_rv32__virt_to_phis_1_9
};

static sc_riscv32__Arch const scr_initial_arch = {
	.error_code = ERROR_OK,
	.last_DAP_ctrl = DAP_CTRL_value_INVALID_CODE,
	.constants = &scr_constants
};

static error_code
scr__init_target(command_context* cmd_ctx, target* const p_target)
{
	sc_riscv32__init_regs_cache(p_target);

	sc_riscv32__Arch* p_arch_info = calloc(1, sizeof(sc_riscv32__Arch));
	assert(p_arch_info);
	*p_arch_info = scr_initial_arch;

	p_target->arch_info = p_arch_info;
	return ERROR_OK;
}

/// @todo make const
target_type syntacore_riscv32_v1_target = {
	.name = "syntacore_riscv32_v1",

	.poll = sc_riscv32__poll,
	.arch_state = sc_riscv32__arch_state,
	.target_request_data = NULL,

	.halt = sc_riscv32__halt,
	.resume = sc_riscv32__resume,
	.step = sc_riscv32__step,

	.assert_reset = sc_riscv32__assert_reset,
	.deassert_reset = sc_riscv32__deassert_reset,
	.soft_reset_halt = sc_riscv32__soft_reset_halt,

	.get_gdb_reg_list = sc_riscv32__get_gdb_reg_list,

	.read_memory = sc_riscv32__read_memory,
	.write_memory = sc_riscv32__write_memory,

	.read_buffer = NULL,
	.write_buffer = NULL,

	.checksum_memory = NULL,
	.blank_check_memory = NULL,

	.add_breakpoint = sc_riscv32__add_breakpoint,
	.add_context_breakpoint = NULL,
	.add_hybrid_breakpoint = NULL,

	.remove_breakpoint = sc_riscv32__remove_breakpoint,

	.add_watchpoint = NULL,
	.remove_watchpoint = NULL,

	.hit_watchpoint = NULL,

	.run_algorithm = NULL,
	.start_algorithm = NULL,
	.wait_algorithm = NULL,

	.commands = NULL,

	.target_create = sc_riscv32__target_create,
	.target_jim_configure = NULL,
	.target_jim_commands = NULL,

	.examine = sc_riscv32__examine,

	.init_target = scr__init_target,
	.deinit_target = sc_riscv32__deinit_target,

	.virt2phys = sc_riscv32__virt2phys,
	.read_phys_memory = sc_riscv32__read_phys_memory,
	.write_phys_memory = sc_riscv32__write_phys_memory,

	.mmu = sc_rv32__mmu_1_9,
	.check_reset = NULL,
	.get_gdb_fileio_info = NULL,
	.gdb_fileio_end = NULL,
	.profiling = NULL,
};
