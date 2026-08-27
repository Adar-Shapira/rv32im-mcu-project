# run_ppa_row1.do - Phase 14: PROVE the interrupt-free configuration is a
#                   working MCU, not merely one that compiles
#
# Run compile.do first.
#
# WHY THIS EXISTS
#   Clause 6's three PPA tables -- Area, Performance, Power, each with
#   "Attaching the print screen ... is mandatory" -- have THREE rows:
#       1. MCU with GPIO
#       2. MCU with GPIO and Interrupt Capability
#       3. Pipelined MCU with GPIO and Interrupt Capability
#   Row 1 is a build with NO interrupt capability, and the point of the table
#   is the delta between rows 1 and 2: what interrupt capability costs. Until
#   Phase 14 this project had no way to produce row 1 at all - the finding was
#   recorded nowhere.
#
#   RV32IMscMCU now has a GEN_INTERRUPT generic. With it FALSE the interrupt
#   controller, the Basic Timer, the USART and PORT_PB are not instantiated
#   and their readers are gated off - exactly clause 6's twelve addresses,
#   no more and no less. PORT_PB is in that list: it looks like a GPIO input
#   port but clause 6 is where the specification puts it, because the KEYs are
#   an interrupt source.
#
# WHAT THIS RUN IS FOR
#   A synthesis run would tell Adar the area of row 1 but nothing about
#   whether row 1 WORKS. This runs the GPIO suite against it. tb_gpio is the
#   right suite and tb_gpio_directed is not: tb_gpio touches the seven GPO
#   ports and nothing in clause 6, so every one of its checks must still pass
#   with the interrupt capability compiled out, whereas tb_gpio_directed reads
#   PORT_PB and is EXPECTED to fail in row 1.
#
#   It is the same testbench, the same benchmark image and the same
#   expectations as run_gpio.do. Only the generic differs. If run_gpio.do
#   passes and this does not, the fault is in the row-1 gating, not in the
#   GPIO ports.
#
# WHAT PASS MEANS
#   The row-1 configuration elaborates with no unbound component and no
#   undriven read-back, the bus one-hot property still holds with a third of
#   its drivers gone, and the seven GPO ports still work. That is the honest
#   precondition for reporting row 1's numbers.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about area, Fmax or power - those are Quartus's answer and the
#   whole reason the generic exists. See DOC/04 for what to compile and which
#   numbers to record.
#
# FOR QUARTUS
#   Either flip G_GEN_INTERRUPT in cond_compilation_package.vhd to False for
#   the row-1 compile and back afterwards, or override the generic in a
#   dedicated revision. tools/check_config_defaults.py asserts the committed
#   value is True, so a tree left flipped after a measurement cannot be
#   committed by accident.

onerror {quit -code 1}

# Images: supplied: Auxiliary/Benchmark Apps/GPIO/test0 -- the same pair
# run_gpio.do uses. Nothing about test0 involves an interrupt.
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/ITCM.hex} C:/TestPrograms/Quartus21_1/app_bin/ITCM.hex
file copy -force {../../Auxiliary/Benchmark Apps/GPIO/test0/bin/M9K-intel/DTCM.hex} C:/TestPrograms/Quartus21_1/app_bin/DTCM.hex

vcom -2008 ../../TB/RV32IMscMCU/tb_gpio.vhd

vsim -t ns -gMODELSIM=1 -gGEN_INTERRUPT=FALSE work.tb_gpio
run -all

echo ""
echo "Read the SUMMARY block above. Expected: identical to run_gpio.do's."
echo ""
echo "If an entity is reported unbound, a generate branch is missing a tie-off."
echo "If the bus reports NO driver ('Z' at the register file), a reader was"
echo "  gated off without its word dropping out of the terminator's condition."
echo "If a GPO check fails here but passes in run_gpio.do, the row-1 gating"
echo "  reached something in clause 5 that it should not have touched."
