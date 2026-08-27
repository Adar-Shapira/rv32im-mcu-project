# regress.do - Phase 13: the whole single-cycle regression, in one run
#
# WHAT IT IS
#   One macro that compiles once, runs every test in SIM\RV32IMscMCU, scores
#   each one, runs the four RV32IM benchmarks with a real DTCM comparison, and
#   **exits with a non-zero status if anything failed**. That exit status is
#   gap G-203: batch_verify.do only ever echoed, so a failing regression looked
#   exactly like a passing one to anything but a human reader.
#
# HOW TO RUN
#   Headless (the way to get the exit status):
#       cd SIM\RV32IMscMCU
#       vsim -c -do regress.do
#       echo %ERRORLEVEL%          <- 0 = everything passed, 1 = something did not
#   From the GUI (Tools -> Tcl -> Execute Macro) it works too and prints the same
#   table; it just closes ModelSim at the end.
#
#   Every test stages its own images, so there is nothing to copy by hand and
#   nothing left over between tests. The ONLY external dependency is the
#   one-time C:\TestPrograms\Quartus21_1\test1..4 layout that section 3 of
#   DOC/04_baseline_runbook.md builds, and that is only needed for PART B - the
#   script checks for it and skips PART B with a clear message if it is absent,
#   rather than running the wrong program.
#
# HOW EACH TEST IS SCORED
#   Every testbench in this project ends with a line containing
#   "VERDICT: PASS" or "VERDICT: FAIL" (tb_div_accel can also say
#   "VERDICT: INCOMPLETE" when its exhaustive sweep was skipped, which is not a
#   pass). So the rule is uniform and needs no per-test knowledge:
#       FAIL / INCOMPLETE present -> failed
#       PASS present, no FAIL     -> passed
#       no VERDICT line at all    -> failed ("never reached its summary")
#   Two tests carry one extra machine-checkable fact each, and both are checked
#   here as well: run_bench_test4.do's capture-event count (must be 3) and the
#   four benchmark cycle counts + DTCM diffs in PART B.
#
#   Per-test transcripts land in logs\<name>.log - that is where to look when
#   the table says FAILED. The table is a summary, never the evidence.
#
# WHAT IT DOES NOT COVER
#   The pipeline (SIM\RV32IMpipelinedMCU has its own batch_verify.do), Quartus,
#   and anything that needs the board. Phase 13's "per core" second half is the
#   pipeline's own regression once Phase 11 lands.

quietly set ::REGRESS 1
file mkdir logs

