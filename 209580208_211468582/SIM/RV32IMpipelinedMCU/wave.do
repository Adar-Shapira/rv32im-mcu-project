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

add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/KEY_i
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/SW_i
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/ledr_q
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/hex_q
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/HEX0_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/HEX1_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/HEX2_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/HEX3_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/HEX4_o
add wave -noupdate -expand -group GPIO -radix hexadecimal /tb_rv32impipelinedmcu/MCU/HEX5_o
add wave -noupdate -expand -group GPIO /tb_rv32impipelinedmcu/MCU/PWM_o
add wave -noupdate -expand -group INTR /tb_rv32impipelinedmcu/MCU/intr_w
add wave -noupdate -expand -group INTR /tb_rv32impipelinedmcu/MCU/inta_w
add wave -noupdate -expand -group INTR /tb_rv32impipelinedmcu/MCU/gie_w
add wave -noupdate -expand -group INTR -radix hexadecimal /tb_rv32impipelinedmcu/MCU/INTC/ie_o
add wave -noupdate -expand -group INTR -radix hexadecimal /tb_rv32impipelinedmcu/MCU/INTC/ifg_o
add wave -noupdate -expand -group INTR -radix hexadecimal /tb_rv32impipelinedmcu/MCU/INTC/type_o
add wave -noupdate -expand -group INTR /tb_rv32impipelinedmcu/MCU/CORE/accept_w
add wave -noupdate -expand -group INTR /tb_rv32impipelinedmcu/MCU/CORE/CTL/Reti_ctrl_o
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/btctl1_q
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/btctl2_q
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/capmd_w
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/capisel_w
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/btcnt_q
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/btcl0_q
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/btcl1_q
add wave -noupdate -expand -group TIMER /tb_rv32impipelinedmcu/MCU/TIMER/cap_ev_w
add wave -noupdate -expand -group TIMER -radix hexadecimal /tb_rv32impipelinedmcu/MCU/TIMER/btcapr_q
add wave -noupdate -expand -group DIV ${CORE}/CTL/DivStart_ctrl_o
add wave -noupdate -expand -group DIV ${CORE}/CTL/DivRem_ctrl_o
add wave -noupdate -expand -group DIV ${CORE}/CTL/div_w
add wave -noupdate -expand -group DIV ${CORE}/CTL/rem_w
add wave -noupdate -expand -group DIV ${CORE}/DIVU/start_i
add wave -noupdate -expand -group DIV -radix hexadecimal ${CORE}/DIVU/dividend_i
add wave -noupdate -expand -group DIV -radix hexadecimal ${CORE}/DIVU/divisor_i

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
