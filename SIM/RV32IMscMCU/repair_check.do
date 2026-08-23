# repair_check.do - directed check of the seven Phase 3A ISA repairs
#
# REFERENCE
#   Auxiliary/Lab 5 - as submitted/SIM/RV32IM_pipeline/directed_isa.do
#   That script is the LAB5 submission's own regression for the same seven
#   repairs on the pipelined core. This is the single-cycle port of it:
#   same method (force a submodule's inputs, examine its output), same
#   instruction encodings where they apply, hierarchy retargeted to
#   /tb_rv32imscmcu/MCU/CORE/... because our tree adds the MCU wrapper level.
#
# WHAT IT PROVES AND WHAT IT DOES NOT
#   These are submodule-level checks: they prove each repaired expression
#   computes the right value. They do NOT prove the repaired core runs a
#   program correctly - that is what run_isa.do and the four benchmarks are
#   for. Run both.
#
# HOW TO RUN
#   Set G_ISA_REPAIR := TRUE in DUT/RV32IMscMCU/cond_compilation_package.vhd,
#   re-run compile.do, then  do repair_check.do
#
#   Against G_ISA_REPAIR = FALSE every check below fails except BRANCH_plus_1024,
#   which is deliberately non-discriminating (see defect 6). That failing run is
#   the "before" measurement and is worth capturing once.

onerror {quit -code 1}

# The ITCM/DTCM init_file paths are hardcoded in IFETCH.vhd and DMEMORY.vhd, so
# app_bin must hold a valid image or elaboration fails. Any image will do - no
# instruction is ever executed here - so reuse the generated ISA test's.
file copy -force isa/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force isa/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vsim -t ns -gMODELSIM=1 work.tb_rv32imscmcu
set StdArithNoWarnings 1
set NumericStdNoWarnings 1

set ::passes 0
set ::fails  0

proc expect_hex {signal expected label} {
    set actual [string tolower [examine -radix hexadecimal $signal]]
    set expected [string tolower $expected]
    if {$actual ne $expected} {
        echo "FAIL: $label expected $expected, got $actual"
        incr ::fails
    } else {
        echo "PASS: $label = $actual"
        incr ::passes
    }
}

set CORE /tb_rv32imscmcu/MCU/CORE

# ---------------------------------------------------------------------------
# Defect 1 - CONTROL must distinguish andi from ori.
# As submitted, CONTROL.vhd's ALU_AND arm tests ori_w, so andi never reaches
# ALU_AND and ori matches the AND arm first. ALU_AND = "00111" = 0x07,
# ALU_OR = "01000" = 0x08 (const_package.vhd).
# ---------------------------------------------------------------------------
force -freeze $CORE/CTL/instruction_i 32'h00007013 0
run 1 ns
expect_hex $CORE/CTL/ALUOp_ctrl_o 07 ANDI_decode
force -freeze $CORE/CTL/instruction_i 32'h00006013 0
run 1 ns
expect_hex $CORE/CTL/ALUOp_ctrl_o 08 ORI_decode
noforce $CORE/CTL/instruction_i

# ---------------------------------------------------------------------------
# Defects 2 and 3 - IDECODE's immediate select must cover loads and lui.
# lw x2,4(x1) = 0x0040A103 ; lui x1,0x12345 = 0x123450B7 ;
# auipc x1,0x12345 = 0x12345097. The auipc pair is the control case: it worked
# before the repair too, so it must still work after it.
# ---------------------------------------------------------------------------
force -freeze $CORE/ID/instruction_i 32'h0040a103 0
run 1 ns
expect_hex $CORE/ID/SignExt_o 00000004 LW_immediate
force -freeze $CORE/ID/instruction_i 32'h123450b7 0
run 1 ns
expect_hex $CORE/ID/SignExt_o 12345000 LUI_immediate
expect_hex $CORE/CTL/UpperIm_ctrl_o 2 LUI_upper_select
force -freeze $CORE/ID/instruction_i 32'h12345097 0
run 1 ns
expect_hex $CORE/ID/SignExt_o 12345000 AUIPC_immediate_unchanged
expect_hex $CORE/CTL/UpperIm_ctrl_o 1 AUIPC_upper_select
noforce $CORE/ID/instruction_i

# ---------------------------------------------------------------------------
# Drive the ALU directly: operand A = rs1, operand B = rs2, no immediate.
# ---------------------------------------------------------------------------
force -freeze $CORE/EXE/UpperIm_ctrl_i 2'h0 0
force -freeze $CORE/EXE/ALUSrc_ctrl_i  1'b0 0

