# run_divunit.do - Phase 7B1: the division subsystem
#
# Run compile.do first.
#
# ####################################################################
# # ZERO SETUP. No memory images, no G_ISA_REPAIR setting, nothing to #
# # stage. A leaf test, like run_sync.do, run_decode.do, run_clock.do  #
# # and run_div.do.                                                    #
# ####################################################################
#
# WHAT THIS IS, AND WHY IT IS NOT run_div.do AGAIN
#   run_div.do verified the ENGINE: one clock domain, unsigned, Figure 9.
#   This verifies everything that only exists once the engine is wrapped --
#     - the four clock-domain crossings (two that Figure 10b draws, the DIVBUSY
#       return path that no figure draws, and the enable);
#     - the MCLK-side handshake, which is where a divider usually goes wrong;
#     - the SIGNED div/rem wrapper.
#
# THE THREE THINGS MOST WORTH KNOWING
#
#   1. THE STALL IS BUILT ON done_o, NOT ON busy_o -- and that is not a naming
#      preference, it is the bug this design exists to avoid. DIVstart takes two
#      synchroniser stages to reach the engine and DIVBUSY takes two more to come
#      back, so for several MCLK cycles after a div issues, busy STILL READS LOW.
#      A stall written as "hold while busy" does not hold at all: the core runs
#      straight past its own divide and writes back whatever the last one left.
#      Phase 7B2's stall term is
#           PCHold <= DIVstart AND NOT done_o
#      and property P1 here is exactly that contract -- done_o must be low for
#      the whole operation and high at the end, while start is still asserted.
#
#   2. THE CLOCKS ARE COPRIME ON PURPOSE. The design will run 20 MHz against
#      50 MHz, a 5:2 ratio that holds the two clock edges in a FIXED
#      relationship -- and a crossing bug can hide behind a fixed relationship
#      indefinitely, then appear on a board when a PLL happens to come up at a
#      different phase. This testbench uses 50 ns against 21 ns, so across the
#      run the DIVCLK edge lands at every phase of the MCLK period. Correctness
#      must not depend on the ratio; this is what makes that testable.
#
#   3. IT FOUND A REAL RACE BEFORE IT EVER RAN. The enable and the two operand
#      buses each cross through their own two-stage synchroniser. Launched on the
#      same MCLK edge, nothing guarantees the operand bits resolve no later than
#      the enable bit -- so DIVENA could arrive one DIVCLK edge before a bit of
#      Ain or Bin had settled, and the engine would load a half-updated operand
#      and return a confidently wrong answer. DIV_UNIT holds the enable back by
#      one MCLK cycle (the LAUNCH state) to give the data a head start. Standard
#      rule for crossing a bus alongside its control: data first, control after.
#
# P8 EXISTS BECAUSE THAT CASE WAS FOUND BROKEN, after the phase was committed.
#   The DONE state used to wait for start_i to fall -- which two adjacent div
#   instructions never allow, because the second asserts DIVstart on the very
#   cycle the first retires. The unit sat in DONE with done_o still high and the
#   second div retired IMMEDIATELY carrying the FIRST one's result: a silent
#   wrong answer, not a hang. DONE now lasts exactly one cycle, which is safe
#   because the retire and that transition happen on the same edge.
#
# SIGNED div/rem -- the two cases the ISA overrides
#   -2^31 / -1 needs NO special hardware: |-2^31| is 0x80000000, the engine
#   returns quotient 0x80000000, the signs agree so nothing is negated, and
#   0x80000000 IS -2^31. The overflow rule falls out of the arithmetic.
#
#   DIVIDE BY ZERO DOES need hardware, and it is the one place the obvious
#   wrapper is wrong. RISC-V requires div(x,0) = -1 for EVERY dividend. The
#   engine returns all-ones; for a positive dividend the sign correction leaves
#   that alone and it is right by luck, but for a NEGATIVE dividend the signs
#   differ, the correction negates 0xFFFFFFFF, and the answer comes out as +1.
#   So divisor = 0 bypasses the sign correction entirely. Verified: removing
#   that override from tools/model_div_unit.py produces 155 failures.
#
# WHAT PASS MEANS
#   P0 reset; P1 done_o never rises early; P2 busy_o tracks the operation;
#   P3/P4 quotient and remainder match NUMERIC_STD's own signed and unsigned
#   "/" and "rem"; P5 every operation completes within a bounded number of MCLK
#   cycles; P6 back-to-back operations are all correct; P7 the run really did
#   what it claims and really produced non-zero results; P8 TWO ADJACENT DIVIDES
#   WITH start_i NEVER DROPPING -- what the core actually does, and what every
#   other property here misses because do_op lowers start between operations.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about the core. div/rem decode, the PCHold stall itself and the
#   write-back mux are Phase 7B2. And no RTL simulator can reproduce
#   metastability -- what is proved here is the STRUCTURE: that the handshake
#   completes at every phase, that no operand is sampled mid-flight, and that
#   the result is stable when it is read.
#
# EXPECTED NUMBERS
#   VERDICT: PASS, failed 0, operations 57 (15 directed corners + 40 random +
#   the two of P8's adjacent pair).
#   About 60 us of simulated time. Quick.
#
# WHY THE FIRST RUN SHOULD PASS
#   The arithmetic has already been executed: tools/model_div_unit.py transcribes
#   the wrapper into Python and checks it against fractions.Fraction (which
#   truncates toward zero exactly, and shares no step with the magnitude
#   algorithm) over ALL 65536 pairs signed AND all 65536 unsigned at N=8, plus
#   32-bit corners and random cases -- 131488 cases, 0 failures. Seven deliberate
#   mutations of it were all caught. So a failure here points at the VHDL
#   translation, the handshake or the crossings rather than at the algebra.

onerror {quit -code 1}

# Development-only testbench: compile.do compiles just the clause 10
# official testbench (tb_RV32IMscMCU), so this script compiles its own.
vcom -2008 ../../TB/RV32IMscMCU/tb_div_unit.vhd

vsim -t ns work.tb_div_unit
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0,"
echo "operations 57."
echo ""
echo "If P5 latency_bound fails: the handshake is STUCK, not slow. The likely"
echo "cause is WAIT_RISE never seeing DIVBUSY, which is the clock-ratio"
echo "constraint written out in DIV_UNIT.vhd's header - DIVBUSY must stay high"
echo "longer than the MCLK synchroniser needs to catch it."
echo "If quotient is right but remainder is wrong on negative dividends: the"
echo "remainder sign follows the DIVIDEND, not the quotient."
echo "If -1/0 gives +1: the divisor=0 override is missing or is being applied"
echo "after the sign correction rather than in place of it."
echo "If only the random cases fail: suspect the crossings, not the algebra -"
echo "the directed corners exercise the same wrapper at the same clock phases."
echo "If P8 fails: two ADJACENT div instructions are broken - the second retires"
echo "with the first one's result. Check that DONE lasts exactly one cycle."
