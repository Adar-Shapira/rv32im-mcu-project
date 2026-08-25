# golden.do — RV32IM single-cycle MCU waveform
#
# Reference: Auxiliary/Lab 5/SIM/RV32IM_sc/golden.do
#            (styled like Auxilary/RV32I/SIM/RV32I.do)
#
# Changes from that file, and why each is required:
#   1. Hierarchy gained the MCU wrapper: /tb_rv32imscmcu/MCU/CORE/...
#      Lab 5 was /tb_rv32im_sc/CORE/...
#   2. Board I/O pane (SW, KEY1-3, LEDR, HEX0-5, PWM, CAPIN) — clause 4–6.
#   3. CLOCK_TREE, ADDR_DECODER, bidirectional data bus — Figure 1.
#   4. DIV_UNIT + DIV_ACCEL (Figure 3 / Figure 9) — Lab 5 had MUL16 only.
#   5. BASIC_TIMER and INTERRUPT_CTRL — clause 6.
#
# HOW TO USE (manual flow; this file only loads waves)
#   G_MODELSIM := 1, compile, copy M9K-intel ITCM.hex+DTCM.hex into
#   C:\TestPrograms\Quartus21_1\app_bin\, simulate work.tb_rv32imscmcu,
#   then:  do golden.do
#   Compact daily set (same signals as Lab 5 wave.do, plus DIV):  do wave.do
#
# DTCM dump path for clause 8.c.i (View -> Memory List, or mem save):
#   /tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
#
# WHICH TEST BELONGS TO WHICH PART  (Auxiliary/Benchmark Apps/)
#   RV32IM/test1                 core ISA — div/mul/rem, then while(1)
#   GPIO/test0                   GPO writes (LEDR + six HEX)
#   GPIO/test1                   PORT_SW: force SW_i=01 up, 02 down, 00 idle
#   GPIO/test2                   same switches, 6-digit HEX number
#   Intrrupt-based IO/test1      KEY1/2/3 FSM + div/rem; KEY request = RELEASE
#   Intrrupt-based IO/test2      1 s Basic Timer
#   Intrrupt-based IO/test3      four timer periods
#   Intrrupt-based IO/test4      compare / PWM / capture
# GPIO and interrupt apps use lui to form 0x2000; the core's lui path is the
# Lab 5 pipeline repair (always on).
# KEY1 press = force KEY_i(1)=0, release = force KEY_i(1)=1.

onerror {resume}
quietly WaveActivateNextPane {} 0
quietly delete wave *

set TB   /tb_rv32imscmcu
set MCU  ${TB}/MCU
set CORE ${MCU}/CORE

#=============================================================================
# TOP — Lab 5 golden TOP, plus board pins
#=============================================================================
add wave -noupdate -divider {TOP}
add wave -noupdate -radix hexadecimal ${TB}/clk_i
add wave -noupdate -radix hexadecimal ${TB}/rst_i
add wave -noupdate -radix hexadecimal ${TB}/SW_i
add wave -noupdate -radix hexadecimal ${TB}/KEY_i
add wave -noupdate -radix hexadecimal ${TB}/CAPIN1_i
add wave -noupdate -radix hexadecimal ${TB}/CAPIN2_i
add wave -noupdate -color Yellow -itemcolor Yellow ${TB}/PWM_o
add wave -noupdate -color Cyan -itemcolor Cyan -radix hexadecimal ${TB}/LEDR_o
add wave -noupdate -radix hexadecimal ${TB}/HEX0_o
add wave -noupdate -radix hexadecimal ${TB}/HEX1_o
add wave -noupdate -radix hexadecimal ${TB}/HEX2_o
add wave -noupdate -radix hexadecimal ${TB}/HEX3_o
add wave -noupdate -radix hexadecimal ${TB}/HEX4_o
add wave -noupdate -radix hexadecimal ${TB}/HEX5_o
add wave -noupdate -radix hexadecimal ${TB}/pc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal ${TB}/instruction_o
add wave -noupdate -radix hexadecimal ${TB}/RegWrite_ctrl_o
add wave -noupdate -radix hexadecimal ${TB}/MemWrite_ctrl_o
add wave -noupdate -radix hexadecimal ${TB}/Branch_ctrl_o
add wave -noupdate -radix hexadecimal ${TB}/read_data1_o
add wave -noupdate -radix hexadecimal ${TB}/read_data2_o
add wave -noupdate -radix hexadecimal ${TB}/write_data_o
add wave -noupdate -radix hexadecimal ${TB}/alu_res_o
add wave -noupdate -radix hexadecimal ${TB}/brTaken_o
add wave -noupdate -radix hexadecimal ${TB}/dtcm_addr_o
add wave -noupdate -radix hexadecimal ${TB}/dtcm_data_wr_o
add wave -noupdate -radix hexadecimal ${TB}/dtcm_data_rd_o
add wave -noupdate ${TB}/dtcm_cs_o
add wave -noupdate ${TB}/unmapped_o
add wave -noupdate ${TB}/dtcm_wren_o
add wave -noupdate -color Cyan -itemcolor Cyan -radix unsigned ${TB}/mclk_cnt_o
add wave -noupdate -color Yellow -itemcolor Yellow ${CORE}/IFE/rst_q

