#!/usr/bin/env python3
"""Generate the directed GPIO test — closes gaps G-406 and G-407.

WHY THIS EXISTS
    Phase 6A and 6B each shipped with a registered hole in their own verification:

      G-406  tb_gpio's cross-talk check is one-sided. GPIO test0 writes the SAME
             value to all seven ports in ascending address order, so a port that
             wrongly captures an EARLIER store fails, but one that wrongly
             captures a LATER store re-captures a value it already holds and is
             invisible.
      G-407  The seven GPO read-back tri-states of Figure 5 are implemented and
             exercised by nothing. No supplied benchmark reads PORT_LEDR or a
             PORT_HEXn; the only MMIO reads anywhere are three lw from PORT_SW.

    The two close each other. Read-back is what makes a port's CONTENT
    observable, and once content is observable the lane decode is fully
    discriminable: write different values to the two halves of a shared chip
    select, read both back, and any extra or missing capture shows up as a wrong
    value. Neither gap needs an answer from anyone — only a program, which no
    supplied benchmark provides.

WHY THIS RUNS AT EITHER G_ISA_REPAIR SETTING
    Every other GPIO test needs G_ISA_REPAIR = TRUE, because the benchmarks reach
    0x2000 through `lui` and `lui` writes zero on the unrepaired core. This
    program builds addresses with li32() from gen_isa_test.py, which assembles a
    constant from addi and slli only. Checked against all seven defects:

      1 andi writes 0 / ori computes AND ..... not used (no andi, no ori)
      2 lui writes 0 ......................... not used (li32 instead)
      3 loads address rs1 + 0 ................ every load here has offset 0
      4 sra is srl ........................... not used
      5 unsigned compares are signed ......... not used (no compares at all)
      6 branch displacement truncated ........ only the sentinel, offset 0
      7 jalr does not clear bit 0 ............ not used (straight-line program)

    So the expected store sequence is the same in both configurations and the
    testbench needs no configuration guard. That also makes this the one GPIO
    test Adar can run without touching cond_compilation_package.vhd.

WHAT IT PROVES, CASE BY CASE
    See CASES below; each entry carries its own reason.

USAGE
    python3 tools/gen_gpio_test.py
        writes SIM/RV32IMscMCU/gpio/{ITCM.hex,DTCM.hex,listing.txt}
        and    TB/RV32IMscMCU/gpio_expected_pkg.vhd
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

# The encoder, the register names and the lui-free constant builder are reused
# rather than rewritten, so an encoder bug cannot differ between the two suites.
from gen_isa_test import enc, li32, ihex, M32                      # noqa: E402

# ───────────────────────────────────────────────────────── the MMIO map ──────
# Transcribed from Auxiliary/Benchmark Apps/GPIO/test0/asm-code/io_map.s.
PORT_LEDR = 0x2000
PORT_HEX0 = 0x2004
PORT_HEX1 = 0x2005
PORT_HEX2 = 0x2008
PORT_HEX3 = 0x2009
PORT_HEX4 = 0x200C
PORT_HEX5 = 0x200D
PORT_SW   = 0x2010
PORT_PB   = 0x2014

# Two SFR words with nothing behind them, used for the aliasing and
# no-cross-contamination cases. 0x2030 and 0x2034 are inside the SFR page
# (A12..A6 = 0) but above the twelve mapped words, so the decoder asserts no chip
# select at all -- see ADDR_DECODER.vhd.
SFR_UNMAPPED_RD = 0x2030
SFR_UNMAPPED_WR = 0x2034

# What the testbench must drive on SW_i. Arbitrary but not symmetric, so a
# reversed bit order cannot pass: 0x5C = 0101_1100.
SW_VALUE = 0x5C

# What the testbench must drive on KEY_i, and what PORT_PB must therefore read.
# KEY_i is the RAW pin, active-low: '0' means pressed. Chosen so that KEY3 and
# KEY2 are pressed and KEY1 is not, giving PORT_PB = 0b110 = 0x06 -- which is NOT
# symmetric under bit reversal, so a wrong bit order (0b011 = 0x03) cannot pass.
# The order itself is Hanan's forum answer: KEY1 -> bit 0, KEY2 -> bit 1,
# KEY3 -> bit 2.
KEY_RAW   = 0b001          # (KEY3, KEY2, KEY1) = (0, 0, 1) on the pins
KEY_VALUE = 0x06           # what PORT_PB must return

# DTCM word 0 is what PORT_LEDR (0x2000) aliased onto before Phase 5B, and it is
# where the interrupt vector table lives. The marker goes there on purpose.
ALIAS_WORD = 0
MARKER = 0xDEADBEEF

SCRATCH0 = 200          # first result word; results occupy 200, 201, ...


# ─────────────────────────────────────────── an independent GPIO model ──────
class GpioModel:
    """What the RTL is supposed to do, derived from the addresses alone.

    Written from io_map.s and Figure 5's rule -- one register per byte address,
    a register captures when its own byte address is stored to, and a read
    returns the stored byte zero-extended to 32 bits. It is NOT derived from
    RV32IMscMCU.vhd, so agreeing with the RTL means something.
    """

    WRITABLE = {PORT_LEDR, PORT_HEX0, PORT_HEX1, PORT_HEX2,
                PORT_HEX3, PORT_HEX4, PORT_HEX5}
    READABLE = WRITABLE | {PORT_SW, PORT_PB}

    def __init__(self, sw_value, pb_value):
        self.reg = {a: 0 for a in self.WRITABLE}
        self.sw = sw_value & 0xFF
        self.pb = pb_value & 0xFF          # PORT_PB is read-only (GPI)

    def store(self, addr, value):
        """Figure 5: the latch takes Data<7..0> unconditionally."""
        if addr in self.WRITABLE:
            self.reg[addr] = value & 0xFF
        # An unmapped SFR write is discarded, and must touch nothing else.
        # PORT_PB is deliberately absent from WRITABLE: it is a GPI, so a store
        # there must change nothing -- which the port_pb_readonly case checks.

    def load(self, addr):
        if addr == PORT_SW:
            return self.sw
        if addr == PORT_PB:
            return self.pb
        if addr in self.reg:
            return self.reg[addr]
        return 0                      # the bus terminator's zero


# ────────────────────────────────────────────────────────── the program ──────
# Each case is (name, [ (kind, ...) ... ]) where kind is one of:
#   ("wr",  addr, value)   store `value` to byte address `addr`
#   ("rd",  addr, why)     load from `addr` and publish the result
#   ("dwr", word, value)   store to a DTCM word (the marker)
#   ("drd", word, why)     load a DTCM word and publish the result
CASES = [
    ("alias_marker", [
        ("dwr", ALIAS_WORD, MARKER),
    ], "Plant a marker in DTCM word 0 -- the word PORT_LEDR aliased onto before "
       "Phase 5B, and where the interrupt vector table lives. Read back at the "
       "end, after every MMIO write, it must be untouched. This is the Phase 5B "
       "aliasing proof at program level rather than at mechanism level."),

    ("hex01_ascending", [
        ("wr", PORT_HEX0, 0xA5),
        ("wr", PORT_HEX1, 0x5A),
        ("rd", PORT_HEX0, "must be A5, not 5A"),
        ("rd", PORT_HEX1, "must be 5A"),
    ], "PORT_HEX0 and PORT_HEX1 share chip select CS_HEX01 and are separated only "
       "by A0. Different values, written low lane first. If PORT_HEX0 also "
       "captures the 0x2005 store -- the direction GPIO test0 CANNOT see, gap "
       "G-406 -- it ends holding 5A and the first read catches it."),

    ("hex01_descending", [
        ("wr", PORT_HEX1, 0xB7),
        ("wr", PORT_HEX0, 0x7B),
        ("rd", PORT_HEX0, "must be 7B"),
        ("rd", PORT_HEX1, "must be B7, not 7B"),
    ], "The same pair written high lane FIRST. This is what catches the other "
       "direction: a PORT_HEX1 whose lane term is missing or stuck at '1' "
       "captures the later 0x2004 store and ends holding 7B. Ascending order "
       "alone cannot see that, which is exactly why both orders are here."),

    ("hex23_both_orders", [
        ("wr", PORT_HEX2, 0xC3),
        ("wr", PORT_HEX3, 0x3C),
        ("rd", PORT_HEX2, "must be C3"),
        ("rd", PORT_HEX3, "must be 3C"),
        ("wr", PORT_HEX3, 0xD9),
        ("wr", PORT_HEX2, 0x9D),
        ("rd", PORT_HEX2, "must be 9D"),
        ("rd", PORT_HEX3, "must be D9"),
    ], "Same two orders on the second shared chip select, CS_HEX23. A wrong "
       "CS_* constant on one of these four instances would swap a pair with "
       "another word entirely, which the values make visible."),

    ("hex45_both_orders", [
        ("wr", PORT_HEX4, 0xE1),
        ("wr", PORT_HEX5, 0x1E),
        ("rd", PORT_HEX4, "must be E1"),
        ("rd", PORT_HEX5, "must be 1E"),
        ("wr", PORT_HEX5, 0xF2),
        ("wr", PORT_HEX4, 0x2F),
        ("rd", PORT_HEX4, "must be 2F"),
        ("rd", PORT_HEX5, "must be F2"),
    ], "Third shared chip select, CS_HEX45, both orders."),

    ("ledr_and_upper_bits", [
        ("wr", PORT_LEDR, 0xFF),
        ("rd", PORT_LEDR, "must be 000000FF, not FFFFFFFF"),
    ], "PORT_LEDR owns its word alone. All eight bits set, so the read also "
       "proves assumption A11: the upper 24 bits of an MMIO read come back ZERO. "
       "A sign-extending or floating read path gives FFFFFFFF or X here."),

    ("port_sw", [
        ("rd", PORT_SW, f"must be {SW_VALUE:08X}"),
    ], f"PORT_SW is the one input port. The testbench drives SW_i = 0x{SW_VALUE:02X} "
       "= 0101_1100, which is not symmetric, so a reversed bit order cannot pass. "
       "This also proves the two-stage synchroniser passes the value intact."),

    ("unmapped_read", [
        ("rd", SFR_UNMAPPED_RD, "must be 0"),
    ], "0x2030 is inside the SFR page but above the twelve mapped words, so no "
       "chip select is asserted and no tri-state drives the bus. Only the "
       "terminator answers. If it reads anything but zero the terminator's enable "
       "is wrong -- and if the bus were left floating this would be Z, which "
       "arrives as X in the register file."),

    ("unmapped_write_then_reread", [
        ("wr", SFR_UNMAPPED_WR, 0xAA),
        ("rd", PORT_LEDR, "must still be 000000FF"),
    ], "A write to an unmapped SFR word must be discarded and must not disturb "
       "any implemented port. PORT_LEDR still holds FF from the earlier case."),

    ("port_pb", [
        ("rd", PORT_PB, f"must be {KEY_VALUE:08X}"),
    ], "PORT_PB at 0x2014 reads KEY3-KEY1. The testbench drives the raw pins with "
       "KEY3 and KEY2 pressed and KEY1 released; with active-low buttons that must "
       "read 0b110 = 0x06. The value is NOT symmetric under bit reversal, so a "
       "wrong bit order gives 0x03 and fails. The order -- KEY1 to bit 0, KEY2 to "
       "bit 1, KEY3 to bit 2 -- is Hanan's forum answer; the polarity is "
       "assumption A16."),

    ("port_pb_readonly", [
        ("wr", PORT_PB, 0x00),
        ("rd", PORT_PB, f"must STILL be {KEY_VALUE:08X}"),
    ], "PORT_PB is a GPI. A store to it must be discarded and must not disturb the "
       "value it presents. Writing 0x00 and reading 0x06 back proves the write "
       "path does not reach it."),

    ("alias_marker_check", [
        ("drd", ALIAS_WORD, f"must still be {MARKER:08X}"),
    ], "The Phase 5B property, at program level: after fourteen MMIO stores, DTCM "
       "word 0 still holds the marker. Without the region decode, the store to "
       "PORT_LEDR would have landed here."),
]


def build():
    """Assemble the program, and derive the expected store sequence by running it."""
    prog = []                 # list of (mnemonic, args...)
    seq = []                  # list of (idx, byte_addr, value, name, note)
    listing = []
    model = GpioModel(SW_VALUE, KEY_VALUE)
    dtcm = {}
    slot = SCRATCH0

    def emit(*ins):
        prog.append(ins)

    for name, steps, why in CASES:
        listing.append((name, why))
        for step in steps:
            kind = step[0]

            if kind == "wr":
                addr, val = step[1], step[2]
                for ins in li32("t0", val):
                    emit(*ins)
                for ins in li32("t1", addr):
                    emit(*ins)
                emit("sw", "t0", 0, "t1")
                model.store(addr, val)
                seq.append((len(seq), addr, val & M32, f"{name}:wr", "mmio store"))

            elif kind == "rd":
                addr, why2 = step[1], step[2]
                for ins in li32("t1", addr):
                    emit(*ins)
                emit("lw", "t2", 0, "t1")
                emit("sw", "t2", slot * 4, "zero")
                got = model.load(addr)
                seq.append((len(seq), slot * 4, got & M32, f"{name}:rd", why2))
                slot += 1

            elif kind == "dwr":
                word, val = step[1], step[2]
                for ins in li32("t0", val):
                    emit(*ins)
                emit("sw", "t0", word * 4, "zero")
                dtcm[word] = val & M32
                seq.append((len(seq), word * 4, val & M32, f"{name}:dwr", "dtcm store"))

            elif kind == "drd":
                word, why2 = step[1], step[2]
                # Every load in this program must use offset 0, so that it behaves
                # identically at G_ISA_REPAIR = FALSE (defect 3 zeroes a load's
                # offset). Word 0 is the only DTCM word read back here, and
                # offset 0 on a zero base is exactly what addresses it.
                if word != 0:
                    raise AssertionError(
                        "a DTCM read-back above word 0 would need a non-zero load "
                        "offset, which breaks at G_ISA_REPAIR = FALSE")
                emit("lw", "t2", 0, "zero")
                emit("sw", "t2", slot * 4, "zero")
                seq.append((len(seq), slot * 4, dtcm.get(word, 0) & M32,
                            f"{name}:drd", why2))
                slot += 1

            else:
                raise AssertionError(f"unknown step kind {kind}")

    # The auto-stop sentinel the whole project already uses: beq x0,x0,0.
    emit("beq", "zero", "zero", 0)
    words = [enc(*ins) for ins in prog]
    return prog, words, seq, listing


# ─────────────────────────────────────── an independent second derivation ────
def interpret(words, sw_value, pb_value):
    """Run the program on a plain RV32I interpreter with the GPIO model attached.

    This is the cross-check: build() derives the expected sequence while
    EMITTING the code, this derives it by EXECUTING the code. If the two
    disagree, generation aborts. Same discipline as gen_isa_test.py's
    reference_run / defect_run pair, and it is what caught two real bugs there.
    """
    reg = [0] * 32
    mem = {}
    model = GpioModel(sw_value, pb_value)
    stores = []
    pc = 0
    steps = 0
    while steps < 200000:
        steps += 1
        if pc // 4 >= len(words):
            break
        w = words[pc // 4]
        op = w & 0x7F
        rd = (w >> 7) & 31
        f3 = (w >> 12) & 7
        rs1 = (w >> 15) & 31
        rs2 = (w >> 20) & 31

        if op == 0x13:                                    # addi / slli / srli
            imm = w >> 20
            imm -= 0x1000 if imm & 0x800 else 0
            if f3 == 0:
                reg[rd] = (reg[rs1] + imm) & M32
            elif f3 == 1:
                reg[rd] = (reg[rs1] << ((w >> 20) & 31)) & M32
            elif f3 == 5:
                reg[rd] = (reg[rs1] % (1 << 32)) >> ((w >> 20) & 31)
            else:
                raise AssertionError(f"unexpected I-type f3={f3}")
        elif op == 0x23:                                  # stores
            imm = ((w >> 25) << 5) | ((w >> 7) & 31)
            imm -= 0x1000 if imm & 0x800 else 0
            addr = (reg[rs1] + imm) & M32
            val = reg[rs2] & M32
            assert f3 == 2, "this program uses only sw"
            stores.append((addr, val))
            if addr >= 0x2000:
                model.store(addr, val)
            else:
                mem[addr // 4] = val
        elif op == 0x03:                                  # loads
            imm = w >> 20
            imm -= 0x1000 if imm & 0x800 else 0
            assert imm == 0 or reg[rs1] == 0, \
                "a non-zero load offset on a non-zero base breaks at repair=FALSE"
            addr = (reg[rs1] + imm) & M32
            assert f3 == 2, "this program uses only lw"
            reg[rd] = model.load(addr) if addr >= 0x2000 else mem.get(addr // 4, 0)
        elif op == 0x63:                                  # the sentinel
            break
        else:
            raise AssertionError(f"unexpected opcode 0x{op:02x} at pc {pc}")
        reg[0] = 0
        pc += 4
    return stores


def main():
    prog, words, seq, listing = build()

    # ---- the cross-check ----
    executed = interpret(words, SW_VALUE, KEY_VALUE)
    emitted = [(a, v) for _, a, v, _, _ in seq]
    if executed != emitted:
        print("CROSS-CHECK FAILED: the emitted and executed store sequences differ.",
              file=sys.stderr)
        for i in range(max(len(executed), len(emitted))):
            e = executed[i] if i < len(executed) else None
            m = emitted[i] if i < len(emitted) else None
            if e != m:
                print(f"  store {i}: executed {e}, emitted {m}", file=sys.stderr)
        sys.exit(1)

    name_len = max(len(n) for _, _, _, n, _ in seq)
    rows = []
    for idx, addr, val, nm, note in seq:
        comma = "" if idx == len(seq) - 1 else ","
        rows.append(f'\t\t(16#{addr:04X}#, x"{val:08X}", "{nm:<{name_len}}"){comma}'
                    f'\t-- {idx:2d} {note}')

    pkg = f'''--============================================================================
-- gpio_expected_pkg — GENERATED by tools/gen_gpio_test.py. Do not edit by hand.
--
-- The complete expected store sequence of the directed GPIO test, in bus order.
-- It closes gaps G-406 and G-407, which Phases 6A and 6B each registered against
-- their own verification:
--   G-406  tb_gpio's cross-talk check is one-sided, because GPIO test0 writes the
--          same value to all seven ports in ascending address order.
--   G-407  the seven GPO read-back tri-states of Figure 5 are exercised by no
--          supplied benchmark.
-- They close each other: read-back makes a port's content observable, and that
-- makes the lane decode discriminable in BOTH directions.
--
-- ADDRESSES HERE ARE FULL 14-BIT BYTE ADDRESSES, not DTCM word indices. That
-- matters: an MMIO store to 0x2004 and a DTCM store to word 1 produce the same
-- dtcm_addr_o, so the testbench compares alu_res_o instead.
--
-- EVERY ENTRY MUST MATCH, in both G_ISA_REPAIR configurations. The program uses
-- only addi, slli, sw, lw at offset zero, and one beq sentinel, so it touches
-- none of the seven ISA defects -- see the header of tools/gen_gpio_test.py for
-- the defect-by-defect check. There is no expected-failure count here.
--
-- Derived twice and cross-checked before this file was written: once while
-- emitting the code, once by executing it on an interpreter with an independent
-- model of the GPIO block. Generation aborts if the two disagree.
--============================================================================
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

package gpio_expected_pkg is

\tconstant NAME_LEN : natural := {name_len};

\ttype expected_t is record
\t\taddr\t: natural;\t\t\t\t\t\t-- full byte address on the data bus
\t\tdata\t: STD_LOGIC_VECTOR(31 DOWNTO 0);
\t\tname\t: string(1 to NAME_LEN);
\tend record;

\ttype expected_array_t is array (natural range <>) of expected_t;

\tconstant STORE_COUNT : natural := {len(seq)};

\t-- What the testbench must drive on SW_i for the port_sw case to pass.
\t-- 0x{SW_VALUE:02X} is deliberately not bit-symmetric.
\tconstant SW_VALUE : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"{SW_VALUE:02X}";

\t-- What the testbench must drive on KEY_i -- the RAW, active-low pins, indexed
\t-- 3 DOWNTO 1. (KEY3, KEY2, KEY1) = ({KEY_RAW:03b}), i.e. KEY3 and KEY2 pressed,
\t-- KEY1 released, so PORT_PB must read 0x{KEY_VALUE:02X}.
\tconstant KEY_VALUE : STD_LOGIC_VECTOR(3 DOWNTO 1) := "{KEY_RAW:03b}";

\tconstant EXPECTED : expected_array_t(0 to STORE_COUNT-1) := (
{chr(10).join(rows)}
\t);

end package gpio_expected_pkg;
'''

    L = ["Directed GPIO test — generated listing",
         "GENERATED by tools/gen_gpio_test.py. Do not edit by hand.",
         "",
         f"{len(words)} instructions, {len(seq)} stores, SW_i = 0x{SW_VALUE:02X}, "
         f"KEY_i = {KEY_RAW:03b} -> PORT_PB = 0x{KEY_VALUE:02X}",
         "",
         "Runs at either G_ISA_REPAIR setting: the program uses only addi, slli,",
         "sw and lw-at-offset-zero, so it touches none of the seven ISA defects.",
         "", "=" * 74, ""]
    for nm, why in listing:
        L.append(f"{nm}")
        L.append("    " + why.replace(". ", ".\n    "))
        L.append("")
    L.append("=" * 74)
    L.append("")
    L.append("Expected store sequence (byte address, value):")
    for idx, addr, val, nm, note in seq:
        L.append(f"  {idx:2d}  0x{addr:04X}  0x{val:08X}  {nm:<{name_len}}  {note}")

    out = ROOT / "SIM" / "RV32IMscMCU" / "gpio"
    out.mkdir(parents=True, exist_ok=True)
    (out / "ITCM.hex").write_text(ihex(words))
    (out / "DTCM.hex").write_text(ihex([0] * 1024))
    (out / "listing.txt").write_text("\n".join(L) + "\n")
    (ROOT / "TB" / "RV32IMscMCU" / "gpio_expected_pkg.vhd").write_text(pkg)

    print(f"instructions : {len(words)}")
    print(f"stores       : {len(seq)}")
    print(f"cross-check  : emitted and executed sequences agree on all {len(seq)}")
    print(f"SW_i         : 0x{SW_VALUE:02X}")
    print(f"KEY_i        : {KEY_RAW:03b} (raw pins) -> PORT_PB = 0x{KEY_VALUE:02X}")
    print(f"wrote        : {out}/ITCM.hex, DTCM.hex, listing.txt")
    print(f"               TB/RV32IMscMCU/gpio_expected_pkg.vhd")


if __name__ == "__main__":
    main()
