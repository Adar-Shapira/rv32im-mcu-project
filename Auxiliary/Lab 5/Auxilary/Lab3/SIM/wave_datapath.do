onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {Clocks & Resets}
add wave -noupdate /tb_datapath/clk
add wave -noupdate /tb_datapath/rst
add wave -noupdate -divider {Datapath Control Signals}
add wave -noupdate /tb_datapath/Imm1_in
add wave -noupdate /tb_datapath/RFout
add wave -noupdate /tb_datapath/RFin
add wave -noupdate /tb_datapath/Ain
add wave -noupdate /tb_datapath/Cin
add wave -noupdate /tb_datapath/Cout
add wave -noupdate /tb_datapath/ALUFN
add wave -noupdate -divider {Data & Instruction}
add wave -noupdate -radix hexadecimal /tb_datapath/Instruction_in
add wave -noupdate -divider Flags
add wave -noupdate /tb_datapath/Zflag
add wave -noupdate /tb_datapath/Nflag
add wave -noupdate /tb_datapath/Cflag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ps} {800 ns}
