Lab 4: Advanced CPU Architecture & Hardware Accelerators
Adar Shapira 209580208
Yehonatan Dadkha 211468582

DUT VHDL files
--------------
* aux_package.vhd        : Component declarations for the whole design (top, FA, AdderSub, Logic, Shifter, pwm, digital_system, hex_decoder, pll).
* FA.vhd                 : Structural 1-bit Full Adder (sum and carry-out).
* AdderSub.vhd           : Generic n-bit ripple-carry adder/subtractor: add, 2's-complement subtract, negate, double increment (Y+2) and double decrement (Y-2).
* Logic.vhd              : Generic n-bit bitwise logic unit: NOT, OR, AND, XOR, NOR, NAND, XNOR.
* Shifter.vhd            : Generic n-bit barrel shifter (structural MUX matrix) for logarithmic left/right shifting with carry-out.
* top.vhd                : Combinational subpart (Lab 1 ALU). Structural top connecting AdderSub/Logic/Shifter, selected by ALUFN[4:3], with N,C,Z,V flags.
* pwm.vhd                : Synchronous subpart. 16-bit up-counter (period = Y) driving a PWM output in three modes (0 Set/Reset, 1 Reset/Set, 2 Toggle at X), with async reset and enable.
* digital_system.vhd     : Structural integration of the combinational (top) and synchronous (pwm) subparts. The PWM is enabled/fed only when ALUFN[4:3]="00" (PWM instruction class, Figure 4).
* hex_decoder.vhd        : 4-bit binary to active-low 7-segment decoder for the DE2-115 HEX displays.
* pll.vhd                : ALTPLL that derives the 2 MHz system clock from the 50 MHz board oscillator (Figure 7).
* fpga_hw_interface.vhd  : Structural board-level top. Input registers (X,Y,ALUFN) loaded from SW via KEY0/KEY1/KEY2 (SW9 selects high/low byte), PLL clock, flags to LEDR3-0, ALUout to HEX5-4, X/Y to HEX3-0, PWM to GPIO[9].
* perf_wrapper.vhd       : Performance test-case wrapper (Figure 1). Confines the combinational ALU (top) between input and output registers on one clock, for f_max / critical-path analysis.

Quartus revisions
-----------------
* Lab4_Perf : performance revision, top = perf_wrapper, no pin assignments, SignalTap off, constrained by Lab4_perf.sdc.
* Lab4_HW   : hardware revision, top = fpga_hw_interface, DE2-115 pins, PLL, SignalTap (stp1.stp), constrained by Lab4_hw.sdc.
