# run_rv32im_test1.do - Phase 11 slice 3: course RV32IM test1 vs RARS DTCM.h
#
# Run compile.do first.
# Images: man_compiled M9K-intel (matches the RARS golden, not gcc_compiled)
# Golden: man_compiled/output/RARS/DTCM.h (NOT Lab 5 DTCM_test1_MS.mem)

onerror {quit -code 1}

file copy -force {../../Auxiliary/Benchmark Apps/RV32IM/test1/man_compiled/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/RV32IM/test1/man_compiled/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vsim -t ns -gMODELSIM=1 work.tb_rv32impipelinedmcu

onbreak {resume}
when {/tb_rv32impipelinedmcu/MCU/CORE/flush_w == "1"} {
    set tgt  [examine -unsigned /tb_rv32impipelinedmcu/MCU/CORE/redirect_addr_w]
    set pcp4 [examine -unsigned /tb_rv32impipelinedmcu/MCU/CORE/mem_pc_plus4_w]
    if {$tgt + 4 == $pcp4} {
        echo "Program finished (while(1) self-jump resolved in MEM) at $now ns"
        stop
    }
}
run 5 ms
nowhen *
run 1 us

quietly set last_word 1023
set dtcm_path /tb_rv32impipelinedmcu/MCU/CORE/MEM/data_memory/MEMORY/m_mem_data_a
mem save -format mti -data hex -addr decimal -wordsperline 1 \
    -startaddress 0 -endaddress $last_word \
    -outfile DTCM_raw.mem $dtcm_path

set fin  [open DTCM_raw.mem r]
set fout [open DTCM.mem w]
while {[gets $fin line] >= 0} {
    if {[string match "//*" $line] || [string trim $line] eq ""} { continue }
    puts $fout [string toupper [string trim [lindex [split $line ":"] end]]]
}
close $fin
close $fout
file delete DTCM_raw.mem

set golden "../../Auxiliary/Benchmark Apps/RV32IM/test1/man_compiled/output/RARS/DTCM.h"
set fh [open $golden r];  set reftxt [read $fh]; close $fh
set fh [open DTCM.mem r]; set outtxt [read $fh]; close $fh
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

set nref [llength $refw]
set nout [llength $outw]
if {$nout < $nref} {
    echo "FAIL: dump has $nout words, RARS has $nref"
    quit -code 1
}
set nd 0
set firstd -1
for {set i 0} {$i < $nref} {incr i} {
    if {[lindex $refw $i] ne [lindex $outw $i]} {
        incr nd
        if {$firstd < 0} { set firstd $i }
    }
}
if {$nd == 0} {
    echo "VERDICT: PASS - $nref words match RARS DTCM.h"
} else {
    echo "VERDICT: FAIL - $nd mismatches, first at word $firstd (got [lindex $outw $firstd] expected [lindex $refw $firstd])"
    quit -code 1
}
quit -f
