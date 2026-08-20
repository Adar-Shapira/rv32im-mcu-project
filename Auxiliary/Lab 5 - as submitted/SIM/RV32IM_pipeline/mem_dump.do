# mem_dump.do - export DTCM words 0..1023 to DTCM.mem,
# one bare hex word per line (same format as the RARS golden DTCM.h)
mem save -format mti -data hex -addr decimal -wordsperline 1 \
    -startaddress 0 -endaddress 1023 \
    -outfile DTCM_raw.mem /tb_rv32im_pipeline/CORE/MEM/data_memory/MEMORY/m_mem_data_a

set fin  [open DTCM_raw.mem r]
set fout [open DTCM.mem w]
while {[gets $fin line] >= 0} {
    if {[string match "//*" $line] || [string trim $line] eq ""} { continue }
    puts $fout [string toupper [string trim [lindex [split $line ":"] end]]]
}
close $fin
close $fout
file delete DTCM_raw.mem
echo "DTCM.mem written"