# run_uart_mmio.do - the USART on the bus, on the PIPELINED MCU
#
# Run compile.do first.
#
# ######################################################################
# # STAGING IS AUTOMATIC, and it stages the SINGLE-CYCLE tree's        #
# # images:  ..\RV32IMscMCU\uartmmio\{ITCM,DTCM}.hex                   #
# # The program is core-agnostic, so there is ONE copy of it rather    #
# # than two copies that can drift apart. Regenerate with:             #
# #     python3 tools/gen_uart_mmio_test.py                            #
# ######################################################################
#
# WHY THIS RUN EXISTS WHEN THE SINGLE-CYCLE ONE PASSES
#   Every peripheral is byte-identical between the two DUT trees, and
#   tools/check_peripheral_copies.py enforces that, so the USART itself is
#   already proven by the single-cycle run. What is NOT shared is the core.
#   The pipelined interrupt entry is a different design - its own retirement
#   boundary, its own flush, RXBUF's read side effect landing in the MEM
#   stage. The same 22 exact expectations are pointed at it.
#
#   The checks are IDENTICAL to the single-cycle testbench's. Only the
#   instantiation differs: store observation comes from MemWrite_ctrl_o /
#   alu_res_o / read_data2_o, and the sentinel is watched in the MEM stage,
#   because branches resolve there and a decode-stage watch would stop on a
#   speculative fetch of the final self-jump (the trap batch_verify.do
#   documents).

onerror {quit -code 1}

file copy -force ../RV32IMscMCU/uartmmio/ITCM.hex C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force ../RV32IMscMCU/uartmmio/DTCM.hex C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMpipelinedMCU/tb_uart_mmio.vhd

vsim -t ns work.tb_uart_mmio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo "If the single-cycle run of the same test passes and this one does not,"
echo "the fault is in the PIPELINED CORE, not in the USART: the peripherals"
echo "are byte-identical in both trees and a checker asserts it."
