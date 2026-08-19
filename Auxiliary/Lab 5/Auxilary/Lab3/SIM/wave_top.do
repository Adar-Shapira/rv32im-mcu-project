onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {System Control}
add wave -noupdate /tb_top/clk
add wave -noupdate /tb_top/rst
add wave -noupdate /tb_top/ena
add wave -noupdate /tb_top/TBactive
add wave -noupdate /tb_top/done
add wave -noupdate -divider {Instruction Memory (ITCM)}
add wave -noupdate /tb_top/TB_ITCM_en
add wave -noupdate -radix hexadecimal /tb_top/TB_ITCM_addr
add wave -noupdate -radix hexadecimal /tb_top/TB_ITCM_din
add wave -noupdate -divider {Data Memory (DTCM)}
add wave -noupdate /tb_top/TB_DTCM_en
add wave -noupdate /tb_top/TB_DTCM_wr
add wave -noupdate -radix hexadecimal /tb_top/TB_DTCM_addr
add wave -noupdate -radix hexadecimal /tb_top/TB_DTCM_din
add wave -noupdate -radix hexadecimal /tb_top/TB_DTCM_dout
add wave -noupdate -divider {CPU Internals}
add wave -noupdate /tb_top/uut/Control_inst/state
add wave -noupdate /tb_top/uut/Control_inst/next_state
add wave -noupdate -radix hexadecimal /tb_top/uut/Datapath_inst/PC_out_addr
add wave -noupdate -radix hexadecimal /tb_top/uut/Datapath_inst/Instruction_in
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
WaveRestoreZoom {0 ps} {4 us}
