/** @file

	Syntacore RISC-V targets common methods

	@copyright Syntacore 2016, 2017
	@author sps (https://github.com/aka-sps)
*/
#include "sc_rv32_common.h"

#include "jtag/jtag.h"
#include "helper/log.h"

#include <assert.h>
#include <limits.h>
#include <memory.h>

/// Queuing operations before force jtag operations
#define WRITE_BUFFER_THRESHOLD (1u << 18)

//#define ECLIPSE_WORKAROUND(code) (code)
#define ECLIPSE_WORKAROUND(code) (ERROR_OK)

/// protection against desynchronizing due to external reset or config
//@{
//#define TAP_DESYNC_PROTECTION
//@}

/// Parameters of RISC-V core
/// @{
/// Size of RISC-V GP registers in bits
#define XLEN (32u)
/// Size of RISC-V FP registers in bits
#define FLEN (64u)
/// Size of RISC-V instruction
#define ILEN (32u)
/// @}

typedef uint32_t rv_x_type;

static_assert(XLEN == CHAR_BIT * sizeof(rv_x_type), "rv_x_type bits number is not XLEN");
static_assert(XLEN == CHAR_BIT * sizeof(rv32_address_type), "rv32_address_type bits number is not XLEN");

/// Number of array 'arr' elements
#define ARRAY_LEN(arr) (sizeof (arr) / sizeof (arr)[0])

/// @return bit-field value
#define EXTRACT_FIELD(bits, first_bit, last_bit) (((bits) >> (first_bit)) & LOW_BITS_MASK((last_bit) + 1u - (first_bit)))

/// @return true if values bits except lower 'LEN' are zero
#define IS_VALID_UNSIGNED_FIELD(FLD,LEN) ((FLD & ~LOW_BITS_MASK(LEN)) == 0)
#define NORMALIZE_INT_FIELD(FLD, SIGN_BIT, ZEROS) ( ~LOW_BITS_MASK(ZEROS) & ( (FLD) | ( -EXTRACT_FIELD((FLD),(SIGN_BIT),(SIGN_BIT)) << (SIGN_BIT) )))
#define IS_VALID_SIGNED_IMMEDIATE_FIELD(FLD, SIGN_BIT, LOW_ZEROS) ( (0u + (FLD)) == NORMALIZE_INT_FIELD((FLD), (SIGN_BIT), (LOW_ZEROS)) )

/// Specialized assert check that register number is 5 bits only
/// @todo static_assert
#define CHECK_REG(REG) assert(IS_VALID_UNSIGNED_FIELD(REG,5))
/// @todo static_assert
#define CHECK_OPCODE(OPCODE) (assert(IS_VALID_UNSIGNED_FIELD(OPCODE,7) && (OPCODE & LOW_BITS_MASK(2)) == LOW_BITS_MASK(2) && (OPCODE & LOW_BITS_MASK(5)) != LOW_BITS_MASK(5)))

/// Specialized asserts to check format of RISC-V immediate
/// @{
#define CHECK_IMM_11_00(imm) assert(IS_VALID_SIGNED_IMMEDIATE_FIELD(imm, 11, 0))
#define CHECK_IMM_12_01(imm) assert(IS_VALID_SIGNED_IMMEDIATE_FIELD(imm, 12, 1))
#define CHECK_IMM_20_01(imm) assert(IS_VALID_SIGNED_IMMEDIATE_FIELD(imm, 20, 1))
#define CHECK_IMM_31_12(imm) assert(IS_VALID_SIGNED_IMMEDIATE_FIELD(imm, 31, 12))
/// @}

/// @todo static_assert
#define CHECK_FUNC7(F) assert(IS_VALID_UNSIGNED_FIELD(F,7))
/// @todo static_assert
#define CHECK_FUNC3(F) assert(IS_VALID_UNSIGNED_FIELD(F,3))

/** Number of octets required for 'num_bits' bits
@param [in] num_bits number of bits
@return number of bytes for 'num_bits' \f$\lceil {\frac{num\_bits}{CHAR\_BIT}} \rceil\f$.
*/
#define NUM_BYTES_FOR_BITS(num_bits) ( ( (size_t)(num_bits) + (CHAR_BIT - 1) ) / CHAR_BIT )

/// @return expression of TYPE with 'first_bit':'last_bit' bits set
#define MAKE_TYPE_FIELD(TYPE, bits, first_bit, last_bit)     ((((TYPE)(bits)) & LOW_BITS_MASK((last_bit) + 1u - (first_bit))) << (first_bit))

#define INT12_MAX ((riscv_short_signed_type)NORMALIZE_INT_FIELD(LOW_BITS_MASK(11), 11, 0))
#define INT12_MIN ((riscv_short_signed_type)NORMALIZE_INT_FIELD(~INT12_MAX, 11, 0))

static_assert(CHAR_BIT == 8, "Unsupported char size");

typedef uint16_t rv_instruction16_type;
typedef enum target_debug_reason target_debug_reason;
typedef enum target_state target_state;
typedef int16_t riscv_short_signed_type;
typedef int32_t riscv_signed_type;
typedef struct reg_feature reg_feature;
typedef struct reg_data_type reg_data_type;
typedef struct scan_field scan_field;
typedef struct Jim_Interp Jim_Interp;
typedef struct reg_data_type_union reg_data_type_union;
typedef struct reg_data_type_union_field reg_data_type_union_field;
typedef struct reg_arch_type reg_arch_type;
typedef struct reg_cache reg_cache;

/** @defgroup SC_RV32_TAPC_IR Syntacore TAP Controller Instructions
@ingroup SC_RV32
*/
/// @{

/** @brief TAP Controller Instructions ID

ir_scan selects one of instruction registers IO to TDI/TDO.
*/
enum TAP_IR_e
{
	/** @brief DBG_ID Register Read

	It connects DBG_ID_DR register between TDI and TDO pins.
	Contains debug facilities version implemented in the given processor DBGC subsystem.
	*/
	TAP_instruction_DBG_ID = 0b0011u,

	/** @brief BLD_ID Register Read

	Connects BLD_ID_DR between TDI and TDO pins.
	It identifies an entire processor system RTL build revision.
	*/
	TAP_instruction_BLD_ID = 0b0100u,

	/** @brief DBG_STATUS Register Read
	Connects DBG_STATUS_DR register providing general status information about debug operations and core state.
	*/
	TAP_instruction_DBG_STATUS = 0b0101u,

	/** @brief DAP_CTRL Register Write

	Connects DAP_CTRL_DR register is the control port of the upper level multiplexer
	for DAP_CMD register.
	*/
	TAP_instruction_DAP_CTRL = 0b0110u,

	/** @brief DAP_CTRL Register Read

	Connects DAP_CTRL_RD_DR register allowing to read
	current DAP Control Context (DAPCC) from the DAP_CONTEXT register.
	*/
	TAP_instruction_DAP_CTRL_RD = 0b0111u,

	/** @brief Debug Access Port Command (DAP Command)

	Provide multiplexed IO to inner DC registers.

	Multiplexing is controlled by DAP_CTRL
	Connects DAP_CMD_DR register.
	*/
	TAP_instruction_DAP_CMD = 0b1000u,

	/** @brief SYS_CTRL Register Access

	Connects SYS_CTRL_DR register,
	used to control state of the Processor Subsystem Reset net,
	and to get its current status.

	@see TAP_length_of_SYS_CTRL
	*/
	TAP_instruction_SYS_CTRL = 0b1001u,

	/** @brief MTAP_SWITCH Register Access

	Connects MTAP_SWITCH_DR register, used to control state
	of the Master TAP Switch Control output, and to
	get its current status.
	*/
	TAP_instruction_MTAP_SWITCH = 0b1101u,

	/** @brief IDCODE Register Read
	Conventional recommended Device Identification instruction compliant with IEEE 1149.1 Standard.
	It connects IDCODE_DR register between TDI and TDO pins.()
	*/
	TAP_instruction_IDCODE = 0b1110u,

	/** @brief BYPASS instruction
	IEEE 1149.1 Standard compliant mandatory instruction.
	It connects BYPASS_DR single bit shiht register between TDI and TDO pins.
	*/
	TAP_instruction_BYPASS = 0b1111,
};
typedef enum TAP_IR_e TAP_IR_e;

/// TAP registers size constants
enum
{
	/**  @brief IR registers code size - 4 bits
	*/
	TAP_length_of_IR = 4u,
	/// @brief size of most IR registers
	TAP_length_of_RO_32 = 32u,
	/// @brief IDCODE, if supported, 32 bits mandatory
	TAP_length_of_IDCODE = TAP_length_of_RO_32,
	TAP_length_of_DBG_ID = TAP_length_of_RO_32,
	TAP_length_of_BLD_ID = TAP_length_of_RO_32,
	TAP_length_of_DBG_STATUS = TAP_length_of_RO_32,

	/// @brief DAP_CTRL Units selector field size
	TAP_length_of_DAP_CTRL_unit_field = 2u,
	/// @brief Functional group selector field size
	TAP_length_of_DAP_CTRL_fgroup_field = 2u,
	TAP_number_of_fields_DAP_CMD = 2u,
	/// @brief Total size of DAP_CTRL instruction
	TAP_length_of_DAP_CTRL = TAP_length_of_DAP_CTRL_unit_field + TAP_length_of_DAP_CTRL_fgroup_field,

	TAP_length_of_DAP_CMD_OPCODE = 4u,
	TAP_length_of_DAP_CMD_OPCODE_EXT = 32u,
	TAP_length_of_DAP_CMD = TAP_length_of_DAP_CMD_OPCODE + TAP_length_of_DAP_CMD_OPCODE_EXT,


	TAP_length_of_SYS_CTRL = 1,

	/// mandatory 1 bit shift register
	TAP_length_of_BYPASS = 1,
};
/// @}

/** @brief DBG_STATUS bits

	Upper-level status register bits

	@see TAP_instruction_DBG_STATUS
*/
enum
{
	DBG_STATUS_bit_HART0_DMODE = BIT_MASK(0),
	DBG_STATUS_bit_HART0_Rst = BIT_MASK(1),
	DBG_STATUS_bit_HART0_Rst_Stky = BIT_MASK(2),
	DBG_STATUS_bit_HART0_Err = BIT_MASK(3),
	DBG_STATUS_bit_HART0_Err_Stky = BIT_MASK(4),
	DBG_STATUS_bit_Err = BIT_MASK(16),
	DBG_STATUS_bit_Err_Stky = BIT_MASK(17),
	DBG_STATUS_bit_Err_HwCore = BIT_MASK(18),
	DBG_STATUS_bit_Err_FsmBusy = BIT_MASK(19),
	DBG_STATUS_bit_Err_DAP_Opcode = BIT_MASK(20),
	DBG_STATUS_bit_Rst = BIT_MASK(28),
	DBG_STATUS_bit_Rst_Stky = BIT_MASK(29),
	DBG_STATUS_bit_Lock = BIT_MASK(30),
	DBG_STATUS_bit_Ready = BIT_MASK(31),
};

/** @brief Status bits of previous operation
*/
enum
{
	/// @brief Exception detected
	DAP_opstatus_bit_EXCEPT = BIT_MASK(0),
	DAP_opstatus_bit_ERROR = BIT_MASK(1),
	/// @brief Debug controller locked after previous operation
	DAP_opstatus_bit_LOCK = BIT_MASK(2),
	/// @brief Ready for next operation
	DAP_opstatus_bit_READY = BIT_MASK(3),

	DAP_status_mask = DAP_opstatus_bit_ERROR | DAP_opstatus_bit_LOCK | DAP_opstatus_bit_READY,
	DAP_status_good = DAP_opstatus_bit_READY,
};

/** @brief DAP_CTRL fields enumerations

	DAP_CTRL transaction select unit and functional group and return previous operation status
*/
/// @{
/// Units IDs
enum type_dbgc_unit_id_e
{
	DBGC_unit_id_HART_0 = 0,
	DBGC_unit_id_HART_1 = 1,  ///< now unused
	DBGC_unit_id_CORE = 3,
};
typedef enum type_dbgc_unit_id_e type_dbgc_unit_id_e;

/** Functional groups for HART units
	@see DBGC_unit_id_HART_0
	@see DBGC_unit_id_HART_1
	*/
enum
{
	/// @see HART_REGTRANS_indexes
	DBGC_functional_group_HART_REGTRANS = 0b00,
	DBGC_functional_group_HART_DBGCMD = 0b01,
	DBGC_functional_group_HART_CSR_CAP = 0b10,
};

/** Functional groups for CORE units
	@see DBGC_unit_id_CORE
*/
enum
{
	/// @see CORE_REGTRANS_indexes
	DBGC_functional_group_CORE_REGTRANS = 0,
};

/// @}

/** @brief HART[0] Debug Registers indexes
	@pre HART unit, REGTRANS functional group registers
	@see DBGC_functional_group_HART_REGTRANS
*/
enum HART_REGTRANS_indexes
{
	/// @brief Hart Debug Control Register HART_DBG_CTRL (HDCR)
	HART_DBG_CTRL_index = 0,

	/// @brief Hart Debug Status Register HART_DBG_STS (HDSR)
	HART_DBG_STS_index = 1,

	/// @brief Hart Debug Mode Enable Register HART_DMODE_ENBL (HDMER)
	HART_DMODE_ENBL_index = 2,

	/// @brief Hart Debug Mode Cause Register HART_DMODE_CAUSE (HDMCR)
	HART_DMODE_CAUSE_index = 3,

	/// @brief Hart Debug Core Instruction Register HART_CORE_INSTR (HDCIR)
	HART_CORE_INSTR_index = 4,

	/** @brief Hart Debug Data HART_DBG_DATA (HDDR) register.

		Corresponds to the DBG_SCRATCH core's CSR.

		@see Debug scratch CSR
	*/
	HART_DBG_DATA_index = 5,

	/** @brief Hart Program Counter (PC) HART_PC_SAMPLE (HPCSR) register.

		Reflects current hart PC value.
	*/
	HART_PC_SAMPLE_index = 6,
};
typedef enum HART_REGTRANS_indexes HART_REGTRANS_indexes;

/// @see DBGC_functional_group_HART_DBGCMD
enum HART_DBGCMD_indexes
{
	/** @brief DBG_CTRL (Debug Control Operation)

	Command for Debug Subsystem state change
	(includes an important option for transition between Run-Mode and Debug-Mode)
	*/
	DBG_CTRL_index = 0x0,

	/** @brief CORE_EXEC (Debug Core Instruction Execution)

	Command carries out execution of a RISC-V instruction
	resided in the DBGC's HART_CORE_INSTR register,
	on a corresponding core's HART.

	@see HART_CORE_INSTR_index
	*/
	CORE_EXEC_index = 0x1,

	/** @brief DBGDATA_WR (Debug Data Register Write)

		Command writes 32-bit data into the HART_DBG_DATA register.

		@see HART_DBG_DATA_index
	*/
	DBGDATA_WR_index = 0x2,

	/** @brief UNLOCK

		Command unlocks DAP which has been previously locked due to error(s) during preceding operations.

		@see HART_DBG_STS_bit_Lock_Stky
		@see DBG_STATUS_bit_Lock
		@see DAP_opstatus_bit_LOCK
	*/
	UNLOCK_index = 0x3,
};
typedef enum HART_DBGCMD_indexes HART_DBGCMD_indexes;

enum HART_CSR_CAP_indexes
{
#if 0
	/// @brief Hart MVENDORID (HMVENDORID) Register
	HART_MVENDORID_index = 0b000,

	/// @brief Hart MARCHID (HMARCHID) Register
	HART_MARCHID_index = 0b001,

	/// @brief Hart MIMPID (HMIMPID) Register
	HART_MIMPID_index = 0b010,

	/// @brief Hart MHARTID (HMHARTID) Register
	HART_MHARTID_index = 0b011,
#endif

	/// @brief Hart MISA Register
	HART_MISA_index = 0b100,
	HART_MCPUID_index = 0b000,
};
typedef enum HART_CSR_CAP_indexes HART_CSR_CAP_indexes;

/// @see DBGC_functional_group_CORE_REGTRANS
enum CORE_REGTRANS_indexes
{
	/** @brief Core Debug ID (CDID) Register
	*/
	CORE_DEBUG_ID_index = 0,

	/** @brief Core Debug Control (CDCR) Register
	*/
	CORE_DBG_CTRL_index = 1,

	/** @brief Core Debug Status (CDSR) Register
	*/
	CORE_DBG_STS_index = 2,
};
typedef enum CORE_REGTRANS_indexes CORE_REGTRANS_indexes;

/** @brief HART_DBG_CTRL bits
	@see HART_DBG_CTRL_index
*/
enum HART_DBG_CTRL_bits
{
	/// HART reset
	/// @warning not used now
	HART_DBG_CTRL_bit_Rst = BIT_MASK(0),

	/// Hart PC Advancement Disable
	HART_DBG_CTRL_bit_PC_Advmt_Dsbl = BIT_MASK(6),
};

/** @brief HART_DBG_STS bits
	@see HART_DBG_STS_index
*/
enum HART_DBG_STS_bits
{
	/// @brief Hart Debug Mode Status
	HART_DBG_STS_bit_DMODE = BIT_MASK(0),

	/// @brief Hart Reset Status
	HART_DBG_STS_bit_Rst = BIT_MASK(1),

	/// @brief Hart Reset Sticky Status
	HART_DBG_STS_bit_Rst_Stky = BIT_MASK(2),

	/// @brief Hart Exception Status
	HART_DBG_STS_bit_Except = BIT_MASK(3),

	/// @brief Hart Error Summary Status
	HART_DBG_STS_bit_Err = BIT_MASK(16),

	/// @brief Hart HW Error Status
	HART_DBG_STS_bit_Err_HwThread = BIT_MASK(17),

	/// @brief Hart DAP OpCode Error Status
	HART_DBG_STS_bit_Err_DAP_OpCode = BIT_MASK(18),

	/// @brief Hart Debug Command NACK Error Status
	HART_DBG_STS_bit_Err_DbgCmd_NACK = BIT_MASK(19),

	/// @brief Hart Illegal Debug Context Error Status
	HART_DBG_STS_bit_Err_Illeg_Contxt = BIT_MASK(20),

	/// @brief Hart Unexpected Reset Error Status
	HART_DBG_STS_bit_Err_Unexp_Rst = BIT_MASK(21),

	/// @brief Hart Debug Operation Time-out Error Status
	HART_DBG_STS_bit_Err_Timeout = BIT_MASK(22),

	/// @brief Hart DAP Lock Sticky Status
	HART_DBG_STS_bit_Lock_Stky = BIT_MASK(31)
};

/** @brief HART_DMODE_ENBL (HDMER) bits
	@see HART_DMODE_ENBL_index
*/
enum HART_DMODE_ENBL_bits
{
	/// @brief Hart Breakpoint Exception DMODE Redirection Enable
	HART_DMODE_ENBL_bit_Brkpt = BIT_MASK(3),

	/// @brief Hart Single Step DMODE Redirection Enable
	HART_DMODE_ENBL_bit_SStep = BIT_MASK(28),

	/// @brief Hart Reset Exit DMODE Redirection Enable
	HART_DMODE_ENBL_bit_Rst_Exit = BIT_MASK(30),

	HART_DMODE_ENBL_bits_Normal = HART_DMODE_ENBL_bit_Brkpt | HART_DMODE_ENBL_bit_Rst_Exit
};

/** HART_DMODE_CAUSE (HDMCR) bits
	@see HART_DMODE_CAUSE_index
*/
enum HART_DMODE_CAUSE_bits
{
	/// @brief Hart Breakpoint Exception
	HART_DMODE_CAUSE_bit_Brkpt = BIT_MASK(3),

	/// @brief Hart HW Breakpoint
	HART_DMODE_CAUSE_bit_Hw_Brkpt = BIT_MASK(27),

	/// @brief Hart Single Step
	HART_DMODE_CAUSE_bit_SStep = BIT_MASK(28),

	/// @brief Hart Reset Entrance Break
	HART_DMODE_CAUSE_bit_Rst_Entr = BIT_MASK(29),

	/// @brief Hart Reset Exit Break
	HART_DMODE_CAUSE_bit_Rst_Exit = BIT_MASK(30),

	/// @brief Hart Debug Mode Enforcement
	HART_DMODE_CAUSE_bit_Enforce = BIT_MASK(31)
};

/// @see DBG_CTRL_index
enum DBG_CTRL_bits
{
	/** @brief Halt

	Transits a corresponding hart from Run-Mode to Debug-Mode (halts the hart)

	Write only
	*/
	DBG_CTRL_bit_Halt = BIT_MASK(0),

	/** @brief Resume

	Transits a corresponding hart from DebugMode to Run-Mode (restarts the hart).
	*/
	DBG_CTRL_bit_Resume = BIT_MASK(1),

	/** @brief Sticky Clear.

	Clears sticky status bits for corresponding HART.
	*/
	DBG_CTRL_bit_Sticky_Clr = BIT_MASK(2),
};

/// Core Debug Control Register (CORE_DBG_CTRL, CDCR) bits
/// @see CORE_DBG_CTRL_index
enum CORE_DBG_CTRL_bits
{
	/** @brief Hart[0] Reset.

		Reserved for future use
	*/
	CORE_DBG_CTRL_bit_HART0_Rst = BIT_MASK(0),

	/** @brief Core Reset
	*/
	CORE_DBG_CTRL_bit_Rst = BIT_MASK(24),

	/** @brief Core IRQ Disable
	*/
	CORE_DBG_CTRL_bit_Irq_Dsbl = BIT_MASK(25),
};

/// RISC-V GP registers values
enum
{
	/// PC register number for gdb
	RISCV_regnum_PC = 32,

	/// First FPU register number for gdb
	RISCV_regnum_FP_first = 33,
	/// Last FPU register number for gdb
	RISCV_regnum_FP_last = 64,
	/// First CSR register number for gdb
	RISCV_regnum_CSR_first = 65,
	/// Last CSR register number for gdb
	RISCV_rtegnum_CSR_last = 4160,

	RISCV_regnum_V_first = 4161,
	RISCV_regnum_V_last = 4416,

	/// Number of X registers
	number_of_regs_X = RISCV_regnum_PC,
	/// Number of GP registers (X registers + PC)
	number_of_regs_GP = number_of_regs_X + 1u,

	/// Number of FPU registers
	number_of_regs_F = RISCV_regnum_FP_last - RISCV_regnum_FP_first + 1,

	/// Total number of registers for gdb
	number_of_regs_GDB = RISCV_regnum_V_last + 1,
};

static uint8_t const obj_DAP_opstatus_GOOD = DAP_status_good;
static uint8_t const obj_DAP_status_MASK = DAP_status_mask;
static reg_data_type GP_reg_data_type = {.type = REG_TYPE_INT32,};
static reg_feature feature_riscv_org = {
	.name = "org.gnu.gdb.riscv.cpu",
};
static char const def_GP_regs_name[] = "general";

static char const def_V_regs_name[] = "vector";
/** @brief Check IDCODE for selected target
*/
static bool
sc_rv32__is_IDCODE_valid(target* const p_target, uint32_t const IDCODE)
{
	assert(p_target);
	assert(p_target->tap);
	return p_target->tap->hasidcode && IDCODE == p_target->tap->idcode;
}

/** @brief Check Debug controller version for compatibility
*/
static bool
sc_rv32__is_DBG_ID_valid(target* const p_target, uint32_t const DBG_ID)
{
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	sc_riscv32__Arch_constants const* const p_const = p_arch->constants;
	assert(p_const);
	/// Mask of DBG_ID version.
	// Required value should be equal to provided version.
	static uint32_t const DBG_ID_major_version_mask = 0xFFFFFF00u;
	// Mask of DBG_ID subversion.
	// Required value should be greater or equal to provided subversion.
	static uint32_t const DBG_ID_subversion_mask = 0x000000FFu;
	return
		(DBG_ID & (DBG_ID_major_version_mask)) == (p_const->expected_dbg_id & (DBG_ID_major_version_mask)) &&
		(DBG_ID & (DBG_ID_subversion_mask)) >= (p_const->expected_dbg_id & (DBG_ID_subversion_mask));
}

/// Error code handling
///@{

/// @brief Get operation code stored in the target context.
static inline error_code
sc_error_code__get(target const* const p_target)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	return p_arch->error_code;
}

/** @brief Forced store operation code into target context.
*/
static inline error_code
sc_error_code__set(target const* const p_target, error_code const a_error_code)
{
	assert(p_target);
	{
		sc_riscv32__Arch* const p_arch = p_target->arch_info;
		assert(p_arch);
		p_arch->error_code = a_error_code;
	}
	return a_error_code;
}

