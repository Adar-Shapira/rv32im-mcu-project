# mem_dump.do - export DTCM words 0..1023 to DTCM.mem,
# one bare hex word per line (same format as the RARS golden DTCM.h)
# endaddress is a variable: the RARS goldens are 1024 words, so keep 1023 for
# golden comparison and raise it to 2047 to inspect the whole 2048-word DTCM -
# the upper half is otherwise never checked by anything.
set dtcm_path /tb_rv32impipelinedmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
set last_word 1023

mem save -format mti -data hex -addr decimal -wordsperline 1 \
    -startaddress 0 -endaddress $last_word \
    -outfile DTCM_raw.mem $dtcm_path

set fin  [open DTCM_raw.mem r]
set fout [open DTCM.mem w]
while {[gets $fin line] >= 0} {
    if {[string match "//*" $line] || [string trim $line] eq ""} { continue }
    puts $fout [string toupper [string trim [lindex [split $line ":"] end]]]
}
close $fin
close $fout
file delete DTCM_raw.mem
echo "DTCM.mem written ([expr {$last_word + 1}] words)"