#=============================================================================
# PART A - every self-checking test, scored by its own VERDICT line
#=============================================================================
# Order: leaves first, then the bus, then whole programs. A failure early makes
# everything after it hard to interpret, so the table is printed in this order
# and the first FAILED row is the one to read.
quietly set TESTS {
    {run_sync.do           "4A  CDC synchronizer"}
    {run_decode.do         "5A  address decoder, exhaustive"}
    {run_clock.do          "4B  clock tree"}
    {run_div.do            "7A  division accelerator (slow: 65536 pairs)"}
    {run_divunit.do        "7B1 division subsystem"}
    {run_timer.do          "8A  Basic Timer core"}
    {run_intc.do           "9A  Interrupt Controller"}
    {run_uart.do           "12A USART, with a real txd->rxd loopback"}
    {repair_check.do       "3A+3B conformance, 43 directed checks"}
    {run_isa.do            "2+3 directed ISA suite"}
    {run_mmio.do           "5B  MMIO no longer reaches the DTCM"}
    {run_gpio.do           "6A  the seven GPO ports"}
    {run_gpio_read.do      "6B  SFR read path"}
    {run_gpio_directed.do  "6C+6D directed GPIO"}
    {run_timer_mmio.do     "8B  timer on the bus"}
    {run_intr_core.do      "9B  CPU-side interrupt protocol"}
    {run_intr_mmio.do      "9C  interrupt path end to end"}
    {run_bench_test1.do    "10A benchmark test1"}
    {run_bench_test4.do    "10B benchmark test4"}
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

quietly set ::results {}
quietly set ::nfail 0

foreach t $TESTS {
    quietly set script [lindex $t 0]
    quietly set label  [lindex $t 1]
    quietly set name   [file rootname $script]

    echo ""
    echo "---- $script  --  $label"
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

    # test4 delegates one pass condition to its own script: the capture events
    # the one-word G-327 fix exists to create. Fold it into the verdict.
    if {$script eq "run_bench_test4.do" && $verdict eq "passed"} {
        if {![info exists ::cap_events] || $::cap_events != 3} {
            quietly set n "?"
            if {[info exists ::cap_events]} { set n $::cap_events }
            quietly set verdict "FAILED (capture events $n, expected 3)"
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

#=============================================================================
# PART B - the four RV32IM benchmarks: counts AND memory, compared
#=============================================================================
# The counts are the Phase 0/1 contract: 134 / 1514 / 2725 / 2735, independently
# confirmed in the reference's own PROJECT_EXPLANATION.md section 7 and
# DOC/HANDOVER_Report_lab5.md section 5.3. The memory comparison is against the
# reference's own 2048-word captures, which is what closes G-204 on this side.
quietly set BENCH_EXPECT {134 1514 2725 2735}
quietly set BENCH_STAGE  "C:/TestPrograms/Quartus21_1"
quietly set BENCH_REF    "../../Auxiliary/Lab 5/SIM/RV32IM_sc"
quietly set bench_done 0

echo ""
echo "=========================================================="
echo " PART B - the four RV32IM benchmarks"
echo "=========================================================="

quietly set have_stage 1
foreach n {1 2 3 4} {
    if {![file exists $BENCH_STAGE/test$n/bin/ITCM.hex]} { set have_stage 0 }
}

if {!$have_stage} {
    echo "SKIPPED: $BENCH_STAGE/test1..4 is not staged."
    echo "  Build it once with the PowerShell block in"
    echo "  DOC/04_baseline_runbook.md section 3, then re-run. PART B is the"
    echo "  only part that needs it; PART A above is complete either way."
    lappend ::results [list "PART B" "four RV32IM benchmarks" "SKIPPED (not staged)"]
} else {
    foreach n {1 2 3 4} {
        quietly set want [lindex $BENCH_EXPECT [expr {$n - 1}]]
        echo ""
        echo "---- benchmark test$n  --  expect mclk_cnt_o = $want"
        transcript file logs/bench_test$n.log

        file copy -force $BENCH_STAGE/test$n/bin/ITCM.hex $BENCH_STAGE/app_bin/ITCM.hex
        file copy -force $BENCH_STAGE/test$n/bin/DTCM.hex $BENCH_STAGE/app_bin/DTCM.hex

        vsim -t ns -gMODELSIM=1 work.tb_rv32imscmcu

        # The official testbench has no auto-stop (Adar's clause 10 rewrite), so
        # the stop condition lives here, exactly as run_test.do states it: the
        # program's final while(1) self-jump, beq x0,x0,0 or jal x0,0.
        onbreak {resume}
        when {/tb_rv32imscmcu/instruction_o == "00000000000000000000000001100011" OR /tb_rv32imscmcu/instruction_o == "00000000000000000000000001101111"} {
            stop
        }
        run 5 ms
        nowhen *

        quietly set got [examine -unsigned /tb_rv32imscmcu/mclk_cnt_o]
        do mem_dump.do
        file copy -force DTCM.mem DTCM_test$n.mem
        quit -sim
        transcript file ""

        # ---- the count
        quietly set count_ok [expr {$got == $want}]

        # ---- the memory, word by word against the reference capture
        #      (the reference file carries a 3-line mti header; ours does not)
        quietly set mem_msg ""
        quietly set ref "$BENCH_REF/DTCM_test$n\_MS.mem"
        if {![file exists $ref]} {
            set mem_msg "no reference capture at $ref"
        } else {
            set fh [open $ref r];            set reftxt [read $fh]; close $fh
            set fh [open DTCM_test$n.mem r]; set outtxt [read $fh]; close $fh
            set refw {}
            foreach ln [split $reftxt "\n"] {
                set ln [string trim $ln]
                if {$ln eq "" || [string match "//*" $ln]} { continue }
                lappend refw [string toupper $ln]
            }
            set outw {}
            foreach ln [split $outtxt "\n"] {
                set ln [string trim $ln]
                if {$ln eq ""} { continue }
                lappend outw [string toupper $ln]
            }
            if {[llength $refw] != [llength $outw]} {
                set mem_msg "length [llength $outw] vs reference [llength $refw]"
            } else {
                set nd 0
                set firstd -1
                for {set i 0} {$i < [llength $refw]} {incr i} {
                    if {[lindex $refw $i] ne [lindex $outw $i]} {
                        incr nd
                        if {$firstd < 0} { set firstd $i }
                    }
                }
                if {$nd != 0} {
                    set mem_msg "$nd word(s) differ, first at word $firstd\
(ours [lindex $outw $firstd], reference [lindex $refw $firstd])"
                }
            }
        }

        if {$count_ok && $mem_msg eq ""} {
            echo "  -> passed: mclk_cnt_o = $got, DTCM identical to the reference capture"
            lappend ::results [list "test$n" "RV32IM benchmark test$n" "passed"]
        } else {
            incr ::nfail
            quietly set why ""
            if {!$count_ok} { append why "mclk_cnt_o = $got, expected $want. " }
            if {$mem_msg ne ""} { append why "DTCM: $mem_msg" }
            echo "  -> FAILED: $why"
            lappend ::results [list "test$n" "RV32IM benchmark test$n" "FAILED"]
        }
        incr bench_done
    }
}

#=============================================================================
# Summary and exit status
#=============================================================================
echo ""
echo "================================================================="
echo " REGRESSION SUMMARY - single-cycle MCU"
echo "================================================================="
foreach r $::results {
    echo [format "  %-24s %-46s %s" [lindex $r 0] [lindex $r 1] [lindex $r 2]]
}
echo "-----------------------------------------------------------------"
if {$::nfail == 0} {
    echo "  ALL PASSED - [llength $::results] entries, 0 failures."
    if {$bench_done == 0} {
        echo "  NOTE: PART B was skipped, so the four benchmark counts and DTCM"
        echo "  comparisons are NOT part of this result. Stage test1..4 and re-run"
        echo "  before treating this as a complete regression."
    }
    echo "================================================================="
    quit -code 0
} else {
    echo "  $::nfail FAILURE(S). Read the per-test log named in the row above;"
    echo "  the first failing row is the one that matters - later tests reuse"
    echo "  what an earlier one proves."
    echo "================================================================="
    quit -code 1
}