/// @brief get stored target context operation code and reset stored code to ERROR_OK.
static inline error_code
sc_error_code__get_and_clear(target const* const p_target)
{
	error_code const result = sc_error_code__get(p_target);
	sc_error_code__set(p_target, ERROR_OK);
	return result;
}

/** @brief Update error context.

Store first occurred code that is no equal to ERROR_OK into target context.

@return first not equal ERROR_OK code or else ERROR_OK
*/
static inline error_code
sc_error_code__update(target const* const p_target, error_code const a_error_code)
{
	error_code const old_code = sc_error_code__get(p_target);

	if (ERROR_OK != old_code || ERROR_OK == a_error_code) {
		return old_code;
	} else {
		LOG_DEBUG("Set new error code: %d", a_error_code);
		return sc_error_code__set(p_target, a_error_code);
	}
}

/** @brief Update error context

	If passed code is not equal to ERROR_OK - replace it in the target context.
*/
static inline error_code
sc_error_code__prepend(target const* const p_target, error_code const older_err_code)
{
	if (ERROR_OK == older_err_code) {
		return sc_error_code__get(p_target);
	} else {
		LOG_DEBUG("Reset error code to previous state: %d", older_err_code);
		return sc_error_code__set(p_target, older_err_code);
	}
}
/// @}

/** RISC-V instruction encoding.
*/
/// @{

#define RISCV_OPCODE_INSTR_R_TYPE(func7, rs2, rs1, func3, rd, opcode) (\
        CHECK_OPCODE(opcode), \
        CHECK_FUNC3(func3), \
        CHECK_FUNC7(func7), \
        CHECK_REG(rs2), \
        CHECK_REG(rs1), \
        CHECK_REG(rd), \
        MAKE_TYPE_FIELD(rv_instruction32_type, (func7), 25, 31) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (rs2), 20, 24) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (rs1), 15, 19) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (func3), 12, 14) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (rd), 7, 11) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (opcode), 0, 6) )

#define RISCV_OPCODE_INSTR_I_TYPE(imm_11_00, rs1, func3, rd, opcode) ( \
        CHECK_OPCODE(opcode), \
        CHECK_FUNC3(func3), \
        CHECK_REG(rd), \
        CHECK_REG(rs1), \
        CHECK_IMM_11_00(imm_11_00), \
        MAKE_TYPE_FIELD(rv_instruction32_type, EXTRACT_FIELD((imm_11_00), 0, 11), 20, 31) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (rs1), 15, 19) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (func3), 12, 14) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (rd), 7, 11) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, (opcode), 0, 6) )

#define RISCV_OPCODE_INSTR_S_TYPE(imm_11_00, rs2, rs1, func3, opcode) ( \
        CHECK_OPCODE(opcode), \
        CHECK_FUNC3(func3), \
        CHECK_IMM_11_00(imm_11_00), \
        CHECK_REG(rs2), \
        CHECK_REG(rs1), \
        MAKE_TYPE_FIELD(rv_instruction32_type, EXTRACT_FIELD(imm_11_00, 5, 11), 25, 31) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, rs2, 20, 24) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, rs1, 15, 19) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, func3, 12, 14) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, EXTRACT_FIELD(imm_11_00, 0, 4), 7, 11) | \
        MAKE_TYPE_FIELD(rv_instruction32_type, opcode, 0, 6) )

#define RV_INSTR_U_TYPE(imm_31_12, rd, opcode) ( \
        CHECK_OPCODE(opcode), \
        CHECK_REG(rd), \
        CHECK_IMM_31_12(imm_31_12), \
        MAKE_TYPE_FIELD(uint32_t, EXTRACT_FIELD(imm_31_12, 12, 31), 12, 31) | \
        MAKE_TYPE_FIELD(uint32_t, rd, 7, 11) | \
        MAKE_TYPE_FIELD(uint32_t, opcode, 0, 6))

#define RISCV_OPCODE_VDBG(rs1, rs2) ( \
				MAKE_TYPE_FIELD(rv_instruction32_type, 0b0010100u, 25, 31) | \
				MAKE_TYPE_FIELD(rv_instruction32_type, (rs2), 20, 24) | \
				MAKE_TYPE_FIELD(rv_instruction32_type, (rs1), 15, 19) | \
				MAKE_TYPE_FIELD(rv_instruction32_type, 0b000u, 12, 14) | \
				MAKE_TYPE_FIELD(rv_instruction32_type, 0b00000u, 7, 11) | \
				MAKE_TYPE_FIELD(rv_instruction32_type, 0b1010111u, 0, 6) )

#define RISCV_OPCODE_ADD(rd, rs1, rs2) RISCV_OPCODE_INSTR_R_TYPE(0b0000000, (rs2), (rs1), 0u, (rd), 0b0110011u)
#define RISCV_OPCODE_FMV_X_S(rd, rs1_fp) RISCV_OPCODE_INSTR_R_TYPE(0x70u, 0u, (rs1_fp), 0u, (rd), 0x53u)
#define RISCV_OPCODE_FMV_S_X(rd_fp, rs1) RISCV_OPCODE_INSTR_R_TYPE(0x78u, 0u, (rs1), 0u, (rd_fp), 0x53u)
#define RISCV_OPCODE_LUI(rd, imm_31_12) RV_INSTR_U_TYPE(imm_31_12, (rd), 0b0110111u)
#define RISCV_OPCODE_ADDI(rd, rs1, imm) RISCV_OPCODE_INSTR_I_TYPE((imm), (rs1), 0u, (rd), 0x13u)
#define RISCV_OPCODE_NOP() RISCV_OPCODE_ADDI(0, 0, 0)
#define RISCV_OPCODE_JALR(rd, rs1, imm) RISCV_OPCODE_INSTR_I_TYPE((imm), (rs1), 0u, (rd), 0x67u)
#define RISCV_OPCODE_CSRRW(rd, csr, rs1) RISCV_OPCODE_INSTR_I_TYPE(NORMALIZE_INT_FIELD((csr), 11, 0), (rs1), 1u, (rd), 0x73u)
#define RISCV_OPCODE_CSRRS(rd, csr, rs1) RISCV_OPCODE_INSTR_I_TYPE(NORMALIZE_INT_FIELD((csr), 11, 0), (rs1), 2u, (rd), 0x73u)
#define RISCV_OPCODE_EBREAK() RISCV_OPCODE_INSTR_I_TYPE(1, 0u, 0u, 0u, 0x73u)

#define RISCV_OPCODE_CSRW(csr, rs1) RISCV_OPCODE_CSRRW(0, (csr), (rs1))
#define RISCV_OPCODE_CSRR(rd, csr) RISCV_OPCODE_CSRRS((rd), csr, 0)
#define RISCV_OPCODE_C_EBREAK(void) (0x9002u)

static rv_instruction32_type
RISCV_opcode_LB(reg_num_type rd, reg_num_type rs1, riscv_short_signed_type imm)
{
	return RISCV_OPCODE_INSTR_I_TYPE(imm, rs1, 0u, rd, 0x03u);
}

static rv_instruction32_type
RISCV_opcode_LH(reg_num_type rd, reg_num_type rs1, riscv_short_signed_type imm)
{
	return RISCV_OPCODE_INSTR_I_TYPE(imm, rs1, 1u, rd, 0x03u);
}

static rv_instruction32_type
RISCV_opcode_LW(reg_num_type rd, reg_num_type rs1, riscv_short_signed_type imm)
{
	return RISCV_OPCODE_INSTR_I_TYPE(imm, rs1, 2u, rd, 0x03u);
}

static rv_instruction32_type
RISCV_opcode_SB(reg_num_type rs_data, reg_num_type rs1, riscv_short_signed_type imm)
{
	return RISCV_OPCODE_INSTR_S_TYPE(imm, rs_data, rs1, 0u, 0x23);
}

static rv_instruction32_type
RISCV_opcode_SH(reg_num_type rs, reg_num_type rs1, riscv_short_signed_type imm)
{
	return RISCV_OPCODE_INSTR_S_TYPE(imm, rs, rs1, 1u, 0x23);
}

static rv_instruction32_type
RISCV_opcode_SW(reg_num_type rs, reg_num_type rs1, riscv_short_signed_type imm)
{
	return RISCV_OPCODE_INSTR_S_TYPE(imm, rs, rs1, 2u, 0x23);
}

/// SC custom instruction copy FPU double precision register value to two 32-bits GP registers (based on S-extension opcode)
rv_instruction32_type
sc_RISCV_opcode_S_FMV_2X_D(reg_num_type rd_hi, reg_num_type rd_lo, reg_num_type rs1_fp)
{
	return RISCV_OPCODE_INSTR_R_TYPE(0x70u, rd_hi, rs1_fp, 0u, rd_lo, 0x53u);
}

/// SC custom instruction to combine from two GP registers values to FPU double precision register value (based on S-extension opcode)
rv_instruction32_type
sc_RISCV_opcode_S_FMV_D_2X(reg_num_type rd_fp, reg_num_type rs_hi, reg_num_type rs_lo)
{
	return RISCV_OPCODE_INSTR_R_TYPE(0x78u, rs_hi, rs_lo, 0u, rd_fp, 0x53u);
}

/// SC custom instruction copy FPU double precision register value to two 32-bits GP registers (based on D-extension opcode)
rv_instruction32_type
sc_RISCV_opcode_D_FMV_2X_D(reg_num_type rd_hi, reg_num_type rd_lo, reg_num_type rs1_fp)
{
	return RISCV_OPCODE_INSTR_R_TYPE(0x71u, rd_hi, rs1_fp, 0u, rd_lo, 0x53u);
}

/// SC custom instruction to combine from two GP registers values to FPU double precision register value (based on D-extension opcode)
rv_instruction32_type
sc_RISCV_opcode_D_FMV_D_2X(reg_num_type rd_fp, reg_num_type rs_hi, reg_num_type rs_lo)
{
	return RISCV_OPCODE_INSTR_R_TYPE(0x79u, rs_hi, rs_lo, 0u, rd_fp, 0x53u);
}

/// @}

/** @brief Always perform scan to write instruction register
*/
static inline void
IR_select_force(target const* const p_target, TAP_IR_e const new_instr)
{
	assert(p_target);
	assert(p_target->tap);
	assert(p_target->tap->ir_length == TAP_length_of_IR);
	uint8_t out_buffer[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {};
	buf_set_u32(out_buffer, 0, TAP_length_of_IR, new_instr);
	scan_field field = {.num_bits = p_target->tap->ir_length,.out_value = out_buffer};
	jtag_add_ir_scan(p_target->tap, &field, TAP_IDLE);
	LOG_DEBUG("irscan %s %d", p_target->cmd_name, new_instr);
}

/** @brief Cached version of instruction register selection
*/
static void
IR_select(target const* const p_target, TAP_IR_e const new_instr)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	if (p_arch->constants->use_ir_select_cache) {
		assert(p_target->tap);
		assert(p_target->tap->ir_length == TAP_length_of_IR);

		/// Skip IR scan if IR is the same
		if (buf_get_u32(p_target->tap->cur_instr, 0u, p_target->tap->ir_length) == new_instr) {
			return;
		}
	}

	/// or call real IR scan
	IR_select_force(p_target, new_instr);
}

/** @brief Common method to retrieve data of read-only 32-bits TAP IR

Method store and update error_code, but ignore previous errors and
allows to repair error state of debug controller.
*/
static error_code
read_only_32_bits_regs(target const* const p_target, TAP_IR_e ir, uint32_t* p_value)
{
	/// Low-level method save but ignore previous errors.
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	/// Error state can be updated in IR_select
	IR_select(p_target, ir);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		uint8_t result_buffer[NUM_BYTES_FOR_BITS(TAP_length_of_RO_32)] = {};
		scan_field const field = {
			.num_bits = TAP_length_of_RO_32,
			.in_value = result_buffer,
		};
		assert(p_target->tap);
		jtag_add_dr_scan(p_target->tap, 1, &field, TAP_IDLE);

		// enforce jtag_execute_queue() to obtain result
		sc_error_code__update(p_target, jtag_execute_queue());
		LOG_DEBUG("drscan %s %d 0 ; # %08X", p_target->cmd_name, field.num_bits, buf_get_u32(result_buffer, 0, TAP_length_of_RO_32));

		if (ERROR_OK != sc_error_code__get(p_target)) {
			/// Error state can be updated in DR scan
			LOG_ERROR("JTAG error %d", sc_error_code__get(p_target));
		} else {
			assert(p_value);
			*p_value = buf_get_u32(result_buffer, 0, TAP_length_of_RO_32);
		}
	}

	return sc_error_code__prepend(p_target, old_err_code);
}

/// @brief IDCODE get accessors
static inline error_code
sc_rv32_IDCODE_get(target const* const p_target, uint32_t* p_value)
{
	return read_only_32_bits_regs(p_target, TAP_instruction_IDCODE, p_value);
}

/// @brief DBG_ID get accessors
static inline error_code
sc_rv32_DBG_ID_get(target const* const p_target, uint32_t* p_value)
{
	return read_only_32_bits_regs(p_target, TAP_instruction_DBG_ID, p_value);
}

/// @brief BLD_ID get accessors
static inline error_code
sc_rv32_BLD_ID_get(target const* const p_target, uint32_t* p_value)
{
	return read_only_32_bits_regs(p_target, TAP_instruction_BLD_ID, p_value);
}

/// @brief DBG_STATUS get accessors
static error_code
sc_rv32_DBG_STATUS_get(target const* const p_target, uint32_t* p_value)
{
	read_only_32_bits_regs(p_target, TAP_instruction_DBG_STATUS, p_value);

	/** Sensitivity mask is union of bits
	- HART0_ERR
	- ERR
	- ERR_HWCORE
	- ERR_FSMBUSY
	- LOCK
	- READY
	*/
	static uint32_t const result_mask =
		DBG_STATUS_bit_HART0_Err |
		DBG_STATUS_bit_Err |
		DBG_STATUS_bit_Err_HwCore |
		DBG_STATUS_bit_Err_FsmBusy |
		DBG_STATUS_bit_Err_DAP_Opcode |
		DBG_STATUS_bit_Lock |
		DBG_STATUS_bit_Ready;

	/** In normal state only READY bit is allowed */
	static uint32_t const good_result = DBG_STATUS_bit_Ready;

	assert(p_value);

	if ((*p_value & result_mask) != (good_result & result_mask)) {
		LOG_WARNING("DBG_STATUS == 0x%08X", *p_value);
	}

	return sc_error_code__get(p_target);
}

/** @brief Upper level DAP_CTRL multiplexer control port cache update method.
*/
static inline void
update_DAP_CTRL_cache(target const* const p_target, uint8_t const set_dap_unit_group)
{
	assert(p_target);
	sc_riscv32__Arch* const p_arch = p_target->arch_info;
	assert(p_arch);
	p_arch->last_DAP_ctrl = set_dap_unit_group;
}

/** @brief Upper level DAP_CTRL multiplexer control port cache invalidation.
*/
static inline void
invalidate_DAP_CTR_cache(target const* const p_target)
{
	update_DAP_CTRL_cache(p_target, DAP_CTRL_value_INVALID_CODE);
}

/** @brief Forced variant of upper level multiplexer control port DAP_CTRL set method (don't use cache state)
*/
static inline error_code
DAP_CTRL_REG_set_force(target const* const p_target, uint8_t const set_dap_unit_group)
{
	assert(p_target);
	/// Save but ignore previous error state.
	error_code const older_err_code = sc_error_code__get_and_clear(p_target);
	IR_select(p_target, TAP_instruction_DAP_CTRL);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		/// Invalidate cache of DAP_CTRL
		invalidate_DAP_CTR_cache(p_target);

		/// Prepare clear status bits
		uint8_t status = 0;
		static_assert(NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CTRL) == sizeof status, "Bad size");
		static_assert(NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CTRL) == sizeof set_dap_unit_group, "Bad size");
		/// Prepare DR scan
		scan_field const field = {
			/// for 4 bits
			.num_bits = TAP_length_of_DAP_CTRL,
			/// send DAP unit/group
			.out_value = &set_dap_unit_group,
			/// and receive old status
			.in_value = &status,
			/// with status check that only READY bit is active
			.check_value = &obj_DAP_opstatus_GOOD,
			/// sensitivity to mask ERROR | LOCK | READY bits
			.check_mask = &obj_DAP_status_MASK,
		};

		jtag_add_dr_scan_check(p_target->tap, 1, &field, TAP_IDLE);

		/// Enforce jtag_execute_queue() to get status.
		error_code const jtag_status = jtag_execute_queue();
		LOG_DEBUG("drscan %s %d 0x%1X ; # %1X", p_target->cmd_name, field.num_bits, set_dap_unit_group, status);

		if (ERROR_OK == jtag_status) {
			/// Update DAP_CTRL cache if no errors
			update_DAP_CTRL_cache(p_target, set_dap_unit_group);
		} else {
			/// or report current error.
			uint32_t dbg_status;
			sc_rv32_DBG_STATUS_get(p_target, &dbg_status);
			static uint32_t const dbg_status_check_value = DBG_STATUS_bit_Ready;
			static uint32_t const dbg_status_mask =
				DBG_STATUS_bit_Lock |
				DBG_STATUS_bit_Ready;

			if ((dbg_status & dbg_status_mask) != (dbg_status_check_value & dbg_status_mask)) {
				LOG_ERROR("JTAG error %d, operation_status=0x%1X, dbg_status=0x%08" PRIX32, jtag_status, (unsigned)(status), dbg_status);
				sc_error_code__update(p_target, jtag_status);
			} else {
				LOG_WARNING("JTAG error %d, operation_status=0x%1X, but dbg_status=0x%08" PRIX32, jtag_status, (unsigned)(status), dbg_status);
			}
		}
	}

	/// Restore previous error (if it was)
	return sc_error_code__prepend(p_target, older_err_code);
}

/// @brief Verify unit/group selection.
static inline error_code
DAP_CTRL_REG_verify(target const* const p_target, uint8_t const set_dap_unit_group)
{
	/// First of all invalidate DAP_CTR cache.
	invalidate_DAP_CTR_cache(p_target);
	/// Ignore bu save previous error state.
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	/// Select read function of DAP_CTRL.
	IR_select(p_target, TAP_instruction_DAP_CTRL_RD);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		/// Restore previous error (if it was)
		return sc_error_code__prepend(p_target, old_err_code);
	}

	/// Prepare DR scan to read actual value of DAP_CTR.
	uint8_t get_dap_unit_group = 0;
	uint8_t set_dap_unit_group_mask = 0x0Fu;
	static_assert(NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CTRL) == sizeof get_dap_unit_group, "Bad size");
	scan_field const field = {
		.num_bits = TAP_length_of_DAP_CTRL,
		.in_value = &get_dap_unit_group,
		/// with checking for expected value.
		.check_value = &set_dap_unit_group,
		.check_mask = &set_dap_unit_group_mask,
	};
	jtag_add_dr_scan_check(p_target->tap, 1, &field, TAP_IDLE);

	/// Enforce jtag_execute_queue() to get get_dap_unit_group.
	sc_error_code__update(p_target, jtag_execute_queue());
	LOG_DEBUG("drscan %s %d 0x%1X ; # %1X", p_target->cmd_name, field.num_bits, 0, get_dap_unit_group);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		/// If no errors
		if (get_dap_unit_group == set_dap_unit_group) {
			/// and read value is equal to expected then update DAP_CTRL cache,
			update_DAP_CTRL_cache(p_target, get_dap_unit_group);
		} else {
			/// else report error.
			LOG_ERROR("Unit/Group verification error: set 0x%1X, but get 0x%1X!", set_dap_unit_group, get_dap_unit_group);
			sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
		}
	}

	/// Restore previous error (if it was)
	return sc_error_code__prepend(p_target, old_err_code);
}

/** @brief Common DR scan of DAP_CMD multiplexed port.

@par[in]  p_target current target pointer
@par[in]  DAP_OPCODE 4-bits: R/W bit and 3-bits next level multiplexer selector
@par[in]  DAP_OPCODE_EXT 32-bits payload
@par[out] p_result pointer to place for input payload
*/
static error_code
sc_rv32_DAP_CMD_scan(target const* const p_target, uint8_t const DAP_OPCODE, uint32_t const DAP_OPCODE_EXT, uint32_t* p_result)
{
	/// Ignore but save previous error state.
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	/// Select DAP_CMD IR.
	IR_select(p_target, TAP_instruction_DAP_CMD);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		/// Restore previous error (if it was)
		return sc_error_code__prepend(p_target, old_err_code);
	}

	/// Prepare DR scan for two fields.

	/// Copy output payload to buffer.
	uint8_t dap_opcode_ext[NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CMD_OPCODE_EXT)] = {};
	buf_set_u32(dap_opcode_ext, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, DAP_OPCODE_EXT);

	/// Reserve and init buffer for payload input.
	uint8_t dbg_data[NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CMD_OPCODE_EXT)] = {};

	/// Prepare operation status buffer.
	uint8_t DAP_OPSTATUS = 0;
	static_assert(NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CMD_OPCODE) == sizeof DAP_OPSTATUS, "Bad size");
	scan_field const fields[2] = {
		{.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = dap_opcode_ext,.in_value = dbg_data},
		/// Pass DAP_OPCODE bits. Check receiving DAP_OPSTATUS good/error bits.
		{.num_bits = TAP_length_of_DAP_CMD_OPCODE,.out_value = &DAP_OPCODE,.in_value = &DAP_OPSTATUS,.check_value = &obj_DAP_opstatus_GOOD,.check_mask = &obj_DAP_status_MASK,},
	};

	/// Add DR scan to queue.
	assert(p_target->tap);
	jtag_add_dr_scan_check(p_target->tap, ARRAY_LEN(fields), fields, TAP_IDLE);

	/// Enforse jtag_execute_queue() to get values
	sc_error_code__update(p_target, jtag_execute_queue());
	/// Log DR scan debug information.
	LOG_DEBUG("drscan %s %d 0x%08X %d 0x%1X ; # %08X %1X", p_target->cmd_name,
			  fields[0].num_bits, DAP_OPCODE_EXT,
			  fields[1].num_bits, DAP_OPCODE,
			  buf_get_u32(dbg_data, 0, TAP_length_of_DAP_CMD_OPCODE_EXT), DAP_OPSTATUS);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		if ((DAP_OPSTATUS & DAP_status_mask) != DAP_status_good) {
			/// Check and report if error was detected.
			LOG_ERROR("DAP_OPSTATUS == 0x%1X", (unsigned)(DAP_OPSTATUS));
			sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
		} else if (p_result) {
			/// or copy result bits to output if 'p_result' pointer is not NULL.
			*p_result = buf_get_u32(dbg_data, 0, TAP_length_of_DAP_CMD_OPCODE_EXT);
		}
	}

	/// Restore previous error (if it was)
	return sc_error_code__prepend(p_target, old_err_code);
}

