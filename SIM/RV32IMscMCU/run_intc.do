# run_intc.do - Phase 9A: the Interrupt Controller (IE / IFG / TYPE)
#
# Run compile.do first.
#
# ####################################################################
# # ZERO SETUP. No memory images, no G_ISA_REPAIR setting, nothing to #
# # stage. A leaf test, like run_sync/run_decode/run_clock/run_div/   #
# # run_divunit/run_timer.                                            #
# ####################################################################
#
# WHERE THIS CONTROLLER COMES FROM -- checked before it was written
#   No lab contains interrupt RTL (searched Lab 3, Lab 4, Lab 5: the only
#   hit is a student explanation document). Built from the p13 controller
#   diagram taken literally -- RAW request latches (D='1' flops) behind
#   the AND gates whose outputs the diagram itself labels IFGx -- from the
#   p14 IE/IFG/TYPE layouts and vector table (benchmark-cross-checked in
#   DOC/02 sections 3.1 and 4), from Hanan's forum answer that falsified
#   assumption A6 (what IFG READS is the masked product, never the raw
#   latch), and from the prep-session transcript in DOC/03 section C:
#   every request event is a rising 0->1 edge, so the KEY request fires
#   on the RELEASE -- the debounced KEY line rises when the key is let
#   go. The KEY inputs go through the course's own Figure 10a two-flop
#   synchronizer (SYNC.vhd, as in DIV_UNIT) plus an edge detect on the
#   pressed level's FALLING edge -- which is that same release, without
#   the spurious post-reset event a raw idle-high line would fabricate
#   (the full reasoning is in INTERRUPT_CTRL.vhd's header).
#
# WHAT PASS MEANS
#   P0  reset clears IE, IFG, TYPE, INTR.
#   P1  IE writes land and read back; bits 7:6 always drop.
#   P2  the falsified-A6 structure: a masked request is INVISIBLE (IFG
#       reads 0) but REMEMBERED -- enabling IE later makes it reappear
#       (assumption A22), and INTR needs GIE on top.
#   P3  the benchmark init pattern works: storing IFG=0 while IE=0 clears
#       the RAW latches, so enabling IE afterwards raises nothing --
#       exactly test1's IE=0, IFG=0, then-enable order.
#   P4  software writes are W0C: the benchmark ISR idiom (AND-mask then
#       store) clears exactly one flag; writing 1s sets nothing (A24).
#   P5  TYPE follows the p14 priority column AND reads the masked view: a
#       masked BT request cannot outrank a visible KEY2; unmasked, BT
#       (10h) wins; KEY1 (14h) outranks KEY2 and KEY3.
#   P6  INTR = OR(masked view) AND GIE -- a masked request raises nothing
#       even with GIE set.
#   P7  the INTA handshake: TYPE pushed exactly one cycle after the INTA
#       pulse; BTIFG auto-clears at service (rule a) while KEY1IFG
#       survives and is cleared manually (rule d); the push self-clears.
#   P7h TYPE capture is FROZEN at the accept edge: a BT event landing in
#       the accept cycle itself neither swaps the pushed TYPE nor is lost.
#   P8  the KEY event is the RELEASE: a press-and-hold sets NOTHING, the
#       release sets the flag, and it is an edge -- no re-set afterwards.
#   P9  the synchronous source (BT) obeys the same mask: invisible while
#       BTIE=0, remembered and visible once BTIE is set.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about the CPU side -- GIE living in gp[0], the two entry
#   cycles, tp, reti, the vector fetch (Phase 9B) -- and nothing about the
#   bus wiring at 0x202C/D/E behind CS_INTC (Phase 9C). Sources and the
#   handshake are driven directly by the testbench here.
#
# WHY THE FIRST RUN SHOULD PASS
#   tools/model_interrupt_ctrl.py executes the RTL's per-edge semantics
#   through these same phases: 0 failures, and TWELVE faithful mutations
#   are ALL caught, each by the phase built to catch it -- including the
#   two structures we ourselves almost built wrong: set-gated-by-IE (no
#   A22 comeback; killed by P2b) and the PRESS edge instead of the
#   RELEASE (DOC/03's own warned-against bug; killed by P8a).

onerror {quit -code 1}

# Development-only testbench: compile.do compiles just the clause 10
# official testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_interrupt_ctrl.vhd

vsim -t ns work.tb_interrupt_ctrl
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo ""
echo "If P2a fails: IFG is reading the raw latch - the original falsified A6."
echo "If P2b or P9b fails: the set path is gated by IE, so masked requests are"
echo "  forgotten instead of remembered (the raw latch is missing)."
echo "If P4c fails: software writes are write-through instead of W0C."
echo "If P5a or P6b fails: TYPE or INTR is reading the raw latches instead of"
echo "  the masked view."
echo "If P7c fails one way and P7f the other: the a-vs-d clearing split is"
echo "  backwards (BT must auto-clear at service, KEYs must not)."
echo "If P7h fails on the pushed value: TYPE is being read live during the"
echo "  push cycle instead of frozen at the accept edge."
echo "If P8a fails: the request fires on the PRESS - the exact bug DOC/03"
echo "  section C warns about; the event must be the RELEASE."
