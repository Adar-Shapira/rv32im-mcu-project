# mem_dump.do - export the DTCM to DTCM.mem, one bare hex word per line
#                (same format as the RARS golden DTCM.h)
#
# Reference: Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/mem_dump.do
# Changes:
#   1. The hierarchical path gained one level. The MCU wrapper now sits between
#      the testbench and the core, so the memory is at
#        /tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
#      and not
#        /tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a
#      Getting this wrong produces an empty dump, not an error.
#   2. endaddress is a variable. The reference hardcoded 1023, which covers only
#      the lower half of the 2048-word DTCM. The RARS goldens are also 1024
#      words, so keep 1023 for golden comparison, but raise it to 2047 when the
#      whole memory needs inspecting - the upper half is otherwise never checked
#      by anything.
#
# NOTE: `mem save` reaches into the precompiled altsyncram model's internals, so
# this script is version-locked to ModelSim ASE 2020.1.

set dtcm_path /tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
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