/** @brief Try to unlock debug controller.

@warning Clear previous error_code and set ERROR_TARGET_FAILURE if unlock was unsuccessful
*/
static inline error_code
sc_rv32_DC__unlock(target const* const p_target, uint32_t* p_lock_context)
{
	LOG_WARNING("========= Try to unlock ==============");

	assert(p_target);
	assert(p_target->tap);
	assert(p_target->tap->ir_length == TAP_length_of_IR);

	{
		/// Enqueue selection of DAP_CTRL IR.
		static uint8_t const ir_out_buffer_DAP_CTRL[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {TAP_instruction_DAP_CTRL};
		/// @todo jtag_add_ir_scan need non-const scan_field
		static scan_field ir_field_DAP_CTRL = {.num_bits = TAP_length_of_IR,.out_value = ir_out_buffer_DAP_CTRL};
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DAP_CTRL);
		jtag_add_ir_scan(p_target->tap, &ir_field_DAP_CTRL, TAP_IDLE);
	}

	{
		/// Enqueue write DAP_CTRL to select HART_DBGCMD group and HART_0 unit.
		static uint8_t const set_dap_unit_group = MAKE_TYPE_FIELD(uint8_t, DBGC_unit_id_HART_0, 2, 3) | MAKE_TYPE_FIELD(uint8_t, DBGC_functional_group_HART_DBGCMD, 0, 1);
		static_assert(NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CTRL) == sizeof set_dap_unit_group, "Bad size");
		static scan_field const dr_field_DAP_CTRL = {.num_bits = TAP_length_of_DAP_CTRL,.out_value = &set_dap_unit_group};
		invalidate_DAP_CTR_cache(p_target);
		LOG_DEBUG("drscan %s %d 0x%1X", p_target->cmd_name,
				  dr_field_DAP_CTRL.num_bits, set_dap_unit_group);
		jtag_add_dr_scan(p_target->tap, 1, &dr_field_DAP_CTRL, TAP_IDLE);
	}

	{
		/// Enqueue selection of DAP_CMD IR.
		static uint8_t const ir_out_buffer_DAP_CMD[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {TAP_instruction_DAP_CMD};
		static scan_field ir_field_DAP_CMD = {.num_bits = TAP_length_of_IR,.out_value = ir_out_buffer_DAP_CMD};
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DAP_CMD);
		jtag_add_ir_scan(p_target->tap, &ir_field_DAP_CMD, TAP_IDLE);
	}

	uint8_t lock_context_buf[4] = {};
	{
		/// Enqueue DR scan transaction to UNLOCK register, write zeros, receive lock context.
		static uint8_t const dap_opcode_ext_UNLOCK[4] = {0, 0, 0, 0};
		static uint8_t const dap_opcode_UNLOCK = UNLOCK_index;
		scan_field const dr_fields_UNLOCK[2] = {
			{.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = dap_opcode_ext_UNLOCK,.in_value = lock_context_buf},
			{.num_bits = TAP_length_of_DAP_CMD_OPCODE,.out_value = &dap_opcode_UNLOCK}
		};

		LOG_DEBUG("drscan %s %d 0x%08X %d 0x%1X", p_target->cmd_name,
				  dr_fields_UNLOCK[0].num_bits, buf_get_u32(dap_opcode_ext_UNLOCK, 0, TAP_length_of_DAP_CMD_OPCODE_EXT),
				  dr_fields_UNLOCK[1].num_bits, dap_opcode_UNLOCK);
		jtag_add_dr_scan(p_target->tap, ARRAY_LEN(dr_fields_UNLOCK), dr_fields_UNLOCK, TAP_IDLE);
	}

	{
		/// Enqueue DBG_STATUS IR selection.
		static uint8_t const ir_out_buffer_DBG_STATUS[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {TAP_instruction_DBG_STATUS};
		static scan_field ir_field_DBG_STATUS = {.num_bits = TAP_length_of_IR,.out_value = ir_out_buffer_DBG_STATUS};
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DBG_STATUS);
		jtag_add_ir_scan(p_target->tap, &ir_field_DBG_STATUS, TAP_IDLE);
	}

	{
		/// Enqueue get DBG_STATUS.
		uint8_t status_buffer[4] = {};
		scan_field const dr_field_DBG_STATUS = {.num_bits = TAP_length_of_DBG_STATUS,.out_value = status_buffer,.in_value = status_buffer};
		jtag_add_dr_scan(p_target->tap, 1, &dr_field_DBG_STATUS, TAP_IDLE);

		/// Enforse jtag_execute_queue() to get values.
		error_code const status = sc_error_code__update(p_target, jtag_execute_queue());
		uint32_t const scan_status = buf_get_u32(status_buffer, 0, TAP_length_of_DAP_CMD_OPCODE_EXT);
		bool const ok =
			ERROR_OK == status &&
			/// and if status is OK, check that LOCK bit is zero now.
			0 == (scan_status & DBG_STATUS_bit_Lock);
		LOG_DEBUG("drscan %s %d 0x%08X ; # 0x%08X", p_target->cmd_name,
				  dr_field_DBG_STATUS.num_bits, 0,
				  scan_status);
		uint32_t const lock_context = buf_get_u32(lock_context_buf, 0, TAP_length_of_DAP_CMD_OPCODE_EXT);
		LOG_DEBUG("%s context=0x%08X, status=0x%08X", ok ? "Unlock succsessful!" : "Unlock unsuccsessful!",
				  lock_context,
				  scan_status);
		assert(p_lock_context);
		*p_lock_context = lock_context;
		return sc_error_code__get(p_target);
	}
}

/** @brief Make code for REGTRANS transaction

To prepare type of access to 2-nd level multiplexed REGTRANS register

@par[in] write read (false) or write (true) transaction type code
@par[in] index multiplexed register index
*/
static inline uint8_t
REGTRANS_scan_type(bool const write, uint8_t const index)
{
	assert((index & LOW_BITS_MASK(3)) == index);
	return
		MAKE_TYPE_FIELD(uint8_t, !!write, 3, 3) |
		MAKE_TYPE_FIELD(uint8_t, index, 0, 2);
}

/** @brief Common method to set DAP_CTRL upper level multiplexer control register

@par[in] p_target pointer to this target
@par[in] dap_unit multiplexed unit of multiplexed group
@par[in] dap_group multiplexed group

@todo Describe details
*/
static error_code
sc_rv32_DAP_CTRL_REG_set(target const* const p_target, type_dbgc_unit_id_e const dap_unit, uint8_t const dap_group)
{
	assert(p_target);
	bool const match_HART_0 = DBGC_unit_id_HART_0 == dap_unit && 0 == p_target->coreid;
	bool const match_HART_1 = DBGC_unit_id_HART_1 == dap_unit && 1 == p_target->coreid;
	bool const HART_unit = match_HART_0 || match_HART_1;
	bool const HART_group =
		DBGC_functional_group_HART_REGTRANS == dap_group ||
		DBGC_functional_group_HART_DBGCMD == dap_group ||
		DBGC_functional_group_HART_CSR_CAP == dap_group;
	bool const CORE_unit = DBGC_unit_id_CORE == dap_unit;
	bool const CORE_group = DBGC_functional_group_CORE_REGTRANS == dap_group;
	assert((HART_unit && HART_group) ^ (CORE_unit && CORE_group));

	uint8_t const set_dap_unit_group =
		MAKE_TYPE_FIELD(uint8_t,
						MAKE_TYPE_FIELD(uint8_t, dap_unit, TAP_length_of_DAP_CTRL_fgroup_field, TAP_length_of_DAP_CTRL_fgroup_field + TAP_length_of_DAP_CTRL_unit_field - 1) |
						MAKE_TYPE_FIELD(uint8_t, dap_group, 0, TAP_length_of_DAP_CTRL_fgroup_field - 1),
						0,
						TAP_length_of_DAP_CTRL_fgroup_field + TAP_length_of_DAP_CTRL_unit_field - 1);

	sc_riscv32__Arch* const p_arch = p_target->arch_info;
	assert(p_arch);

	if (p_arch->constants->use_dap_control_cache) {
		/// If use_dap_control_cache enabled and last unit/group is the same, then return without actions.
		if (p_arch->last_DAP_ctrl == set_dap_unit_group) {
			return sc_error_code__get(p_target);
		}

		LOG_DEBUG("DAP_CTRL_REG of %s reset to 0x%1X", p_target->cmd_name, set_dap_unit_group);
	}

	invalidate_DAP_CTR_cache(p_target);
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);

	if (ERROR_OK != DAP_CTRL_REG_set_force(p_target, set_dap_unit_group)) {
		return sc_error_code__prepend(p_target, old_err_code);
	}

	if (p_arch->constants->use_verify_dap_control) {
		sc_error_code__get_and_clear(p_target);

		if (ERROR_OK == DAP_CTRL_REG_verify(p_target, set_dap_unit_group)) {
			update_DAP_CTRL_cache(p_target, set_dap_unit_group);
		}
	}

	return sc_error_code__prepend(p_target, old_err_code);
}

/** @brief Common REGTRANS write operation

@par[inout] p_target pointer to this target
@par[in] func_unit functional unit
@par[in] func_group functional group
@par[in] index REGTRANS register index in func_unit/func_group
*/
static error_code
REGTRANS_write(target const* const p_target, type_dbgc_unit_id_e func_unit, uint8_t const func_group, uint8_t const index, uint32_t const data)
{
	/// Set upper level multiplexer to access unit/group.
	if (ERROR_OK != sc_rv32_DAP_CTRL_REG_set(p_target, func_unit, func_group)) {
		/// On error report and do not scan.
		/// @todo LOG_ERROR?
		LOG_WARNING("DAP_CTRL_REG_set error");
		return sc_error_code__get(p_target);
	}

	/// If no errors perform single DR scan with 4-bits field write bit/index bits and 32-bits data.
	return sc_rv32_DAP_CMD_scan(p_target, REGTRANS_scan_type(true, index), data, NULL);
}

/** @brief Common REGTRANS read operation

@par[inout] p_target pointer to this target
@par[in] func_unit functional unit
@par[in] func_group functional group
@par[in] index REGTRANS register index in func_unit/func_group
*/
static error_code
REGTRANS_read(target const* const p_target, type_dbgc_unit_id_e const func_unit, uint8_t const func_group, uint8_t const index, uint32_t* p_value)
{
	/// Set upper level multiplexer to access unit/group.
	if (ERROR_OK != sc_rv32_DAP_CTRL_REG_set(p_target, func_unit, func_group)) {
		return sc_error_code__get(p_target);
	}

	/// If no errors then perform first DR scan with 4-bits field register index bits (set to bit 'write' to zero)
	/// and dummy (zero) 32-bits data.
	/** Input data captured before TDI/TDO shifting and TAP register will update only after shifting,
	so first transaction can read only old register data, but not requested. Only second DR scan can get requested data.

	@bug Bad DC design. Context-dependent read transaction, in common case, transmit at least 36-bits of waste.
	*/
	if (ERROR_OK != sc_rv32_DAP_CMD_scan(p_target, REGTRANS_scan_type(false, index), 0, NULL)) {
		return sc_error_code__get(p_target);
	}

	/** If errors not detected, perform second same DR scan to really get requested data */
	return sc_rv32_DAP_CMD_scan(p_target, REGTRANS_scan_type(false, index), 0, p_value);
}

/** @brief HART REGTRANS read operation

@par[inout] p_target pointer to this target
@par[in] index REGTRANS register index in DBGC_unit_id_HART_0/HART_REGTRANS
*/
static inline error_code
sc_rv32_HART_REGTRANS_read(target const* const p_target, HART_REGTRANS_indexes const index, uint32_t* p_value)
{
	/// @todo remove unused DBGC_unit_id_HART_1
	type_dbgc_unit_id_e const unit = p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1;
	return REGTRANS_read(p_target, unit, DBGC_functional_group_HART_REGTRANS, index, p_value);
}

/** @brief HART HART_CSR_CAP read operation

@par[inout] p_target pointer to this target
@par[in] index REGTRANS register index in DBGC_unit_id_HART_0/HART_REGTRANS
*/
static inline error_code
sc_rv32_HART_CSR_CAP_read(target const* const p_target, HART_CSR_CAP_indexes const index, uint32_t* p_value)
{
	/// @todo remove unused DBGC_unit_id_HART_1
	type_dbgc_unit_id_e const unit = p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1;
	return REGTRANS_read(p_target, unit, DBGC_functional_group_HART_CSR_CAP, index, p_value);
}

static inline error_code
get_ISA(target* const p_target, uint32_t* p_value)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	HART_CSR_CAP_indexes const misa_index =
		0x00800000 == (p_arch->constants->expected_dbg_id & 0xFFFFFF00) ? HART_MCPUID_index :
		HART_MISA_index;
	return sc_rv32_HART_CSR_CAP_read(p_target, misa_index, p_value);
}

/** @brief HART REGTRANS write operation

@par[inout] p_target pointer to this target
@par[in] index REGTRANS register index in DBGC_unit_id_HART_0/HART_REGTRANS
@par[in] set_value 32-bits data
*/
static inline error_code
HART_REGTRANS_write(target const* const p_target, HART_REGTRANS_indexes const index, uint32_t const set_value)
{
	assert(p_target);
	type_dbgc_unit_id_e const unit = p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1;
	return REGTRANS_write(p_target, unit, DBGC_functional_group_HART_REGTRANS, index, set_value);
}

/** @brief HART REGTRANS write operation with re-read writing value.

@par[inout] p_target pointer to this target
@par[in] index REGTRANS register index in DBGC_unit_id_HART_0/HART_REGTRANS
@par[in] set_value 32-bits data
*/
static error_code
sc_rv32_HART_REGTRANS_write_and_check(target const* const p_target, HART_REGTRANS_indexes const index, uint32_t const set_value)
{
	if (ERROR_OK == HART_REGTRANS_write(p_target, index, set_value)) {
		sc_riscv32__Arch const* const p_arch = p_target->arch_info;
		assert(p_arch);

		if (p_arch->constants->use_verify_hart_regtrans_write) {
			uint32_t get_value;
			sc_rv32_HART_REGTRANS_read(p_target, index, &get_value);

			if (get_value != set_value) {
				LOG_ERROR("Write HART_REGTRANS"
						  " #%u"
						  " with value 0x%08" PRIX32
						  ", but re-read value is 0x%08" PRIX32,
						  (unsigned)(index),
						  set_value,
						  get_value);
				return sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
			}
		}
	}

	return sc_error_code__get(p_target);
}

/** @brief CORE REGTRANS read operation

@par[inout] p_target pointer to this target
@par[in] index REGTRANS register index in CORE/CORE_REGTRANS
*/
static inline error_code
sc_rv32_core_REGTRANS_read(target const* const p_target, CORE_REGTRANS_indexes const index, uint32_t* p_value)
{
	return REGTRANS_read(p_target, DBGC_unit_id_CORE, DBGC_functional_group_CORE_REGTRANS, index, p_value);
}

/** @brief Core REGTRANS write operation

@par[inout] p_target pointer to this target
@par[in] index REGTRANS register index in CORE/CORE_REGTRANS
@par[in] set_value 32-bits data
*/
static inline error_code
sc_rv32_CORE_REGTRANS_write(target const* const p_target, CORE_REGTRANS_indexes const index, uint32_t const data)
{
	REGTRANS_write(p_target, DBGC_unit_id_CORE, DBGC_functional_group_CORE_REGTRANS, index, data);
	return sc_error_code__get(p_target);
}

/** @brief Setup HART before group HART_DBGCMD transactions.

@par[inout] p_target pointer to this target
*/
static inline error_code
sc_rv32_EXEC__setup(target const* const p_target)
{
	if (ERROR_OK == sc_error_code__get(p_target)) {
		/// @note Skipped if error detected
		/// @todo remove references to DBGC_unit_id_HART_1
		sc_rv32_DAP_CTRL_REG_set(p_target, p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1, DBGC_functional_group_HART_DBGCMD);
	}

	return sc_error_code__get(p_target);
}

/** @brief Push 32-bits data through keyhole from debug controller to core special SC Debug CSR.
*/
static inline error_code
sc_rv32_EXEC__push_data_to_CSR(target const* const p_target, uint32_t const csr_data)
{
	if (ERROR_OK == sc_error_code__get(p_target)) {
		/// @note Skipped if error detected
		sc_rv32_DAP_CMD_scan(p_target, DBGDATA_WR_index, csr_data, NULL);
	}

	return sc_error_code__get(p_target);
}

/** @brief Push instruction (up to 32-bits) through keyhole from debug controller immediately to core.
@return SC Debug CSR data
*/
static inline error_code
sc_rv32_EXEC__step(target const* const p_target, uint32_t instruction, uint32_t* p_value)
{
	if (ERROR_OK == sc_error_code__get(p_target)) {
		sc_rv32_DAP_CMD_scan(p_target, CORE_EXEC_index, instruction, p_value);
	}

	return sc_error_code__get(p_target);
}

/** @brief Return last sampled PC value
*/
static error_code
sc_rv32_get_PC(target const* const p_target, uint32_t* p_pc)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	return sc_rv32_HART_REGTRANS_read(p_target, HART_PC_SAMPLE_index, p_pc);
}

/** @brief Convert HART status bits to target state enum values
*/
static target_state
HART_status_bits_to_target_state(uint32_t const status)
{
	static uint32_t const err_bits =
		HART_DBG_STS_bit_Err |
		HART_DBG_STS_bit_Err_HwThread |
		HART_DBG_STS_bit_Err_DAP_OpCode |
		HART_DBG_STS_bit_Err_DbgCmd_NACK;

	if (status & err_bits) {
		LOG_WARNING("Error status: 0x%08x", status);
		return TARGET_UNKNOWN;
	} else if (status & HART_DBG_STS_bit_Rst) {
		return TARGET_RESET;
	} else if (status & HART_DBG_STS_bit_DMODE) {
		return TARGET_HALTED;
	} else {
		return TARGET_RUNNING;
	}
}

static target_debug_reason BRKM_reason_get(target* const p_target);

/** @brief Read DMODE_CAUSE and try to encode to enum target_debug_reason
*/
static inline error_code
read_debug_cause(target* const p_target, target_debug_reason* p_reason)
{
	uint32_t value;

	if (ERROR_OK != sc_rv32_HART_REGTRANS_read(p_target, HART_DMODE_CAUSE_index, &value)) {
		*p_reason = DBG_REASON_UNDEFINED;
	} else if (value & HART_DMODE_CAUSE_bit_Enforce) {
		*p_reason = DBG_REASON_DBGRQ;
	} else if (value & HART_DMODE_CAUSE_bit_SStep) {
		*p_reason = DBG_REASON_SINGLESTEP;
	} else if (value & HART_DMODE_CAUSE_bit_Brkpt) {
		*p_reason = DBG_REASON_BREAKPOINT;
	} else if (value & HART_DMODE_CAUSE_bit_Hw_Brkpt) {
		*p_reason = BRKM_reason_get(p_target);
	} else if (value & HART_DMODE_CAUSE_bit_Rst_Exit) {
		*p_reason = DBG_REASON_DBGRQ;
	} else {
		*p_reason = DBG_REASON_UNDEFINED;
	}

	return sc_error_code__get(p_target);
}

static void
update_debug_reason(target* const p_target)
{
	assert(p_target);
	static char const* reasons_names[] = {
		"DBG_REASON_DBGRQ",
		"DBG_REASON_BREAKPOINT",
		"DBG_REASON_WATCHPOINT",
		"DBG_REASON_WPTANDBKPT",
		"DBG_REASON_SINGLESTEP",
		"DBG_REASON_NOTHALTED",
		"DBG_REASON_EXIT",
		"DBG_REASON_UNDEFINED",
	};
	static_assert(DBG_REASON_UNDEFINED + 1 == sizeof reasons_names / sizeof reasons_names[0], "Invalid number of reasons_names");
	target_debug_reason debug_reason;

	if (ERROR_OK != read_debug_cause(p_target, &debug_reason)) {
		return;
	}

	if (debug_reason != p_target->debug_reason) {
		LOG_DEBUG("New debug reason:"
				  " 0x%d"
				  " (%s)",
				  (unsigned)(debug_reason),
				  debug_reason >= ARRAY_LEN(reasons_names) ? "unknown" : reasons_names[debug_reason]);
		p_target->debug_reason = debug_reason;
	}
}

static inline void
update_debug_status(target* const p_target)
{
	assert(p_target);
	target_state const old_state = p_target->state;
	/// Only 1 HART available now
	assert(p_target->coreid == 0);
	uint32_t HART_status;
	target_state const new_state =
		ERROR_OK != sc_rv32_HART_REGTRANS_read(p_target, HART_DBG_STS_index, &HART_status) ?
		TARGET_UNKNOWN :
		HART_status_bits_to_target_state(HART_status);

	if (new_state == old_state) {
		return;
	}

	LOG_DEBUG("debug_status changed: old=%d, new=%d", old_state, new_state);

	p_target->state = new_state;

	switch (new_state) {
	case TARGET_HALTED:
		update_debug_reason(p_target);
		LOG_DEBUG("TARGET_EVENT_HALTED");
		target_call_event_callbacks(p_target, TARGET_EVENT_HALTED);
		break;

	case TARGET_RESET:
		update_debug_reason(p_target);
		LOG_DEBUG("TARGET_EVENT_RESET_ASSERT");
		target_call_event_callbacks(p_target, TARGET_EVENT_RESET_ASSERT);
		break;

	case TARGET_RUNNING:
		LOG_DEBUG("New debug reason: 0x%08X (DBG_REASON_NOTHALTED)", DBG_REASON_NOTHALTED);
		p_target->debug_reason = DBG_REASON_NOTHALTED;
		LOG_DEBUG("TARGET_EVENT_RESUMED");
		target_call_event_callbacks(p_target, TARGET_EVENT_RESUMED);
		break;

	case TARGET_UNKNOWN:
	default:
		LOG_WARNING("TARGET_UNKNOWN %d", new_state);
		break;
	}
}

/** Try for wait the READY state
*/
static inline error_code
try_to_get_ready(target* const p_target, uint32_t* p_core_status)
{
	if (ERROR_OK != sc_rv32_DBG_STATUS_get(p_target, p_core_status)) {
		return sc_error_code__get(p_target);
	}

	if (DBG_STATUS_bit_Ready == (*p_core_status & DBG_STATUS_bit_Ready)) {
		return sc_error_code__get(p_target);
	}

	static unsigned const max_retries = 10u;

	for (unsigned i = 2; i <= max_retries; ++i) {
		sc_error_code__get_and_clear(p_target);

		if (ERROR_OK != sc_rv32_DBG_STATUS_get(p_target, p_core_status)) {
			continue;
		}

		if (0 != (*p_core_status & DBG_STATUS_bit_Ready)) {
			LOG_DEBUG("Ready: 0x%08X after %d requests", *p_core_status, i);
			return sc_error_code__get(p_target);
		}
	}

	LOG_ERROR("Not ready: 0x%08X after %d requests", *p_core_status, max_retries);
	return sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
}

/** @brief Try to clear HART0 errors.
*/
static inline void
sc_rv32_HART0_clear_error(target* const p_target)
{
	LOG_DEBUG("========= Try to clear HART0 errors ============");
	assert(p_target);
	sc_riscv32__Arch* const p_arch = p_target->arch_info;
	assert(p_arch);
	assert(p_target->tap);
	assert(p_target->tap->ir_length == TAP_length_of_IR);

	{
		/// Enqueue irscan to select DAP_CTRL IR.
		uint8_t ir_dap_ctrl_out_buffer[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {};
		buf_set_u32(ir_dap_ctrl_out_buffer, 0, TAP_length_of_IR, TAP_instruction_DAP_CTRL);
		scan_field ir_dap_ctrl_field = {.num_bits = p_target->tap->ir_length,.out_value = ir_dap_ctrl_out_buffer};
		jtag_add_ir_scan(p_target->tap, &ir_dap_ctrl_field, TAP_IDLE);
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DAP_CTRL);
	}

	{
		/// Invalidate DAP_CTRL cache value.
		invalidate_DAP_CTR_cache(p_target);
		/// Enqueue DR scan to set DAP_CTRL HART_DBGCMD group and HART_0 unit (0x1u)
		uint8_t const set_dap_unit_group = MAKE_TYPE_FIELD(uint8_t, DBGC_unit_id_HART_0, 2, 3) | MAKE_TYPE_FIELD(uint8_t, DBGC_functional_group_HART_DBGCMD, 0, 1);
		scan_field const dr_dap_ctrl_field = {.num_bits = TAP_length_of_DAP_CTRL,.out_value = &set_dap_unit_group};
		LOG_DEBUG("drscan %s 0x%1X 0x%1X ; ", p_target->cmd_name, dr_dap_ctrl_field.num_bits, set_dap_unit_group);
		jtag_add_dr_scan(p_target->tap, 1, &dr_dap_ctrl_field, TAP_IDLE);
	}

	{
		/// Enqueue irscan to select DAP_CMD IR.
		uint8_t ir_dap_cmd_out_buffer[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {};
		buf_set_u32(ir_dap_cmd_out_buffer, 0, TAP_length_of_IR, TAP_instruction_DAP_CMD);
		scan_field ir_dap_cmd_field = {.num_bits = p_target->tap->ir_length,.out_value = ir_dap_cmd_out_buffer};
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DAP_CMD);
		jtag_add_ir_scan(p_target->tap, &ir_dap_cmd_field, TAP_IDLE);
	}

	{
		/// @todo describe
		uint8_t dap_opcode_ext[NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CMD_OPCODE_EXT)];
		uint32_t const opcode_ext = DBG_CTRL_bit_Sticky_Clr;
		buf_set_u32(dap_opcode_ext, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, opcode_ext);
		uint8_t const dap_opcode = DBG_CTRL_index;
		scan_field const fields[2] = {
			{.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = dap_opcode_ext},
			{.num_bits = TAP_length_of_DAP_CMD_OPCODE,.out_value = &dap_opcode}
		};
		LOG_DEBUG("drscan %s 0x%1X 0x%08X 0x%1X 0x%08X ; ", p_target->cmd_name,
				  fields[0].num_bits, opcode_ext,
				  fields[1].num_bits, DBG_CTRL_index);
		jtag_add_dr_scan(p_target->tap, ARRAY_LEN(fields), fields, TAP_IDLE);
	}
}

