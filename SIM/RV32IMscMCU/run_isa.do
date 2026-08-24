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
echo "Read the SUMMARY block above. It prints which configuration was compiled and"
echo "how many mismatches that configuration is supposed to produce, so you do not"
echo "have to remember the numbers:"
echo "  G_ISA_REPAIR = FALSE  ->  21 mismatches  (core exactly as LAB5 submitted)"
echo "  G_ISA_REPAIR = TRUE   ->   5 mismatches  (phases 3A and 3B applied)"
echo ""
echo "THESE DROPPED FROM 25/9 AT PHASE 7B2. div/divu/rem/remu used to be four of"
echo "the mismatches - they were not decoded at all and the core wrote zero. They"
echo "now go through the Figure 9 accelerator, and they pass at EITHER setting of"
echo "G_ISA_REPAIR because the divider is not behind that switch."
echo "The 5 that remain are ALL mul-related and ALL out of scope by Hanan's own"
echo "answer (mul only, 16-bit). 5 is the floor, not a to-do list."
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
