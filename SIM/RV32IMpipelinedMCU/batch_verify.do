# batch_verify.do - headless verification: compile once, then run test1..test4.
# For each test it loads the benchmark images, runs until the final while(1)
# self-jump reaches ID, reports the CLKCNT/STCNT/FHCNT counters + IPC equation,
# lets the in-flight instructions retire, and dumps the DTCM to DTCM_testN.mem
# (same flow as run_test.do, without the GUI/wave setup).
do compile.do

for {set N 1} {$N <= 4} {incr N} {
    file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
    file copy -force C:/TestPrograms/Quartus21_1/test$N/bin/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

    vsim -t ns -gMODELSIM=1 work.tb_rv32impipelinedmcu

    onbreak {resume}
    when {/tb_rv32impipelinedmcu/MCU/CORE/flush_w == "1"} {
        set tgt  [examine -unsigned /tb_rv32impipelinedmcu/MCU/CORE/redirect_addr_w]
        set pcp4 [examine -unsigned /tb_rv32impipelinedmcu/MCU/CORE/mem_pc_plus4_w]
        if {$tgt + 4 == $pcp4} {
            echo "TEST$N: program finished (while(1) self-jump resolved in MEM) at $now ns"
            stop
        }
    }
    run 5 ms

    set clkcnt [examine -unsigned /tb_rv32impipelinedmcu/CLKCNT_o]
    set stcnt  [examine -unsigned /tb_rv32impipelinedmcu/STCNT_o]
    set fhcnt  [examine -unsigned /tb_rv32impipelinedmcu/FHCNT_o]
    if {$clkcnt > 0} {
        set retired [expr {$clkcnt - ($stcnt + 4 + 3*$fhcnt)}]
        set ipc [expr {double($retired) / $clkcnt}]
        echo "TEST$N RESULT: CLKCNT=$clkcnt STCNT=$stcnt FHCNT=$fhcnt RETIRED=$retired IPC=[format %.4f $ipc]"
    }

    nowhen *
    run 1 us
    do mem_dump.do
    file copy -force DTCM.mem DTCM_test$N.mem
    quit -sim
}
quit -f