/** @brief Try to clear errors bit of core
*/
static inline void
sc_rv32_CORE_clear_errors(target* const p_target)
{
	LOG_DEBUG("========= Try to clear core errors ============");
	assert(p_target);
	sc_riscv32__Arch* const p_arch = p_target->arch_info;
	assert(p_arch);
	assert(p_target->tap);
	assert(p_target->tap->ir_length == TAP_length_of_IR);

	{
		uint8_t ir_dap_ctrl_out_buffer[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {};
		buf_set_u32(ir_dap_ctrl_out_buffer, 0, TAP_length_of_IR, TAP_instruction_DAP_CTRL);
		scan_field ir_dap_ctrl_field = {.num_bits = p_target->tap->ir_length,.out_value = ir_dap_ctrl_out_buffer};
		jtag_add_ir_scan(p_target->tap, &ir_dap_ctrl_field, TAP_IDLE);
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DAP_CTRL);
	}

	{
		/// set invalid cache value
		invalidate_DAP_CTR_cache(p_target);

		uint8_t const set_dap_unit_group = MAKE_TYPE_FIELD(uint8_t, DBGC_unit_id_CORE, 2, 3) | MAKE_TYPE_FIELD(uint8_t, DBGC_functional_group_CORE_REGTRANS, 0, 1);
		scan_field const field = {.num_bits = TAP_length_of_DAP_CTRL,.out_value = &set_dap_unit_group};
		LOG_DEBUG("drscan %s %d 0x%1X", p_target->cmd_name, field.num_bits, set_dap_unit_group);
		jtag_add_dr_scan(p_target->tap, 1, &field, TAP_IDLE);
	}

	{
		uint8_t ir_dap_cmd_out_buffer[NUM_BYTES_FOR_BITS(TAP_length_of_IR)] = {};
		buf_set_u32(ir_dap_cmd_out_buffer, 0, TAP_length_of_IR, TAP_instruction_DAP_CMD);
		scan_field ir_dap_cmd_field = {.num_bits = p_target->tap->ir_length,.out_value = ir_dap_cmd_out_buffer};
		jtag_add_ir_scan(p_target->tap, &ir_dap_cmd_field, TAP_IDLE);
		LOG_DEBUG("irscan %s %d", p_target->cmd_name, TAP_instruction_DAP_CMD);
	}

	{
		uint8_t dap_opcode_ext[NUM_BYTES_FOR_BITS(TAP_length_of_DAP_CMD_OPCODE_EXT)];
		buf_set_u32(dap_opcode_ext, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, 0xFFFFFFFF);
		uint8_t const dap_opcode = REGTRANS_scan_type(true, CORE_DBG_STS_index);
		scan_field const fields[2] = {
			{.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = dap_opcode_ext},
			{.num_bits = TAP_length_of_DAP_CMD_OPCODE,.out_value = &dap_opcode},
		};
		LOG_DEBUG("drscan %s %d 0x%08X %d 0x%1X", p_target->cmd_name,
				  fields[0].num_bits,
				  buf_get_u32(dap_opcode_ext, 0, 32),
				  fields[1].num_bits, dap_opcode);
		jtag_add_dr_scan(p_target->tap, ARRAY_LEN(fields), fields, TAP_IDLE);
	}
}

static inline error_code
check_and_repair_debug_controller_errors(target* const p_target)
{
#ifdef TAP_DESYNC_PROTECTION
	// protection against desynchronizing due to external reset
	jtag_add_tlr();
#endif
	invalidate_DAP_CTR_cache(p_target);
	uint32_t IDCODE;
	sc_rv32_IDCODE_get(p_target, &IDCODE);

	if (!sc_rv32__is_IDCODE_valid(p_target, IDCODE)) {
		/// If IDCODE is invalid, then its is serious error: reset target examined flag
		/// @todo replace by target_reset_examined;
		p_target->examined = false;
		LOG_ERROR("TAP controller/JTAG error! Try to re-examine!");
		return sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
	}

	uint32_t core_status;
	try_to_get_ready(p_target, &core_status);

	if (DBG_STATUS_bit_Ready != (core_status & DBG_STATUS_bit_Ready)) {
		/// If no DBG_STATUS_bit_Ready then any actions are disabled.
		/// @todo replace by target_reset_examined;
		p_target->examined = false;
		LOG_ERROR("Debug controller unrecoverable error!");
		return sc_error_code__get(p_target);
	}

	static uint32_t const controlled_mask =
		DBG_STATUS_bit_Ready |
		DBG_STATUS_bit_Lock |
		DBG_STATUS_bit_Err_DAP_Opcode |
		DBG_STATUS_bit_Err_FsmBusy |
		DBG_STATUS_bit_Err_HwCore |
		DBG_STATUS_bit_Err |
		DBG_STATUS_bit_HART0_Err;

	if (DBG_STATUS_bit_Ready == (core_status & controlled_mask)) {
		return sc_error_code__get(p_target);
	}

	/// First of all, try to unlock before any following actions
	if (DBG_STATUS_bit_Lock == (core_status & DBG_STATUS_bit_Lock)) {
		LOG_ERROR("Lock detected: 0x%08X", core_status);
		uint32_t lock_context;

		if (ERROR_OK != sc_rv32_DC__unlock(p_target, &lock_context)) {
			/// @todo replace by target_reset_examined;
			p_target->examined = false;
			/// return with error_code != ERROR_OK if unlock was unsuccsesful
			LOG_ERROR("Unlock unsucsessful with lock_context=0x%8X, unrecoverable error", lock_context);
			return sc_error_code__get(p_target);
		}

		sc_rv32_DBG_STATUS_get(p_target, &core_status);
		LOG_INFO("Lock with lock_context=0x%08X repaired: 0x%08X", lock_context, core_status);
	}

	if (DBG_STATUS_bit_Ready != (core_status & (DBG_STATUS_bit_Lock | DBG_STATUS_bit_Ready))) {
		LOG_ERROR("Core_status should be ready and unlocked!: 0x%08X", core_status);
		/// @todo replace by target_reset_examined;
		p_target->examined = false;
		return sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
	}

	static uint32_t const hart0_err_bits = DBG_STATUS_bit_HART0_Err /* | DBG_STATUS_bit_HART0_Err_Stky*/;

	if (0 != (core_status & hart0_err_bits)) {
		LOG_WARNING("Hart errors detected: 0x%08X", core_status);
	}

	sc_rv32_HART0_clear_error(p_target);
	sc_error_code__get_and_clear(p_target);
	sc_rv32_DBG_STATUS_get(p_target, &core_status);

	if (0 != (core_status & hart0_err_bits)) {
		LOG_ERROR("Hart errors not fixed!: 0x%08X", core_status);
	}

	static uint32_t const cdsr_err_bits =
		DBG_STATUS_bit_Err |
		DBG_STATUS_bit_Err_HwCore |
		DBG_STATUS_bit_Err_FsmBusy |
		DBG_STATUS_bit_Err_DAP_Opcode;

	if (0 != (core_status & cdsr_err_bits)) {
		LOG_WARNING("Core errors detected: 0x%08X", core_status);
	}

	sc_error_code__get_and_clear(p_target);
	sc_rv32_CORE_clear_errors(p_target);
	sc_error_code__get_and_clear(p_target);
	sc_rv32_DBG_STATUS_get(p_target, &core_status);

	if (0 != (core_status & cdsr_err_bits)) {
		LOG_ERROR("Core errors not fixed!: 0x%08X", core_status);
		sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
	}

	LOG_INFO("Core status: 0x%08X", core_status);
	return sc_error_code__get(p_target);
}

static error_code
sc_riscv32__update_status(target* const p_target)
{
	LOG_DEBUG("update_status");
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);

	if (ERROR_OK == check_and_repair_debug_controller_errors(p_target)) {
		update_debug_status(p_target);
	}

	return sc_error_code__prepend(p_target, old_err_code);
}

static error_code
sc_rv32_check_that_target_halted(target* const p_target)
{
	if (ERROR_OK == sc_riscv32__update_status(p_target)) {
		if (p_target->state != TARGET_HALTED) {
			LOG_ERROR("Target not halted");
			return sc_error_code__update(p_target, ERROR_TARGET_NOT_HALTED);
		}
	}

	return sc_error_code__get(p_target);
}

/// GP registers accessors
/// @brief Invalidate register
static void
reg__invalidate(reg* const p_reg)
{
	assert(p_reg);

	if (p_reg->exist) {
		if (p_reg->dirty) {
			/// Log error if invalidate dirty (not updated) register
			LOG_ERROR("Invalidate dirty register: %s", p_reg->name);
			target* const p_target = p_reg->arch_info;
			sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
		}

		p_reg->valid = false;
	}
}

static inline void
reg__set_valid_value_to_cache(reg* const p_reg, uint32_t const value)
{
	static_assert(CHAR_BIT == 8, "Unsupported char size");
	assert(p_reg);
	assert(p_reg->size <= CHAR_BIT * sizeof value);

	LOG_DEBUG("Updating cache from register %s to 0x%08X", p_reg->name, value);

	assert(p_reg->exist);
	assert(p_reg->value);
	buf_set_u32(p_reg->value, 0, p_reg->size, value);

	p_reg->valid = true;
	p_reg->dirty = false;
}

static void
reg__set_new_cache_value(reg* const p_reg, uint8_t* const buf)
{
	assert(p_reg);
	assert(p_reg->exist);
	assert(buf);

	switch (p_reg->size) {
	case 32:
		LOG_DEBUG("Set register %s cache to 0x%08" PRIX32, p_reg->name, buf_get_u32(buf, 0, p_reg->size));
		break;

	case 64:
		LOG_DEBUG("Set register %s cache to 0x%016" PRIX64, p_reg->name, buf_get_u64(buf, 0, p_reg->size));
		break;

	default:
		assert(!"Bad register size");
		break;
	}

	assert(p_reg->value);
	buf_cpy(buf, p_reg->value, p_reg->size);

	p_reg->valid = true;
	p_reg->dirty = true;
}

static inline bool
reg__check(reg const* const p_reg)
{
	assert(p_reg);

	if (!p_reg->exist) {
		LOG_ERROR("Register %s not exists", p_reg->name);
		return false;
	} else if (p_reg->dirty && !p_reg->valid) {
		LOG_ERROR("Register %s dirty but not valid", p_reg->name);
		return false;
	} else {
		return true;
	}
}

static inline void
reg_cache__invalidate(reg_cache const* const p_reg_cache)
{
	assert(p_reg_cache);
	assert(!(p_reg_cache->num_regs && !p_reg_cache->reg_list));

	for (size_t i = 0; i < p_reg_cache->num_regs; ++i) {
		reg* const p_reg = &p_reg_cache->reg_list[i];

		if (p_reg->exist) {
			assert(reg__check(&p_reg_cache->reg_list[i]));
			reg__invalidate(&p_reg_cache->reg_list[i]);
		}
	}
}

static void
reg_cache__chain_invalidate(reg_cache* p_reg_cache)
{
	for (; p_reg_cache; p_reg_cache = p_reg_cache->next) {
		reg_cache__invalidate(p_reg_cache);
	}
}

static error_code
reg_x__operation_conditions_check(reg const* const p_reg)
{
	if (!reg__check(p_reg)) {
		return ERROR_TARGET_INVALID;
	}

	if (p_reg->number >= number_of_regs_X) {
		LOG_WARNING("Bad GP register %s id=%d", p_reg->name, p_reg->number);
		return ERROR_TARGET_INVALID;
	}

	if (p_reg->number < 16) {
		return ERROR_OK;
	}

	target* const p_target = p_reg->arch_info;
	assert(p_target);

	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	assert(!!(0 != (p_arch->misa & BIT_MASK('I' - 'A'))) ^ !!(0 != (p_arch->misa & BIT_MASK('E' - 'A'))));

	if (0 == (p_arch->misa & BIT_MASK('I' - 'A'))) {
		LOG_WARNING("Bad GP register %s id=%d for RV32E", p_reg->name, p_reg->number);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	return ERROR_OK;
}

static void
sc_rv32_check_PC_value(target const* const p_target, uint32_t const previous_pc)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	uint32_t current_pc;
	sc_rv32_get_PC(p_target, &current_pc);

	if (current_pc != previous_pc) {
		LOG_ERROR("pc changed from 0x%08X to 0x%08X", previous_pc, current_pc);
		sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
	}
}

static error_code
reg_x__get(reg* const p_reg)
{
	error_code const check_result = reg_x__operation_conditions_check(p_reg);

	if (ERROR_OK != check_result) {
		if (ERROR_TARGET_RESOURCE_NOT_AVAILABLE != check_result) {
			return check_result;
		} else {
			// Eclipse workaround
			//@{
			buf_set_u32(p_reg->value, 0, p_reg->size, UINT32_C(0xFEEDBEEF));
			p_reg->valid = true;
			p_reg->dirty = false;
			//@}

			return ECLIPSE_WORKAROUND(ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
		}
	}

	target* p_target = p_reg->arch_info;
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK == sc_rv32_check_that_target_halted(p_target)) {
		if (p_reg->valid) {
			// register cache already valid
			if (p_reg->dirty) {
				LOG_WARNING("Try re-read dirty cache register %s", p_reg->name);
			} else {
				LOG_DEBUG("Try re-read cache register %s", p_reg->name);
			}
		}

		uint32_t previous_pc;

		if (ERROR_OK == sc_rv32_get_PC(p_target, &previous_pc)) {
			sc_riscv32__Arch const* const p_arch = p_target->arch_info;
			assert(p_arch);

			uint32_t value;

			if (
				ERROR_OK == sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl) &&
				ERROR_OK == sc_rv32_EXEC__setup(p_target) &&
				// Save p_reg->number register to Debug scratch CSR
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_arch->constants->debug_scratch_CSR, p_reg->number), NULL) &&
				/// Exec NOP instruction and get previous instruction CSR result.
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_NOP(), &value)
			) {
				reg__set_valid_value_to_cache(p_reg, value);
				sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
			}

			if (ERROR_OK != sc_error_code__get(p_target)) {
				sc_riscv32__update_status(p_target);

				if (!target_was_examined(p_target)) {
					return sc_error_code__get_and_clear(p_target);
				}
			}

			sc_rv32_check_PC_value(p_target, previous_pc);
		}
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);
	}

	return sc_error_code__get_and_clear(p_target);
}

static error_code
reg_x__store(reg* const p_reg)
{
	assert(p_reg);
	target* p_target = p_reg->arch_info;
	assert(p_target);
	uint32_t pc_sample_1;

	if (ERROR_OK != sc_rv32_get_PC(p_target, &pc_sample_1)) {
		return sc_error_code__get_and_clear(p_target);
	}

	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

	sc_rv32_EXEC__setup(p_target);

	assert(p_reg->value);

	if (ERROR_OK != sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(p_reg->value, 0, p_reg->size))) {
		return sc_error_code__get_and_clear(p_target);
	}

	assert(p_reg->valid);
	assert(p_reg->dirty);
	sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_reg->number, p_arch->constants->debug_scratch_CSR), NULL);
	p_reg->dirty = false;

	LOG_DEBUG("Store register value 0x%08" PRIX32 " from cache to register %s", buf_get_u32(p_reg->value, 0, p_reg->size), p_reg->name);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);

	assert(reg__check(p_reg));
	sc_rv32_check_PC_value(p_target, pc_sample_1);

	return sc_error_code__get_and_clear(p_target);
}

static error_code
reg_x__set(reg* const p_reg, uint8_t* const buf)
{
	error_code const check_result = reg_x__operation_conditions_check(p_reg);

	if (ERROR_OK != check_result) {
		return check_result;
	} else {
		target* p_target = p_reg->arch_info;
		invalidate_DAP_CTR_cache(p_target);

		if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}

		reg__set_new_cache_value(p_reg, buf);

		/// store dirty register data to HW
		return reg_x__store(p_reg);
	}
}

static reg_arch_type const reg_x_accessors = {
	.get = reg_x__get,
	.set = reg_x__set,
};

static error_code
reg_x0__get(reg* const p_reg)
{
	assert(p_reg);
	assert(p_reg->number == 0u);
	reg__set_valid_value_to_cache(p_reg, 0u);
	return ERROR_OK;
}

static error_code
reg_x0__set(reg* const p_reg, uint8_t* const buf)
{
	assert(p_reg);
	assert(buf);
	LOG_ERROR("Try to write to read-only register");
	assert(p_reg->number == 0u);
	reg__set_valid_value_to_cache(p_reg, 0u);
	return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
}

static reg_arch_type const reg_x0_accessors = {.get = reg_x0__get,.set = reg_x0__set,};

static reg*
prepare_temporary_GP_register(target const* const p_target, int const after_reg)
{
	assert(p_target);
	assert(p_target->reg_cache);
	reg* const p_reg_list = p_target->reg_cache->reg_list;
	assert(p_reg_list);
	assert(p_target->reg_cache->num_regs >= number_of_regs_X);
	reg* p_valid = NULL;
	reg* p_dirty = NULL;

	for (size_t i = after_reg + 1; i < number_of_regs_X; ++i) {
		assert(reg__check(&p_reg_list[i]));

		if (p_reg_list[i].valid) {
			if (p_reg_list[i].dirty) {
				p_dirty = &p_reg_list[i];
				p_valid = p_dirty;
				break;
			} else if (!p_valid) {
				p_valid = &p_reg_list[i];
			}
		}
	}

	if (!p_dirty) {
		if (!p_valid) {
			assert(after_reg + 1 < number_of_regs_X);
			p_valid = &p_reg_list[after_reg + 1];

			if (ERROR_OK != sc_error_code__update(p_target, reg_x__get(p_valid))) {
				return NULL;
			}
		}

		assert(p_valid);
		assert(p_valid->valid);
		p_valid->dirty = true;
		LOG_DEBUG("Mark temporary register %s dirty", p_valid->name);
		p_dirty = p_valid;
	}

	assert(p_dirty);
	assert(p_dirty->valid);
	assert(p_dirty->dirty);
	return p_dirty;
}

static uint32_t
sc_riscv32__csr_get_value(target* const p_target, uint32_t const csr_number)
{
	uint32_t value = 0xBADBAD;

	if (ERROR_OK == sc_rv32_check_that_target_halted(p_target)) {
		/// Find temporary GP register
		reg* const p_wrk_reg = prepare_temporary_GP_register(p_target, 0);
		assert(p_wrk_reg);

		uint32_t pc_sample_1;

		if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
			sc_riscv32__Arch const* const p_arch = p_target->arch_info;
			assert(p_arch);
			sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

			if (
				ERROR_OK == sc_rv32_EXEC__setup(p_target) &&
				/// Copy values to temporary register
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg->number, csr_number), NULL) &&
				/// and store temporary register to Debug scratch CSR.
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_arch->constants->debug_scratch_CSR, p_wrk_reg->number), NULL)
			) {
				/// Exec NOP instruction and get previous instruction CSR result.
				sc_rv32_EXEC__step(p_target, RISCV_OPCODE_NOP(), &value);
			}

			if (ERROR_OK != sc_error_code__get(p_target)) {
				sc_riscv32__update_status(p_target);

				if (!target_was_examined(p_target)) {
					return value;
				}
			}

			sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
		}

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return value;
			}
		}

		sc_rv32_check_PC_value(p_target, pc_sample_1);

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return value;
			}
		}

		// restore temporary register
		error_code const old_err_code = sc_error_code__get_and_clear(p_target);
		sc_error_code__update(p_target, reg_x__store(p_wrk_reg));
		sc_error_code__prepend(p_target, old_err_code);
		assert(!p_wrk_reg->dirty);
	}

	return value;
}

/// Update pc cache from HW (if non-cached)
static error_code
reg_pc__get(reg* const p_reg)
{
	assert(p_reg);
	assert(p_reg->number == RISCV_regnum_PC);
	assert(reg__check(p_reg));

	/// Find temporary GP register
	target* const p_target = p_reg->arch_info;
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	uint32_t pc_sample;

	if (ERROR_OK == sc_rv32_HART_REGTRANS_read(p_target, HART_PC_SAMPLE_index, &pc_sample)) {
		reg__set_valid_value_to_cache(p_reg, pc_sample);
	} else {
		reg__invalidate(p_reg);
	}

	return sc_error_code__get_and_clear(p_target);
}

static bool
is_RVC_enable(target* const p_target)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	return 0 != (p_arch->misa & BIT_MASK('C' - 'A'));
}

static error_code
reg_pc__set(reg* const p_reg, uint8_t* const buf)
{
	assert(p_reg);
	assert(p_reg->number == RISCV_regnum_PC);
	assert(reg__check(p_reg));

	if (!p_reg->valid) {
		LOG_DEBUG("force rewriting of pc register before read");
	}

	target* const p_target = p_reg->arch_info;
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	uint32_t const new_pc = buf_get_u32(buf, 0, p_reg->size);

	/// @note odd address is valid for pc, bit 0 value is ignored.
	if (0 != (new_pc & (1u << 1))) {
		bool const RVC_enable = is_RVC_enable(p_target);

		if (ERROR_OK != sc_error_code__get(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		} else if (!RVC_enable) {
			LOG_ERROR("Unaligned PC: 0x%08" PRIX32, new_pc);
			sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
			return sc_error_code__get_and_clear(p_target);
		}
	}

	reg* const p_wrk_reg = prepare_temporary_GP_register(p_target, 0);

	assert(p_wrk_reg);

	reg__set_new_cache_value(p_reg, buf);

	sc_riscv32__Arch const* const p_arch = p_target->arch_info;

	assert(p_arch);

	sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

	// Update to HW
	if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
		assert(p_reg->value);

		if (ERROR_OK == sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(p_reg->value, 0, p_reg->size))) {
			// set temporary register value to restoring pc value
			sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg->number, p_arch->constants->debug_scratch_CSR), NULL);

			if (ERROR_OK == sc_error_code__get(p_target)) {
				assert(p_wrk_reg->dirty);

				sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
				sc_rv32_EXEC__setup(p_target);

				/// and exec JARL to set pc
				sc_rv32_EXEC__step(p_target, RISCV_OPCODE_JALR(0, p_wrk_reg->number, 0), NULL);
				assert(p_reg->valid);
				assert(p_reg->dirty);
				p_reg->dirty = false;
			}
		}
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	// restore temporary register
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	sc_error_code__update(p_target, reg_x__store(p_wrk_reg));
	sc_error_code__prepend(p_target, old_err_code);
	assert(!p_wrk_reg->dirty);

	return sc_error_code__get_and_clear(p_target);
}

static reg_arch_type const reg_pc_accessors = {
	.get = reg_pc__get,
	.set = reg_pc__set,
};
static reg_data_type PC_reg_data_type = {
	.type = REG_TYPE_CODE_PTR,
};

static error_code
reg_FPU_S__get(reg* const p_reg)
{
	assert(p_reg);
	assert(p_reg->size == 32);
	assert(RISCV_regnum_FP_first <= p_reg->number && p_reg->number <= RISCV_regnum_FP_last);

	if (!p_reg->exist) {
		LOG_WARNING("FP register %s (#%d) is unavailable", p_reg->name, p_reg->number - RISCV_regnum_FP_first);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	assert(reg__check(p_reg));

	target* const p_target = p_reg->arch_info;
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);

	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	if (0 == (p_arch->misa & BIT_MASK('F' - 'A'))) {
		LOG_WARNING("F extention is unavailable");

		// Eclipse workaround
		//@{
		buf_set_u32(p_reg->value, 0, p_reg->size, UINT32_C(0xFEEDBEEF));
		p_reg->valid = true;
		p_reg->dirty = false;
		//@}

		return ECLIPSE_WORKAROUND(ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	}

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	/// @todo check that FPU is enabled
	/// Find temporary GP register
	reg* const p_wrk_reg_1 = prepare_temporary_GP_register(p_target, 0);
	assert(p_wrk_reg_1);

	uint32_t pc_sample_1;

	if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

		if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
			/// Copy values to temporary register
			sc_rv32_EXEC__step(p_target, RISCV_OPCODE_FMV_X_S(p_wrk_reg_1->number, p_reg->number - RISCV_regnum_FP_first), NULL);

			if (ERROR_OK == sc_error_code__get(p_target)) {
				/// and store temporary register to Debug scratch CSR.
				sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_arch->constants->debug_scratch_CSR, p_wrk_reg_1->number), NULL);

				if (ERROR_OK == sc_error_code__get(p_target)) {
					/// Exec NOP instruction and get previous instruction CSR result.
					uint32_t value;

					if (ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_NOP(), &value)) {
						buf_set_u32(p_reg->value, 0, p_reg->size, value);
						p_reg->valid = true;
						p_reg->dirty = false;
					}
				}
			}
		}

		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
	}

	sc_rv32_check_PC_value(p_target, pc_sample_1);

	// restore temporary register
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);

	if (ERROR_OK == sc_error_code__update(p_target, reg_x__store(p_wrk_reg_1))) {
		assert(!p_wrk_reg_1->dirty);
	}

	sc_error_code__prepend(p_target, old_err_code);

	return sc_error_code__get_and_clear(p_target);
}

