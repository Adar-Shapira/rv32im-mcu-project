# run_decode.do - run the exhaustive MMIO address decoder test (Phase 5A)
#
# Run compile.do first. Nothing else is needed: ADDR_DECODER.vhd is combinational
# with no memory, so no benchmark image and no app_bin staging has to be on disk.
#
# The testbench prints its own verdict and stops itself, so there is no stop
# condition here and no waveform to read.
#
# WHAT PASS MEANS
#   All 16384 byte addresses of the §3 data address space agree with a reference
#   model transcribed from Auxiliary/Benchmark Apps/.../io_map.s - not from the
#   RTL. Specifically:
#     - 0x0000..0x1FFF select the DTCM and nothing else                (8192)
#     - exactly 29 SFR bytes are mapped: the 17 byte-resolution
#       registers, plus all four lanes of each of the three
#       Word-resolution registers BTCMPR0 / BTCMPR1 / BTCAPR          (29)
#     - every other address reports unmapped                          (8163)
#     - at most one chip select is ever active
#     - no address ever selects the DTCM and a peripheral at once
#
#   CHECK 0 runs before the sweep and is the one to read first if anything fails.
#   It holds SFR_LANE_MASK in const_package.vhd against the address list in the
#   testbench, lane by lane. If CHECK 0 fails, the specification is wrong and the
#   RTL may be a faithful implementation of it - fix const_package, not the RTL.
#
# WHY THE THREE TOTALS ARE PRINTED
#   Per-address equality can pass while model and RTL share a misconception. The
#   three counts are derived from the register list alone, so a map that is
#   systematically off by one register or one lane shows up as a wrong total even
#   when every individual comparison agreed. The numbers above are absolute:
#   8192 / 29 / 8163, and they must sum to 16384.
#
# IF vcom REJECTS SOMETHING
#   Two constructs here are VHDL-2008 and worth naming, so a failure is a
#   one-line fix rather than a puzzle:
#     - to_string(std_logic_vector) and to_hstring(std_logic_vector), both from
#       ieee.std_logic_1164 in VHDL-2008. tb_sync.vhd already uses to_hstring,
#       so if that testbench compiled, these do too.
#     - the named-association aggregate with OTHERS in SFR_LANE_MASK
#       (const_package.vhd), which is plain VHDL-93.
#   Report what it said rather than rewriting the check.

onerror {quit -code 1}

vsim -t ns work.tb_addr_decoder
run -all

echo ""
echo "Read the SUMMARY block above. Expected: VERDICT: PASS, failures 0,"
echo "and the three totals 8192 / 29 / 8163."
echo ""
echo "This proves the decode function. It does NOT prove the decoder is wired in:"
echo "Phase 5A deliberately leaves ADDR_DECODER.vhd as an uninstantiated leaf, so"
echo "the Phase 1 exit criterion still holds and the four Lab 5 benchmark cycle"
echo "counts (134 / 1514 / 2725 / 2735) must be unchanged by this phase."
