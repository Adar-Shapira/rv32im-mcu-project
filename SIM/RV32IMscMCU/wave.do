onerror {resume}
quietly WaveActivateNextPane {} 0
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
