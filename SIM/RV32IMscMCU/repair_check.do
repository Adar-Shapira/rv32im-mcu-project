# repair_check.do - directed check of the ISA conformance work: the seven
# Phase 3A decode repairs and the Phase 3B sub-word access path. 43 checks.
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
#   After compile.do:  do repair_check.do

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

# ===========================================================================
# PHASE 3B - byte enables and sub-word load/store (gap G-309)
# ===========================================================================
# CONTROL must carry the access width, and DMEMORY must act on it. MemOp codes
# are the RISC-V funct3 values (const_package.vhd): 0=byte 1=half 2=word
# 4=byte-unsigned 5=half-unsigned.
# ---------------------------------------------------------------------------
# CONTROL: every load and store width must decode to its own MemOp code.
# ---------------------------------------------------------------------------
proc memop {instr expect label} {
    global CORE
    force -freeze $CORE/CTL/instruction_i $instr 0
    run 1 ns
    expect_hex $CORE/CTL/MemOp_ctrl_o $expect $label
}
memop 32'h00000003 0 MemOp_lb
memop 32'h00001003 1 MemOp_lh
memop 32'h00002003 2 MemOp_lw
memop 32'h00004003 4 MemOp_lbu
memop 32'h00005003 5 MemOp_lhu
memop 32'h00000023 0 MemOp_sb
memop 32'h00001023 1 MemOp_sh
memop 32'h00002023 2 MemOp_sw
# A non-memory instruction must resolve to word, never to an undefined width.
memop 32'h00000013 2 MemOp_default_is_word
noforce $CORE/CTL/instruction_i

# ---------------------------------------------------------------------------
# DMEMORY store path: byteena_a one-hot per byte, half-hot per half, all lanes
# for a word. byteena_w is 4 bits, so it reads as a single hex digit.
# ---------------------------------------------------------------------------
proc byteena {op sel expect label} {
    global CORE
    force -freeze $CORE/MEM/MemOp_ctrl_i $op 0
    force -freeze $CORE/MEM/byte_sel_i $sel 0
    run 1 ns
    expect_hex $CORE/MEM/byteena_w $expect $label
}
byteena 3'h0 2'h0 1 byteena_sb_offset0
byteena 3'h0 2'h1 2 byteena_sb_offset1
byteena 3'h0 2'h2 4 byteena_sb_offset2
byteena 3'h0 2'h3 8 byteena_sb_offset3
byteena 3'h1 2'h0 3 byteena_sh_low
byteena 3'h1 2'h2 c byteena_sh_high
byteena 3'h2 2'h0 f byteena_sw_all_lanes

# Store data must be replicated across the lanes so byteena can pick one.
force -freeze $CORE/MEM/dtcm_data_wr_i 32'h0000007F 0
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h0 0
run 1 ns
expect_hex $CORE/MEM/store_data_w 7f7f7f7f store_replicate_byte
force -freeze $CORE/MEM/dtcm_data_wr_i 32'h00005566 0
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h1 0
run 1 ns
expect_hex $CORE/MEM/store_data_w 55665566 store_replicate_half
force -freeze $CORE/MEM/dtcm_data_wr_i 32'hAABBCCDD 0
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h2 0
run 1 ns
expect_hex $CORE/MEM/store_data_w aabbccdd store_word_untouched
noforce $CORE/MEM/dtcm_data_wr_i

# ---------------------------------------------------------------------------
# DMEMORY load path: select the addressed lane, then sign- or zero-extend.
# q_w is the raw word the RAM returns; forcing it removes the RAM from the test
# so a failure here is the extract/extend logic and nothing else.
# ---------------------------------------------------------------------------
force -freeze $CORE/MEM/q_w 32'hAABBCCDD 0
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h4 0
force -freeze $CORE/MEM/byte_sel_i 2'h0 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o 000000dd load_lbu_offset0
force -freeze $CORE/MEM/byte_sel_i 2'h2 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o 000000bb load_lbu_offset2
force -freeze $CORE/MEM/byte_sel_i 2'h3 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o 000000aa load_lbu_offset3
# lb: byte 3 of 0xAABBCCDD is 0xAA, bit 7 set, so it must sign-extend.
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h0 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o ffffffaa load_lb_sign_extend
# lb on a byte with bit 7 clear must NOT sign-extend.
force -freeze $CORE/MEM/byte_sel_i 2'h1 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o 000000cc load_lb_no_sign_extend
# lhu / lh on both halves.
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h5 0
force -freeze $CORE/MEM/byte_sel_i 2'h0 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o 0000ccdd load_lhu_low
force -freeze $CORE/MEM/byte_sel_i 2'h2 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o 0000aabb load_lhu_high
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h1 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o ffffaabb load_lh_sign_extend
# lw must return the word untouched, whatever the byte offset says.
force -freeze $CORE/MEM/MemOp_ctrl_i 3'h2 0
run 1 ns
expect_hex $CORE/MEM/dtcm_data_rd_o aabbccdd load_lw_untouched
noforce $CORE/MEM/q_w
noforce $CORE/MEM/MemOp_ctrl_i
noforce $CORE/MEM/byte_sel_i

# ---------------------------------------------------------------------------
echo ""
echo "========== PHASE 3A + 3B CONFORMANCE CHECK =========="
echo "  passed : $::passes  of 43"
echo "  failed : $::fails"
if {$::fails == 0} {
    echo "  VERDICT: all 43 checks behave as specified."
    echo "====================================================="
    quit -f
} else {
    echo "  VERDICT: $::fails check(s) failed."
    echo "  0 means every repair works; anything else is a real finding."
    echo "  Paste the FAIL lines above into the plan file."
    echo "====================================================="
    quit -code 1
}