#=============================================================================
# CLOCK TREE — Figure 1. At MODELSIM=1 altpll is bypassed; mclk is clk_i.
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {CLOCK TREE}
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/CLKTREE/clk_i
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/CLKTREE/rst_i
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/CLKTREE/mclk_o
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/CLKTREE/smclk_o
add wave -noupdate -expand -group CLOCK_TREE -color Magenta -itemcolor Magenta ${MCU}/CLKTREE/accelclk_o
add wave -noupdate -expand -group CLOCK_TREE -color {Medium Spring Green} -itemcolor {Medium Spring Green} ${MCU}/CLKTREE/locked_o
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/mclk_w
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/smclk_w
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/accelclk_w
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/pll_locked_w
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/rst_w
add wave -noupdate -expand -group CLOCK_TREE ${MCU}/sys_rst_w

#=============================================================================
# IFETCH
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {IFETCH}
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/clk_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/rst_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/addr_gen_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/Branch_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/brTaken_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/Jal_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/Jalr_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/alu_res_i
add wave -noupdate -expand -group IFETCH -color Yellow -itemcolor Yellow ${CORE}/IFE/PCHold_i
add wave -noupdate -expand -group IFETCH ${CORE}/IFE/IntrVec_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/intr_vector_i
add wave -noupdate -expand -group IFETCH -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/IFE/pc_o
add wave -noupdate -expand -group IFETCH -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/IFE/pc_plus4_o
add wave -noupdate -expand -group IFETCH -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/IFE/next_pc_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/instruction_o
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_plus4_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_plus4_r
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/itcm_addr_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/jalr_target_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/brTaken_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/rst_q

#=============================================================================
# IDECODE
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {IDECODE}
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/clk_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/rst_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/pc_plus4_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/instruction_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/dtcm_data_rd_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/alu_res_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/RegDst_ctrl_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/RegWrite_ctrl_i
add wave -noupdate -expand -group IDECODE ${CORE}/ID/DivSel_ctrl_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/div_result_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/MemtoReg_ctrl_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/read_data1_o
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/read_data2_o
add wave -noupdate -expand -group IDECODE -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/ID/SignExt_o
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/write_data_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/opc_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/rs1_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/rs2_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/rd_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/Iimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/Simm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/SBimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/Uimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/UJimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/SignExt_Iimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/SignExt_Simm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/SignExt_SBimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/SignExt_Uimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/SignExt_UJimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/load_imm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/lui_imm_w

#=============================================================================
# REGISTER FILE
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {REGISTER FILE}
add wave -noupdate -expand -group REGFILE -radix hexadecimal ${CORE}/ID/RF_q

