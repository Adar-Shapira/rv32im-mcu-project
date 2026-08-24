#!/usr/bin/env python3
"""Bit-exact model of DUT/RV32IMscMCU/DIV_UNIT.vhd's arithmetic, exhaustively checked.

WHY
    Same reason as tools/model_div_accel.py: the toolchain is Windows-only, so
    this RTL cannot be compiled where it was written.  What is checked here is
    the part that is easy to get subtly wrong and that no waveform makes obvious
    -- the SIGNED div/rem wrapper, including the two cases the RISC-V spec calls
    out specially.

WHAT IS **NOT** CHECKED HERE
    The clock-domain crossings and the handshake FSM.  Those are structural and
    their correctness is a timing argument, not an arithmetic one; they are what
    tb_div_unit.vhd exercises with two genuinely different clocks.  This file is
    only the algebra -- but the algebra is where -2^31/-1 and divide-by-zero live.

THE REFERENCE IS DELIBERATELY NOT THE SAME ALGORITHM
    A reference that also divided magnitudes and re-applied signs would agree
    with the DUT precisely when both were wrong.  So the expected quotient comes
    from fractions.Fraction, whose int() truncates toward zero exactly as RISC-V
    requires, with no floating point and no magnitude step; the remainder is then
    a - q*b, straight from the definition.
"""

import sys
from fractions import Fraction

sys.path.insert(0, "tools")
from model_div_accel import DivAccel, run_one


def sext(bits, n):
    """Interpret an n-bit pattern as a signed integer."""
    return bits - (1 << n) if (bits >> (n - 1)) & 1 else bits


def dut(a_bits, b_bits, is_signed, n):
    """One-for-one with DIV_UNIT.vhd: magnitudes, the engine, sign correction,
    and the zero-divisor rule that overrides it."""
    mask = (1 << n) - 1

    aneg = is_signed and bool((a_bits >> (n - 1)) & 1)      # aneg_w
    bneg = is_signed and bool((b_bits >> (n - 1)) & 1)      # bneg_w
    aabs = (-a_bits) & mask if aneg else a_bits             # aabs_w
    babs = (-b_bits) & mask if bneg else b_bits             # babs_w
    qneg = aneg ^ bneg                                       # qneg_q
    rneg = aneg                                              # rneg_q
    bzero = (b_bits == 0)                                    # bzero_q

    engine = DivAccel(n)
    q_raw, r_raw = run_one(engine, aabs, babs)[:2]           # qraw_q, rraw_q

    if bzero:                                                # the override
        return mask, a_bits
    q = (-q_raw) & mask if qneg else q_raw
    r = (-r_raw) & mask if rneg else r_raw
    return q, r


def reference(a_bits, b_bits, is_signed, n):
    """What RISC-V requires, derived from the definition rather than from an
    algorithm that resembles the DUT's."""
    mask = (1 << n) - 1
    if b_bits == 0:
        # "The quotient of division by zero has all bits set"; the remainder is
        # the dividend.  True for div/divu and rem/remu alike.
        return mask, a_bits
    a = sext(a_bits, n) if is_signed else a_bits
    b = sext(b_bits, n) if is_signed else b_bits
    q = int(Fraction(a, b))          # truncation toward zero, exact
    r = a - q * b
    return q & mask, r & mask


