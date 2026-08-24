# run_gpio_directed.do - the directed GPIO test. Closes gaps G-406 and G-407.
#
# Run compile.do first.
#
# ####################################################################
# # THE ONE GPIO TEST THAT NEEDS NEITHER a benchmark NOR              #
# # G_ISA_REPAIR = TRUE. Run it in whatever configuration you have.   #
# ####################################################################
#
# STAGING - generated images, not a benchmark:
#
#   copy <repo>\SIM\RV32IMscMCU\gpio\ITCM.hex  C:\TestPrograms\Quartus21_1\app_bin\ITCM.hex
#   copy <repo>\SIM\RV32IMscMCU\gpio\DTCM.hex  C:\TestPrograms\Quartus21_1\app_bin\DTCM.hex
#
# Regenerate them with:  python3 tools/gen_gpio_test.py
# (Only needed if the map or the cases change; the files are committed.)
#
# WHY IT WORKS AT EITHER G_ISA_REPAIR SETTING
#   Every other GPIO test needs TRUE, because the benchmarks reach 0x2000 through
#   lui and lui writes zero on the unrepaired core. This program builds addresses
#   from addi and slli only (li32 in the generator), loads at offset zero, and has
#   no compares, no sra, no jalr and one beq sentinel at offset 0 - so it touches
#   none of the seven ISA defects. The expected sequence is identical in both
#   configurations, which means a mismatch here is a GPIO problem, never an ISA
#   one.
#
# WHAT IT CLOSES
#   G-406  tb_gpio's cross-talk check was ONE-SIDED: GPIO test0 writes the same
#          value to all seven ports in ascending address order, so a port that
#          wrongly captures a LATER store re-captures a value it already holds and
#          is invisible. This program writes DIFFERENT values to the two halves of
#          each shared chip select, in BOTH orders.
#   G-407  the seven GPO read-back tri-states of Figure 5 were exercised by
#          nothing. This program reads all seven back.
#
#   The two close each other: read-back is what makes a port's content
#   observable, and that is what makes the lane decode discriminable both ways.
#
# THE 32 STORES ALSO COVER
#   - assumption A11: reading PORT_LEDR after writing 0xFF must give 0x000000FF,
#     not 0xFFFFFFFF - so the upper 24 bits really do come back zero
#   - PORT_SW read, value 0x5C (not bit-symmetric, so a reversed bit order
#     cannot pass)
#   - PORT_PB read with KEY3 and KEY2 pressed and KEY1 released, which must give
#     0x06. Also not symmetric under bit reversal - a wrong order gives 0x03. The
#     order is Hanan's forum answer (KEY1 -> bit 0, KEY2 -> bit 1, KEY3 -> bit 2);
#     the polarity is assumption A16
#   - a store to PORT_PB, which is a GPI, must be discarded and must not disturb
#     the value it presents
#   - an unmapped SFR read (0x2030) must return 0 - proves the bus terminator; a
#     floating bus would give Z, which arrives as X in the register file
#   - an unmapped SFR write (0x2034) must be discarded and must not disturb
#     PORT_LEDR
#   - THE PHASE 5B PROPERTY AT PROGRAM LEVEL: a marker is planted in DTCM word 0
#     - the word PORT_LEDR aliased onto before Phase 5B - and read back at the end
#     after fourteen MMIO stores. It must still be 0xDEADBEEF.
#
# WHAT PASS MEANS
#   ZERO mismatches. Unlike run_isa.do, there is no expected-failure count here.
#
#   Every mismatch names its case. Look the case up in
#   SIM\RV32IMscMCU\gpio\listing.txt, which says in words what that case is for
#   and what a failure of it means.
#
#   A wrong ADDRESS points at the effective-address computation or the store path.
#   A wrong VALUE on a ":rd" entry points at the GPIO block itself - the lane
#   decode, the read enables, or the terminator.

onerror {quit -code 1}

vsim -t ns -gMODELSIM=1 work.tb_gpio_directed
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, 35 of 35 stores seen,"
echo "mismatches 0, and about 332 cycles."
echo ""
echo "If two stores of one pair are swapped, the lane term (lane_en_i) on those"
echo "two P_HEXn instances is wrong. If every ':rd' entry reads zero, read-back is"
echo "off - check GEN_GPO_READBACK and rdbk_w. If the unmapped read is non-zero,"
echo "the terminator's enable is wrong. If DTCM word 0 lost its marker, the"
echo "Phase 5B write gating in DMEMORY.vhd is not doing its job."
