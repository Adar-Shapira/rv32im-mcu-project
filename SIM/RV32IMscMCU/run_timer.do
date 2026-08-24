# run_timer.do - Phase 8A: the Basic Timer core of Figure 7
#
# Run compile.do first.
#
# ####################################################################
# # ZERO SETUP. No memory images, no G_ISA_REPAIR setting, nothing to #
# # stage. A leaf test, like run_sync/run_decode/run_clock/run_div/   #
# # run_divunit.                                                      #
# ####################################################################
#
# WHERE THIS TIMER COMES FROM -- checked before it was written
#   Most of the skeleton is Auxiliary/Lab4/DUT/pwm.vhd, read in full first:
#   its wrap-at-Y counter is BTCNT with F17's wrap-at-BTCL0, its ena is
#   BTOUTEN ("hold the PWMout signal value" -- page 8's own words for an
#   update-enable), its Mode 0 Set/Reset and Mode 1 Reset/Set are BTOUTMD's
#   two values with X renamed BTCL1. Its Mode 2 (Toggle) is dropped -- BTOUTMD
#   is one bit and Figure 8 draws exactly two traces. No other timer, counter
#   or capture precedent exists anywhere in Labs 3, 4 or 5 -- searched.
#
# BTINT -- TWO OF THE FOUR CODES ARE PINNED BY THE BENCHMARKS, NOT GUESSED
#   io_map.s defines BTINT2 = 0x02, and test4/01_func.s:156-158 writes
#   BTCTL1=(BTHOLD,BTCLR,BTINT=2) precisely when configuring INPUT CAPTURE;
#   every compare-interrupt test runs with BTINT=0. So 00->EQU0 and
#   10->capture are benchmark facts; 01->EQU1 is the only source left; 11 is
#   reserved -- "three options" in two bits, exactly as page 8 says.
#   Question B4 is thereby mostly answered from the material (assumption A20
#   covers only the 01/11 half).
#
# WHAT PASS MEANS
#   P0  F16 exactly as Hanan stated it -- reset clears the five interface
#       registers AND LEAVES BTCNT ALONE. The second half is checked by
#       running the counter, pulsing reset, and requiring it to come out
#       non-zero.
#   P1  the prescaler is exact: EQU0 every 10 / 20 / 40 / 80 cycles for
#       BTSSEL = 00 / 01 / 10 / 11 with BTCL0 = 9.
#   P2  F17 live: BTCNT never exceeds BTCL0 while the monitor is armed.
#   P3  PWM duty over whole periods: Mode0 high 6 of 20 cycles, Mode1 high
#       14 of 20 (BTCL0=9, BTCL1=3) -- Lab 4 pwm.vhd's own update ordering.
#   P4  BTOUTEN=0 freezes PWMout.   P5  BTHOLD freezes, BTCLR zeroes.
#   P6  capture: test4's actual 0x07 value produces NOTHING (the source is
#       parked on GND -- the benchmark bug DOC/03 Q3 documents, reproduced in
#       hardware); GND->VCC produces exactly one capture with BTCAPR equal to
#       the frozen BTCNT, no tolerance; falling edge works; CAPMD=00 blocks;
#       and a real CAPIN1 pin edge captures once.
#   P7  BTINT=11 (reserved) never pulses; BTINT=00 pulses exactly 5 times in
#       25 cycles at period 5.
#   P8  FREQ_5K with the real io_map.s constant: interval = (500+1)*8 = 4008
#       SMCLK cycles. THE NOTE IT PRINTS IS A FINDING: 4008 cycles at 20 MHz
#       is 4990 Hz, not 5000. F17-literal hardware ("restarts after reaching
#       BTCL0") makes the period BTCL0+1, so exactly 5 kHz needs BTCMPR0=499.
#       Same class as B2's SEC_PERIOD factor-8: the constant and the hardware
#       definition disagree, the hardware follows Hanan's stated definition,
#       and the discrepancy is reported rather than silently fixed.
#
# WHAT PASS DOES NOT MEAN
#   Nothing about the MMIO wiring (Phase 8B puts the five registers on the
#   bus and the read-backs behind BidirPin) and nothing about the interrupt
#   controller (Phase 9 latches btifg_set_o into IFG under the falsified-A6
#   rule). CAPIN pin assignment needs B1/F18.
#
# WHY THE FIRST RUN SHOULD PASS
#   tools/model_basic_timer.py executes the RTL's per-edge semantics through
#   these same phases: 0 failures, and eight faithful mutations (a counter
#   that obeys reset, a wrap one count early, a lame /4 divider, swapped PWM
#   modes, PWM toggling at EQU0, the reserved BTINT code firing, capture not
#   writing BTCAPR, BTHOLD ignored) are ALL caught -- each by the property
#   built to catch it.

onerror {quit -code 1}

vsim -t ns work.tb_basic_timer
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failed 0, and the"
echo "P8 NOTE about 4008-vs-4000 cycles (a finding about FREQ_5K, not a bug)."
echo ""
echo "If P1 fails at one BTSSEL value only: that divider tap of the prescaler."
echo "If P3 fails with 6 and 14 swapped: BTOUTMD's modes are inverted."
echo "If P0b fails: BTCNT has a reset arm it must not have - Hanan's F16."
echo "If P6a fails: a capture fired from a GND-parked source, which would make"
echo "test4's buggy 0x07 configuration 'work' - that is wrong twice over."