#=============================================================================
# CONTROL
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {CONTROL}
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/instruction_i
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/RegDst_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/ALUSrc_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/MemtoReg_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/RegWrite_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/MemRead_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/MemWrite_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Branch_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Jal_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Jalr_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/UpperIm_ctrl_o
add wave -noupdate -expand -group CONTROL -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/CTL/ALUOp_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/MemOp_ctrl_o
add wave -noupdate -expand -group CONTROL -color Magenta -itemcolor Magenta ${CORE}/CTL/DivStart_ctrl_o
add wave -noupdate -expand -group CONTROL ${CORE}/CTL/DivSigned_ctrl_o
add wave -noupdate -expand -group CONTROL ${CORE}/CTL/DivRem_ctrl_o
add wave -noupdate -expand -group CONTROL -color {Violet Red} -itemcolor {Violet Red} ${CORE}/CTL/Reti_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Rtype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Itype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Stype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/SBtype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/Utype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/UJtype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/lb_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/lh_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/lw_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/lbu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/lhu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sb_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sh_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sw_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/beq_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/bne_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/blt_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/bge_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/bltu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/bgeu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/branch_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/jal_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/jalr_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/add_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/addi_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/and_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/andi_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/or_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/ori_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sll_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/slli_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sra_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/srai_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/srl_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/srli_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sub_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/xor_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/xori_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/auipc_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/lui_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/slt_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/slti_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sltu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/sltiu_w
add wave -noupdate -expand -group CONTROL -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/CTL/mul_w
add wave -noupdate -expand -group CONTROL -color Magenta -itemcolor Magenta ${CORE}/CTL/div_w
add wave -noupdate -expand -group CONTROL ${CORE}/CTL/divu_w
add wave -noupdate -expand -group CONTROL ${CORE}/CTL/rem_w
add wave -noupdate -expand -group CONTROL ${CORE}/CTL/remu_w
add wave -noupdate -expand -group CONTROL ${CORE}/CTL/divop_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/opc_w

#=============================================================================
# EXECUTE
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {EXECUTE}
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/read_data1_i
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/read_data2_i
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/UpperIm_ctrl_i
add wave -noupdate -expand -group EXECUTE -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/ALUOp_ctrl_i
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/ALUSrc_ctrl_i
add wave -noupdate -expand -group EXECUTE -color {Violet Red} -itemcolor {Violet Red} -radix hexadecimal ${CORE}/EXE/pc_i
add wave -noupdate -expand -group EXECUTE -color Navy -itemcolor Navy -radix hexadecimal ${CORE}/EXE/sign_extend_i
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/EXE/addr_gen_o
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/sub_res_w
add wave -noupdate -expand -group EXECUTE -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/EXE/ain_w
add wave -noupdate -expand -group EXECUTE -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/EXE/bin_w
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/EXE/alu_res_o
add wave -noupdate -expand -group EXECUTE -color {Medium Spring Green} -itemcolor {Medium Spring Green} -radix hexadecimal ${CORE}/EXE/brTaken_o
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/ltu_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/eq_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/msbneq_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brTaken_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/alu_res_r
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/EXE/mul_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shl_s1_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shl_s2_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shl_s3_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shl_s4_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shr_s1_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shr_s2_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shr_s3_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shr_s4_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/brl_shr_pad_r

#=============================================================================
# MUL16
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {MUL16}
add wave -noupdate -expand -group MUL16 -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/EXE/MUL/a_i
add wave -noupdate -expand -group MUL16 -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/EXE/MUL/b_i
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/al_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/ah_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/bl_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/bh_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL/p0_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL/p1_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL/p2_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL/p3_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/mid_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/term0_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/term1_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal ${CORE}/EXE/MUL/term2_w
add wave -noupdate -expand -group MUL16 -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/EXE/MUL/res_w
add wave -noupdate -expand -group MUL16 -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/EXE/MUL/res_o