# ---------------------------------------------------------------------------
# Defect 5 - unsigned compare. ALU_LESS_THAN_UNSIGNED = "01010" = 0x0A.
# Unsigned 0x80000000 < 1 is false; 1 < 0x80000000 is true. The as-submitted
# signed import inverts both.
# ---------------------------------------------------------------------------
force -freeze $CORE/EXE/ALUOp_ctrl_i 5'h0a 0
force -freeze $CORE/EXE/read_data1_i 32'h80000000 0
force -freeze $CORE/EXE/read_data2_i 32'h00000001 0
run 1 ns
expect_hex $CORE/EXE/alu_res_r 00000000 SLTU_high_bit
force -freeze $CORE/EXE/read_data1_i 32'h00000001 0
force -freeze $CORE/EXE/read_data2_i 32'h80000000 0
run 1 ns
expect_hex $CORE/EXE/alu_res_r 00000001 SLTU_reverse

# Signed slt must be unaffected by the repair: ALU_LESS_THAN_SIGNED = 0x0B.
# Signed 0x80000000 (= -2^31) < 1 is TRUE - the opposite of the unsigned answer.
force -freeze $CORE/EXE/ALUOp_ctrl_i 5'h0b 0
force -freeze $CORE/EXE/read_data1_i 32'h80000000 0
force -freeze $CORE/EXE/read_data2_i 32'h00000001 0
run 1 ns
expect_hex $CORE/EXE/alu_res_r 00000001 SLT_signed_unchanged

# ---------------------------------------------------------------------------
# Defect 4 - arithmetic right shift must replicate the sign bit through every
# barrel stage. ALU_SHIFTR_ARITH = "00011" = 0x03. 0x80000000 >>a 4 = 0xF8000000.
# ---------------------------------------------------------------------------
force -freeze $CORE/EXE/ALUOp_ctrl_i 5'h03 0
force -freeze $CORE/EXE/read_data1_i 32'h80000000 0
force -freeze $CORE/EXE/read_data2_i 32'h00000004 0
run 1 ns
expect_hex $CORE/EXE/alu_res_r f8000000 SRA_sign_extension

# Logical srl must be unaffected: ALU_SHIFTR = "00010" = 0x02 -> 0x08000000.
force -freeze $CORE/EXE/ALUOp_ctrl_i 5'h02 0
run 1 ns
expect_hex $CORE/EXE/alu_res_r 08000000 SRL_unchanged

# ---------------------------------------------------------------------------
# Defect 6 - branch/jal target adder must keep the whole displacement.
# IDECODE delivers imm[12:1], so the adder shifts left by one.
#
# NOTE: the reference script's case (imm 0x400 -> 0x0800) passes in BOTH
# configurations, because bit 11 of the immediate is clear - it does not
# discriminate. The discriminating case is imm 0x800, where the as-submitted
# slice drops the only set bit and produces pc+0 instead of pc+0x1000.
# ---------------------------------------------------------------------------
force -freeze $CORE/EXE/pc_i 13'h0000 0
force -freeze $CORE/EXE/sign_extend_i 32'h00000400 0
run 1 ns
expect_hex $CORE/EXE/addr_gen_o 0800 BRANCH_plus_1024_nondiscriminating
force -freeze $CORE/EXE/sign_extend_i 32'h00000800 0
run 1 ns
expect_hex $CORE/EXE/addr_gen_o 1000 BRANCH_plus_2048_discriminating

noforce $CORE/EXE/UpperIm_ctrl_i
noforce $CORE/EXE/ALUSrc_ctrl_i
noforce $CORE/EXE/ALUOp_ctrl_i
noforce $CORE/EXE/read_data1_i
noforce $CORE/EXE/read_data2_i
noforce $CORE/EXE/pc_i
noforce $CORE/EXE/sign_extend_i

# ---------------------------------------------------------------------------
# Defect 7 - the jalr target must have bit 0 cleared. 0x3 -> 0x2.
# jalr_target_w is examined rather than next_pc_w because the reset mux ahead of
# it forces zero while rst_q is high, and no program is running here.
# ---------------------------------------------------------------------------
force -freeze $CORE/IFE/alu_res_i 32'h00000003 0
run 1 ns
expect_hex $CORE/IFE/jalr_target_w 0002 JALR_lsb_clear
noforce $CORE/IFE/alu_res_i

# ---------------------------------------------------------------------------
echo ""
echo "=============== PHASE 3A REPAIR CHECK ==============="
echo "  passed : $::passes"
echo "  failed : $::fails"
if {$::fails == 0} {
    echo "  VERDICT: all seven repairs behave as specified."
    echo "====================================================="
    quit -f
} else {
    echo "  VERDICT: $::fails check(s) failed."
    echo "  If ALL of them failed, the design was compiled with"
    echo "  G_ISA_REPAIR = FALSE - that is the baseline run, not a bug."
    echo "  A partial failure is a real finding: the repair is wrong."
    echo "====================================================="
    quit -code 1
}
