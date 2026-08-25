# run_intr_mmio.do - Phase 9C: the interrupt path end to end, on the MCU
#
# Run compile.do first.
#
# ######################################################################
# # STAGING REQUIRED, like run_mmio/run_gpio/run_timer_mmio:           #
# #   copy SIM\RV32IMscMCU\intrmmio\ITCM.hex and DTCM.hex into app_bin #
# #   (C:\TestPrograms\Quartus21_1\app_bin\). NOT any other image set. #
# # Runs at EITHER G_ISA_REPAIR setting.                               #
# ######################################################################
#
# WHAT THIS IS
#   The first test with NO testbench emulation anywhere in the interrupt
#   path: a real KEY1 release on the raw active-low pin and a real Basic
#   Timer EQU0 each travel pin/timer -> INTERRUPT_CTRL (9A) -> INTR ->
#   the core's two-cycle entry (9B) -> the TYPE PUSH as a real driver of
#   the one shared data bus -> the vector the program itself wrote ->
#   the ISR reading and W0C-clearing IFG through the bus -> reti. The
#   bench does exactly one thing: presses KEY1 when the program says it
#   is ready. All 14 expected stores are EXACT - no ranges.
#
# WHAT PASS MEANS
#   - CS_INTC and lanes 0/1/2 decode (IE at 0x202C, IFG at the ODD 0x202D,
#     TYPE at 0x202E - the map's first lane-2 register).
#   - The release edge of a real pin becomes an interrupt (DOC/03 C).
#   - TYPE reads 0x14 inside the KEY ISR while the flag pends (rule d),
#     and the benchmark and-mask store clears it (W0C) - all via the bus.
#   - bt_ifg_set_w, generated in Phase 8B and deliberately unconsumed
#     since, finally raises an interrupt with no pin involved; the BT ISR
#     reads IFG = 0, i.e. rule a's auto-clear observed from software.
#   - IE reads back 0x0C; IFG/TYPE read 0 when idle; gp reads 1 after
#     both retis; the end marker lands - main resumed both times.
#
# WHAT PASS DOES NOT MEAN
#   Nothing new about the controller's corner cases (run_intc.do) or the
#   entry FSM's timing corners incl. F13 (run_intr_core.do) - those stay
#   proven at their own levels. And not yet the supplied Interrupt-based
#   IO benchmarks - that is Phase 10, on exactly this hardware.
#
# EXPECTED FIRST-RUN BEHAVIOUR
#   The program and its 14 expectations were derived twice: declared in
#   tools/gen_intr_mmio_test.py, and reproduced by executing the program
#   against model_interrupt_ctrl.Intc + model_basic_timer.Timer COMPOSED
#   on the bus with the 9B protocol between them - the same two models
#   whose 12 + 8 mutations were all caught at their leaf phases.

onerror {quit -code 1}

vsim -t ns work.tb_intr_mmio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0."
echo ""
echo "If [0x200] stayed 0: the KEY1 release never became an interrupt. Check"
echo "  in this order: PORT_PB still reads the keys (KEYCOND), run_intc P8"
echo "  passed (release edge), and the MCU's INTC instance wiring."
echo "If [0x204] stayed 0: the timer fired but never reached the controller;"
echo "  bt_ifg_set_w is the suspect wire."
echo "If [0x180] is 0x00: the ISR ran but TYPE's lane-2 reader is miswired."
echo "If [0x188] is not 0: the IFG write path (lane 1) does not clear - W0C."
echo "If [0x18C] is 0x04: rule a's auto-clear did not happen at service."
echo "If the bus warns about 2 drivers during entry: the TYPE push collided;"
echo "  the core's annul must keep MemRead AND MemWrite low in Cycle 1."
