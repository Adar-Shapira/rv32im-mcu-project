# run_isa.do - run the directed, self-checking ISA test
#
# Regenerate the inputs first if the suite changed:
#     python3 tools/gen_isa_test.py
# then compile.do, then this macro.
#
# The images live in this directory under isa/, but the RTL always loads from
# C:\TestPrograms\Quartus21_1\app_bin (init_file is hardcoded in IFETCH.vhd:64
# and DMEMORY.vhd:50), so they are staged there exactly like a benchmark.

file copy -force isa/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force isa/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vsim -t ns -gMODELSIM=1 work.tb_isa_directed

# The testbench stops itself at the sentinel after printing the summary, and the
# watchdog fires with severity failure if the PC ever leaves the program. The
# bound below only backstops a hang in the tool itself.
run 250 us

echo ""
echo "Read the SUMMARY block above. The ISA-repaired core is supposed to produce"
echo "5 mismatches, all mul-related (16-bit mul, Hanan's scope). 5 is the floor,"
echo "not a to-do list."
echo ""
echo "Both numbers are cross-checked two independent ways by"
echo "tools/gen_isa_test.py: once by tagging each case with the gap it exercises,"
echo "and once by executing the generated program through a model of this core's"
echo "own defects. Generation aborts if the two disagree."
echo ""
echo "The 9 that remain are NOT regressions. Each is blocked on a question rather"
echo "than on effort, which is why none of them is implemented:"
echo "  G-326  2 cases  MUL16 multiplies only the low 16 bits -> open question"
echo "  G-308  3 cases  mulh / mulhu / mulhsu not decoded     -> open question"
echo "  G-307  4 cases  div / divu / rem / remu not decoded   -> Phase 7, Q6"
echo ""
echo "  Which cases and why: SIM/RV32IMscMCU/isa/listing.txt"
echo "  Repair-level check : do repair_check.do   (43 checks)"
echo "  The switch         : DUT/RV32IMscMCU/cond_compilation_package.vhd"