// vector reg get-----------------------------------------------------------------------
static error_code
reg_VECTOR_S__get(reg* const p_reg)
{
	for (int i = 0; i < 8; ++i) {
		assert((p_reg+i));
		assert((p_reg+i)->size == 32);
		assert(RISCV_regnum_V_first <= (p_reg+i)->number && (p_reg+i)->number <= RISCV_regnum_V_last);

		if (!(p_reg+i)->exist) {
			LOG_WARNING("Vector register %s (#%d) is unavailable", (p_reg+i)->name, (p_reg+i)->number - RISCV_regnum_V_first);
			return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
		}

		assert(reg__check((p_reg+i)));

		target* const p_target = (p_reg+i)->arch_info;
		assert(p_target);
		invalidate_DAP_CTR_cache(p_target);

		sc_riscv32__Arch const* const p_arch = p_target->arch_info;
		assert(p_arch);

		if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}

		uint32_t pc_sample_1;

		if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
			sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

			if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
				/// Copy values to temporary register
				sc_rv32_EXEC__step(p_target, RISCV_OPCODE_VDBG((((p_reg+i)->number)-RISCV_regnum_V_first) / 8, i), NULL);


					if (ERROR_OK == sc_error_code__get(p_target)) {
						/// Exec NOP instruction and get previous instruction CSR result.
						uint32_t value;

						if (ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_NOP(), &value)) {
							buf_set_u32((p_reg+i)->value, 0, (p_reg+i)->size, value);
							(p_reg+i)->valid = true;
							(p_reg+i)->dirty = false;
						}
					}
			}
			sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
		}

		sc_rv32_check_PC_value(p_target, pc_sample_1);
	}
	target* const p_target = p_reg->arch_info;
	return sc_error_code__get_and_clear(p_target);
}
// not implemented
static error_code
reg_VECTOR_S__set(reg* const p_reg, uint8_t* const buf)
{
	return ERROR_OK;
}

static reg_arch_type const reg_v_accessors = {
	.get = reg_VECTOR_S__get,
	.set = reg_VECTOR_S__set,
};
//-------------------------------------------------------------------------------------------

static error_code
reg_FPU_S__set(reg* const p_reg, uint8_t* const buf)
{
	assert(p_reg);
	assert(p_reg->size == 32);
	assert(RISCV_regnum_FP_first <= p_reg->number && p_reg->number < RISCV_regnum_FP_last);

	if (!p_reg->exist) {
		LOG_WARNING("Register %s is unavailable", p_reg->name);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	assert(reg__check(p_reg));

	target* const p_target = p_reg->arch_info;
	assert(p_target);

	invalidate_DAP_CTR_cache(p_target);

	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	if (0 == (p_arch->misa & BIT_MASK('F' - 'A'))) {
		LOG_WARNING("F extention is unavailable");
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	/// @todo check that FPU is enabled
	/// Find temporary GP register
	reg* const p_wrk_reg = prepare_temporary_GP_register(p_target, 0);
	assert(p_wrk_reg);

	uint32_t pc_sample_1;

	if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

		if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
			reg__set_new_cache_value(p_reg, buf);

			if (ERROR_OK == sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(p_reg->value, 0, p_reg->size))) {
				// set temporary register value to restoring pc value
				if (ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg->number, p_arch->constants->debug_scratch_CSR), NULL)) {
					assert(p_wrk_reg->dirty);
					assert(0 < p_wrk_reg->number && p_wrk_reg->number < RISCV_regnum_PC);

					if (ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_FMV_S_X(p_reg->number - RISCV_regnum_FP_first, p_wrk_reg->number), NULL)) {
						assert(p_reg->valid);
						assert(p_reg->dirty);
						p_reg->dirty = false;
						LOG_DEBUG("Store register value 0x%08" PRIX32 " from cache to register %s", buf_get_u32(p_reg->value, 0, p_reg->size), p_reg->name);
					}
				}
			}
		}

		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
	}

	sc_rv32_check_PC_value(p_target, pc_sample_1);
	// restore temporary register
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	sc_error_code__update(p_target, reg_x__store(p_wrk_reg));
	sc_error_code__prepend(p_target, old_err_code);
	assert(!p_wrk_reg->dirty);
	return sc_error_code__get_and_clear(p_target);
}

static reg_arch_type const reg_FPU_S_accessors = {.get = reg_FPU_S__get,.set = reg_FPU_S__set,};
static reg_data_type FPU_S_reg_data_type = {.type = REG_TYPE_IEEE_SINGLE,};

enum
{
	CSR_mstatus = 0x300
};

static error_code
reg_FPU_D__get(reg* const p_reg)
{
	assert(p_reg);
	assert(p_reg->size == 64);
	assert(RISCV_regnum_FP_first <= p_reg->number && p_reg->number <= RISCV_regnum_FP_last);

	if (!p_reg->exist) {
		LOG_WARNING("FP register %s (#%d) is unavailable", p_reg->name, p_reg->number - RISCV_regnum_FP_first);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	assert(reg__check(p_reg));

	target* const p_target = p_reg->arch_info;
	assert(p_target);

	invalidate_DAP_CTR_cache(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	if (0 == (p_arch->misa & BIT_MASK('d' - 'a'))) {
		LOG_WARNING("D/F extentions are unavailable");

		// Eclipse workaround
		//@{
		buf_set_u64(p_reg->value, 0, p_reg->size, UINT64_C(0xBADC0DFEEDBEEF));
		p_reg->valid = true;
		p_reg->dirty = false;
		//@}

		return ECLIPSE_WORKAROUND(ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	}

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	uint32_t const mstatus = sc_riscv32__csr_get_value(p_target, CSR_mstatus);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	if (0 == ((mstatus >> p_arch->constants->mstatus_FS_offset) & 3)) {
		LOG_ERROR("FPU is disabled");
		sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
		return sc_error_code__get_and_clear(p_target);
	}

	bool const FPU_D = 0 != (p_arch->misa & BIT_MASK('d' - 'a'));

	/// Find temporary GP register
	reg* const p_wrk_reg_1 = prepare_temporary_GP_register(p_target, 0);
	assert(p_wrk_reg_1);
	reg* const p_wrk_reg_2 = prepare_temporary_GP_register(p_target, p_wrk_reg_1->number);
	assert(p_wrk_reg_2);

	uint32_t pc_sample_1;

	if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

		if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
			uint32_t const opcode_1 =
				FPU_D ?
				p_arch->constants->opcode_FMV_2X_D(p_wrk_reg_2->number, p_wrk_reg_1->number, p_reg->number - RISCV_regnum_FP_first) :
				RISCV_OPCODE_FMV_X_S(p_wrk_reg_1->number, p_reg->number - RISCV_regnum_FP_first);

			uint32_t value_hi;
			uint32_t value_lo;

			if (
				ERROR_OK == sc_rv32_EXEC__step(p_target, opcode_1, NULL) &&
				/// and store temporary register to Debug scratch CSR.
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_arch->constants->debug_scratch_CSR, p_wrk_reg_1->number), NULL) &&
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_arch->constants->debug_scratch_CSR, p_wrk_reg_2->number), &value_lo) &&
				/// Exec NOP instruction and get previous instruction CSR result.
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_NOP(), &value_hi)
			) {
				buf_set_u64(p_reg->value, 0, p_reg->size, (FPU_D ? (uint64_t)value_hi << 32 : 0u) | (uint64_t)value_lo);
				p_reg->valid = true;
				p_reg->dirty = false;
			}
		}

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return sc_error_code__get_and_clear(p_target);
			}
		}

		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	sc_rv32_check_PC_value(p_target, pc_sample_1);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	// restore temporary register
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);

	if (ERROR_OK == sc_error_code__update(p_target, reg_x__store(p_wrk_reg_2))) {
		assert(!p_wrk_reg_2->dirty);
	}

	if (ERROR_OK == sc_error_code__update(p_target, reg_x__store(p_wrk_reg_1))) {
		assert(!p_wrk_reg_1->dirty);
	}

	sc_error_code__prepend(p_target, old_err_code);

	return sc_error_code__get_and_clear(p_target);
}

static error_code
reg_FPU_D__set(reg* const p_reg, uint8_t* const buf)
{
	assert(p_reg);
	assert(p_reg->size == 64);
	assert(RISCV_regnum_FP_first <= p_reg->number && p_reg->number < RISCV_regnum_FP_last);

	if (!p_reg->exist) {
		LOG_WARNING("Register %s is unavailable", p_reg->name);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	assert(reg__check(p_reg));

	target* const p_target = p_reg->arch_info;
	assert(p_target);

	invalidate_DAP_CTR_cache(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);

	if (0 == (p_arch->misa & BIT_MASK('d' - 'a'))) {
		LOG_WARNING("D/F extentions are unavailable");
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	uint32_t const mstatus = sc_riscv32__csr_get_value(p_target, CSR_mstatus);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	if (0 == ((mstatus >> p_arch->constants->mstatus_FS_offset) & 3)) {
		LOG_ERROR("FPU is disabled");
		sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
		return sc_error_code__get_and_clear(p_target);
	}

	bool const FPU_D = 0 != (p_arch->misa & BIT_MASK('d' - 'a'));

	/// Find temporary GP register
	reg* const p_wrk_reg_1 = prepare_temporary_GP_register(p_target, 0);
	assert(p_wrk_reg_1);
	assert(p_wrk_reg_1->dirty);
	assert(0 < p_wrk_reg_1->number && p_wrk_reg_1->number < RISCV_regnum_PC);

	reg* const p_wrk_reg_2 = prepare_temporary_GP_register(p_target, p_wrk_reg_1->number);
	assert(p_wrk_reg_2);
	assert(p_wrk_reg_2->dirty);
	assert(0 < p_wrk_reg_2->number && p_wrk_reg_2->number < RISCV_regnum_PC);

	uint32_t pc_sample_1;

	if (
		ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1) &&
		ERROR_OK == sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl) &&
		ERROR_OK == sc_rv32_EXEC__setup(p_target)
	) {
		reg__set_new_cache_value(p_reg, buf);

		if (
			ERROR_OK == sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(p_reg->value, 0, p_reg->size)) &&
			// set temporary register value to restoring pc value
			ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg_1->number, p_arch->constants->debug_scratch_CSR), NULL) &&
			ERROR_OK == sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(&((uint8_t const*)p_reg->value)[4], 0, p_reg->size)) &&
			ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg_2->number, p_arch->constants->debug_scratch_CSR), NULL)
		) {
			uint32_t const opcode_1 =
				FPU_D ?
				p_arch->constants->opcode_FMV_D_2X(p_reg->number - RISCV_regnum_FP_first, p_wrk_reg_2->number, p_wrk_reg_1->number) :
				RISCV_OPCODE_FMV_S_X(p_reg->number - RISCV_regnum_FP_first, p_wrk_reg_1->number);

			if (ERROR_OK == sc_rv32_EXEC__step(p_target, opcode_1, NULL)) {
				/// Correct pc by jump 2 instructions back and get previous command result.
				assert(p_reg->valid);
				assert(p_reg->dirty);
				p_reg->dirty = false;
				LOG_DEBUG("Store"
						  " register value 0x%016" PRIX64
						  " from cache to register %s",
						  buf_get_u64(p_reg->value, 0, p_reg->size),
						  p_reg->name);
			}
		}

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return sc_error_code__get_and_clear(p_target);
			}
		}

		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	sc_rv32_check_PC_value(p_target, pc_sample_1);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	// restore temporary register
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);

	if (ERROR_OK == sc_error_code__update(p_target, reg_x__store(p_wrk_reg_2))) {
		assert(!p_wrk_reg_2->dirty);
	}

	if (ERROR_OK == sc_error_code__update(p_target, reg_x__store(p_wrk_reg_1))) {
		assert(!p_wrk_reg_1->dirty);
	}

	sc_error_code__prepend(p_target, old_err_code);
	return sc_error_code__get_and_clear(p_target);
}

static reg_arch_type const reg_FPU_D_accessors = {.get = reg_FPU_D__get,.set = reg_FPU_D__set,};
static reg_data_type IEEE_single_precision_type = {.type = REG_TYPE_IEEE_SINGLE,.id = "ieee_single",};
static reg_data_type IEEE_double_precision_type = {.type = REG_TYPE_IEEE_DOUBLE,.id = "ieee_double",};
static reg_data_type_union_field FPU_S = {.name = "S",.type = &IEEE_single_precision_type};
static reg_data_type_union_field FPU_D = {.name = "D",.type = &IEEE_double_precision_type,.next = &FPU_S};
static reg_data_type_union FPU_D_or_S = {.fields = &FPU_D};
static reg_data_type FPU_D_reg_data_type = {.type = REG_TYPE_ARCH_DEFINED,.id = "Float_D_or_S",.type_class = REG_TYPE_CLASS_UNION,.reg_type_union = &FPU_D_or_S};

static error_code
reg_csr__get(reg* const p_reg)
{
	assert(p_reg);
	assert(RISCV_regnum_CSR_first <= p_reg->number && p_reg->number <= RISCV_rtegnum_CSR_last);
	uint32_t const csr_number = p_reg->number - RISCV_regnum_CSR_first;
	assert(csr_number < 4096u);

	if (!p_reg->exist) {
		LOG_WARNING("CSR %s (#%d) is unavailable", p_reg->name, csr_number);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	// Eclipse workaround
	//@{
	buf_set_u32(p_reg->value, 0, p_reg->size, UINT32_C(0xFEEDBEEF));
	p_reg->valid = true;
	p_reg->dirty = false;
	//@}

	assert(reg__check(p_reg));
	target* const p_target = p_reg->arch_info;
	invalidate_DAP_CTR_cache(p_target);

	uint32_t const value = sc_riscv32__csr_get_value(p_target, csr_number);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		reg__set_valid_value_to_cache(p_reg, value);
	}

	return sc_error_code__get_and_clear(p_target);
}

static error_code
reg_csr__set(reg* const p_reg, uint8_t* const buf)
{
	assert(p_reg);
	assert(RISCV_regnum_CSR_first <= p_reg->number && p_reg->number <= RISCV_rtegnum_CSR_last);

	if (!p_reg->exist) {
		LOG_WARNING("Register %s is unavailable", p_reg->name);
		return ERROR_TARGET_RESOURCE_NOT_AVAILABLE;
	}

	assert(reg__check(p_reg));

	target* const p_target = p_reg->arch_info;
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	reg* const p_wrk_reg = prepare_temporary_GP_register(p_target, 0);

	assert(p_wrk_reg);

	uint32_t pc_sample_1;

	if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
		sc_riscv32__Arch const* const p_arch = p_target->arch_info;
		assert(p_arch);

		if (
			ERROR_OK == sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl) &&
			ERROR_OK == sc_rv32_EXEC__setup(p_target)
		) {
			reg__set_new_cache_value(p_reg, buf);

			if (
				ERROR_OK == sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(p_reg->value, 0, p_reg->size)) &&
				// set temporary register value
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg->number, p_arch->constants->debug_scratch_CSR), NULL)
			) {
				assert(p_wrk_reg->dirty);
				assert(p_wrk_reg->number < number_of_regs_X);

				if (ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_reg->number - RISCV_regnum_CSR_first, p_wrk_reg->number), NULL)) {
					assert(p_reg->valid);
					assert(p_reg->dirty);
					p_reg->dirty = false;
					LOG_DEBUG("Store register value 0x%08" PRIX32
							  " from cache to register %s",
							  buf_get_u32(p_reg->value, 0, p_reg->size),
							  p_reg->name);
				}
			}
		}

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return sc_error_code__get_and_clear(p_target);
			}
		}

		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	sc_rv32_check_PC_value(p_target, pc_sample_1);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	// restore temporary register
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	sc_error_code__update(p_target, reg_x__store(p_wrk_reg));
	sc_error_code__prepend(p_target, old_err_code);
	assert(!p_wrk_reg->dirty);
	return sc_error_code__get_and_clear(p_target);
}

static reg_arch_type const reg_csr_accessors = {
	.get = reg_csr__get,
	.set = reg_csr__set,
};

static reg_cache*
reg_cache__section_create(char const* name, reg const regs_templates[], size_t const num_regs, void* const p_arch_info)
{
	assert(name);
	assert(0 < num_regs);
	assert(p_arch_info);
	reg* const p_dst_array = calloc(num_regs, sizeof(reg));
	reg* p_dst_iter = &p_dst_array[0];
	reg const* p_src_iter = &regs_templates[0];

	for (size_t i = 0; i < num_regs; ++i) {
		*p_dst_iter = *p_src_iter;
		p_dst_iter->value = calloc(1, NUM_BYTES_FOR_BITS(p_src_iter->size));
		p_dst_iter->arch_info = p_arch_info;

		++p_src_iter;
		++p_dst_iter;
	}

	reg_cache const the_reg_cache = {
		.name = name,
		.reg_list = p_dst_array,
		.num_regs = num_regs,
	};

	reg_cache* const p_obj = calloc(1, sizeof(reg_cache));

	assert(p_obj);

	*p_obj = the_reg_cache;

	return p_obj;
}

static error_code
set_DEMODE_ENBL(target* const p_target, uint32_t const set_value)
{
	sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DMODE_ENBL_index, set_value);
	return sc_error_code__get(p_target);
}

static breakpoint*
find_breakpoint_by_address(target* const p_target,
						   rv32_address_type const address)
{
	breakpoint* p_bkp = p_target->breakpoints;

	for (; p_bkp; p_bkp = p_bkp->next) {
		if (p_bkp->set && p_bkp->address == address) {
			break;
		}
	}

	return p_bkp;
}

static error_code
resume_common(target* const p_target,
			  uint32_t dmode_enabled,
			  int const current,
			  rv32_address_type const address,
			  int const handle_breakpoints,
			  int const debug_execution)
{
	LOG_DEBUG("Resume ");

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	// PC cache
	reg* const p_pc = &p_target->reg_cache->reg_list[number_of_regs_X];

	if (!current) {
		// setup new PC
		uint8_t buf[sizeof address];
		buf_set_u32(buf, 0, XLEN, address);

		if (ERROR_OK != sc_error_code__update(p_target, reg_pc__set(p_pc, buf))) {
			return sc_error_code__get_and_clear(p_target);
		}

		assert(!p_pc->dirty);
	}

	if (handle_breakpoints) {
		if (current) {
			// Find breakpoint for current instruction
			sc_error_code__update(p_target, reg_pc__get(p_pc));
			assert(p_pc->value);
			uint32_t const pc = buf_get_u32(p_pc->value, 0, XLEN);
			breakpoint* p_breakpoint_at_pc = find_breakpoint_by_address(p_target, pc);

			if (p_breakpoint_at_pc) {
				// exec single step without breakpoint
				sc_riscv32__Arch const* const p_arch = p_target->arch_info;
				assert(p_arch);
				// remove breakpoint
				sc_error_code__update(p_target, target_remove_breakpoint(p_target, p_breakpoint_at_pc));
				// prepare for single step
				reg_cache__chain_invalidate(p_target->reg_cache);
				// force single step
				set_DEMODE_ENBL(p_target, dmode_enabled | HART_DMODE_ENBL_bit_SStep);
				sc_rv32_DAP_CTRL_REG_set(p_target, p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1, DBGC_functional_group_HART_DBGCMD);
				// resume for single step
				sc_rv32_DAP_CMD_scan(p_target, DBG_CTRL_index, DBG_CTRL_bit_Resume | DBG_CTRL_bit_Sticky_Clr, NULL);
				// restore breakpoint
				sc_error_code__update(p_target, target_add_breakpoint(p_target, p_breakpoint_at_pc));

				// If resume/halt already done (by single step)
				if (0 != (dmode_enabled & HART_DMODE_ENBL_bit_SStep)) {
					// TODO: extra call
					reg_cache__chain_invalidate(p_target->reg_cache);
					// set status
					p_target->state = debug_execution ? TARGET_DEBUG_RUNNING : TARGET_RUNNING;
					// raise resume event
					target_call_event_callbacks(p_target, debug_execution ? TARGET_EVENT_DEBUG_RESUMED : TARGET_EVENT_RESUMED);
					// setup debug mode
					set_DEMODE_ENBL(p_target, dmode_enabled);
					// set debug reason
					sc_riscv32__update_status(p_target);

					if (!target_was_examined(p_target)) {
						return sc_error_code__get_and_clear(p_target);
					}

					LOG_DEBUG("New debug reason: 0x%08X", DBG_REASON_SINGLESTEP);
					p_target->debug_reason = DBG_REASON_SINGLESTEP;
					// raise halt event
					target_call_event_callbacks(p_target, debug_execution ? TARGET_EVENT_DEBUG_HALTED : TARGET_EVENT_HALTED);
					// and exit
					return sc_error_code__get_and_clear(p_target);
				}
			}
		}
	}

	// prepare for execution continue
	reg_cache__chain_invalidate(p_target->reg_cache);

	// enable requested debug mode
	if (ERROR_OK != set_DEMODE_ENBL(p_target, dmode_enabled)) {
		return sc_error_code__get_and_clear(p_target);
	}

	// resume exec
	if (ERROR_OK != sc_rv32_DAP_CTRL_REG_set(p_target, p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1, DBGC_functional_group_HART_DBGCMD)) {
		LOG_WARNING("DAP_CTRL_REG_set error");
		return sc_error_code__get_and_clear(p_target);
	}

	if (ERROR_OK != sc_rv32_DAP_CMD_scan(p_target, DBG_CTRL_index, DBG_CTRL_bit_Resume | DBG_CTRL_bit_Sticky_Clr, NULL)) {
		return sc_error_code__get_and_clear(p_target);
	}

	// Mark "not halted", set state, raise event
	LOG_DEBUG("New debug reason: 0x%08X", DBG_REASON_NOTHALTED);
	p_target->debug_reason = DBG_REASON_NOTHALTED;
	p_target->state = debug_execution ? TARGET_DEBUG_RUNNING : TARGET_RUNNING;
	target_call_event_callbacks(p_target, debug_execution ? TARGET_EVENT_DEBUG_RESUMED : TARGET_EVENT_RESUMED);

	sc_riscv32__update_status(p_target);
	return sc_error_code__get_and_clear(p_target);
}

static error_code
sc_rv32_core_reset__set(target* const p_target, bool const active)
{
	uint32_t get_old_value1;

	if (ERROR_OK == sc_rv32_core_REGTRANS_read(p_target, CORE_DBG_CTRL_index, &get_old_value1)) {
		static uint32_t const bit_mask = CORE_DBG_CTRL_bit_HART0_Rst | CORE_DBG_CTRL_bit_Rst;
		uint32_t const set_value = (get_old_value1 & ~bit_mask) | (active ? bit_mask : 0u);

		if (ERROR_OK == sc_rv32_CORE_REGTRANS_write(p_target, CORE_DBG_CTRL_index, set_value)) {
			sc_riscv32__Arch const* const p_arch = p_target->arch_info;
			assert(p_arch);

			if (p_arch->constants->use_verify_core_regtrans_write) {
				uint32_t get_new_value2;

				if (ERROR_OK != sc_rv32_core_REGTRANS_read(p_target, CORE_DBG_CTRL_index, &get_new_value2)) {
					return sc_error_code__get_and_clear(p_target);
				}

				if ((get_new_value2 & bit_mask) != (set_value & bit_mask)) {
					LOG_ERROR("Fail to verify write:"
							  " set 0x%08" PRIX32
							  ", but get 0x%08" PRIX32,
							  set_value,
							  get_new_value2);
					sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
					return sc_error_code__get_and_clear(p_target);
				}
			}

			if (ERROR_OK == sc_riscv32__update_status(p_target)) {
				if (active) {
					if (p_target->state != TARGET_RESET) {
						/// issue error if we are still running
						LOG_ERROR("Target is not resetting after reset assert");
						sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
					}
				} else {
					if (p_target->state == TARGET_RESET) {
						LOG_ERROR("Target is still in reset after reset deassert");
						sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
					}
				}
			}
		}
	}

	return sc_error_code__get_and_clear(p_target);
}

