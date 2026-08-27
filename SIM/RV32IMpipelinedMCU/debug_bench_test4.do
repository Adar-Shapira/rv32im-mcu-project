# debug_bench_test4.do -- log interrupt entry and early stores

onerror {resume}

file copy -force ../RV32IMscMCU/bench_fixed/test4/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/bench_fixed/test4/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_bench_test4.vhd
vsim -t ns -gMODELSIM=1 work.tb_bench_test4

when {/tb_bench_test4/MCU/CORE/istate_q'event} {
    echo "ISTATE t=$now istate=[examine /tb_bench_test4/MCU/CORE/istate_q] MEMpc=[examine -hex /tb_bench_test4/MCU/CORE/mem_pc_w] MEMinst=[examine -hex /tb_bench_test4/MCU/CORE/mem_instruction_w] addr=[examine -hex /tb_bench_test4/MCU/dbus_addr_w] type=[examine -hex /tb_bench_test4/MCU/INTC/type_w] typeq=[examine -hex /tb_bench_test4/MCU/CORE/type_q] ifg=[examine -hex /tb_bench_test4/MCU/INTC/ifg_w] irq=[examine -hex /tb_bench_test4/MCU/INTC/irq_q] gie=[examine /tb_bench_test4/MCU/CORE/gie_w] intr_i=[examine /tb_bench_test4/MCU/CORE/intr_i] intr_q=[examine /tb_bench_test4/MCU/CORE/intr_q] accept=[examine /tb_bench_test4/MCU/CORE/accept_w] nst=[examine /tb_bench_test4/nstores]"
}

when {/tb_bench_test4/memw'event} {
    if {[examine /tb_bench_test4/memw] == "1"} {
        echo "STORE t=$now nst=[examine /tb_bench_test4/nstores] addr=[examine -hex /tb_bench_test4/alu_res] data=[examine -hex /tb_bench_test4/st_data] MEMpc=[examine -hex /tb_bench_test4/MCU/CORE/mem_pc_w] istate=[examine /tb_bench_test4/MCU/CORE/istate_q]"
    }
}

run 2 ms
quit -f
