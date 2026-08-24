onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /test_counter/clk_i
add wave -noupdate -radix unsigned /test_counter/ena_i
add wave -noupdate -color Cyan -itemcolor Cyan -radix unsigned /test_counter/count_o
add wave -noupdate -expand -group pll -radix unsigned /test_counter/tester/m1/inclk0
add wave -noupdate -expand -group pll -radix unsigned /test_counter/tester/m1/c0
add wave -noupdate -expand -group counter -radix unsigned /test_counter/tester/m0/clk_i
add wave -noupdate -expand -group counter -radix unsigned /test_counter/tester/m0/ena_i
add wave -noupdate -expand -group counter -radix unsigned /test_counter/tester/m0/count_q
add wave -noupdate -expand -group counter -color Cyan -itemcolor Cyan -radix unsigned /test_counter/tester/m0/count_o
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1283803 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 249
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
WaveRestoreZoom {0 ps} {3841320 ps}
bookmark add wave bookmark9 {{36 ps} {116 ps}} 0
bookmark add wave bookmark10 {{0 ps} {1 ns}} 0
