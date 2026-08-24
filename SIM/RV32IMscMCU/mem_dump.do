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
#   2. endaddress is a variable, and the default changed on 2026-08-24 from 1023
#      to 2047 - the whole DTCM. Gap G-204 was that the lower half was all
#      anything ever checked. Two things made the wider range the right default:
#      the replaced reference now ships full 2048-word captures of its own
#      (SIM/RV32IM_sc/DTCM_testN_MS.mem, 2051 lines = 3 header + 2048 data), so
#      there is finally something to compare the upper half against; and
#      Phase 3B's sub-word tests write to word 211, which the old range happened
#      to cover but which makes the habit of truncating dangerous.
#
#      Set it back to 1023 only to diff against a 1024-word RARS golden
#      (Benchmark Apps/*/output/RARS/DTCM.h). Note G-404: test1's
#      output/RARS/DTCM.hex is stale - use DTCM.h.
#
# NOTE: `mem save` reaches into the precompiled altsyncram model's internals, so
# this script is version-locked to ModelSim ASE 2020.1.

set dtcm_path /tb_rv32imscmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
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
