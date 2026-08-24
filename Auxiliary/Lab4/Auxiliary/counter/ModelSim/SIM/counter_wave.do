onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /test_counter/clk_i
add wave -noupdate -radix hexadecimal /test_counter/ena_i
add wave -noupdate -radix unsigned /test_counter/count_o
add wave -noupdate -color Blue -itemcolor Blue -radix unsigned -childformat {{/test_counter/tester/count_q(31) -radix unsigned} {/test_counter/tester/count_q(30) -radix unsigned} {/test_counter/tester/count_q(29) -radix unsigned} {/test_counter/tester/count_q(28) -radix unsigned} {/test_counter/tester/count_q(27) -radix unsigned} {/test_counter/tester/count_q(26) -radix unsigned} {/test_counter/tester/count_q(25) -radix unsigned} {/test_counter/tester/count_q(24) -radix unsigned} {/test_counter/tester/count_q(23) -radix unsigned} {/test_counter/tester/count_q(22) -radix unsigned} {/test_counter/tester/count_q(21) -radix unsigned} {/test_counter/tester/count_q(20) -radix unsigned} {/test_counter/tester/count_q(19) -radix unsigned} {/test_counter/tester/count_q(18) -radix unsigned} {/test_counter/tester/count_q(17) -radix unsigned} {/test_counter/tester/count_q(16) -radix unsigned} {/test_counter/tester/count_q(15) -radix unsigned} {/test_counter/tester/count_q(14) -radix unsigned} {/test_counter/tester/count_q(13) -radix unsigned} {/test_counter/tester/count_q(12) -radix unsigned} {/test_counter/tester/count_q(11) -radix unsigned} {/test_counter/tester/count_q(10) -radix unsigned} {/test_counter/tester/count_q(9) -radix unsigned} {/test_counter/tester/count_q(8) -radix unsigned} {/test_counter/tester/count_q(7) -radix unsigned} {/test_counter/tester/count_q(6) -radix unsigned} {/test_counter/tester/count_q(5) -radix unsigned} {/test_counter/tester/count_q(4) -radix unsigned} {/test_counter/tester/count_q(3) -radix unsigned} {/test_counter/tester/count_q(2) -radix unsigned} {/test_counter/tester/count_q(1) -radix unsigned} {/test_counter/tester/count_q(0) -radix unsigned}} -subitemconfig {/test_counter/tester/count_q(31) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(30) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(29) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(28) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(27) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(26) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(25) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(24) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(23) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(22) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(21) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(20) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(19) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(18) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(17) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(16) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(15) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(14) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(13) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(12) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(11) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(10) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(9) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(8) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(7) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(6) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(5) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(4) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(3) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(2) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(1) {-color Blue -itemcolor Blue -radix unsigned} /test_counter/tester/count_q(0) {-color Blue -itemcolor Blue -radix unsigned}} /test_counter/tester/count_q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {160000 ps} 0} {{Cursor 2} {20000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 205
configure wave -valuecolwidth 108
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
WaveRestoreZoom {0 ps} {491984 ps}
bookmark add wave bookmark1 {{36 ps} {116 ps}} 0
bookmark add wave bookmark2 {{0 ps} {1 ns}} 0