#=============================================================================
# DIVIDER — Figure 3 / Figure 9. Lab 5 golden.do had no equivalent.
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {DIVIDER}
add wave -noupdate -expand -group DIV_CORE ${CORE}/div_start_w
add wave -noupdate -expand -group DIV_CORE ${CORE}/div_start_gated_w
add wave -noupdate -expand -group DIV_CORE ${CORE}/div_signed_w
add wave -noupdate -expand -group DIV_CORE ${CORE}/div_rem_w
add wave -noupdate -expand -group DIV_CORE -color Yellow -itemcolor Yellow ${CORE}/pc_hold_w
add wave -noupdate -expand -group DIV_CORE ${CORE}/div_busy_w
add wave -noupdate -expand -group DIV_CORE -color {Medium Spring Green} -itemcolor {Medium Spring Green} ${CORE}/div_done_w
add wave -noupdate -expand -group DIV_CORE -radix hexadecimal ${CORE}/div_quot_w
add wave -noupdate -expand -group DIV_CORE -radix hexadecimal ${CORE}/div_remd_w
add wave -noupdate -expand -group DIV_CORE -radix hexadecimal ${CORE}/div_result_w
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/mclk_i
add wave -noupdate -expand -group DIV_UNIT -color Magenta -itemcolor Magenta ${CORE}/DIVU/divclk_i
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/rst_i
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/start_i
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/signed_i
add wave -noupdate -expand -group DIV_UNIT -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/DIVU/dividend_i
add wave -noupdate -expand -group DIV_UNIT -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/DIVU/divisor_i
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/busy_o
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/done_o
add wave -noupdate -expand -group DIV_UNIT -radix hexadecimal ${CORE}/DIVU/quotient_o
add wave -noupdate -expand -group DIV_UNIT -radix hexadecimal ${CORE}/DIVU/remainder_o
add wave -noupdate -expand -group DIV_UNIT -radix hexadecimal ${CORE}/DIVU/state_q
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/ena_q
add wave -noupdate -expand -group DIV_UNIT -radix hexadecimal ${CORE}/DIVU/a_q
add wave -noupdate -expand -group DIV_UNIT -radix hexadecimal ${CORE}/DIVU/b_q
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/qneg_q
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/rneg_q
add wave -noupdate -expand -group DIV_UNIT ${CORE}/DIVU/bzero_q
add wave -noupdate -expand -group DIV_ACCEL ${CORE}/DIVU/ENGINE/divclk_i
add wave -noupdate -expand -group DIV_ACCEL ${CORE}/DIVU/ENGINE/divrst_i
add wave -noupdate -expand -group DIV_ACCEL ${CORE}/DIVU/ENGINE/divena_i
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/dividend_i
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/divisor_i
add wave -noupdate -expand -group DIV_ACCEL -color Yellow -itemcolor Yellow ${CORE}/DIVU/ENGINE/divbusy_o
add wave -noupdate -expand -group DIV_ACCEL -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/DIVU/ENGINE/quotient_o
add wave -noupdate -expand -group DIV_ACCEL -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/DIVU/ENGINE/residue_o
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/state_q
add wave -noupdate -expand -group DIV_ACCEL ${CORE}/DIVU/ENGINE/busy_q
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/sr_q
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/dvsr_q
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/qsr_q
add wave -noupdate -expand -group DIV_ACCEL -radix unsigned ${CORE}/DIVU/ENGINE/cnt_q
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/y_w
add wave -noupdate -expand -group DIV_ACCEL -radix hexadecimal ${CORE}/DIVU/ENGINE/diff_w
add wave -noupdate -expand -group DIV_ACCEL ${CORE}/DIVU/ENGINE/nonneg_w

#=============================================================================
# DMEMORY
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {DMEMORY}
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/clk_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/rst_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/dtcm_addr_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/dtcm_data_wr_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/MemRead_ctrl_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/MemWrite_ctrl_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/MemOp_ctrl_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/byte_sel_i
add wave -noupdate -expand -group DMEMORY ${CORE}/MEM/dtcm_cs_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/dtcm_data_rd_o
add wave -noupdate -expand -group DMEMORY ${CORE}/MEM/dtcm_wren_o
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/wrclk_w
add wave -noupdate -expand -group DMEMORY ${CORE}/MEM/wren_w
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/byteena_w
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/store_data_w
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/extend_w
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/q_w

#=============================================================================
# BUS INTERFACE — Figure 1 / Figure 5
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {BUS}
add wave -noupdate -expand -group BUS -radix hexadecimal ${MCU}/dbus_addr_w
add wave -noupdate -expand -group BUS -radix hexadecimal ${MCU}/dbus_wdata_w
add wave -noupdate -expand -group BUS ${MCU}/dbus_MemRead_w
add wave -noupdate -expand -group BUS ${MCU}/dbus_MemWrite_w
add wave -noupdate -expand -group BUS -color Cyan -itemcolor Cyan -radix hexadecimal ${MCU}/data_bus_w
add wave -noupdate -expand -group BUS -radix hexadecimal ${MCU}/dbus_rdata_w
add wave -noupdate -expand -group BUS ${MCU}/dtcm_cs_w
add wave -noupdate -expand -group BUS ${MCU}/unmapped_w
add wave -noupdate -expand -group BUS -radix hexadecimal ${MCU}/sfr_cs_w
add wave -noupdate -expand -group DECODER -radix hexadecimal ${MCU}/DEC/addr_i
add wave -noupdate -expand -group DECODER ${MCU}/DEC/dtcm_cs_o
add wave -noupdate -expand -group DECODER -radix hexadecimal ${MCU}/DEC/sfr_cs_o
add wave -noupdate -expand -group DECODER ${MCU}/DEC/unmapped_o
add wave -noupdate -expand -group DECODER ${MCU}/DEC/sfr_page_w

