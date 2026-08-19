# run_test.do - edit N to choose the benchmark, then run this macro
set N 4

# load the benchmark images into app_bin (Tcl needs forward slashes)
file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vsim -t ns work.tb_rv32im_pipeline
do wave.do

# stop automatically when the program's final while(1) self-jump (beq x0,x0,0
# or jal x0,0) is RESOLVED TAKEN IN THE MEM STAGE. Watching for the instruction
# in ID (like the single-cycle script does) is wrong here: branches resolve in
# MEM, so straight-line speculative fetch brings the end-of-program while(1)
# into ID during the first loop iteration - it would be flushed, but the "when"
# would already have stopped the run. A flush whose redirect target equals the
# flushing instruction's own PC (target+4 == mem_pc_plus4) can only be the
# final self-jump. The 5 ms bound only catches a runaway (bug) case.
onbreak {resume}
when {/tb_rv32im_pipeline/flush_o == "1"} {
    set tgt  [examine -unsigned /tb_rv32im_pipeline/CORE/redirect_addr_w]
    set pcp4 [examine -unsigned /tb_rv32im_pipeline/CORE/mem_pc_plus4_w]
    if {$tgt + 4 == $pcp4} {
        echo "Program finished (while(1) self-jump resolved in MEM) at $now ns"
        stop
    }
}
run 5 ms

# capture the counters now, before the endless self-jump loop keeps bumping
# CLKCNT/FHCNT, and report the IPC equation from the lab PDF
set clkcnt [examine -unsigned /tb_rv32im_pipeline/CLKCNT_o]
set stcnt  [examine -unsigned /tb_rv32im_pipeline/STCNT_o]
set fhcnt  [examine -unsigned /tb_rv32im_pipeline/FHCNT_o]
if {$clkcnt > 0} {
    set ipc [expr {double($clkcnt - ($stcnt + 4 + 3*$fhcnt)) / $clkcnt}]
    echo "CLKCNT=$clkcnt STCNT=$stcnt FHCNT=$fhcnt  =>  IPC = (CLKCNT-(STCNT+4+3*FHCNT))/CLKCNT = [format %.4f $ipc]"
}

# let the instructions still in flight (EX/MEM/WB) retire - the last stores
# must reach the DTCM before the dump
nowhen *
run 1 us
do mem_dump.do