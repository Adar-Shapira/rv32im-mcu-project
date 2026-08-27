# batch_verify.do - headless verification of the pipelined MCU: compile once,
#                   then run test1..test4, COMPARE, and exit non-zero on any
#                   failure.
#
# WHAT CHANGED 2026-08-26 (Phase 13, the pipeline half of gap G-203)
#   This script used to run the four benchmarks and echo the counters. It never
#   compared anything and it always exited 0, so a broken pipeline produced
#   output that looked exactly like a working one. It now:
#     * diffs each DTCM dump word by word against the reference's own capture,
#       Auxiliary\Lab 5\SIM\RV32IM_pipeline\DTCM_testN_MS.mem, naming the first
#       differing word and both values;
#     * fails a test whose program never reached its final while(1) - the run
#       hitting the 5 ms bound instead of the stop condition;
#     * prints one summary table and `quit -code 1` if anything failed.
#   The single-cycle equivalent is SIM\RV32IMscMCU\regress.do, which also scores
#   that core's self-checking tests. This script stays benchmark-only, but the
#   pipeline is no longer without a self-checking suite: since Phase 12B/12C it
#   has run_uart_mmio.do and run_uart_menu.do, which point the single-cycle
#   tests' own exact expectations at THIS core (the peripherals are byte-
#   identical in both trees, so what those two runs actually exercise is the
#   pipelined interrupt entry). Run them alongside this script; they stage the
#   single-cycle tree's generated images and need nothing else.
#
# HOW TO RUN
#       cd SIM\RV32IMpipelinedMCU
#       vsim -c -do batch_verify.do
#       echo %ERRORLEVEL%          REM 0 = all four matched, 1 = something did not
#
#   Needs the one-time C:\TestPrograms\Quartus21_1\test1..4 layout from
#   DOC/04_baseline_runbook.md section 3. The script checks for it and stops
#   with a named reason rather than running whatever is left in app_bin.
#
# THE COUNTERS ARE REPORTED, NOT ASSERTED - deliberately.
#   CLKCNT/STCNT/FHCNT are the input to the IPC check (gap G-205) and are
#   recorded nowhere yet. PROJECT_EXPLANATION.md section 8.6 gives roughly
#   170 / 1,918 / 3,623 / 3,651 cycles, stalls 8 / 100 / 0 / 0, flushes
#   8 / 100 / 298 / 304 - but those include the testbench drain, so they are a
#   RANGE, not a target. Asserting on them would manufacture false failures.
#   The DTCM comparison is the exact pass criterion; the counters are evidence
#   to copy into the plan file.

quietly set STAGE "C:/TestPrograms/Quartus21_1"
quietly set REF   "../../Auxiliary/Lab 5/SIM/RV32IM_pipeline"

quietly set have_stage 1
foreach n {1 2 3 4} {
    if {![file exists $STAGE/test$n/bin/ITCM.hex]} { set have_stage 0 }
}
if {!$have_stage} {
    echo "ABORT: $STAGE/test1..4 is not staged."
    echo "  Build it once with the PowerShell block in"
    echo "  DOC/04_baseline_runbook.md section 3, then re-run."
    quit -code 1
}

if {[catch {do compile.do} err]} {
    echo "COMPILE FAILED: $err"
    quit -code 1
}

# Word-by-word DTCM comparison. The reference file carries a 3-line mti header;
# ours does not, so both are reduced to a bare list of upper-case words first.
proc dtcm_diff {ours ref} {
    if {![file exists $ref]} { return "no reference capture at $ref" }
    set fh [open $ref r];  set reftxt [read $fh]; close $fh
    set fh [open $ours r]; set outtxt [read $fh]; close $fh
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
        return "length [llength $outw] vs reference [llength $refw]"
    }
    set nd 0
    set firstd -1
    for {set i 0} {$i < [llength $refw]} {incr i} {
        if {[lindex $refw $i] ne [lindex $outw $i]} {
            incr nd
            if {$firstd < 0} { set firstd $i }
        }
    }
    if {$nd != 0} {
        return "$nd word(s) differ, first at word $firstd (ours\
[lindex $outw $firstd], reference [lindex $refw $firstd])"
    }
    return ""
}