def main():
    fails = []
    checked = 0

    # ---- exhaustive at N = 8, signed AND unsigned, every pair --------------
    n = 8
    for is_signed in (True, False):
        bad = 0
        for a in range(1 << n):
            for b in range(1 << n):
                gq, gr = dut(a, b, is_signed, n)
                eq, er = reference(a, b, is_signed, n)
                checked += 1
                if (gq, gr) != (eq, er):
                    bad += 1
                    if len(fails) < 20:
                        fails.append(
                            f"N=8 {'signed' if is_signed else 'unsigned'} "
                            f"{sext(a,n) if is_signed else a}/"
                            f"{sext(b,n) if is_signed else b}: "
                            f"got q=0x{gq:02X} r=0x{gr:02X}, "
                            f"want q=0x{eq:02X} r=0x{er:02X}")
        print(f"N=8 {'signed  ' if is_signed else 'unsigned'} exhaustive: "
              f"{1 << (2*n)} pairs, {bad} failure(s)")

    # ---- N = 32: the corners the spec calls out ----------------------------
    n = 32
    M = (1 << n) - 1
    corners = [
        # (dividend, divisor, signed, why)
        (0x80000000, 0xFFFFFFFF, True,  "-2^31 / -1  -- the overflow case"),
        (0x80000000, 0x00000001, True,  "-2^31 / 1"),
        (0x80000000, 0x00000002, True,  "-2^31 / 2"),
        (0xFFFFFFFF, 0x00000002, True,  "-1 / 2      -- truncation toward zero"),
        (0x00000007, 0xFFFFFFFE, True,  "7 / -2      -- truncation toward zero"),
        (0xFFFFFFF9, 0x00000002, True,  "-7 / 2      -- remainder takes the dividend's sign"),
        (0xFFFFFFF9, 0xFFFFFFFE, True,  "-7 / -2"),
        (0x00000000, 0x00000000, True,  "0 / 0"),
        (0x00000001, 0x00000000, True,  "1 / 0"),
        (0xFFFFFFFF, 0x00000000, True,  "-1 / 0      -- THE case the naive wrapper gets wrong"),
        (0x80000000, 0x00000000, True,  "-2^31 / 0   -- likewise"),
        (0xDEADBEEF, 0x00000000, True,  "negative / 0"),
        (0xFFFFFFFF, 0xFFFFFFFF, False, "unsigned max / max"),
        (0xFFFFFFFF, 0x80000000, False, "unsigned, divisor >= 2^31"),
        (0xFFFFFFFF, 0x00000000, False, "unsigned / 0"),
        (0x7FFFFFFF, 0xFFFFFFFF, True,  "2^31-1 / -1"),
    ]
    bad = 0
    for a, b, sg, why in corners:
        gq, gr = dut(a, b, sg, n)
        eq, er = reference(a, b, sg, n)
        checked += 1
        if (gq, gr) != (eq, er):
            bad += 1
            fails.append(f"N=32 {why}: 0x{a:08X}/0x{b:08X} "
                         f"got q=0x{gq:08X} r=0x{gr:08X}, "
                         f"want q=0x{eq:08X} r=0x{er:08X}")
    print(f"N=32 directed corners  : {len(corners)} cases, {bad} failure(s)")

    # ---- N = 32 pseudo-random, both signednesses ---------------------------
    lf = 0x2468ACE1

    def step(s):
        fb = ((s >> 31) ^ (s >> 21) ^ (s >> 1) ^ s) & 1
        return ((s << 1) | fb) & M

    bad = 0
    OPS = 400
    for i in range(1, OPS + 1):
        lf = step(lf); a = lf
        lf = step(lf); b = lf
        if i % 8 == 0:
            b &= 0xFF
        elif i % 16 == 3:
            b |= 0x80000000
        sg = (i % 2 == 0)
        gq, gr = dut(a, b, sg, n)
        eq, er = reference(a, b, sg, n)
        checked += 1
        if (gq, gr) != (eq, er):
            bad += 1
            if len(fails) < 20:
                fails.append(f"N=32 random #{i} 0x{a:08X}/0x{b:08X} signed={sg}: "
                             f"got q=0x{gq:08X} r=0x{gr:08X}, "
                             f"want q=0x{eq:08X} r=0x{er:08X}")
    print(f"N=32 random            : {OPS} cases, {bad} failure(s)")

    print()
    print(f"total checked: {checked}")
    if fails:
        print(f"FAIL -- {len(fails)} failure(s) shown:")
        for x in fails[:20]:
            print("   " + x)
        return 1
    print("PASS -- signed and unsigned div/rem match the RISC-V definition, "
          "including -2^31/-1 and every divide-by-zero.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