static reg const def_GP_regs_array[] = {
	// Hard-wired zero
	{.name = "x0",.number = 0,.caller_save = false,.dirty = false,.valid = true,.exist = true,.size = XLEN,.type = &reg_x0_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Return address
	{.name = "x1",.number = 1,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Stack pointer
	{.name = "x2",.number = 2,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Global pointer
	{.name = "x3",.number = 3,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Thread pointer
	{.name = "x4",.number = 4,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Temporaries
	{.name = "x5",.number = 5,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x6",.number = 6,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x7",.number = 7,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Saved register/frame pointer
	{.name = "x8",.number = 8,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Saved register
	{.name = "x9",.number = 9,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Function arguments/return values
	{.name = "x10",.number = 10,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x11",.number = 11,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Function arguments
	{.name = "x12",.number = 12,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x13",.number = 13,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x14",.number = 14,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x15",.number = 15,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x16",.number = 16,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x17",.number = 17,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Saved registers
	{.name = "x18",.number = 18,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x19",.number = 19,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x20",.number = 20,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x21",.number = 21,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x22",.number = 22,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x23",.number = 23,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x24",.number = 24,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x25",.number = 25,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x26",.number = 26,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x27",.number = 27,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Temporaries
	{.name = "x28",.number = 28,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x29",.number = 29,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x30",.number = 30,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},
	{.name = "x31",.number = 31,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_x_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_GP_regs_name},

	// Program counter
	{.name = "pc",.number = RISCV_regnum_PC,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_pc_accessors,.feature = &feature_riscv_org,.reg_data_type = &PC_reg_data_type,.group = def_GP_regs_name},
};
static char const def_FPU_regs_name[] = "float";
static reg const def_FP_regs_array[] = {
	// FP temporaries
	{.name = "f0",.number = 0 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f1",.number = 1 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f2",.number = 2 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f3",.number = 3 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f4",.number = 4 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f5",.number = 5 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f6",.number = 6 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f7",.number = 7 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},

	// FP saved registers
	{.name = "f8",.number = 8 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f9",.number = 9 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},

	// FP arguments/return values
	{.name = "f10",.number = 10 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f11",.number = 11 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},

	// FP arguments
	{.name = "f12",.number = 12 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f13",.number = 13 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f14",.number = 14 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f15",.number = 15 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f16",.number = 16 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f17",.number = 17 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},

	// FP saved registers
	{.name = "f18",.number = 18 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f19",.number = 19 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f20",.number = 20 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f21",.number = 21 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f22",.number = 22 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f23",.number = 23 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f24",.number = 24 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f25",.number = 25 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f26",.number = 26 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f27",.number = 27 + RISCV_regnum_FP_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},

	// FP temporaries
	{.name = "f28",.number = 28 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f29",.number = 29 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f30",.number = 30 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
	{.name = "f31",.number = 31 + RISCV_regnum_FP_first,.caller_save = true,.dirty = false,.valid = false,.exist = true,.size = FLEN,.type = &reg_FPU_D_accessors,.feature = &feature_riscv_org,.reg_data_type = &FPU_D_reg_data_type,.group = def_FPU_regs_name},
};

static reg const def_V_regs_array[] = {
	// Hard-wired zero
	{.name = "v0",.number = 0 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 1 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 2 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 3 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 4 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 5 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 6 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v0",.number = 7 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Return address
	{.name = "v1",.number = 8 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 9 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 10 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 11 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 12 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 13 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 14 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v1",.number = 15 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Stack pointer
	{.name = "v2",.number = 16 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 17 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 18 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 19 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 20 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 21 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 22 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v2",.number = 23 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Global pointer
	{.name = "v3",.number = 24 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 25 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 26 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 27 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 28 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 29 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 30 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v3",.number = 31 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Thread pointer
	{.name = "v4",.number = 32 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 33 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 34 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 35 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 36 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 37 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 38 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v4",.number = 39 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Temporaries
	{.name = "v5",.number = 40 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 41 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 42 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 43 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 44 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 45 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 46 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v5",.number = 47 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v6",.number = 48 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 49 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 50 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 51 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 52 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 53 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 54 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v6",.number = 55 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v7",.number = 56 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 57 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 58 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 59 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 60 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 61 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 62 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v7",.number = 63 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Saved register/frame pointer
	{.name = "v8",.number = 64 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 65 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 66 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 67 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 68 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 69 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 70 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v8",.number = 71 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Saved register
	{.name = "v9",.number = 72 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 73 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 74 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 75 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 76 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 77 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 78 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v9",.number = 79 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	// Function arguments/return values
	{.name = "v10",.number = 80 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 81 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 82 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 83 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 84 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 85 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 86 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v10",.number = 87 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v11",.number = 88 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 89 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 90 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 91 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 92 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 93 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 94 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v11",.number = 95 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v12",.number = 96 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 97 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 98 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 99 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 100 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 101 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 102 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v12",.number = 103 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v13",.number = 104 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 105 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 106 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 107 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 108 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 109 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 110 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v13",.number = 111 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v14",.number = 112 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 113 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 114 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 115 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 116 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 117 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 118 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v14",.number = 119 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v15",.number = 120 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 121 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 122 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 123 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 124 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 125 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 126 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v15",.number = 127 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v16",.number = 128 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 129 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 130 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 131 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 132 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 133 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 134 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v16",.number = 135 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v17",.number = 136 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 137 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 138 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 139 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 140 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 141 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 142 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v17",.number = 143 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v18",.number = 144 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 145 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 146 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 147 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 148 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 149 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 150 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v18",.number = 151 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v19",.number = 152 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 153 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 154 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 155 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 156 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 157 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 158 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v19",.number = 159 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v20",.number = 160 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 161 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 162 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 163 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 164 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 165 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 166 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v20",.number = 167 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v21",.number = 168 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 169 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 170 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 171 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 172 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 173 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 174 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v21",.number = 175 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v22",.number = 176 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 177 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 178 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 179 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 180 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 181 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 182 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v22",.number = 183 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v23",.number = 184 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 185 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 186 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 187 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 188 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 189 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 190 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v23",.number = 191 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v24",.number = 192 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 193 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 194 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 195 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 196 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 197 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 198 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v24",.number = 199 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v25",.number = 200 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 201 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 202 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 203 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 204 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 205 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 206 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v25",.number = 207 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v26",.number = 208 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 209 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 210 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 211 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 212 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 213 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 214 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v26",.number = 215 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v27",.number = 216 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 217 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 218 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 219 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 220 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 221 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 222 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v27",.number = 223 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v28",.number = 224 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 225 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 226 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 227 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 228 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 229 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 230 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v28",.number = 231 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v29",.number = 232 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 233 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 234 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 235 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 236 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 237 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 238 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v29",.number = 239 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v30",.number = 240 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 241 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 242 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 243 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 244 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 245 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 246 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v30",.number = 247 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

	{.name = "v31",.number = 248 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 249 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 250 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 251 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 252 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 253 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 254 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},
	{.name = "v31",.number = 255 + RISCV_regnum_V_first,.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_v_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_V_regs_name},

};

static char const def_CSR_regs_name[] = "system";
static reg const CSR_not_exists = {.name = "",.caller_save = false,.dirty = false,.valid = false,.exist = true,.size = XLEN,.type = &reg_csr_accessors,.feature = &feature_riscv_org,.reg_data_type = &GP_reg_data_type,.group = def_CSR_regs_name};
static char csr_names[4096][50] = {[0 ... 4095] = {'\0'}};

static void
init_csr_names(void)
{
	static bool csr_names_inited = false;

	if (!csr_names_inited) {
		for (int i = 0; i < 4096; ++i) {
			sprintf(csr_names[i], "csr%d", i);
		}

		csr_names_inited = true;
	}
}

static reg_cache*
reg_cache__CSR_section_create_gdb(char const* name, void* const p_arch_info)
{
	init_csr_names();
	assert(name);
	reg* const p_dst_array = calloc(4096, sizeof(reg));
	{
		for (size_t i = 0; i < 4096; ++i) {
			reg* p_reg = &p_dst_array[i];
			*p_reg = CSR_not_exists;
			// TODO cleanup
			p_reg->name = csr_names[i];
			p_reg->number = i + RISCV_regnum_CSR_first;
			p_reg->value = calloc(1, NUM_BYTES_FOR_BITS(p_reg->size));;
			p_reg->arch_info = p_arch_info;
		}
	}
	reg_cache const the_reg_cache = {
		.name = name,
		.reg_list = p_dst_array,
		.num_regs = 4096,
	};

	reg_cache* const p_obj = calloc(1, sizeof(reg_cache));
	assert(p_obj);
	*p_obj = the_reg_cache;
	return p_obj;
}

void
sc_riscv32__init_regs_cache(target* const p_target)
{
	assert(p_target);
	p_target->reg_cache = reg_cache__section_create(def_GP_regs_name, def_GP_regs_array, ARRAY_LEN(def_GP_regs_array), p_target);
	reg_cache* p_reg_cache_last = p_target->reg_cache;
	p_reg_cache_last = p_reg_cache_last->next = reg_cache__section_create(def_FPU_regs_name, def_FP_regs_array, ARRAY_LEN(def_FP_regs_array), p_target);
	p_reg_cache_last = p_reg_cache_last->next = reg_cache__CSR_section_create_gdb(def_CSR_regs_name, p_target);
	p_reg_cache_last->next = reg_cache__section_create(def_V_regs_name, def_V_regs_array, ARRAY_LEN(def_V_regs_array), p_target);
}

void
sc_riscv32__deinit_target(target* const p_target)
{
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);

	while (p_target->reg_cache) {
		reg_cache* const p_reg_cache = p_target->reg_cache;
		p_target->reg_cache = p_target->reg_cache->next;
		reg* const reg_list = p_reg_cache->reg_list;
		assert(!p_reg_cache->num_regs || reg_list);

		for (unsigned i = 0; i < p_reg_cache->num_regs; ++i) {
			free(reg_list[i].value);
		}

		free(reg_list);

		free(p_reg_cache);
	}

	if (p_target->arch_info) {
		free(p_target->arch_info);
		p_target->arch_info = NULL;
	}
}

error_code
sc_riscv32__target_create(target* const p_target, Jim_Interp* interp)
{
	assert(p_target);
	return ERROR_OK;
}

static error_code
adjust_target_registers_cache(target* const p_target)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	bool const RV_D = 0 != (p_arch->misa & BIT_MASK('D' - 'A'));
	bool const RV_F = 0 != (p_arch->misa & BIT_MASK('F' - 'A'));
	assert(!!(0 != (p_arch->misa & BIT_MASK('I' - 'A'))) ^ !!(0 != (p_arch->misa & BIT_MASK('E' - 'A'))));
	assert(p_target->reg_cache && p_target->reg_cache->reg_list && 33 == p_target->reg_cache->num_regs);
	{
		reg* const p_regs = p_target->reg_cache->reg_list;

		for (int i = 0; i < 32; ++i) {
			p_regs[i].dirty = false;
			p_regs[i].valid = false;
		}
	}

	if (RV_D) {
		assert(RV_F);
		assert(p_target->reg_cache && p_target->reg_cache->next && p_target->reg_cache->next->reg_list && 32 == p_target->reg_cache->next->num_regs);
		reg* const p_regs = p_target->reg_cache->next->reg_list;

		for (int i = 0; i < 32; ++i) {
			reg* const p_reg = &p_regs[i];
			p_reg->exist = true;
			p_reg->size = 64;
			p_reg->type = &reg_FPU_D_accessors;
			p_reg->reg_data_type = &FPU_D_reg_data_type;
		}

		LOG_INFO("Enable RVFD FPU registers");
	} else if (RV_F) {
		assert(p_target->reg_cache && p_target->reg_cache->next && p_target->reg_cache->next->reg_list && 32 == p_target->reg_cache->next->num_regs);
		reg* const p_regs = p_target->reg_cache->next->reg_list;

		for (int i = 0; i < 32; ++i) {
			reg* const p_reg = &p_regs[i];
			p_reg->exist = true;
			p_reg->size = 32;
			p_reg->type = &reg_FPU_S_accessors;
			p_reg->reg_data_type = &FPU_S_reg_data_type;
		}

		LOG_INFO("Enable RVF FPU registers");
	}

	return sc_error_code__get(p_target);
}

error_code
sc_riscv32__examine(target* const p_target)
{
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);

	for (int i = 0; i < 10; ++i) {
		sc_error_code__get_and_clear(p_target);

		if (ERROR_OK == sc_riscv32__update_status(p_target)) {
			break;
		}

		LOG_DEBUG("update_status error, retry");
	}

	if (ERROR_OK == sc_error_code__get(p_target)) {
		uint32_t IDCODE;
		sc_rv32_IDCODE_get(p_target, &IDCODE);

		if (!sc_rv32__is_IDCODE_valid(p_target, IDCODE)) {
			LOG_ERROR("Invalid IDCODE=0x%08" PRIX32 "!", IDCODE);
			sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
		} else {
			uint32_t DBG_ID;
			sc_rv32_DBG_ID_get(p_target, &DBG_ID);

			if (!sc_rv32__is_DBG_ID_valid(p_target, DBG_ID)) {
				LOG_ERROR("Unsupported DBG_ID=0x%08" PRIX32 "!", DBG_ID);
				sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
			} else {
				uint32_t BLD_ID;
				sc_rv32_BLD_ID_get(p_target, &BLD_ID);
				LOG_INFO("IDCODE=0x%08" PRIX32 " DBG_ID=0x%08" PRIX32 " BLD_ID=0x%08" PRIX32, IDCODE, DBG_ID, BLD_ID);

				sc_riscv32__Arch* const p_arch = p_target->arch_info;
				assert(p_arch);

				if (
					ERROR_OK == get_ISA(p_target, &p_arch->misa) &&
					ERROR_OK == set_DEMODE_ENBL(p_target, HART_DMODE_ENBL_bits_Normal) &&
					ERROR_OK == adjust_target_registers_cache(p_target)
				) {
					LOG_DEBUG("Examined OK");
					target_set_examined(p_target);
				}
			}
		}
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__poll(target* const p_target)
{
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);
	sc_riscv32__update_status(p_target);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__arch_state(target* const p_target)
{
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);
	sc_riscv32__update_status(p_target);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__halt(target* const p_target)
{
	assert(p_target);
	invalidate_DAP_CTR_cache(p_target);
	// May be already halted?
	{
		if (ERROR_OK != sc_riscv32__update_status(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}

		if (p_target->state == TARGET_HALTED) {
			LOG_WARNING("Halt request when target is already in halted state");
			return sc_error_code__get_and_clear(p_target);
		}
	}

	// Try to halt
	{
		if (ERROR_OK != sc_rv32_DAP_CTRL_REG_set(p_target, p_target->coreid == 0 ? DBGC_unit_id_HART_0 : DBGC_unit_id_HART_1, DBGC_functional_group_HART_DBGCMD)) {
			LOG_WARNING("DAP_CTRL_REG_set error");
			return sc_error_code__get_and_clear(p_target);
		}

		if (ERROR_OK != sc_rv32_DAP_CMD_scan(p_target, DBG_CTRL_index, DBG_CTRL_bit_Halt | DBG_CTRL_bit_Sticky_Clr, NULL)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	sc_rv32_check_that_target_halted(p_target);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__resume(target* const p_target,
				   int const current,
				   target_addr_t const _address,
				   int const handle_breakpoints,
				   int const debug_execution)
{
	assert((UINT32_MAX & _address) == _address);
	invalidate_DAP_CTR_cache(p_target);
	uint32_t const address = (uint32_t)(_address);
	LOG_DEBUG("resume:"
			  " current=%d"
			  " address=0x%08" PRIx32
			  " handle_breakpoints=%d"
			  " debug_execution=%d",
			  current,
			  address,
			  handle_breakpoints,
			  debug_execution);
	assert(p_target);
	static uint32_t const dmode_enabled = HART_DMODE_ENBL_bits_Normal;
	return resume_common(p_target, dmode_enabled, current, address, handle_breakpoints, debug_execution);
}

error_code
sc_riscv32__step(target* const p_target,
				 int const current,
				 target_addr_t const _address,
				 int const handle_breakpoints)
{
	assert((UINT32_MAX & _address) == _address);
	invalidate_DAP_CTR_cache(p_target);
	uint32_t const address = (uint32_t)(_address);
	LOG_DEBUG("step:"
			  " current=%d"
			  " address=0x%08" PRIx32
			  " handle_breakpoints=%d",
			  current,
			  address,
			  handle_breakpoints);
	assert(p_target);
	// disable halt on SW breakpoint to pass SW breakpoint processing to core
	static uint32_t const dmode_enabled = (HART_DMODE_ENBL_bits_Normal & ~HART_DMODE_ENBL_bit_Brkpt) | HART_DMODE_ENBL_bit_SStep;
	return resume_common(p_target, dmode_enabled, current, address, handle_breakpoints, false);
}

error_code
sc_riscv32__soft_reset_halt(target* const p_target)
{
	LOG_DEBUG("Soft reset halt called");
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_riscv32__update_status(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	// Halt before reset
	if (TARGET_HALTED != p_target->state) {
		target_halt(p_target);
	}

	set_DEMODE_ENBL(p_target, HART_DMODE_ENBL_bits_Normal | HART_DMODE_ENBL_bit_Rst_Exit);
	sc_rv32_core_reset__set(p_target, true);
	sc_rv32_core_reset__set(p_target, false);
	return sc_error_code__get_and_clear(p_target);
}

static error_code
scrv32_sys_reset__set(target* const p_target, bool const active)
{
	jtag_add_tlr();
	IR_select(p_target, TAP_instruction_SYS_CTRL);
	uint8_t out = active ? 1 : 0;
	scan_field const field = {
		.num_bits = TAP_length_of_SYS_CTRL,
		.out_value = &out,
	};
	assert(p_target->tap);
	jtag_add_dr_scan(p_target->tap, 1, &field, TAP_IDLE);
	sc_error_code__update(p_target, jtag_execute_queue());
	LOG_DEBUG("drscan %s %d 0x%1X", p_target->cmd_name, field.num_bits, *field.out_value);
	jtag_add_tlr();

	if (active) {
		p_target->state = TARGET_RESET;
		target_call_event_callbacks(p_target, TARGET_EVENT_RESET_ASSERT);
	} else {
		p_target->state = TARGET_UNKNOWN;
		target_call_event_callbacks(p_target, TARGET_EVENT_RESET_DEASSERT_PRE);
	}

	return sc_error_code__get(p_target);
}

error_code
sc_riscv32__assert_reset(target* const p_target)
{
	LOG_DEBUG("Assert reset");
	invalidate_DAP_CTR_cache(p_target);
	scrv32_sys_reset__set(p_target, true);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__deassert_reset(target* const p_target)
{
	LOG_DEBUG("Deassert reset");
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK == scrv32_sys_reset__set(p_target, false) && p_target->reset_halt) {
		return sc_riscv32__soft_reset_halt(p_target);
	}

	sc_riscv32__update_status(p_target);
	return sc_error_code__get_and_clear(p_target);
}

static error_code
read_memory_space(target* const p_target,
				  uint32_t address,
				  uint32_t const size,
				  uint32_t count,
				  uint8_t* p_buffer,
				  bool const instruction_space)
{
	if (!(size == 1 || size == 2 || size == 4)) {
		LOG_ERROR("Invalid item size %" PRIu32, size);
		return sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
	} else if (address % size != 0) {
		LOG_ERROR("Unaligned access at 0x%08" PRIX32 ", for item size %" PRIu32, address, size);
		return sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
	} else {
		while (0 != count) {
			target_addr_t physical;
			uint32_t bound;
			sc_riscv32__Arch const* const p_arch = p_target->arch_info;
			assert(p_arch);

			if (ERROR_OK != p_arch->constants->virt_to_phis(p_target, address, &physical, &bound, instruction_space)) {
				break;
			}

			uint32_t const page_count = size * count > bound ? bound / size : count;
			assert(0 != page_count);
			assert(p_buffer);

			if (ERROR_OK != sc_error_code__update(p_target, target_read_phys_memory(p_target, physical, size, page_count, p_buffer))) {
				break;
			}

			uint32_t const bytes = size * page_count;
			p_buffer += bytes;
			address += bytes;
			count -= page_count;
		}
	}

	return sc_error_code__get(p_target);
}

static error_code
write_memory_space(target* const p_target,
				   uint32_t address,
				   uint32_t const size,
				   uint32_t count,
				   uint8_t const* p_buffer,
				   bool const instruction_space)
{
	if (!(size == 1 || size == 2 || size == 4)) {
		LOG_ERROR("Invalid item size %" PRIu32, size);
		return sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
	} else if (address % size != 0) {
		LOG_ERROR("Unaligned access at 0x%08" PRIx32 ", for item size %" PRIu32, address, size);
		return sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
	} else {
		while (0 != count) {
			target_addr_t physical;
			uint32_t bound;
			sc_riscv32__Arch const* const p_arch = p_target->arch_info;
			assert(p_arch);

			if (ERROR_OK != p_arch->constants->virt_to_phis(p_target, address, &physical, &bound, instruction_space)) {
				break;
			}

			uint32_t const page_count = size * count > bound ? bound / size : count;
			assert(0 != page_count);
			assert(p_buffer);

			if (ERROR_OK != sc_error_code__update(p_target, target_write_phys_memory(p_target, physical, size, page_count, p_buffer))) {
				break;
			}

			uint32_t const bytes = size * page_count;
			p_buffer += bytes;
			address += bytes;
			count -= page_count;
		}
	}

	return sc_error_code__get(p_target);
}

error_code
sc_riscv32__read_memory(target* const p_target,
						target_addr_t address,
						uint32_t const size,
						uint32_t count,
						uint8_t* buffer)
{
	assert((UINT32_MAX & address) == address);
	invalidate_DAP_CTR_cache(p_target);
	read_memory_space(p_target, (uint32_t)(address), size, count, buffer, false);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__write_memory(target* const p_target,
						 target_addr_t address,
						 uint32_t const size,
						 uint32_t count,
						 uint8_t const* buffer)
{
	assert((UINT32_MAX & address) == address);
	invalidate_DAP_CTR_cache(p_target);
	write_memory_space(p_target, (uint32_t)(address), size, count, buffer, false);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__read_phys_memory(target* const p_target,
							 target_addr_t _address,
							 uint32_t const size,
							 uint32_t count,
							 uint8_t* buffer)
{
	assert((UINT32_MAX & _address) == _address);
	uint32_t address = (uint32_t)(_address);
	LOG_DEBUG("Read_memory"
			  " at 0x%08" PRIx32
			  ", %" PRIu32 " items"
			  ", each %" PRIu32 " bytes"
			  ", total %" PRIu64 " bytes", address, count, size, (uint64_t)(count)* size);

	invalidate_DAP_CTR_cache(p_target);

	/// Check for size
	if (!(size == 1 || size == 2 || size == 4)) {
		LOG_ERROR("Invalid item size %" PRIu32, size);
		sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
		return sc_error_code__get_and_clear(p_target);
	} else if (address % size != 0) {
		LOG_ERROR("Unaligned access"
				  " at 0x%08" PRIx32
				  ", for item size %" PRIu32,
				  address,
				  size);
		sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
		return sc_error_code__get_and_clear(p_target);
	} else if (0 == count) {
		LOG_WARNING("Zero items count");
		return sc_error_code__get_and_clear(p_target);
	} else if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	} else {
		/// Reserve work register
		reg* const p_wrk_reg = prepare_temporary_GP_register(p_target, 0);
		assert(p_wrk_reg);

		uint32_t pc_sample_1;

		if (ERROR_OK == sc_rv32_get_PC(p_target, &pc_sample_1)) {
			/// Define opcode function for load item to register
			typedef rv_instruction32_type
			(*load_func_type)(reg_num_type rd, reg_num_type rs1, riscv_short_signed_type imm);
			load_func_type const load_OP =
				size == 4 ? &RISCV_opcode_LW :
				size == 2 ? &RISCV_opcode_LH :
				/*size == 1*/&RISCV_opcode_LB;

			sc_riscv32__Arch const* const p_arch = p_target->arch_info;
			assert(p_arch);
			sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

			/// Setup exec operations mode
			if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
				assert(buffer);

				/// For count number of items do loop
				while (count--) {
					/// Set address to CSR
					if (ERROR_OK != sc_rv32_EXEC__push_data_to_CSR(p_target, address)) {
						break;
					}

					/// Load address to work register
					if (ERROR_OK != sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_wrk_reg->number, p_arch->constants->debug_scratch_CSR), NULL)) {
						break;
					}

					/// Exec load item to register
					if (ERROR_OK != sc_rv32_EXEC__step(p_target, load_OP(p_wrk_reg->number, p_wrk_reg->number, 0), NULL)) {
						break;
					}

					/// Exec store work register to csr
					sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRW(p_arch->constants->debug_scratch_CSR, p_wrk_reg->number), NULL);

					/// Exec NOP instruction and get previous instruction CSR result.
					uint32_t value;

					if (ERROR_OK != sc_rv32_EXEC__step(p_target, RISCV_OPCODE_NOP(), &value)) {
						break;
					}

					/// store read data to buffer
					buf_set_u32(buffer, 0, CHAR_BIT * size, value);

					/// advance src/dst pointers
					address += size;
					buffer += size;
				}
			}

			sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
		}

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return sc_error_code__get_and_clear(p_target);
			}
		}

		sc_rv32_check_PC_value(p_target, pc_sample_1);

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return sc_error_code__get_and_clear(p_target);
			}
		}

		/// restore temporary register
		error_code const old_err_code = sc_error_code__get_and_clear(p_target);
		sc_error_code__update(p_target, reg_x__store(p_wrk_reg));
		sc_error_code__prepend(p_target, old_err_code);
		assert(!p_wrk_reg->dirty);

		return sc_error_code__get_and_clear(p_target);
	}
}

error_code
sc_riscv32__write_phys_memory(target* const p_target,
							  target_addr_t _address,
							  uint32_t const size,
							  uint32_t count,
							  uint8_t const* buffer)
{
	assert((UINT32_MAX & _address) == _address);
	uint32_t address = (uint32_t)(_address);
	LOG_DEBUG("Write_memory"
			  " at 0x%08" PRIx32
			  ", %" PRIu32 " items"
			  ", each %" PRIu32 " bytes"
			  ", total %" PRIu64 " bytes",
			  address,
			  count,
			  size,
			  (uint64_t)(count)* size);

	invalidate_DAP_CTR_cache(p_target);

	/// Check for size
	if (!(size == 1 || size == 2 || size == 4)) {
		LOG_ERROR("Invalid item size %" PRIu32, size);
		sc_error_code__update(p_target, ERROR_TARGET_FAILURE);
		return sc_error_code__get_and_clear(p_target);
	}

	/// Check for alignment
	if (address % size != 0) {
		LOG_ERROR("Unaligned access"
				  " at 0x%08" PRIx32
				  ", for item size %" PRIu32,
				  address,
				  size);
		sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
		return sc_error_code__get_and_clear(p_target);
	}

	if (0 == count) {
		LOG_WARNING("Zero items count");
		return sc_error_code__get_and_clear(p_target);
	}

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	uint32_t pc_sample_1;

	if (ERROR_OK != sc_rv32_get_PC(p_target, &pc_sample_1)) {
		return sc_error_code__get_and_clear(p_target);
	}

	/// Reserve work register
	reg* const p_addr_reg = prepare_temporary_GP_register(p_target, 0);
	assert(p_addr_reg);
	reg* const p_data_reg = prepare_temporary_GP_register(p_target, p_addr_reg->number);
	assert(p_data_reg);
	assert(p_addr_reg->number != p_data_reg->number);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		sc_riscv32__Arch const* const p_arch = p_target->arch_info;
		assert(p_arch);
		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, HART_DBG_CTRL_bit_PC_Advmt_Dsbl);

		/// Setup exec operations mode
		if (ERROR_OK == sc_rv32_EXEC__setup(p_target)) {
			rv_instruction32_type
			(*store_item_opcode)(reg_num_type rs, reg_num_type rs1, riscv_short_signed_type imm) =
				size == 4 ? &RISCV_opcode_SW :
				size == 2 ? &RISCV_opcode_SH :
				/*size == 1*/ &RISCV_opcode_SB;

			// Set address to CSR
			// Load address to work register
			if (
				ERROR_OK == sc_rv32_EXEC__push_data_to_CSR(p_target, address - INT12_MIN) &&
				ERROR_OK == sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_addr_reg->number, p_arch->constants->debug_scratch_CSR), NULL)
			) {
				riscv_short_signed_type offset = INT12_MIN;

				if (p_arch->constants->use_queuing_for_dr_scans) {
					uint8_t DAP_OPSTATUS = 0;
					uint8_t const data_wr_opcode[1] = {DBGDATA_WR_index};
					static uint8_t const DAP_OPSTATUS_GOOD = DAP_status_good;
					static uint8_t const DAP_STATUS_MASK = DAP_status_mask;
					scan_field const data_scan_opcode_field = {
						.num_bits = TAP_length_of_DAP_CMD_OPCODE,
						.out_value = data_wr_opcode,
						.in_value = &DAP_OPSTATUS,
						.check_value = &DAP_OPSTATUS_GOOD,
						.check_mask = &DAP_STATUS_MASK,
					};
					scan_field data_scan_fields[TAP_number_of_fields_DAP_CMD] = {{.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT}, data_scan_opcode_field,};
					uint8_t const instr_exec_opcode[1] = {CORE_EXEC_index};
					scan_field const instr_scan_opcode_field = {
						.num_bits = TAP_length_of_DAP_CMD_OPCODE,
						.out_value = instr_exec_opcode,
						.in_value = &DAP_OPSTATUS,
						.check_value = &DAP_OPSTATUS_GOOD,
						.check_mask = &DAP_STATUS_MASK,
					};

					assert(buffer);
					data_scan_fields[0].out_value = buffer;

					while (ERROR_OK == sc_error_code__get(p_target) && 0 < count) {
						assert(p_target->tap);
						data_scan_fields[0].out_value = buffer;
						jtag_add_dr_scan_check(p_target->tap, ARRAY_LEN(data_scan_fields), data_scan_fields, TAP_IDLE);

						{
							uint8_t instr_buf[sizeof(uint32_t)];
							buf_set_u32(instr_buf, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, RISCV_OPCODE_CSRR(p_data_reg->number, p_arch->constants->debug_scratch_CSR));
							scan_field const fld = {.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = instr_buf};
							scan_field instr_fields[TAP_number_of_fields_DAP_CMD];
							instr_fields[0] = fld;
							instr_fields[1] = instr_scan_opcode_field;
							jtag_add_dr_scan_check(p_target->tap, TAP_number_of_fields_DAP_CMD, instr_fields, TAP_IDLE);
						}

						{
							uint8_t instr_buf[sizeof(uint32_t)];
							buf_set_u32(instr_buf, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, store_item_opcode(p_data_reg->number, p_addr_reg->number, offset));
							scan_field const fld = {.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = instr_buf};
							scan_field instr_fields[TAP_number_of_fields_DAP_CMD];
							instr_fields[0] = fld;
							instr_fields[1] = instr_scan_opcode_field;
							jtag_add_dr_scan_check(p_target->tap, TAP_number_of_fields_DAP_CMD, instr_fields, TAP_IDLE);
						}

						offset += (riscv_short_signed_type)size;
						buffer += size;
						--count;

						if (0 == count) {
							LOG_DEBUG("Force jtag_execute_queue() - last time");
							sc_error_code__update(p_target, jtag_execute_queue());
							break;
						}

						if (p_arch->constants->use_separate_items) {
							if (ERROR_OK != sc_error_code__update(p_target, jtag_execute_queue())) {
								break;
							}
						}

						if (offset <= INT12_MAX) {
							continue;
						}

						{
							uint8_t instr_buf[sizeof(uint32_t)];
							buf_set_u32(instr_buf, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, RISCV_OPCODE_LUI(p_data_reg->number, 1 << 12));
							scan_field const fld = {.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = instr_buf};
							scan_field instr_fields[TAP_number_of_fields_DAP_CMD];
							instr_fields[0] = fld;
							instr_fields[1] = instr_scan_opcode_field;
							jtag_add_dr_scan_check(p_target->tap, TAP_number_of_fields_DAP_CMD, instr_fields, TAP_IDLE);
						}

						{
							uint8_t instr_buf[sizeof(uint32_t)];
							buf_set_u32(instr_buf, 0, TAP_length_of_DAP_CMD_OPCODE_EXT, RISCV_OPCODE_ADD(p_addr_reg->number, p_addr_reg->number, p_data_reg->number));
							scan_field const fld = {.num_bits = TAP_length_of_DAP_CMD_OPCODE_EXT,.out_value = instr_buf};
							scan_field instr_fields[TAP_number_of_fields_DAP_CMD];
							instr_fields[0] = fld;
							instr_fields[1] = instr_scan_opcode_field;
							jtag_add_dr_scan_check(p_target->tap, TAP_number_of_fields_DAP_CMD, instr_fields, TAP_IDLE);
						}

						offset -= 1 << 12;

						LOG_DEBUG("Force jtag_execute_queue()");

						if (ERROR_OK != sc_error_code__update(p_target, jtag_execute_queue())) {
							break;
						}

						LOG_DEBUG("jtag_execute_queue() - OK");
					}
				} else {
					while (ERROR_OK == sc_error_code__get(p_target) && 0 < count) {
						/// Set data to CSR
						if (
							ERROR_OK != sc_rv32_EXEC__push_data_to_CSR(p_target, buf_get_u32(buffer, 0, CHAR_BIT * size)) ||
							ERROR_OK != sc_rv32_EXEC__step(p_target, RISCV_OPCODE_CSRR(p_data_reg->number, p_arch->constants->debug_scratch_CSR), NULL) ||
							ERROR_OK != sc_rv32_EXEC__step(p_target, store_item_opcode(p_data_reg->number, p_addr_reg->number, offset), NULL)
						) {
							break;
						}

						offset += (riscv_short_signed_type)size;
						buffer += size;
						--count;

						if (offset <= INT12_MAX) {
							continue;
						}

						if (
							ERROR_OK != sc_rv32_EXEC__step(p_target, RISCV_OPCODE_LUI(p_data_reg->number, 1 << 12), NULL) &&
							ERROR_OK != sc_rv32_EXEC__step(p_target, RISCV_OPCODE_ADD(p_addr_reg->number, p_addr_reg->number, p_data_reg->number), NULL)
						) {
							break;
						}

						offset -= 1 << 12;
					}
				}
			}
		}

		if (ERROR_OK != sc_error_code__get(p_target)) {
			sc_riscv32__update_status(p_target);

			if (!target_was_examined(p_target)) {
				return sc_error_code__get_and_clear(p_target);
			}
		}

		sc_rv32_HART_REGTRANS_write_and_check(p_target, HART_DBG_CTRL_index, 0);
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	sc_rv32_check_PC_value(p_target, pc_sample_1);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);

		if (!target_was_examined(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}
	}

	/// restore temporary registers
	error_code const old_err_code = sc_error_code__get_and_clear(p_target);
	error_code const new_err_code_1 = reg_x__store(p_data_reg);
	assert(!p_data_reg->dirty);
	error_code const new_err_code_2 = reg_x__store(p_addr_reg);
	assert(!p_addr_reg->dirty);
	sc_error_code__update(p_target, old_err_code);
	sc_error_code__update(p_target, new_err_code_1);
	sc_error_code__update(p_target, new_err_code_2);

	return sc_error_code__get_and_clear(p_target);
}

/**
@pre target is halted
@pre p_breakpoint->length is checked
@pre p_breakpoint->address is checked
*/
static inline error_code
add_sw_breakpoint(target* const p_target,
				  breakpoint* const p_breakpoint)
{
	assert(p_target);

	if (ERROR_OK != read_memory_space(p_target, (uint32_t)(p_breakpoint->address), 2, p_breakpoint->length / 2, p_breakpoint->orig_instr, true)) {
		LOG_ERROR("Can't save original instruction");
	} else {
		uint8_t buffer[4];

		if (p_breakpoint->length == 4) {
			target_buffer_set_u32(p_target, buffer, RISCV_OPCODE_EBREAK());
		} else if (p_breakpoint->length == 2) {
			target_buffer_set_u16(p_target, buffer, RISCV_OPCODE_C_EBREAK());
		} else {
			assert(/*logic_error:Bad breakpoint size*/ 0);
		}

		if (ERROR_OK != write_memory_space(p_target, p_breakpoint->address, 2, p_breakpoint->length / 2, buffer, true)) {
			LOG_ERROR("Can't write EBREAK");
		} else {
			p_breakpoint->set = 1;
		}
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__add_breakpoint(target* const p_target,
						   breakpoint* const p_breakpoint)
{
	bool const RVC_enable = is_RVC_enable(p_target);
	assert(p_breakpoint);

	if (!(4 == p_breakpoint->length || (RVC_enable && 2 == p_breakpoint->length))) {
		LOG_ERROR("Invalid breakpoint length: %d", p_breakpoint->length);
		sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
	} else if (p_breakpoint->address % (RVC_enable ? 2 : 4) != 0) {
		LOG_ERROR("Unaligned breakpoint: 0x%08" TARGET_PRIxADDR, p_breakpoint->address);
		sc_error_code__update(p_target, ERROR_TARGET_UNALIGNED_ACCESS);
	} else {
		invalidate_DAP_CTR_cache(p_target);

		if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}

		assert(p_breakpoint);

		switch (p_breakpoint->type) {
		case BKPT_SOFT:
			return add_sw_breakpoint(p_target, p_breakpoint);

		default:
			LOG_ERROR("Unsupported breakpoint type");
			sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
		}
	}

	return sc_error_code__get_and_clear(p_target);
}

enum BRKM_csrs_base
{
	BRKM_csr_base = 0x7C0
};

typedef enum BRKM_csr_indexes
{
	BPSELECT = 0,
	BPCONTROL = 1,
	BPLOADDR = 2,
	BPHIADDR = 3,
	BPLODATA = 4,
	BPHIDATA = 5,
	BPCTRLEXT = 6,
	BRKMCTRL = 7,
} BRKM_csr_indexes;

typedef enum BPCONTROL_bits
{
	BPCONTROL_DMASKEN = 1,
	BPCONTROL_DRANGEEN = 2,
	BPCONTROL_DEN = 3,

	BPCONTROL_AMASKEN = 5,
	BPCONTROL_ARANGEEN = 6,
	BPCONTROL_AEN = 7,

	BPCONTROL_EXECEN = 8,
	BPCONTROL_STOREEN = 9,
	BPCONTROL_LOADEN = 10,

	/**
	From the EAS:

	Action. Determines what happens when this breakpoint matches:

	0: means nothing happens

	1: means cause a debug exception

	2: means enter Debug Mode

	Other values are reserved for future use
	*/
	///@{
	BPCONTROL_ACTION_LOW = 12,
	BPCONTROL_ACTION_HIGH = 14,
	///@}

	BPCONTROL_MATCHED = 15,

	BPCONTROL_DMASKSUP = 17,
	BPCONTROL_DRANGESUP = 18,
	BPCONTROL_DSUP = 19,

	BPCONTROL_AMASKSUP = 21,
	BPCONTROL_ARANGESUP = 22,
	BPCONTROL_ASUP = 23,

	BPCONTROL_EXECSUP = 24,
	BPCONTROL_STORESUP = 25,
	BPCONTROL_LOADSUP = 26,

} BPCONTROL_bits;

typedef enum BPCTRLEXT_bits
{
	BPCTRLEXT_AMASKEXT_EN = 14,
	BPCTRLEXT_ARANGEEXT_EN = 15,
} BPCTRLEXT_bits;

static error_code
BRKM_csr_set(target* const p_target,
			 BRKM_csr_indexes const idx,
			 uint32_t const value)
{
	assert(p_target);
	assert(p_target->reg_cache && p_target->reg_cache->next && p_target->reg_cache->next->next && 4096 == p_target->reg_cache->next->next->num_regs && p_target->reg_cache->next->next->reg_list);
	// TODO: define BRKM csr 0x7C0
	reg* const p_bpselect = p_target->reg_cache->next->next->reg_list + 0x7C0 + idx;
	p_bpselect->dirty = false;
	p_bpselect->valid = false;
	uint8_t buffer[XLEN / CHAR_BIT];
	buf_set_u32(buffer, 0, XLEN, value);
	return sc_error_code__update(p_target, reg_csr__set(p_bpselect, buffer));
}

static error_code
BRKM_csr_get(target* const p_target,
			 BRKM_csr_indexes const idx,
			 uint32_t* p_value)
{
	assert(p_target);
	assert(p_target->reg_cache && p_target->reg_cache->next && p_target->reg_cache->next->next && 4096 == p_target->reg_cache->next->next->num_regs && p_target->reg_cache->next->next->reg_list);
	// TODO: define BRKM csr 0x7C0
	reg* const p_bpselect = p_target->reg_cache->next->next->reg_list + 0x7C0 + idx;
	p_bpselect->dirty = false;
	p_bpselect->valid = false;
	static_assert(XLEN <= CHAR_BIT * sizeof(uint32_t), "Unsupported XLEN");

	if (ERROR_OK != sc_error_code__update(p_target, reg_csr__get(p_bpselect))) {
		LOG_ERROR("Error read CSR");
	} else {
		assert(p_value);
		*p_value = buf_get_u32(p_bpselect->value, 0, XLEN);
	}

	return sc_error_code__get(p_target);
}

static uint32_t const BRKM_channel_busy_mask =
BIT_MASK(BPCONTROL_DMASKEN) |
BIT_MASK(BPCONTROL_DRANGEEN) |
BIT_MASK(BPCONTROL_DEN) |
BIT_MASK(BPCONTROL_AMASKEN) |
BIT_MASK(BPCONTROL_ARANGEEN) |
BIT_MASK(BPCONTROL_AEN) |
BIT_MASK(BPCONTROL_EXECEN) |
BIT_MASK(BPCONTROL_STOREEN) |
BIT_MASK(BPCONTROL_LOADEN);

static uint32_t
find_BRKM_free_channel(target* const p_target,
					   uint32_t* const p_bpcontrol)
{
	// TODO: replace 12 bits of BPSELECT
	for (uint32_t channel = 0; channel < BIT_MASK(12); ++channel) {
		if (ERROR_OK != BRKM_csr_set(p_target, BPSELECT, channel)) {
			LOG_ERROR("Error in BRKM select channel #%" PRIu32, channel);
			return UINT32_MAX;
		} else if (ERROR_OK != BRKM_csr_get(p_target, BPCONTROL, p_bpcontrol)) {
			LOG_ERROR("Error read BRKM BPCONTROL for channel #%" PRIu32, channel);
			return UINT32_MAX;
		} else if (0 == (BRKM_channel_busy_mask & *p_bpcontrol)) {
			LOG_DEBUG("BRKM channel %" PRIu32 " is free", channel);
			return channel;
		}

		// channel busy, find next
		LOG_DEBUG("BRKM channel %" PRIu32 " is busy", channel);
	}

	LOG_ERROR("No free BRKM channels");
	sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	return UINT32_MAX;
}

static target_debug_reason
BRKM_reason_get(target* const p_target)
{
	assert(p_target);

	bool bp = false;
	bool wp = false;

	for (uint32_t channel = 0; channel < BIT_MASK(12); ++channel) {
		if (ERROR_OK != BRKM_csr_set(p_target, BPSELECT, channel)) {
			LOG_ERROR("Error in BRKM select channel #%" PRIu32, channel);
			break;
		}

		uint32_t bpcontrol = 0;

		if (ERROR_OK != BRKM_csr_get(p_target, BPCONTROL, &bpcontrol)) {
			LOG_ERROR("Error read BRKM BPCONTROL for channel #%" PRIu32, channel);
			break;
		}

		if (0 == (BIT_MASK(BPCONTROL_ASUP) & bpcontrol)) {
			break;
		}

		if (0 != (BIT_MASK(BPCONTROL_MATCHED) & bpcontrol)) {
			if (0 == (BIT_MASK(BPCONTROL_EXECEN)& bpcontrol)) {
				wp = true;
			} else {
				bp = true;
			}
		}
	}

	return
		bp && wp ? DBG_REASON_WPTANDBKPT :
		wp ? DBG_REASON_WATCHPOINT :
		DBG_REASON_BREAKPOINT;
}

/**
@pre target is halted
*/
static error_code
add_hw_breakpoint(target* const p_target,
				  breakpoint* const p_breakpoint)
{
	uint32_t bpcontrol = 0;
	uint32_t const channel = find_BRKM_free_channel(p_target, &bpcontrol);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	if (0 == (BIT_MASK(BPCONTROL_EXECSUP) & bpcontrol)) {
		LOG_WARNING("BRKM EXECSUP is not available for channel #%" PRIu32, channel);
		sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	} else if (0 == ((BIT_MASK(BPCONTROL_ASUP) | BIT_MASK(BPCONTROL_ARANGESUP)) & bpcontrol)) {
		LOG_WARNING("ASUP and ARANGESUP are not supported by BRKM for channel #%" PRIu32, channel);
		sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	} else if (ERROR_OK != BRKM_csr_set(p_target, BRKMCTRL, BIT_MASK(15))) {
		// TODO: BRKMCTRL, BIT_MASK(15)
		LOG_ERROR("Error: can't init BRKMCTRL");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPLOADDR, (uint32_t)(p_breakpoint->address))) {
		LOG_ERROR("Error: can't setup BPLOADDR");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPHIADDR, (uint32_t)(p_breakpoint->address) + p_breakpoint->length)) {
		LOG_ERROR("Error: can't setup BPHIADDR");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPCTRLEXT, BIT_MASK(BPCTRLEXT_ARANGEEXT_EN))) {
		LOG_ERROR("Error: can't setup BPCTRLEXT");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPCONTROL, BIT_MASK(BPCONTROL_ARANGEEN) | BIT_MASK(BPCONTROL_AEN) | BIT_MASK(BPCONTROL_EXECEN) | (2 << BPCONTROL_ACTION_LOW))) {
		// TODO: add definition for (2 << BPCONTROL_ACTION_LOW)
		LOG_ERROR("Error: can't setup BPCONTROL");
	} else {
		// OK
		LOG_DEBUG("HW breakpoint"
				  " #%" PRIu32
				  " enabled for address %" TARGET_PRIxADDR
				  " length %d",
				  channel,
				  p_breakpoint->address,
				  p_breakpoint->length);
		p_breakpoint->set = BIT_MASK(12) | channel;
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__add_breakpoint_v2(target* const p_target,
							  breakpoint* const p_breakpoint)
{
	bool const RVC_enable = is_RVC_enable(p_target);
	assert(p_breakpoint);

	if (!(
		(BKPT_SOFT == p_breakpoint->type && (4 == p_breakpoint->length || (RVC_enable && 2 == p_breakpoint->length))) ||
		(BKPT_HARD == p_breakpoint->type && p_breakpoint->length >= 0 && 0 == p_breakpoint->length % (RVC_enable ? 2 : 4))
		)) {
		LOG_ERROR("Invalid breakpoint size: %d", p_breakpoint->length);
		sc_error_code__update(p_target, ERROR_COMMAND_ARGUMENT_INVALID);
	} else if (0 != p_breakpoint->address % (RVC_enable ? 2 : 4)) {
		LOG_ERROR("Unaligned breakpoint: 0x%08" TARGET_PRIxADDR, p_breakpoint->address);
		sc_error_code__update(p_target, ERROR_COMMAND_ARGUMENT_INVALID);
	} else {
		invalidate_DAP_CTR_cache(p_target);

		if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
			return sc_error_code__get_and_clear(p_target);
		}

		assert(p_breakpoint);

		switch (p_breakpoint->type) {
		case BKPT_SOFT:
			return add_sw_breakpoint(p_target, p_breakpoint);

		case BKPT_HARD:
			return add_hw_breakpoint(p_target, p_breakpoint);

		default:
			LOG_ERROR("Ivalid breakpoint type");
			sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
		}
	}

	return sc_error_code__get_and_clear(p_target);
}

static inline error_code
remove_sw_breakpoint(target* const p_target,
					 breakpoint* const p_breakpoint)
{
	assert(p_breakpoint->orig_instr);

	if (ERROR_OK == write_memory_space(p_target, p_breakpoint->address, 2, p_breakpoint->length / 2, p_breakpoint->orig_instr, true)) {
		p_breakpoint->set = 0;
	}

	return sc_error_code__get_and_clear(p_target);
}

static error_code
BRKM_disable_channel(target* const p_target,
					 uint32_t const channel)
{
	if (ERROR_OK != BRKM_csr_set(p_target, BPSELECT, channel)) {
		LOG_ERROR("Error in BRKM select channel #%" PRIu32, channel);
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPCONTROL, 0)) {
		LOG_ERROR("Error clear BRKM BPCONTROL for channel %" PRIu32, channel);
	} else {
		LOG_DEBUG("Disable BRKM channel #%" PRIu32, channel);
	}

	return sc_error_code__get(p_target);
}

static inline error_code
remove_hw_breakpoint(target* const p_target,
					 breakpoint* const p_breakpoint)
{
	// TODO: replace 12 by BPSELECT property
	assert(0 != (p_breakpoint->set & BIT_MASK(12)));
	uint32_t const channel = ~(~UINT32_C(0) << 12) & p_breakpoint->set;

	if (ERROR_OK == BRKM_disable_channel(p_target, channel)) {
		p_breakpoint->set = 0;
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__remove_breakpoint(target* const p_target,
							  breakpoint* const p_breakpoint)
{
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	assert(p_breakpoint);

	switch (p_breakpoint->type) {
	case BKPT_SOFT:
		return remove_sw_breakpoint(p_target, p_breakpoint);

	case BKPT_HARD:
		return remove_hw_breakpoint(p_target, p_breakpoint);

	default:
		LOG_ERROR("Invalid breakpoint type");
		sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__add_watchpoint(target* const p_target,
						   watchpoint* const p_watchpoint)
{
	assert(p_watchpoint);

	LOG_DEBUG("Add watchpoint request:"
			 " address=%08" TARGET_PRIxADDR
			 " length=%" PRIu32
			 " rw=%d"
			 " value=%08" PRIx32
			 " mask=%08" PRIx32
			 " unique_id=%d",
			 p_watchpoint->address,
			 p_watchpoint->length,
			 p_watchpoint->rw,
			 p_watchpoint->value,
			 p_watchpoint->mask,
			 p_watchpoint->unique_id);

	if (0 == p_watchpoint->mask && 0 != p_watchpoint->value) {
		LOG_ERROR("Bad mask/value combination:"
				  " value=%08" PRIx32
				  " mask=%08" PRIx32,
				  p_watchpoint->value,
				  p_watchpoint->mask);
		return ERROR_COMMAND_ARGUMENT_INVALID;
	}

	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	uint32_t bpcontrol = 0;
	uint32_t const channel = find_BRKM_free_channel(p_target, &bpcontrol);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	assert(!(0 == p_watchpoint->mask && 0 != p_watchpoint->value));

	uint32_t const required_capabilities =
		BIT_MASK(BPCONTROL_ASUP) |
		BIT_MASK(BPCONTROL_ARANGESUP) |
		(
			WPT_ACCESS == p_watchpoint->rw ? BIT_MASK(BPCONTROL_LOADSUP) | BIT_MASK(BPCONTROL_STORESUP) :
			WPT_READ == p_watchpoint->rw ? BIT_MASK(BPCONTROL_LOADSUP) :
			WPT_WRITE == p_watchpoint->rw ? BIT_MASK(BPCONTROL_STORESUP) :
			(assert(0), 0)
		) |
		(
			WPT_ACCESS == p_watchpoint->rw || 0 == p_watchpoint->mask ? 0 :
			UINT32_MAX == p_watchpoint->mask ? BIT_MASK(BPCONTROL_DSUP) :
			BIT_MASK(BPCONTROL_DMASKSUP)
		);

	uint32_t const control_bits =
		BIT_MASK(BPCONTROL_AEN) |
		BIT_MASK(BPCONTROL_ARANGEEN) |
		(
			WPT_ACCESS == p_watchpoint->rw ? BIT_MASK(BPCONTROL_LOADEN) | BIT_MASK(BPCONTROL_STOREEN) :
			WPT_READ == p_watchpoint->rw ? BIT_MASK(BPCONTROL_LOADEN) :
			WPT_WRITE == p_watchpoint->rw ? BIT_MASK(BPCONTROL_STOREEN) :
			(assert(0), 0)
		) |
		(
			WPT_ACCESS == p_watchpoint->rw || 0 == p_watchpoint->mask ? 0 :
			UINT32_MAX == p_watchpoint->mask ? BIT_MASK(BPCONTROL_DEN) :
			BIT_MASK(BPCONTROL_DMASKEN)
		) |
		/* TODO: add definition for (2 << BPCONTROL_ACTION_LOW) */
		2 << BPCONTROL_ACTION_LOW;

	if ((required_capabilities & bpcontrol) != required_capabilities) {
		LOG_ERROR("BRKM watchpoint mode is not supported by BRKM for channel"
					" #%" PRIu32
					": bpcontrol=%08" PRIx32
					" but required %08" PRIx32
					"(not-enough=%08" PRIx32 ")",
					channel,
					bpcontrol,
					required_capabilities,
					(required_capabilities ^ bpcontrol) & required_capabilities);
		sc_error_code__update(p_target, ERROR_TARGET_RESOURCE_NOT_AVAILABLE);
	} else if (ERROR_OK != BRKM_csr_set(p_target, BRKMCTRL, BIT_MASK(15)/* TODO: BRKMCTRL, BIT_MASK(15) */)) {
		LOG_ERROR("Error: can't init BRKMCTRL");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPLOADDR, (uint32_t)(p_watchpoint->address))) {
		LOG_ERROR("Error: can't setup BPLOADDR");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPHIADDR, (uint32_t)(p_watchpoint->address) + p_watchpoint->length)) {
		LOG_ERROR("Error: can't setup BPHIADDR");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPLODATA, p_watchpoint->value)) {
		LOG_ERROR("Error: can't setup BPLODATA");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPHIDATA, p_watchpoint->mask)) {
		LOG_ERROR("Error: can't setup BPHIDATA");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPCTRLEXT, BIT_MASK(BPCTRLEXT_ARANGEEXT_EN))) {
		LOG_ERROR("Error: can't setup BPCTRLEXT");
	} else if (ERROR_OK != BRKM_csr_set(p_target, BPCONTROL, control_bits)) {
		LOG_ERROR("Error: can't setup BPCONTROL");
	} else {
		// OK
		LOG_INFO("Watchpoint enabled "
				 " channel=%" PRId32
				 " address=%08" TARGET_PRIxADDR
				 " length=%" PRIu32
				 " rw=%d"
				 " value=%08" PRIx32
				 " mask=%08" PRIx32
				 " unique_id=%d"
				 " BPCONTROL=%08" PRIx32,
				 channel,
				 p_watchpoint->address,
				 p_watchpoint->length,
				 p_watchpoint->rw,
				 p_watchpoint->value,
				 p_watchpoint->mask,
				 p_watchpoint->unique_id,
				 control_bits);
		p_watchpoint->set = BIT_MASK(12) | channel;
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__remove_watchpoint(target* const p_target,
							  watchpoint* const p_watchpoint)
{
	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	// TODO: replace 12 by BPSELECT property
	assert(0 != (p_watchpoint->set & BIT_MASK(12)));
	uint32_t const channel = ~(~UINT32_C(0) << 12) & p_watchpoint->set;

	if (ERROR_OK == BRKM_disable_channel(p_target, channel)) {
		LOG_INFO("Watchpoint disabled "
				 " channel=%" PRId32
				 " address=%08" TARGET_PRIxADDR
				 " length=%" PRIu32
				 " rw=%d"
				 " value=%08" PRIx32
				 " mask=%08" PRIx32
				 " unique_id=%d",
				 channel,
				 p_watchpoint->address,
				 p_watchpoint->length,
				 p_watchpoint->rw,
				 p_watchpoint->value,
				 p_watchpoint->mask,
				 p_watchpoint->unique_id);
		p_watchpoint->set = 0;
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__hit_watchpoint(target* const p_target,
						   watchpoint** const pp_hit_watchpoint)
{
	assert(pp_hit_watchpoint);
	*pp_hit_watchpoint = NULL;

	invalidate_DAP_CTR_cache(p_target);

	if (ERROR_OK != sc_rv32_check_that_target_halted(p_target)) {
		return sc_error_code__get_and_clear(p_target);
	}

	for (watchpoint* p_watchpoint = p_target->watchpoints; p_watchpoint; p_watchpoint = p_watchpoint->next) {
		if (0 == (BIT_MASK(12) & p_watchpoint->set)) {
			continue;
		}

		uint32_t const channel = ~(~UINT32_C(0) << 12) & p_watchpoint->set;

		if (ERROR_OK != BRKM_csr_set(p_target, BPSELECT, channel)) {
			LOG_ERROR("Error in BRKM select"
					  " channel #%" PRId32,
					  channel);
			break;
		}

		uint32_t bpcontrol = 0;

		if (ERROR_OK != BRKM_csr_get(p_target, BPCONTROL, &bpcontrol)) {
			LOG_ERROR("Error read BRKM BPCONTROL for"
					  " channel #%" PRId32,
					  channel);
			break;;
		}

		if (0 != (BIT_MASK(BPCONTROL_MATCHED) & bpcontrol)) {
			if (ERROR_OK != BRKM_csr_set(p_target, BPCONTROL, ~BIT_MASK(BPCONTROL_MATCHED) & bpcontrol)) {
				LOG_ERROR("Error reset MATCH bit of BRKM BPCONTROL for"
						  " channel #%" PRId32,
						  channel);
				break;
			}

			*pp_hit_watchpoint = p_watchpoint;
			LOG_INFO("Watchpoint hit"
					 " channel=%" PRIu32
					 " address=%08" TARGET_PRIxADDR
					 " length=%" PRIu32
					 " rw=%d"
					 " value=%08" PRIx32
					 " mask=%08" PRIx32
					 " unique_id=%d",
					 channel,
					 p_watchpoint->address,
					 p_watchpoint->length,
					 p_watchpoint->rw,
					 p_watchpoint->value,
					 p_watchpoint->mask,
					 p_watchpoint->unique_id);
			break;
		}
	}

	return sc_error_code__get_and_clear(p_target);
}

/// gdb_server expects valid reg values and will use set method for updating reg values
error_code
sc_riscv32__get_gdb_reg_list(target* const p_target, reg** reg_list[], int* const reg_list_size, target_register_class const reg_class)
{
	assert(p_target);
	assert(reg_list_size);
	assert(reg_class == REG_CLASS_ALL || reg_class == REG_CLASS_GENERAL);

	invalidate_DAP_CTR_cache(p_target);
	size_t const num_regs = reg_class == REG_CLASS_ALL ? number_of_regs_GDB : number_of_regs_GP;
	reg** const p_reg_array = calloc(num_regs, sizeof(reg*));
	reg** p_reg_iter = p_reg_array;
	size_t regs_left = num_regs;

	for (reg_cache* p_reg_cache = p_target->reg_cache; p_reg_cache && regs_left; p_reg_cache = p_reg_cache->next) {
		reg* p_reg_list = p_reg_cache->reg_list;

		for (size_t i = 0; i < p_reg_cache->num_regs && regs_left; ++i, --regs_left) {
			*p_reg_iter++ = &p_reg_list[i];
		}
	}

	// out results
	*reg_list = p_reg_array;
	*reg_list_size = num_regs - regs_left;
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_riscv32__virt2phys(target* p_target,
					  target_addr_t address,
					  target_addr_t* p_physical)
{
	assert((UINT32_MAX & address) == address);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	invalidate_DAP_CTR_cache(p_target);
	assert(p_arch);
	assert(p_physical);
	*p_physical = 0;
	p_arch->constants->virt_to_phis(p_target, address, p_physical, NULL, false);
	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_rv32__virt_to_phis_direct_map(target* p_target,
								 rv32_address_type address,
								 target_addr_t* p_physical,
								 uint32_t* p_bound,
								 bool const instruction_space)
{
	assert(p_physical);
	*p_physical = address;

	if (p_bound) {
		*p_bound = UINT32_MAX;
	}

	LOG_DEBUG("Direct virt_to_phis"
			  " address %08" PRIx32,
			  address);
	return sc_error_code__get(p_target);
}

/// RISC-V Privileged ISA 1.7 CSR
enum
{
	CSR_sptbr_Pr_ISA_1_7 = 0x180,

	/// Machine Protection and Translation
	/// privilege: MRW
	///@{

	/// @brief Base register
	CSR_mbase_Pr_ISA_1_7 = 0x380u,

	/// @brief Base register
	CSR_mbound_Pr_ISA_1_7 = 0x381u,

	/// @brief Bound register.
	CSR_mibase_Pr_ISA_1_7 = 0x382u,

	/// @brief Instruction base register.
	CSR_mibound_Pr_ISA_1_7 = 0x383u,

	/// @brief Data base register
	CSR_mdbase_Pr_ISA_1_7 = 0x384u,

	/// @brief Data bound register
	CSR_mdbound_Pr_ISA_1_7 = 0x385u,
	///@}
};

/// RISC-V Privileged ISA 1.7 levels
enum
{
	Priv_U = 0x0,
	Priv_S = 0x1,
	Priv_H = 0x2,
	Priv_M = 0x3,
};

/// RISC-V Privileged ISA 1.7 VM modes
enum
{
	VM_Mbare = 0,
	VM_Mbb = 1,
	VM_Mbbid = 2,
	VM_Sv32 = 8,
	VM_Sv39 = 9,
	VM_Sv48 = 10,
};

error_code
sc_rv32__mmu_1_7(target* p_target, int* p_mmu_enabled)
{
	invalidate_DAP_CTR_cache(p_target);
	uint32_t const mstatus = sc_riscv32__csr_get_value(p_target, CSR_mstatus);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		/// @todo Privileged Instruction 1.7 version
		uint32_t const privilege_level = (mstatus >> 1) & LOW_BITS_MASK(2);
		assert(p_mmu_enabled);

		/// @todo Privileged Instruction 1.7 version
		if (privilege_level == Priv_M || privilege_level == Priv_H) {
			*p_mmu_enabled = 0;
		} else {
			/// @todo Privileged Instruction 1.7 version
			uint32_t const VM = (mstatus >> 17) & LOW_BITS_MASK(21 - 16);

			switch (VM) {
			case VM_Mbb:
			case VM_Mbbid:
			case VM_Sv32:
			case VM_Sv39:
			case VM_Sv48:
				*p_mmu_enabled = 1;
				break;

			case VM_Mbare:
			default:
				*p_mmu_enabled = 0;
				break;
			}
		}
	} else {
		sc_riscv32__update_status(p_target);
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_rv32__virt_to_phis_1_7(target* p_target,
						  rv32_address_type address,
						  target_addr_t* p_physical,
						  uint32_t* p_bound,
						  bool const instruction_space)
{
	invalidate_DAP_CTR_cache(p_target);
	uint32_t const mstatus = sc_riscv32__csr_get_value(p_target, CSR_mstatus);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_riscv32__update_status(p_target);
	}

	/// @todo Privileged Instruction 1.7 version
	uint32_t const PRV = (mstatus >> 1) & LOW_BITS_MASK(2);
	/// @todo Privileged Instruction 1.7 version
	uint32_t const VM = PRV == Priv_M || PRV == Priv_H ? VM_Mbare : (mstatus >> 17) & LOW_BITS_MASK(21 - 16);
	assert(p_physical);

	switch (VM) {
	case VM_Mbare:
		*p_physical = address;

		if (p_bound) {
			*p_bound = UINT32_MAX;
		}

		return sc_error_code__get(p_target);
		break;

	case VM_Mbb:
	case VM_Mbbid:
		{
			uint32_t const bound = sc_riscv32__csr_get_value(p_target, VM == VM_Mbb ? CSR_mbound_Pr_ISA_1_7 : /*VM == VM_Mbbid*/instruction_space ? CSR_mibound_Pr_ISA_1_7 : CSR_mdbound_Pr_ISA_1_7);

			if (ERROR_OK == sc_error_code__get(p_target)) {
				if (!(address < bound)) {
					return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
				}

				uint32_t const base = sc_riscv32__csr_get_value(p_target, VM_Mbb ? CSR_mbase_Pr_ISA_1_7 : /*VM == VM_Mbbid*/instruction_space ? CSR_mibase_Pr_ISA_1_7 : CSR_mdbase_Pr_ISA_1_7);

				if (ERROR_OK == sc_error_code__get(p_target)) {
					*p_physical = address + base;

					if (p_bound) {
						*p_bound = bound - address;
					}

					return sc_error_code__get(p_target);
				}
			}
		}
		break;

	case VM_Sv32:
		{
			static uint32_t const offset_mask = LOW_BITS_MASK(10) << 2;
			uint32_t const main_page = sc_riscv32__csr_get_value(p_target, CSR_sptbr_Pr_ISA_1_7);

			if (ERROR_OK == sc_error_code__get(p_target)) {
				// lower bits should be zero
				assert(0 == (main_page & LOW_BITS_MASK(12)));
				uint32_t const offset_bits1 = address >> 20 & offset_mask;
				uint8_t pte1_buf[4];

				if (ERROR_OK == sc_error_code__update(p_target, target_read_phys_memory(p_target, main_page | offset_bits1, 4, 1, pte1_buf))) {
					uint32_t const pte1 = buf_get_u32(pte1_buf, 0, 32);

					if (0 == (pte1 & BIT_MASK(0))) {
						return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
					}

					if ((pte1 >> 1 & LOW_BITS_MASK(4)) >= 2) {
						*p_physical = (pte1 << 2 & ~LOW_BITS_MASK(22)) | (address & LOW_BITS_MASK(22));

						if (p_bound) {
							*p_bound = BIT_MASK(22) - (address & LOW_BITS_MASK(22));
						}
					} else {
						uint32_t const base_0 = pte1 << 2 & ~LOW_BITS_MASK(12);
						uint32_t const offset_bits0 = address >> 10 & offset_mask;
						uint8_t pte0_buf[4];

						if (ERROR_OK == sc_error_code__update(p_target, target_read_phys_memory(p_target, base_0 | offset_bits0, 4, 1, pte0_buf))) {
							uint32_t const pte0 = buf_get_u32(pte0_buf, 0, 32);

							if (0 == (pte0 & BIT_MASK(0)) || (pte0 >> 1 & LOW_BITS_MASK(4)) < 2) {
								return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
							}

							*p_physical = (pte0 << 2 & ~LOW_BITS_MASK(12)) | (address & LOW_BITS_MASK(12));

							if (p_bound) {
								*p_bound = BIT_MASK(12) - (address & LOW_BITS_MASK(12));
							}
						}
					}
				}
			}
		}
		break;

	case VM_Sv39:
	case VM_Sv48:
	default:
		return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
		break;
	}

	if (ERROR_OK != sc_error_code__get(p_target)) {
		sc_riscv32__update_status(p_target);
	}

	return sc_error_code__get(p_target);
}

enum
{
	CSR_satp = 0x180,
};

error_code
sc_rv32__mmu_1_9(target* p_target,
				 int* p_mmu_enabled)
{
	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	bool const RV_S = 0 != (p_arch->misa & BIT_MASK('S' - 'A'));

	if (!RV_S) {
		LOG_DEBUG("S-mode is not supporeted");
		*p_mmu_enabled = 0;
		return ERROR_OK;
	}

	uint32_t const satp = sc_riscv32__csr_get_value(p_target, CSR_satp);

	if (ERROR_OK == sc_error_code__get(p_target)) {
		LOG_DEBUG("satp=%08" PRIx32, satp);
		*p_mmu_enabled = 0 != (satp & BIT_MASK(31));
	}

	return sc_error_code__get_and_clear(p_target);
}

error_code
sc_rv32__virt_to_phis_1_9(target* p_target,
						  rv32_address_type va,
						  target_addr_t* p_physical,
						  uint32_t* p_bound,
						  bool const instruction_space)
{
	enum
	{
		user_mode = 0b00u,
		supervisor_mode = 0b10u,
		machine_mode = 0b11u,
	};

	assert(p_target);
	sc_riscv32__Arch const* const p_arch = p_target->arch_info;
	assert(p_arch);
	bool const RV_S = 0 != (p_arch->misa & BIT_MASK('S' - 'A'));

	invalidate_DAP_CTR_cache(p_target);

	if (!RV_S) {
		LOG_DEBUG("misa bit 'S' is 0");
		return sc_rv32__virt_to_phis_direct_map(p_target, va, p_physical, p_bound, instruction_space);
	}

	uint32_t dbg_status;

	if (ERROR_OK != sc_rv32_DBG_STATUS_get(p_target, &dbg_status)) {
		return sc_error_code__get(p_target);
	}

	if (0 == (dbg_status & DBG_STATUS_bit_HART0_DMODE)) {
		return sc_error_code__update(p_target, ERROR_TARGET_NOT_HALTED);
	}

	uint32_t const current_mode = EXTRACT_FIELD(dbg_status, 6, 7);

	LOG_DEBUG("current_mode=%" PRIu32, current_mode);

	if (machine_mode == current_mode) {
		return sc_rv32__virt_to_phis_direct_map(p_target, va, p_physical, p_bound, instruction_space);
	}

	uint32_t const satp = sc_riscv32__csr_get_value(p_target, CSR_satp);

	if (ERROR_OK != sc_error_code__get(p_target)) {
		return sc_error_code__get(p_target);
	}

	LOG_DEBUG("satp=%08" PRIx32, satp);

	if (0 == (satp & BIT_MASK(31))) {
		return sc_rv32__virt_to_phis_direct_map(p_target, va, p_physical, p_bound, instruction_space);
	}

	static const uint32_t pagesize = UINT32_C(1) << 12;
	static const int levels = 2;
	static const uint32_t PTESIZE = 4;

	// 1
	uint32_t vpn[2] = {EXTRACT_FIELD(va, 12, 21), EXTRACT_FIELD(va, 22, 31)};
	uint32_t const ppn = EXTRACT_FIELD(satp, 0, 21);
	uint32_t a = ppn * pagesize;

	for (int i = levels - 1;;) {
		// 2
		uint8_t buf[sizeof(uint32_t)];

		if (ERROR_OK != target_read_phys_memory(p_target, (target_addr_t)(a) + vpn[i] * PTESIZE, sizeof buf, 1, buf)) {
			return sc_riscv32__update_status(p_target);
		}

		uint32_t const pte = buf_get_u32(buf, 0, 32);

		// 3
		uint32_t const pte_v = EXTRACT_FIELD(pte, 0, 0);
		uint32_t const pte_r = EXTRACT_FIELD(pte, 1, 1);
		uint32_t const pte_w = EXTRACT_FIELD(pte, 2, 2);
		LOG_DEBUG("pte = 0x%08" PRIx32 " (v = 0x%08" PRIx32 " r = 0x%08" PRIx32 " w = 0x%08" PRIx32 ")", pte, pte_v, pte_r, pte_w);

		if (0 == pte_v || (0 == pte_r && 0 != pte_w)) {
			LOG_ERROR("Address translation fault: pte = 0x%08" PRIx32 " (v = 0x%08" PRIx32 " r = 0x%08" PRIx32 " w = 0x%08" PRIx32 ")", pte, pte_v, pte_r, pte_w);
			return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
		}

		// 4
		uint32_t const pte_x = EXTRACT_FIELD(pte, 3, 3);

		if (!(0 != pte_r || 0 != pte_x)) {
			if (i < 1) {
				LOG_ERROR("Address translation fault: Bad level");
				return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
			}

			i = i - 1;
			a = EXTRACT_FIELD(pte, 10, 31) * pagesize;
			LOG_DEBUG("Intermediate a= 0x%08" PRIx32, a);
		} else {
			// 5
			uint32_t const pte_u = EXTRACT_FIELD(pte, 4, 4);

			if ((user_mode == current_mode && 0 == pte_u) || (instruction_space && 0 == pte_x)) {
				LOG_ERROR("Address translation fault: MMU disable access");
				return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
			}

			// 6
			if (i > 0 && 0 != EXTRACT_FIELD(pte, 10, 19)) {
				LOG_ERROR("Address translation fault: pte_a[19..10] != 0");
				return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
			}

			// 7
			uint32_t const pte_a = EXTRACT_FIELD(pte, 6, 6);

			if (0 == pte_a) {
				LOG_ERROR("Address translation fault: pte_a[6] == 0");
				return sc_error_code__update(p_target, ERROR_TARGET_TRANSLATION_FAULT);
			}

			// 8
			unsigned const off_bits = i > 0 ? 22 : 12;
			assert(p_physical);
			*p_physical = (EXTRACT_FIELD(pte, off_bits - 2, 32) << off_bits) | EXTRACT_FIELD(va, 0, off_bits - 1);
			LOG_DEBUG("Final a= 0x%08" TARGET_PRIxADDR, *p_physical);

			if (p_bound) {
				*p_bound = UINT32_C(1) << off_bits;
			}

			return sc_error_code__get(p_target);
		}
	}
}
