# run_intr_core.do - the CPU-side interrupt protocol on the PIPELINED core
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC, and it stages the SINGLE-CYCLE tree's        #
# # images:  ..\RV32IMscMCU\intr\{ITCM,DTCM}.hex                       #
# # The program is core-agnostic, so there is ONE copy of it rather    #
# # than two copies that can drift apart. Regenerate with:             #
# #     python3 tools/gen_intr_core_test.py                            #
# ######################################################################
#
# WHY THIS RUN EXISTS WHEN THE SINGLE-CYCLE ONE PASSES
#   Because this is the ONE test in the set whose subject IS the difference
#   between the two cores. The single-cycle entry runs on a machine where every
#   instruction retires in its own cycle. The pipelined entry has to pick a
#   RETIREMENT BOUNDARY (MEM), gate acceptance on mem_active_w so a flush bubble
#   is not mistaken for an instruction, kill three younger stages, and recover a
#   resume PC that may itself be a branch redirect. The Phase 11 review checked
#   all of that by READING RV32IM_PIPE_CORE.vhd; nothing executed it. Phase 12D's
#   USART tests exercise the entry indirectly - this one does it cycle by cycle
#   against REQ p15.
#
#   RV32IM_PIPE_CORE alone, with the TESTBENCH playing the interrupt controller:
#   it drives intr_i, checks the one-cycle INTA pulse, and pushes TYPE on the
#   data bus in the following cycle. That handshake needed NO adaptation, which
#   is itself worth knowing - it is what lets INTERRUPT_CTRL be reused
#   byte-identical in both trees.
#
# WHAT PASS MEANS
#   - REQ p15's two-cycle entry ON A PIPELINE: GIE (gp[0]) cleared IN HW (the
#     ISR reads gp = 0), TYPE captured from the DATA bus, the vector fetched
#     from the DTCM table THE PROGRAM ITSELF WROTE, tp = the return address.
#   - reti sets GIE back IN HW and execution resumes: main reads gp = 1 after
#     every round, and tp in main equals tp in the ISR. THAT equality is the
#     protocol claim; the printed ranges are only a sanity bound.
#   - Two DIFFERENT vectors reach two different handlers (TYPE 14h -> the KEY1
#     ISR, TYPE 10h -> the BT ISR's 0xB7 marker).
#   - F13: a request raised while the div is IN EX is DEFERRED through the div,
#     the adjacent rem AND the busy tail, and both results are exact afterwards
#     (142 and 6).
#   - Exactly 16 scored stores: the annulled instruction at the return address
#     retires exactly once. dbus_MemWrite_o is the annul-gated strobe, so a
#     store that leaked past the annul would land twice and break the count.
#
# THE ONE ADAPTATION THAT IS NOT COSMETIC
#   Round 3 raises the request off EXinstruction_o, not MEMinstruction_o.
#   Acceptance is blocked by ex_DivStart_w and div_busy_w, both EX-stage, and a
#   divide completes IN EX before it advances - so a MEM watch would raise the
#   request against an ALREADY IDLE divider, measure a deferral of ~0, and
#   report PASS having tested nothing. The bench header explains it at length.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about INTERRUPT_CTRL itself (run_intc.do in the single-cycle tree is
#   its leaf test, and the file is byte-identical here) and nothing about the two
#   sides wired together on the bus - that is run_intr_mmio.do.

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/intr/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/intr/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

# Development-only testbench: compile.do compiles just the clause 10 official
# testbench (tb_RV32IMpipelinedMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_intr_core.vhd

# No -gMODELSIM=1 here, and that is correct rather than an oversight: this bench
# instantiates the bare CORE, not the MCU top, so there is no CLOCK_TREE to send
# down its CLK_FPGA branch. It drives clk and divclk itself.
# tools/check_staging.py knows the difference - it derives which testbenches
# instantiate an MCU top from the TB sources.
vsim -t ns work.tb_intr_core
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0, and"
echo "sane printed values: tp1 in 44..48, tp3 in 100..124, deferral >= 12."
echo ""
echo "FIRST THING TO DO ON A FAILURE: run the single-cycle bench,"
echo "  do run_intr_core.do  in SIM\\RV32IMscMCU"
echo "If that passes and this does not, the fault is in the PIPELINED entry,"
echo "not in the program, the protocol or the expectations - the two benches"
echo "score the identical checks against the identical program."
echo ""
echo "If the program never finishes: wrong images staged."
echo "If gp-inside-ISR is 1: GIE was not cleared in HW (rule e broke)."
echo "If gp-after-reti is 0: reti did not set GIE in HW (rule f broke)."
echo "If [0x188] is not 0xB7: TYPE 10h did not select vector word 4 - check"
echo "  the type_q capture and the Cycle-2 vector arm in IFETCH."
echo "If the R3 deferral is tiny: the accept gate ignored div_start/div_busy"
echo "  (F13). If 142/6 are wrong: the entry corrupted an in-flight divide."
echo "If stores != 16: the annul gating leaked or swallowed a retire - on this"
echo "  core that is mem_write_core_w <= mem_MemWrite_w AND (NOT annul_w)."
echo "If tp1/tp3 are outside their ranges but EQUAL in main and the ISR: the"
echo "  protocol is intact and the resume PC landed somewhere the single-cycle"
echo "  core would not - read RV32IM_PIPE_CORE's resume_w before changing RTL."
