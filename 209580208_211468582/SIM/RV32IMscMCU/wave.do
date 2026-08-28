# wave.do — compact daily waveform for RV32IMscMCU
#
# Lab 5 SIM/RV32IM_sc/wave.do plus DIV / GPIO / interrupt so the same
# window covers every official benchmark. For the full signal set
# (report screenshots, debugging a submodule) use golden.do instead.
#
# After simulating work.tb_rv32imscmcu:  do wave.do

onerror {resume}
quietly WaveActivateNextPane {} 0
quietly delete wave *

add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/rst_i
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/clk_i
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/pc_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/instruction_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/RegWrite_ctrl_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/MemWrite_ctrl_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/Branch_ctrl_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/read_data1_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/read_data2_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/write_data_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/alu_res_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/brTaken_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/dtcm_addr_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/dtcm_data_wr_o
add wave -noupdate -expand -group TOP -radix hexadecimal /tb_rv32imscmcu/dtcm_data_rd_o
add wave -noupdate -expand -group TOP -radix unsigned /tb_rv32imscmcu/mclk_cnt_o

add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/SW_i
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/KEY_i
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/LEDR_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/HEX0_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/HEX1_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/HEX2_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/HEX3_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/HEX4_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32imscmcu/HEX5_o
add wave -noupdate -expand -group GPIO /tb_rv32imscmcu/PWM_o
add wave -noupdate -expand -group GPIO /tb_rv32imscmcu/CAPIN1_i
add wave -noupdate -expand -group GPIO /tb_rv32imscmcu/CAPIN2_i

add wave -noupdate -divider {DIV}
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/CTL/DivStart_ctrl_o
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/CTL/DivSigned_ctrl_o
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/CTL/DivRem_ctrl_o
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/CTL/div_w
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/CTL/rem_w
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/pc_hold_w
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/div_busy_w
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/div_done_w
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/DIVU/dividend_i
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/DIVU/divisor_i
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/DIVU/quotient_o
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/DIVU/remainder_o
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/DIVU/ENGINE/divena_i
add wave -noupdate -expand -group DIV /tb_rv32imscmcu/MCU/CORE/DIVU/ENGINE/divbusy_o
add wave -noupdate -expand -group DIV -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/DIVU/ENGINE/state_q
add wave -noupdate -expand -group DIV -radix unsigned /tb_rv32imscmcu/MCU/CORE/DIVU/ENGINE/cnt_q

add wave -noupdate -expand -group INTR /tb_rv32imscmcu/MCU/intr_w
add wave -noupdate -expand -group INTR /tb_rv32imscmcu/MCU/inta_w
add wave -noupdate -expand -group INTR /tb_rv32imscmcu/MCU/gie_w
add wave -noupdate -expand -group INTR -radix hexadecimal /tb_rv32imscmcu/MCU/INTC/ie_o
add wave -noupdate -expand -group INTR -radix hexadecimal /tb_rv32imscmcu/MCU/INTC/ifg_o
add wave -noupdate -expand -group INTR -radix hexadecimal /tb_rv32imscmcu/MCU/INTC/type_o
add wave -noupdate -expand -group INTR /tb_rv32imscmcu/MCU/TIMER/btifg_set_o
add wave -noupdate -expand -group INTR /tb_rv32imscmcu/MCU/CORE/CTL/Reti_ctrl_o

add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/CTL/Jal_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/CTL/Jalr_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/CTL/ALUOp_ctrl_o
add wave -noupdate -expand -group CONTROL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/CTL/mul_w

add wave -noupdate -expand -group MUL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/EXE/MUL/a_i
add wave -noupdate -expand -group MUL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/EXE/MUL/b_i
add wave -noupdate -expand -group MUL -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/EXE/MUL/res_o

add wave -noupdate -expand -group REGFILE -radix hexadecimal /tb_rv32imscmcu/MCU/CORE/ID/RF_q

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
