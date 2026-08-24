# run_div.do - Phase 7A: the division accelerator of Figure 9
#
# Run compile.do first.
#
# ####################################################################
# # ZERO SETUP. No memory images, no G_ISA_REPAIR setting, nothing to #
# # stage. Like run_sync.do and run_decode.do, this one runs the      #
# # moment compile.do finishes. It is a leaf test.                    #
# ####################################################################
#
# WHAT THIS TEST DOES
#   Two instances of div_accel, on purpose:
#
#     N = 8   swept EXHAUSTIVELY - all 256 dividends against all 256 divisors,
#             65536 operations, the divide-by-zero column included. Every
#             quotient and every residue is compared against IEEE.NUMERIC_STD's
#             own "/" and "rem", which share no line of code with the restoring
#             datapath under test.
#
#     N = 32  the case page 9 fixes: 16 directed corners, 500 pseudo-random
#             pairs, then reset-while-busy and DIVENA-held-high.
#
#   And on EVERY one of those 66000+ operations it also checks the timing page 9
#   states - "results are ready after N DIVCLK cycles after loading a value to
#   the second operand DIVISOR" - by measuring how long DIVBUSY stays high. Not
#   as a spot check: 66000 measurements, so a data-dependent early exit cannot
#   hide behind an average.
#
# WHY THE EXHAUSTIVE SWEEP IS AT 8 BITS AND THE DESIGN SHIPS AT 32
#   Because 65536 cases at N=8 is not a proof for N=32 and pretending otherwise
#   would be the point at which this stopped being verification. What makes the
#   small sweep worth more than any sample at 32 bits is that the datapath is
#   width-independent - the same shift, the same subtract, the same select, N
#   times - so a wrong slice boundary or a wrong restore condition is a bug at
#   every width and the sweep finds it. The one bug class it cannot find is one
#   that exists only at 32 bits, and there is exactly one candidate: the claim in
#   DIV_ACCEL.vhd's header that an N-bit Y never overflows. The N=32 directed
#   list aims straight at it - divisors at and above 2**31, dividends at
#   0xFFFFFFFF - and the random stream forces a divisor with bit 31 set every
#   sixteenth case.
#
# THE PROPERTY THAT MATTERS MOST IS P7
#   P7 holds DIVENA high for twenty cycles after the result is ready and requires
#   that nothing restarts. That is not a hypothetical: Figure 3 makes DIVstart a
#   combinational output of the Control Unit, so while the core is stalled on a
#   div the div is still the current instruction and DIVstart stays asserted for
#   the whole operation and beyond. An engine that starts on a level relaunches
#   the divide forever and the core never sees a result - and it passes every
#   other property in this file. It was checked that P7 is the only one that
#   catches it: tools/model_div_accel.py was mutated to start on a level, and
#   P7 was the sole failure.
#
# WHAT PASS MEANS
#   P0 reset holds the outputs at zero; P1c DIVBUSY is low before every load;
#   P1 DIVBUSY rises on the load edge and falls exactly N cycles later, on every
#   operation; P2/P3 quotient and residue match the independent model; P3b the
#   result is still there after DIVENA falls and the engine re-arms; P4
#   divide-by-zero gives all-ones and the dividend; P5 DIVRST mid-operation
#   aborts, clears, and leaves the engine usable -- and P5 checks that its own
#   abort point has non-zero partials, so it cannot go vacuous; P6 back-to-back
#   operations are all correct; P7 no restart on a held DIVENA; P8 the operation
#   counts are what was intended and the run really did produce non-zero results.
#
#   P1c, P3b and P5's vacuity guard were all added after an adversarial review of
#   this testbench found three real RTL mutations that the earlier version passed
#   with byte-identical counters: DIVBUSY meaning "not DONE" instead of
#   "running", DIVRST clearing only the FSM and not the shift registers, and the
#   engine wiping its results on the DONE -> IDLE re-arm. All three would have
#   broken Phase 7B and none would have shown up here.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about the core. This is the unsigned engine on its own - Phase 7A.
#   Not covered here, and all of it is Phase 7B:
#     - the SIGNED div/rem wrapper. The benchmarks use the signed opcodes (`div`
#       and `rem`, in RV32IM/test1 and in Interrupt-based IO test1 and test4),
#       though every operand in every supplied benchmark is a small positive
#       integer, so the signed path is required for conformance rather than by
#       any supplied program.
#     - the two clock-domain crossings, which is where the `sync` block of Phase
#       4A gets its first real use.
#     - the DIVstart/PCHold stall, the write-back mux, and div/rem decode.
#   And Phase 7B needs DIVCLK, so it needs Phase 4B.
#
# EXPECTED NUMBERS
#   N=32 operations 517 (16 directed + 500 random + 1 after-abort).
#   N=8  operations 65536. Failures 0. The sweep prints a progress line every 16
#   dividends, 16 lines in all, so a long run visibly advances.
#
# RUNTIME
#   About 13 ms of simulated time, dominated by the N=8 sweep at roughly 10 clock
#   periods per operation. On ModelSim ASE expect tens of seconds, not minutes.
#   If you are editing the RTL and want a fast smoke test, use
#       vsim -t ns -gEXHAUSTIVE=0 work.tb_div_accel
#   which skips the sweep - and then says VERDICT: INCOMPLETE rather than PASS,
#   because a run without the sweep has not verified the divider.
#
# WHY THE FIRST RUN SHOULD PASS
#   The algorithm has already been executed. The whole toolchain is Windows-only,
#   so this RTL could not be compiled where it was written; instead
#   tools/model_div_accel.py transcribes it line for line into Python and runs
#   the same 66053 cases against Python's own // and %. It reports 0 failures,
#   and ELEVEN deliberate mutations of it were all caught: inverted non-negative
#   flag, off-by-one counter, wrong Y slice, no restore, no quotient shift, level
#   start, right shift instead of left, divisor register never loaded, plus the
#   three the review found (DIVBUSY = "not DONE", DIVRST clearing only the FSM,
#   results wiped on re-arm) which survived the FIRST version of this suite and
#   are caught by P1c, P5's guard and P3b. So if this testbench
#   fails, suspect the VHDL translation or the simulator setup before suspecting
#   the arithmetic - and say which, because that distinction is the whole point
#   of having both.

onerror {quit -code 1}

vsim -t ns work.tb_div_accel
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0 on both"
echo "instances, N=8 operations 65536, N=32 operations 517."
echo ""
echo "If the N=8 sweep fails on many pairs at once: the datapath is wrong, and"
echo "the first FAIL line names the smallest failing pair - start there, and"
echo "compare against tools/model_div_accel.py which is the same algorithm."
echo "If only the latency property fails: the counter or the RUN->DONE test in"
echo "DIV_ACCEL.vhd is off by one, not the arithmetic."
echo "If only P7 fails: the start is level-triggered instead of armed once per"
echo "DIVENA assertion, which would make the core hang on its first div."
echo "If only P5 fails: DIVRST aborts but leaves the engine wedged."
echo "If VERDICT says INCOMPLETE: EXHAUSTIVE was 0. Re-run without it."
