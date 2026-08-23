# golden.do - RV32IM single-cycle waveform, styled like Auxilary/RV32I/SIM/RV32I.do
onerror {resume}
quietly WaveActivateNextPane {} 0
quietly delete wave *

add wave -noupdate -divider {TOP}
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/clk_i
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/rst_i
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/pc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal /tb_rv32im_sc/instruction_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/RegWrite_ctrl_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/MemWrite_ctrl_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/Branch_ctrl_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/read_data1_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/read_data2_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/write_data_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/alu_res_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/brTaken_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/dtcm_addr_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/dtcm_data_wr_o
add wave -noupdate -radix hexadecimal /tb_rv32im_sc/dtcm_data_rd_o
add wave -noupdate -color Cyan -itemcolor Cyan -radix unsigned /tb_rv32im_sc/mclk_cnt_o
add wave -noupdate -color Yellow -itemcolor Yellow /tb_rv32im_sc/CORE/IFE/rst_q

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {IFETCH}
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/clk_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/rst_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/addr_gen_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/Branch_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/brTaken_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/Jal_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/Jalr_ctrl_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/alu_res_i
add wave -noupdate -expand -group IFETCH -color Magenta -itemcolor Magenta -radix hexadecimal /tb_rv32im_sc/CORE/IFE/pc_o
add wave -noupdate -expand -group IFETCH -color Blue -itemcolor Blue -radix hexadecimal /tb_rv32im_sc/CORE/IFE/pc_plus4_o
add wave -noupdate -expand -group IFETCH -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/IFE/next_pc_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/instruction_o
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/pc_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/pc_plus4_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/pc_plus4_r
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/itcm_addr_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/brTaken_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal /tb_rv32im_sc/CORE/IFE/rst_q

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {IDECODE}
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/clk_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/rst_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/pc_plus4_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/instruction_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/dtcm_data_rd_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/alu_res_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/RegDst_ctrl_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/RegWrite_ctrl_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/MemtoReg_ctrl_i
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/read_data1_o
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/read_data2_o
add wave -noupdate -expand -group IDECODE -color Blue -itemcolor Blue -radix hexadecimal /tb_rv32im_sc/CORE/ID/SignExt_o
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/write_data_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/opc_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/rs1_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/rs2_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/rd_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/Iimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/Simm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/SBimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/Uimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/UJimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/SignExt_Iimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/SignExt_Simm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/SignExt_SBimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/SignExt_Uimm_w
add wave -noupdate -expand -group IDECODE -radix hexadecimal /tb_rv32im_sc/CORE/ID/SignExt_UJimm_w

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {REGISTER FILE}
add wave -noupdate -expand -group REGFILE -radix hexadecimal /tb_rv32im_sc/CORE/ID/RF_q

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {CONTROL}
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/instruction_i
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/RegDst_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/ALUSrc_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/MemtoReg_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/RegWrite_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/MemRead_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/MemWrite_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Branch_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Jal_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Jalr_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/UpperIm_ctrl_o
add wave -noupdate -expand -group CONTROL -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/CTL/ALUOp_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Rtype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Itype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Stype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/SBtype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/Utype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/UJtype_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lb_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lh_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lw_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lbu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lhu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lwu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/ld_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sb_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sh_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sw_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/st_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/beq_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/bne_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/blt_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/bge_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/bltu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/bgeu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/branch_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/jal_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/jalr_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/add_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/addi_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/and_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/andi_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/or_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/ori_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sll_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/slli_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sra_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/srai_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/srl_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/srli_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sub_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/xor_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/xori_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/auipc_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/lui_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/slt_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/slti_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sltu_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/sltiu_w
add wave -noupdate -expand -group CONTROL -color Yellow -itemcolor Yellow -radix hexadecimal /tb_rv32im_sc/CORE/CTL/mul_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_sc/CORE/CTL/opc_w

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {EXECUTE}
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/read_data1_i
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/read_data2_i
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/UpperIm_ctrl_i
add wave -noupdate -expand -group EXECUTE -color Yellow -itemcolor Yellow -radix hexadecimal /tb_rv32im_sc/CORE/EXE/ALUOp_ctrl_i
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/ALUSrc_ctrl_i
add wave -noupdate -expand -group EXECUTE -color {Violet Red} -itemcolor {Violet Red} -radix hexadecimal /tb_rv32im_sc/CORE/EXE/pc_i
add wave -noupdate -expand -group EXECUTE -color Navy -itemcolor Navy -radix hexadecimal /tb_rv32im_sc/CORE/EXE/sign_extend_i
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/EXE/addr_gen_o
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/sub_res_w
add wave -noupdate -expand -group EXECUTE -color Magenta -itemcolor Magenta -radix hexadecimal /tb_rv32im_sc/CORE/EXE/ain_w
add wave -noupdate -expand -group EXECUTE -color Blue -itemcolor Blue -radix hexadecimal /tb_rv32im_sc/CORE/EXE/bin_w
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/EXE/alu_res_o
add wave -noupdate -expand -group EXECUTE -color {Medium Spring Green} -itemcolor {Medium Spring Green} -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brTaken_o
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/ltu_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/eq_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/msbneq_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brTaken_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/alu_res_r
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/EXE/mul_res_w
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shl_s1_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shl_s2_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shl_s3_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shl_s4_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shr_s1_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shr_s2_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shr_s3_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shr_s4_r
add wave -noupdate -expand -group EXECUTE -radix hexadecimal /tb_rv32im_sc/CORE/EXE/brl_shr_pad_r

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {MUL16}
add wave -noupdate -expand -group MUL16 -color Magenta -itemcolor Magenta -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/a_i
add wave -noupdate -expand -group MUL16 -color Blue -itemcolor Blue -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/b_i
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/al_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/ah_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/bl_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/bh_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/p0_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/p1_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/p2_w
add wave -noupdate -expand -group MUL16 -color Yellow -itemcolor Yellow -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/p3_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/mid_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/term0_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/term1_w
add wave -noupdate -expand -group MUL16 -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/term2_w
add wave -noupdate -expand -group MUL16 -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/res_w
add wave -noupdate -expand -group MUL16 -color Cyan -itemcolor Cyan -radix hexadecimal /tb_rv32im_sc/CORE/EXE/MUL/res_o

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {DMEMORY}
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/clk_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/rst_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/dtcm_addr_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/dtcm_data_wr_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/MemRead_ctrl_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/MemWrite_ctrl_i
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/dtcm_data_rd_o
add wave -noupdate -expand -group DMEMORY -radix hexadecimal /tb_rv32im_sc/CORE/MEM/wrclk_w

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
