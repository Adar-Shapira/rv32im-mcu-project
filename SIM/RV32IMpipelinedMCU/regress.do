# regress.do - ONE command that runs everything provable about the PIPELINED
#              MCU in ModelSim, scores it, and exits non-zero if anything failed.
#
# HOW TO RUN
#       cd SIM\RV32IMpipelinedMCU
#       vsim -c -do regress.do
#       echo %ERRORLEVEL%        REM 0 = everything passed, 1 = something did not
#
# WHY THIS EXISTS
#   Gap G-203 asked for a regression command per core. The single-cycle half
#   landed at Phase 13 (SIM\RV32IMscMCU\regress.do). This is the pipeline half,
#   which the plan deferred until Phase 11 had something to regress: before
#   Phase 11B the pipeline's only self-checking tests were the GPIO trio, the
#   two USART ones and the four benchmark benches, and nothing scored them
#   together. A green run of one script says nothing about the other eight.
#
#   Thirteen tests now. Phase 11B added the directed ISA suite; G-408 added the
#   three that test the CORE's interaction with a peripheral and therefore do
#   NOT transfer from the single-cycle tree the way a leaf test does: the entry
#   protocol cycle by cycle, the timer on the bus, and the interrupt path end
#   to end.
#
# HOW A TEST IS SCORED
#   Exactly the rule SIM\RV32IMscMCU\regress.do uses, so the two summaries mean
#   the same thing:
#       FAIL / INCOMPLETE present  -> failed
#       PASS present, no FAIL      -> passed
#       no VERDICT line at all     -> failed ("never reached its summary")
#   Three tests carry one extra machine-checkable fact each and it is folded in
#   here: test2 and test3 must see BTCNT tick, and test4 must see 3 capture
#   events. They already set ::btcnt_ticked / ::cap_events for exactly this.
#
#   Per-test transcripts land in logs\<name>.log - that is where to look when
#   the table says FAILED. The table is a summary, never the evidence.
#
# WHAT PART B ADDS THAT PART A CANNOT
#   PART A's benchmark benches run the CORRECTED images (bench_fixed) and check
#   their own assertions. PART B runs batch_verify.do, which runs the SHIPPED
#   images and diffs each final DTCM word-by-word against the reference's own
#   capture in Auxiliary\Lab 5\SIM\RV32IM_pipeline. Different inputs, different
#   question. It also prints the four CLKCNT/STCNT/FHCNT triples, which are gap
#   G-205 and the input to the clause 6.iii.b IPC check - REPORTED, not
#   asserted, because PROJECT_EXPLANATION section 8.6's figures include the
#   testbench drain and are a range rather than a target. Copy them into the
#   plan file when this run finishes.
#
#   batch_verify.do compiles again on entry. That is deliberate: it stays
#   correct as a standalone command, and one extra vcom pass is cheap next to
#   four 5 ms benchmark runs.
#
# ONE BEHAVIOUR TO KNOW ABOUT
#   Every script in the list carries `onerror {quit -code 1}` of its own, so a
#   hard TOOL error - a vcom failure, a missing image - takes the whole run down
#   with status 1 instead of producing a table. That is deliberate and it is
#   what SIM\RV32IMscMCU\regress.do has always done: nothing after a broken
#   compile is scoreable. A test that RUNS and fails its own assertions is a
#   different thing entirely and is caught, scored and continued past.
#
# WHAT IT DOES NOT COVER
#   The single-cycle tree (it has its own regress.do), Quartus, and anything
#   that needs the board. The four static checkers under tools/ are the part
#   that needs no simulator at all - run those first, on either machine.

quietly set ::REGRESS 1
file mkdir logs

#=============================================================================
# PART 0 - compile
#=============================================================================
echo ""
echo "=========================================================="
echo " PART 0 - compile"
echo "=========================================================="
transcript file logs/compile.log
if {[catch {do compile.do} err]} {
    transcript file ""
    echo "COMPILE FAILED: $err"
    echo "Nothing else can be trusted. See logs/compile.log."
    quit -code 1
}
transcript file ""
echo "compile.do: done (see logs/compile.log for the warning count)"

#=============================================================================
# PART A - every self-checking test, scored by its own VERDICT line
#=============================================================================
# Order: the ISA suite first, then the bus, then whole programs. A core that
# gets bgeu wrong makes every later result hard to read, so the table is
# printed in this order and the first FAILED row is the one to read.
quietly set TESTS {
    {run_isa.do            "11B directed ISA suite, 56 stores (expects 5 mul mismatches)"}
    {run_intr_core.do      "G-408 the CPU-side entry protocol, REQ p15 cycle by cycle"}
    {run_gpio.do           "11  GPIO test0 on the pipeline"}
    {run_gpio_read.do      "11  GPIO test1, the SFR read path"}
    {run_gpio_directed.do  "11  directed GPIO, 35 exact stores"}
    {run_timer_mmio.do     "G-408 the Basic Timer on the bus, + PWM at the pin"}
    {run_intr_mmio.do      "G-408 the interrupt path end to end, 14 exact stores"}
    {run_uart_mmio.do      "12D USART on the bus, pin-to-pin loopback"}
    {run_uart_menu.do      "12D clause 8 menu, bench as the PC (slow: ~75 ms)"}
    {run_bench_test1.do    "11  interrupt benchmark test1 (corrected copy)"}
    {run_bench_test2.do    "11  interrupt benchmark test2 (+ BTCNT must tick)"}
    {run_bench_test3.do    "11  interrupt benchmark test3 (+ BTCNT must tick)"}
    {run_bench_test4.do    "11  interrupt benchmark test4 (+ 3 capture events)"}
}

