onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32im_pipeline/rst_i
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32im_pipeline/clk_i
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/IFpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/IFinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/IDpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/IDinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/EXpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/EXinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/MEMpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/MEMinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/WBpc_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/WBinstruction_o
add wave -noupdate -expand -group STAGES -radix hexadecimal /tb_rv32im_pipeline/STRIGGER_o
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32im_pipeline/CORE/stall_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32im_pipeline/CORE/flush_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32im_pipeline/CORE/redirect_addr_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32im_pipeline/CORE/forward_a_w
add wave -noupdate -expand -group PIPE_CTRL -radix hexadecimal /tb_rv32im_pipeline/CORE/forward_b_w
add wave -noupdate -expand -group COUNTERS -radix unsigned /tb_rv32im_pipeline/CLKCNT_o
add wave -noupdate -expand -group COUNTERS -radix unsigned /tb_rv32im_pipeline/STCNT_o
add wave -noupdate -expand -group COUNTERS -radix unsigned /tb_rv32im_pipeline/FHCNT_o
add wave -noupdate -expand -group COUNTERS -radix hexadecimal /tb_rv32im_pipeline/BPADDR_i
add wave -noupdate -expand -group COUNTERS -radix hexadecimal /tb_rv32im_pipeline/STRIGGER_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_pipeline/CORE/CTL/Jal_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_pipeline/CORE/CTL/Jalr_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_pipeline/CORE/CTL/ALUOp_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32im_pipeline/CORE/CTL/mul_w
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32im_pipeline/CORE/EXE/MUL1/a_i
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32im_pipeline/CORE/EXE/MUL1/b_i
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32im_pipeline/CORE/EXE/MUL1/p0_o
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32im_pipeline/CORE/EXE/MUL1/p1_o
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32im_pipeline/CORE/EXE/MUL1/p2_o
add wave -noupdate -expand -group MUL_STAGE1 -radix hexadecimal /tb_rv32im_pipeline/CORE/EXE/MUL1/p3_o
add wave -noupdate -expand -group MUL_STAGE2 -radix hexadecimal /tb_rv32im_pipeline/CORE/MEM/mul_res_w
add wave -noupdate -expand -group MUL_STAGE2 -radix hexadecimal /tb_rv32im_pipeline/CORE/MEM/mem_result_w
add wave -noupdate -expand -group REGFILE -radix hexadecimal /tb_rv32im_pipeline/CORE/ID/RF_q
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