quietly set ::results {}
quietly set ::nfail 0

for {set N 1} {$N <= 4} {incr N} {
    echo ""
    echo "---- pipeline benchmark test$N"
    file copy -force $STAGE/test$N/bin/ITCM.hex $STAGE/app_bin/ITCM.hex
    file copy -force $STAGE/test$N/bin/DTCM.hex $STAGE/app_bin/DTCM.hex

    vsim -t ns -gMODELSIM=1 work.tb_rv32impipelinedmcu

    # The stop condition, unchanged and load-bearing: do NOT halt when the
    # while(1) self-jump appears in a decode stage. Branches resolve in MEM, so
    # straight-line speculative fetch brings the end-of-program while(1) into ID
    # during the FIRST loop iteration - it would be flushed, but a "when" on ID
    # would already have stopped the run. A flush whose redirect target equals
    # the flushing instruction's own PC (target+4 == mem_pc_plus4) can only be
    # the final self-jump.
    quietly set ::finished 0
    onbreak {resume}
    when {/tb_rv32impipelinedmcu/MCU/CORE/flush_w == "1"} {
        set tgt  [examine -unsigned /tb_rv32impipelinedmcu/MCU/CORE/redirect_addr_w]
        set pcp4 [examine -unsigned /tb_rv32impipelinedmcu/MCU/CORE/mem_pc_plus4_w]
        if {$tgt + 4 == $pcp4} {
            echo "TEST$N: program finished (while(1) self-jump resolved in MEM) at $now ns"
            quietly set ::finished 1
            stop
        }
    }
    run 5 ms

    quietly set clkcnt [examine -unsigned /tb_rv32impipelinedmcu/CLKCNT_o]
    quietly set stcnt  [examine -unsigned /tb_rv32impipelinedmcu/STCNT_o]
    quietly set fhcnt  [examine -unsigned /tb_rv32impipelinedmcu/FHCNT_o]
    if {$clkcnt > 0} {
        # The IPC equation is LAB5 task definition clause 6.iii.b: the retired
        # count removes the fill (depth-1 = 4) and depth = 3 per flush.
        quietly set retired [expr {$clkcnt - ($stcnt + 4 + 3*$fhcnt)}]
        quietly set ipc [expr {double($retired) / $clkcnt}]
        echo "TEST$N RESULT: CLKCNT=$clkcnt STCNT=$stcnt FHCNT=$fhcnt RETIRED=$retired IPC=[format %.4f $ipc]"
    }

    nowhen *
    run 1 us
    do mem_dump.do
    file copy -force DTCM.mem DTCM_test$N.mem
    quit -sim

    quietly set why ""
    if {!$::finished} {
        append why "the program never reached its final while(1) - the run hit\
the 5 ms bound. "
    }
    quietly set mem_msg [dtcm_diff DTCM_test$N.mem "$REF/DTCM_test$N\_MS.mem"]
    if {$mem_msg ne ""} { append why "DTCM: $mem_msg" }

    if {$why eq ""} {
        echo "  -> passed: DTCM identical to the reference capture"
        lappend ::results [list "test$N" "passed" "CLKCNT=$clkcnt STCNT=$stcnt FHCNT=$fhcnt"]
    } else {
        incr ::nfail
        echo "  -> FAILED: $why"
        lappend ::results [list "test$N" "FAILED" $why]
    }
}

echo ""
echo "================================================================="
echo " PIPELINE BENCHMARK REGRESSION"
echo "================================================================="
foreach r $::results {
    echo [format "  %-8s %-10s %s" [lindex $r 0] [lindex $r 1] [lindex $r 2]]
}
echo "-----------------------------------------------------------------"
echo "  Copy the CLKCNT/STCNT/FHCNT triples into the plan file - they are"
echo "  gap G-205 and the input to the IPC check. They are reported, not"
echo "  asserted: PROJECT_EXPLANATION section 8.6's figures include the"
echo "  testbench drain, so they are a range and not a target."
if {$::nfail == 0} {
    echo "  ALL FOUR MATCHED the reference captures."
    echo "================================================================="
    quit -code 0
} else {
    echo "  $::nfail FAILURE(S) - see the rows above."
    echo "================================================================="
    quit -code 1
}