proc score_log {path} {
    if {![file exists $path]} { return "NO LOG" }
    set fh [open $path r]
    set txt [read $fh]
    close $fh
    if {[string first "VERDICT: FAIL" $txt] >= 0}       { return "FAILED" }
    if {[string first "VERDICT: INCOMPLETE" $txt] >= 0} { return "INCOMPLETE" }
    if {[string first "VERDICT: PASS" $txt] >= 0}       { return "passed" }
    return "NO VERDICT"
}

quietly set ::results {}
quietly set ::nfail 0

echo ""
echo "=========================================================="
echo " PART A - self-checking tests"
echo "=========================================================="

foreach t $TESTS {
    quietly set script [lindex $t 0]
    quietly set label  [lindex $t 1]
    quietly set name   [file rootname $script]

    echo ""
    echo "---- $script  --  $label"

    # Cleared before each run so a stale value from the PREVIOUS test can never
    # be scored as this one's. That is a real hazard: these globals live in the
    # interpreter, not in the simulation, and survive quit -sim.
    quietly set ::cap_events   -1
    quietly set ::btcnt_ticked -1

    transcript file logs/$name.log
    quietly set err ""
    if {[catch {do $script} err]} {
        transcript file ""
        lappend ::results [list $script $label "SCRIPT ERROR"]
        incr ::nfail
        echo "  SCRIPT ERROR: $err"
        catch {nowhen *}
        catch {quit -sim}
        continue
    }
    transcript file ""
    catch {nowhen *}
    catch {quit -sim}

    quietly set verdict [score_log logs/$name.log]

    # The extra machine-checkable facts, folded into the verdict so one table
    # row carries the whole result.
    if {$verdict eq "passed"} {
        if {$script eq "run_bench_test4.do" && $::cap_events != 3} {
            quietly set verdict "FAILED (capture events $::cap_events, expected 3)"
        }
        if {($script eq "run_bench_test2.do" || $script eq "run_bench_test3.do")
            && $::btcnt_ticked != 1} {
            quietly set verdict "FAILED (BTCNT never left 0)"
        }
    }

    lappend ::results [list $script $label $verdict]
    if {[string match "passed" $verdict]} {
        echo "  -> passed"
    } else {
        incr ::nfail
        echo "  -> $verdict   (read logs/$name.log)"
    }
}

quietly set ::a_nfail $::nfail
quietly set ::a_results $::results

#=============================================================================
# PART B - the four SHIPPED benchmarks against the reference's own DTCM
#=============================================================================
echo ""
echo "=========================================================="
echo " PART B - batch_verify.do (golden DTCM + the G-205 counters)"
echo "=========================================================="
quietly set ::bv_status "NOT RUN"
quietly set ::bv_nfail 0
transcript file logs/batch_verify.log
if {[catch {do batch_verify.do} err]} {
    transcript file ""
    echo "  batch_verify.do raised: $err"
    quietly set ::bv_status "SCRIPT ERROR"
    quietly set ::bv_nfail 1
} else {
    transcript file ""
}
catch {nowhen *}
catch {quit -sim}
echo "  batch_verify: $::bv_status   (full transcript in logs/batch_verify.log)"

#=============================================================================
# SUMMARY
#=============================================================================
echo ""
echo "=========================================================="
echo " REGRESSION SUMMARY - pipelined MCU"
echo "=========================================================="
foreach r $::a_results {
    echo [format "  %-24s %-12s %s" [lindex $r 0] [lindex $r 2] [lindex $r 1]]
}
echo "----------------------------------------------------------"
echo [format "  %-24s %-12s %s" "batch_verify.do" \
     [expr {$::bv_nfail == 0 ? "passed" : "FAILED"}] $::bv_status]
echo "----------------------------------------------------------"

quietly set total [expr {$::a_nfail + $::bv_nfail}]
if {$total == 0} {
    echo "  ALL PASSED."
    echo ""
    echo "  Before closing Phase 11, copy the four CLKCNT/STCNT/FHCNT triples"
    echo "  out of logs/batch_verify.log into the plan file. They are gap"
    echo "  G-205 and nothing else produces them."
    echo "=========================================================="
    quit -code 0
} else {
    echo "  $total FAILURE(S) - the rows above name them; logs\\ holds the evidence."
    echo "=========================================================="
    quit -code 1
}
