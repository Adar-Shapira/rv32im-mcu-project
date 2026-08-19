onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clocks & Enables}
add wave -noupdate /tb_control/clk
add wave -noupdate /tb_control/rst
add wave -noupdate /tb_control/ena
add wave -noupdate -divider {Inputs from IR & ALU}
add wave -noupdate -radix hexadecimal /tb_control/OPC
add wave -noupdate /tb_control/Cflag
add wave -noupdate /tb_control/Zflag
add wave -noupdate /tb_control/Nflag
add wave -noupdate -divider {Internal FSM State}
add wave -noupdate /tb_control/uut/state
add wave -noupdate /tb_control/uut/next_state
add wave -noupdate -divider {Fetch & PC Control}
add wave -noupdate /tb_control/PCin
add wave -noupdate /tb_control/PCsel
add wave -noupdate /tb_control/IRin
add wave -noupdate -divider {RF & ALU Control}
add wave -noupdate /tb_control/RFout
add wave -noupdate /tb_control/RFin
add wave -noupdate /tb_control/Ain
add wave -noupdate /tb_control/Cin
add wave -noupdate /tb_control/Cout
add wave -noupdate -radix hexadecimal /tb_control/ALUFN
add wave -noupdate -divider {Memory & Done}
add wave -noupdate /tb_control/DTCM_wr
add wave -noupdate /tb_control/done
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {623602 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1 us}
