# mem_dump.do - export the reference core's DTCM and compare it to the golden
#
# Run immediately after run_test.do, in the same simulation session.
#
# THE HIERARCHICAL PATH
#   /tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a
#
#   Note there is NO wrapper level here: this is the bare reference core, so the
#   path goes straight from the testbench to CORE. Our own tree inserts the MCU
#   wrapper and needs /tb_rv32imscmcu/MCU/CORE/... instead - that one extra level
#   is the single most common reason a dump comes out empty, and `mem save` does
#   NOT report it as an error. It writes a valid file with no data in it.
#
#   m_mem_data_a is the altsyncram's internal array. That name is a simulator
#   internal, which version-locks this script to ModelSim ASE 2020.1. A different
#   version fails here, at the dump, not at compile.
#
# ALL 2048 WORDS, NOT 1024
#   The captured dumps the reference ships are 2048 data words
#   (SIM/RV32IM_sc/DTCM_test1..4_MS.mem, 2051 lines = 3 header + 2048 data), so
#   the whole DTCM is now covered. The earlier 1024-word export - gap G-204 -
#   left the upper half of the memory unchecked by anything. Matching the
#   reference's own range is what makes a byte-for-byte diff possible.

onerror {resume}

if {![info exists N]} { set N 1 }

set inst /tb_rv32im_sc/CORE/MEM/data_memory/MEMORY/m_mem_data_a
set out  DTCM_test${N}_run.mem

mem save -o $out -f mti -data hex -addr hex -startaddress 0 -endaddress 2047 -wordsperline 1 -noaddress $inst

echo ""
echo "wrote [pwd]/$out"
echo ""
echo "Compare it against the reference's own capture:"
echo "  Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/DTCM_test${N}_MS.mem"
echo ""
echo "In PowerShell, ignoring the 3 header lines and case:"
echo "  \$a = Get-Content DTCM_test${N}_run.mem | Select-Object -Skip 3"
echo "  \$b = Get-Content '..\\..\\Auxiliary\\Lab 5 - as submitted\\SIM\\RV32IM_sc\\DTCM_test${N}_MS.mem' | Select-Object -Skip 3"
echo "  Compare-Object \$a \$b"
echo ""
echo "No output from Compare-Object means all 2048 words are identical, which is"
echo "the Phase 0 pass criterion. Any output at all is a finding - report the"
echo "first few differing lines and their word numbers, not just the count."
echo ""
echo "If the dump is EMPTY: the hierarchical path above is wrong for this design."
echo "mem save does not treat that as an error."
