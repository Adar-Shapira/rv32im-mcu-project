# golden.do - RV32IM pipeline waveform, styled like Auxilary/RV32I/SIM/RV32I.do
onerror {resume}
quietly WaveActivateNextPane {} 0
quietly delete wave *

set TB   /tb_rv32impipelinedmcu
set CORE ${TB}/MCU/CORE

add wave -noupdate -divider {TOP}
add wave -noupdate -radix hexadecimal ${TB}/clk_i
add wave -noupdate -radix hexadecimal ${TB}/rst_i
add wave -noupdate -radix hexadecimal ${TB}/BPADDR_i
add wave -noupdate -color Cyan -itemcolor Cyan -radix unsigned ${TB}/CLKCNT_o
add wave -noupdate -radix hexadecimal ${TB}/IFpc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal ${TB}/IFinstruction_o
add wave -noupdate -radix hexadecimal ${TB}/IDpc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal ${TB}/IDinstruction_o
add wave -noupdate -radix hexadecimal ${TB}/EXpc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal ${TB}/EXinstruction_o
add wave -noupdate -radix hexadecimal ${TB}/MEMpc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal ${TB}/MEMinstruction_o
add wave -noupdate -radix hexadecimal ${TB}/WBpc_o
add wave -noupdate -color Blue -itemcolor Blue -radix hexadecimal ${TB}/WBinstruction_o
add wave -noupdate -color {Medium Spring Green} -itemcolor {Medium Spring Green} ${TB}/STRIGGER_o
add wave -noupdate -color Magenta -itemcolor Magenta -radix unsigned ${TB}/FHCNT_o
add wave -noupdate -color Yellow -itemcolor Yellow -radix unsigned ${TB}/STCNT_o

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {PIPELINE CONTROL}
add wave -noupdate -expand -group PIPE_CONTROL -color Yellow -itemcolor Yellow ${CORE}/stall_w
add wave -noupdate -expand -group PIPE_CONTROL -color {Violet Red} -itemcolor {Violet Red} ${CORE}/flush_w
add wave -noupdate -expand -group PIPE_CONTROL -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/redirect_addr_w
add wave -noupdate -expand -group PIPE_CONTROL -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/forward_a_w
add wave -noupdate -expand -group PIPE_CONTROL -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/forward_b_w
add wave -noupdate -expand -group PIPE_CONTROL -color Cyan -itemcolor Cyan -radix unsigned ${CORE}/mclk_cnt_q
add wave -noupdate -expand -group PIPE_CONTROL -color Yellow -itemcolor Yellow -radix unsigned ${CORE}/stcnt_q
add wave -noupdate -expand -group PIPE_CONTROL -color Magenta -itemcolor Magenta -radix unsigned ${CORE}/fhcnt_q
add wave -noupdate -expand -group PIPE_CONTROL -radix hexadecimal ${CORE}/bpaddr_q

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {PIPELINE STAGES}
add wave -noupdate -expand -group PIPELINE -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/if_pc_w
add wave -noupdate -expand -group PIPELINE -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/id_instruction_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/id_pc_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/id_pc_plus4_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/id_rs1_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/id_rs2_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_pc_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_pc_plus4_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_read_data1_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_read_data2_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_sign_ext_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_rs1_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_rs2_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/ex_rd_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/mem_pc_plus4_w
add wave -noupdate -expand -group PIPELINE -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/mem_alu_res_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/mem_write_data_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/mem_addr_gen_w
add wave -noupdate -expand -group PIPELINE -color {Medium Spring Green} -itemcolor {Medium Spring Green} ${CORE}/mem_brTaken_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/mem_rd_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/wb_pc_plus4_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/wb_alu_res_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/wb_dtcm_data_rd_w
add wave -noupdate -expand -group PIPELINE -radix hexadecimal ${CORE}/wb_rd_w
add wave -noupdate -expand -group PIPELINE -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/wb_write_data_w

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {IFETCH}
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/clk_i
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/rst_i
add wave -noupdate -expand -group IFETCH -color Yellow -itemcolor Yellow ${CORE}/IFE/stall_i
add wave -noupdate -expand -group IFETCH -color {Violet Red} -itemcolor {Violet Red} ${CORE}/IFE/flush_i
add wave -noupdate -expand -group IFETCH -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/IFE/redirect_addr_i
add wave -noupdate -expand -group IFETCH -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/IFE/if_pc_o
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_o
add wave -noupdate -expand -group IFETCH -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/IFE/pc_plus4_o
add wave -noupdate -expand -group IFETCH -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/IFE/instruction_o
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_plus4_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/pc_plus4_r
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/itcm_addr_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/itcm_data_w
add wave -noupdate -expand -group IFETCH -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/IFE/next_pc_w
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/rst_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/if_id_pc_q
add wave -noupdate -expand -group IFETCH -radix hexadecimal ${CORE}/IFE/if_id_pc_plus4_q
add wave -noupdate -expand -group IFETCH -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/IFE/if_id_instruction_q

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {IDECODE / ID-EX}
add wave -noupdate -expand -group IDECODE -radix hexadecimal ${CORE}/ID/*
add wave -noupdate -expand -group REGFILE -radix hexadecimal ${CORE}/ID/RF_q
add wave -noupdate -expand -group ID_EX -color Yellow -itemcolor Yellow ${CORE}/ID/bubble_w
add wave -noupdate -expand -group ID_EX -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/ID/id_ex_ALUOp_q
add wave -noupdate -expand -group ID_EX -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/ID/id_ex_read_data1_q
add wave -noupdate -expand -group ID_EX -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/ID/id_ex_read_data2_q
add wave -noupdate -expand -group ID_EX -color Navy -itemcolor Navy -radix hexadecimal ${CORE}/ID/id_ex_sign_ext_q

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {CONTROL}
add wave -noupdate -expand -group CONTROL -radix hexadecimal ${CORE}/CTL/*
add wave -noupdate -expand -group CONTROL -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/CTL/ALUOp_ctrl_o
add wave -noupdate -expand -group CONTROL -color Yellow -itemcolor Yellow ${CORE}/CTL/mul_w

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {EXECUTE / EX-MEM}
add wave -noupdate -expand -group EXECUTE -radix hexadecimal ${CORE}/EXE/*
add wave -noupdate -expand -group EXECUTE -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/EXE/fw_read_data1_w
add wave -noupdate -expand -group EXECUTE -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/EXE/fw_read_data2_w
add wave -noupdate -expand -group EXECUTE -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/EXE/ain_w
add wave -noupdate -expand -group EXECUTE -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/EXE/bin_w
add wave -noupdate -expand -group EXECUTE -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/EXE/alu_res_r
add wave -noupdate -expand -group EXECUTE -color {Medium Spring Green} -itemcolor {Medium Spring Green} ${CORE}/EXE/brTaken_w

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {MULTIPLIER EX / MEM}
add wave -noupdate -expand -group MULT_STAGE1 -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/EXE/MUL1/a_i
add wave -noupdate -expand -group MULT_STAGE1 -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/EXE/MUL1/b_i
add wave -noupdate -expand -group MULT_STAGE1 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL1/p0_o
add wave -noupdate -expand -group MULT_STAGE1 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL1/p1_o
add wave -noupdate -expand -group MULT_STAGE1 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL1/p2_o
add wave -noupdate -expand -group MULT_STAGE1 -color Yellow -itemcolor Yellow -radix hexadecimal ${CORE}/EXE/MUL1/p3_o
add wave -noupdate -expand -group EX_MEM_MUL -radix hexadecimal ${CORE}/EXE/ex_mem_mul_p0_q
add wave -noupdate -expand -group EX_MEM_MUL -radix hexadecimal ${CORE}/EXE/ex_mem_mul_p1_q
add wave -noupdate -expand -group EX_MEM_MUL -radix hexadecimal ${CORE}/EXE/ex_mem_mul_p2_q
add wave -noupdate -expand -group EX_MEM_MUL -radix hexadecimal ${CORE}/EXE/ex_mem_mul_p3_q
add wave -noupdate -expand -group EX_MEM_MUL ${CORE}/EXE/ex_mem_Mul_q
add wave -noupdate -expand -group MULT_STAGE2 -radix hexadecimal ${CORE}/MEM/MUL2/middle_w
add wave -noupdate -expand -group MULT_STAGE2 -radix hexadecimal ${CORE}/MEM/MUL2/p0_ext_w
add wave -noupdate -expand -group MULT_STAGE2 -radix hexadecimal ${CORE}/MEM/MUL2/middle_shift_w
add wave -noupdate -expand -group MULT_STAGE2 -radix hexadecimal ${CORE}/MEM/MUL2/p3_shift_w
add wave -noupdate -expand -group MULT_STAGE2 -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/MEM/mul_res_w
add wave -noupdate -expand -group MULT_STAGE2 -color Cyan -itemcolor Cyan -radix hexadecimal ${CORE}/MEM/mem_result_w

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {DMEMORY / MEM-WB}
add wave -noupdate -expand -group DMEMORY -radix hexadecimal ${CORE}/MEM/*
add wave -noupdate -expand -group DTCM -radix hexadecimal ${CORE}/MEM/data_memory/*

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {WRITEBACK}
add wave -noupdate -expand -group WRITEBACK -radix hexadecimal ${CORE}/WB/*

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {HAZARD UNIT}
add wave -noupdate -expand -group HAZARD_UNIT -radix hexadecimal ${CORE}/HZD/*
add wave -noupdate -expand -group HAZARD_UNIT -color Yellow -itemcolor Yellow ${CORE}/HZD/stall_o

TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {FORWARD UNIT}
add wave -noupdate -expand -group FORWARD_UNIT -radix hexadecimal ${CORE}/FWD/*
add wave -noupdate -expand -group FORWARD_UNIT -color Magenta -itemcolor Magenta -radix hexadecimal ${CORE}/FWD/forward_a_o
add wave -noupdate -expand -group FORWARD_UNIT -color Blue -itemcolor Blue -radix hexadecimal ${CORE}/FWD/forward_b_o

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