#=============================================================================
# GPIO — clause 5
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {GPIO}
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/SW_i
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/KEY_i
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/key_pressed_w
add wave -noupdate -expand -group GPIO -color Cyan -itemcolor Cyan -radix hexadecimal ${MCU}/LEDR_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/ledr_q
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/hex_q
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/HEX0_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/HEX1_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/HEX2_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/HEX3_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/HEX4_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/HEX5_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/P_LEDR/q_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/P_HEX0/q_o
add wave -noupdate -expand -group GPIO -radix hexadecimal ${MCU}/P_HEX1/q_o

#=============================================================================
# BASIC TIMER — clause 6.ii
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {BASIC TIMER}
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/clk_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/rst_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/ctl_cs_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/cmpr0_cs_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/cmpr1_cs_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/MemWrite_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/lane0_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/lane1_i
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/data_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/capin1_i
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/capin2_i
add wave -noupdate -expand -group TIMER -color Yellow -itemcolor Yellow ${MCU}/TIMER/pwm_o
add wave -noupdate -expand -group TIMER -color Magenta -itemcolor Magenta ${MCU}/TIMER/btifg_set_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btctl1_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btctl2_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcmpr0_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcmpr1_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcapr_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcnt_o
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btctl1_q
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btctl2_q
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcl0_q
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcl1_q
add wave -noupdate -expand -group TIMER -radix hexadecimal ${MCU}/TIMER/btcnt_q
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/tick_w
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/equ0_w
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/equ1_w
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/cap_ev_w
add wave -noupdate -expand -group TIMER ${MCU}/TIMER/pwm_q

#=============================================================================
# INTERRUPT — clause 6.v / p15 protocol
#=============================================================================
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {INTERRUPT}
add wave -noupdate -expand -group INTR_MCU ${MCU}/intr_w
add wave -noupdate -expand -group INTR_MCU ${MCU}/inta_w
add wave -noupdate -expand -group INTR_MCU ${MCU}/gie_w
add wave -noupdate -expand -group INTR_MCU -radix hexadecimal ${MCU}/key_pressed_w
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/clk_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/rst_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/cs_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/MemWrite_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/lane0_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/lane1_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/bt_ifg_set_i
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/key_pressed_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/gie_i
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/inta_i
add wave -noupdate -expand -group INTR_CTRL -color Magenta -itemcolor Magenta ${MCU}/INTC/intr_o
add wave -noupdate -expand -group INTR_CTRL ${MCU}/INTC/type_push_o
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/type_capt_o
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/ie_o
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/ifg_o
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/type_o
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/ie_q
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/irq_q
add wave -noupdate -expand -group INTR_CTRL -radix hexadecimal ${MCU}/INTC/ifg_w
add wave -noupdate -expand -group INTR_CORE -radix hexadecimal ${CORE}/istate_q
add wave -noupdate -expand -group INTR_CORE ${CORE}/intr_q
add wave -noupdate -expand -group INTR_CORE ${CORE}/accept_w
add wave -noupdate -expand -group INTR_CORE ${CORE}/cyc1_w
add wave -noupdate -expand -group INTR_CORE ${CORE}/cyc2_w
add wave -noupdate -expand -group INTR_CORE ${CORE}/annul_w
add wave -noupdate -expand -group INTR_CORE ${CORE}/reti_w
add wave -noupdate -expand -group INTR_CORE ${CORE}/gie_w
add wave -noupdate -expand -group INTR_CORE -radix hexadecimal ${CORE}/type_q
add wave -noupdate -expand -group INTR_CORE -radix hexadecimal ${CORE}/tp_val_w

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 314
configure wave -valuecolwidth 194
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {1000 ns}
