# compile.do - compile the UNMODIFIED Lab 5 single-cycle reference
#
# WHY THIS FILE EXISTS
#   Phase 0 proves the environment against the reference before anything of ours
#   is trusted. The reference used to ship its own compile/run/dump scripts; the
#   2026-08-23 replacement deleted them. What remains in
#   Auxiliary/Lab 5 - as submitted/SIM/RV32IM_sc/ is golden.do, wave.do, the
#   four captured DTCM dumps and the .mpf - there is no compile.do for the
#   single-cycle core anywhere in the reference tree (only the pipeline has one).
#
#   So the scripts live here instead of being added to Auxiliary/. That folder is
#   reference-only by rule, and it stays byte-for-byte as supplied. Everything
#   below reaches into it read-only.
#
# NO SOURCE EDIT IS NEEDED, IN THE REFERENCE OR ANYWHERE
#   The older runbook told you to set G_MODELSIM := 1 by hand in the reference's
#   cond_compilation_package.vhd. Do not. tb_RV32IM_sc exposes MODELSIM as a
#   generic (TB/RV32IM_sc/tb_RV32IM_sc.vhd:19) and forwards it to the core
#   (line 61), so run_test.do passes -gMODELSIM=1 and the package default of 0
#   stays untouched for Quartus. This is what closes gap G-201 on the reference
#   side as well as ours.
#
#   That matters more than convenience here: the revised reference core inverts
#   reset when MODELSIM = 0
#   (DUT/RV32IM_sc/RV32IM_CORE.vhd: rst_w <= rst_i WHEN MODELSIM /= 0 ELSE NOT rst_i).
#   Compiled at the default of 0, the testbench's active-high reset pulse would
#   hold the core in reset forever and nothing would run.
#
# HOW TO RUN
#   ModelSim -> File -> Change Directory -> SIM\baseline_reference
#   then  do compile.do  followed by  do run_test.do

transcript on
onerror {quit -code 1}

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# Braces, not quotes: the reference path contains spaces.
set REF {../../Auxiliary/Lab 5 - as submitted}

# packages first - everything depends on them
vcom -2008 "$REF/DUT/RV32IM_sc/cond_compilation_package.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/const_package.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/aux_package.vhd"

# multiplier, submodules, core, testbench
vcom -2008 "$REF/DUT/RV32IM_sc/MUL16.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/PLL.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/CONTROL.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/IFETCH.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/IDECODE.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/EXECUTE.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/DMEMORY.vhd"
vcom -2008 "$REF/DUT/RV32IM_sc/RV32IM_CORE.vhd"
vcom -2008 "$REF/TB/RV32IM_sc/tb_RV32IM_sc.vhd"

echo ""
echo "PASS: reference single-cycle sources compiled."
echo "  Expect 0 errors. Three EXECUTE.vhd warnings"
echo "  ('Non-locally static OTHERS choice') are known and harmless."
echo "  Next: do run_test.do"
