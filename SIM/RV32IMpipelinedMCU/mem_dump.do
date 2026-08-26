# mem_dump.do - export the DTCM to DTCM.mem, one bare hex word per line
#               (same format as the RARS golden DTCM.h)
#
# endaddress is a variable, and the default changed on 2026-08-26 from 1023 to
# 2047 - the whole DTCM. This mirrors the single-cycle mem_dump.do, which made
# the same change on 2026-08-24, and for the same two reasons: the reference
# ships full 2048-word captures of its own for THIS core too
# (Auxiliary/Lab 5/SIM/RV32IM_pipeline/DTCM_testN_MS.mem, 2051 lines = 3 header
# + 2048 data), so there is finally something to compare the upper half
# against; and batch_verify.do now diffs against exactly those files, which a
# 1024-word dump cannot do at all. That is gap G-204 on the pipeline side.
#
# Set it back to 1023 only to diff against a 1024-word RARS golden
# (Benchmark Apps/*/output/RARS/DTCM.h). Note G-404: test1's
# output/RARS/DTCM.hex is stale - use DTCM.h.
#
# NOTE: `mem save` reaches into the precompiled altsyncram model's internals, so
# this script is version-locked to ModelSim ASE 2020.1.
set dtcm_path /tb_rv32impipelinedmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
set last_word 2047

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