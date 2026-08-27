# run_isa.do - the directed, self-checking ISA suite on the PIPELINED core
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC, and it stages the SINGLE-CYCLE tree's        #
# # images:  ..\RV32IMscMCU\isa\{ITCM,DTCM}.hex                        #
# # The program is core-agnostic, so there is ONE copy of it rather    #
# # than two copies that can drift apart. Regenerate both the program  #
# # and BOTH expectation packages with:                                #
# #     python3 tools/gen_isa_test.py                                  #
# ######################################################################
#
# WHY THIS RUN EXISTS WHEN THE SINGLE-CYCLE ONE PASSES
#   Because the CORE is not a copy. Every peripheral is byte-identical between
#   the two DUT trees and tools/check_peripheral_copies.py enforces it, so a
#   leaf proven on the single-cycle side is proven here. CONTROL, IDECODE,
#   EXECUTE, IFETCH and DMEMORY are a rewrite - 212 changed lines in EXECUTE
#   alone - and each of the seven ISA repairs had to be present there
#   independently.
#
#   Until Phase 11B that was a claim from READING the pipeline's source. The
#   four benchmarks compare a final DTCM image, which catches a gross error but
#   says nothing about bgeu on operands no benchmark forms, or about sra's sign
#   fill, or about a load's offset. 43 of the 56 stores scored here are cases
#   the benchmarks never execute.
#
#   The expectations and every check are IDENTICAL to the single-cycle bench's,
#   so a difference in the printed numbers is a difference in the CORE. What
#   changes is the instantiation: store data from read_data2_o, the address from
#   alu_res_o (byte, so divided by 4), the sentinel watched in the MEM stage,
#   and CLKCNT_o for the cycle count. The reasoning behind each is in the
#   testbench header.
#
# WHAT TO EXPECT
#   VERDICT: PASS with exactly 5 mismatches. That is the FLOOR, not a to-do
#   list: all five are mul-related and out of scope on BOTH cores by Hanan's
#   forum answer, "mul only (as in Lab 5), 16-bit multiplier only".
#       G-326  2 cases  the multiplier sees only the low half-words
#       G-308  3 cases  mulh / mulhu / mulhsu are not decoded
#   div / divu / rem / remu are NOT in that list any more - Phase 7B2 put them
#   through the accelerator and they are expected to PASS on both cores.
#
#   Which cases and why: SIM/RV32IMscMCU/isa/listing.txt

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/isa/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/isa/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10 official
# testbench (tb_RV32IMpipelinedMCU), so this script compiles its own. The
# package must precede the bench that uses it.
vcom -2008 ../../TB/RV32IMpipelinedMCU/isa_expected_pkg.vhd
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_isa_directed.vhd

# -gMODELSIM=1: G_MODELSIM ships at 0 for Quartus, and this bench instantiates
# the whole MCU. Without the switch CLOCK_TREE builds the real altpll instead of
# the behavioural clocks. tools/check_staging.py asserts it on every whole-MCU
# vsim line.
vsim -t ns -gMODELSIM=1 work.tb_isa_directed

# The bench stops itself when the sentinel RETIRES in MEM, after printing the
# summary, and its watchdog fires with severity failure if the PC ever leaves
# the program. The bound below only backstops a hang in the tool itself.
run 250 us

echo ""
echo "Read the SUMMARY block above."
echo ""
echo "  VERDICT: PASS, 5 mismatches   -> the seven ISA repairs are present in"
echo "                                   the PIPELINED core and produce the"
echo "                                   right values under execution."
echo ""
echo "  Any other number is a finding. Compare against the single-cycle run of"
echo "  the SAME suite (do run_isa.do in SIM\\RV32IMscMCU) before reading"
echo "  anything else: a case that mismatches HERE and passes THERE is a defect"
echo "  this core does not share, and the pipelined EXECUTE / IDECODE are where"
echo "  to look."
