onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/rst
add wave -noupdate /tb/ena
add wave -noupdate -radix hexadecimal /tb/Y_i
add wave -noupdate -radix hexadecimal /tb/X_i
add wave -noupdate -radix binary /tb/ALUFN_i
add wave -noupdate -radix hexadecimal /tb/ALUout_o
add wave -noupdate /tb/Nflag_o
add wave -noupdate /tb/Cflag_o
add wave -noupdate /tb/Zflag_o
add wave -noupdate /tb/Vflag_o
add wave -noupdate /tb/PWMout_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 64
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
WaveRestoreZoom {0 ps} {2093455 ps}
