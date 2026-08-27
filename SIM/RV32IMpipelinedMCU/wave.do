onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32impipelinedmcu/rst_i
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32impipelinedmcu/clk_i
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/IFpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/IFinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/IDpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/IDinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/EXpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/EXinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/MEMpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/MEMinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/WBpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/WBinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32impipelinedmcu/STRIGGER_o
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/stall_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/hold_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/flush_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/redirect_addr_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/forward_a_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/forward_b_w
add wave -noupdate -expand -group COUNTERS -radix unsigned /tb_rv32impipelinedmcu/CLKCNT_o
add wave -noupdate -expand -group COUNTERS -radix unsigned /tb_rv32impipelinedmcu/STCNT_o
add wave -noupdate -expand -group COUNTERS -radix unsigned /tb_rv32impipelinedmcu/FHCNT_o
add wave -noupdate -expand -group COUNTERS -radix hexadecimal /tb_rv32impipelinedmcu/BPADDR_i
add wave -noupdate -expand -group COUNTERS -radix hexadecimal /tb_rv32impipelinedmcu/STRIGGER_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/Jal_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/Jalr_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/ALUOp_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/mul_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/DivStart_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/DivSigned_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/DivRem_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/div_w
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/CTL/rem_w
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/MUL1/a_i
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/MUL1/b_i
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/MUL1/p0_o
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/MUL1/p1_o
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/MUL1/p2_o
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/MUL1/p3_o
add wave -noupdate -expand -group MUL_STAGE2 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/MEM/mul_res_w
add wave -noupdate -expand -group MUL_STAGE2 -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/MEM/mem_result_w
add wave -noupdate -divider {DIV}
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/CTL/DivStart_ctrl_o
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/CTL/DivSigned_ctrl_o
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/CTL/DivRem_ctrl_o
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/CTL/div_w
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/CTL/rem_w
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/ex_DivStart_w
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/hold_w
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/div_busy_w
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/div_done_w
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/div_result_w
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/EXE/hold_i
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/EXE/DivStart_ctrl_i
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/fw_rs1_o
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/fw_rs2_o
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/EXE/div_result_i
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/start_i
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/signed_i
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/DIVU/dividend_i
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/DIVU/divisor_i
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/busy_o
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/done_o
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/DIVU/quotient_o
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/DIVU/remainder_o
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/ENGINE/divena_i
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/ENGINE/divbusy_o
add wave -noupdate -expand -group DIV /tb_rv32impipelinedmcu/MCU/CORE/DIVU/ENGINE/state_q
add wave -noupdate -expand -group DIV -radix unsigned /tb_rv32impipelinedmcu/MCU/CORE/DIVU/ENGINE/cnt_q
add wave -noupdate -expand -group REGFILE -radix hexadecimal /tb_rv32impipelinedmcu/MCU/CORE/ID/RF_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 290
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ns} {914 ns}
