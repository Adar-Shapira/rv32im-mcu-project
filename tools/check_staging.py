#!/usr/bin/env python3
"""Assert every memory image a ModelSim script stages is the right file.

Phase 13 asks for two things this checks mechanically:

  * "Assert that ITCM.h is never loaded as an ITCM source - the two formats are
    different programs, .hex at text base 0 and .h retaining RARS's 0x3000."
    A run that loads the wrong one does not fail loudly; it runs a different
    program and produces plausible, wrong numbers.

  * That the flow has no broken paths. Every `file copy -force <src>` source
    that lives in the repo must exist. This is not hypothetical: DOC/04's
    staging table pointed at `Auxilary/testN/...` for weeks after Adar's
    Auxiliary restructure moved it to `Auxilary/Benchmarks/testN/...`.

Run from the repo root:  python3 tools/check_staging.py
Exit status 0 = clean, 1 = findings (so it can gate a commit or a CI step).

It reads only .do scripts; it never runs a simulator, so it works on the Mac.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SIM = ROOT / "SIM"

# `file copy -force <src> <dst>`, src either bare or {braced} (Tcl quoting for
# paths with spaces, which "Benchmark Apps" has).
COPY = re.compile(
    r"file\s+copy\s+-force\s+(?:\{(?P<b>[^}]+)\}|(?P<p>\S+))\s+(?:\{(?P<db>[^}]+)\}|(?P<dp>\S+))"
)

# A staged ITCM/DTCM source must be one of these. Anything else is a finding,
# so a new bad habit shows up here rather than in a wrong result.
GOOD_SUFFIX = ".hex"
BAD_MARKERS = ("Hexadecimal-Text", ".h")


def sources(text):
    for m in COPY.finditer(text):
        src = m.group("b") or m.group("p")
        dst = m.group("db") or m.group("dp")
        yield src, dst


# ---------------------------------------------------------------------------
# The MODELSIM switch, added 2026-08-27 after the same class of defect appeared
# a fourth time. G_MODELSIM ships at 0 -- the Quartus value, which
# tools/check_config_defaults.py asserts and which must NOT be edited to run a
# simulation. A testbench that instantiates an MCU top therefore has to be given
# -gMODELSIM=1 on the vsim line, or CLOCK_TREE takes its CLK_FPGA branch and
# elaborates two real altpll megafunctions fed by the bench's 100 ns clock:
# mclk stops being clk_i, every cycle-counted bound is measured against the
# wrong clock, and with GEN_RESET_ON_LOCK the core waits on a PLL lock.
#
# It was missing from run_uart_mmio.do and run_uart_menu.do in BOTH trees --
# four scripts written across Phases 12B/12C/12D, none of them run yet, all
# four wrong in the same way. Every other whole-MCU script in the project had
# it, which is exactly why nobody noticed: the habit was right 14 times out of
# 18. This check makes the 15th impossible.
VSIM = re.compile(r"^\s*vsim\b(?P<args>[^\n]*)$", re.M)
TOP = re.compile(r"work\.(?P<top>\w+)")

# Testbench entity -> does it instantiate a whole MCU top? Derived from the TB
# sources at check time rather than listed here, so a new testbench is covered
# the day it is written.
MCU_ENTITY = re.compile(r"^\s*\w+\s*:\s*(RV32IMscMCU|RV32IMpipelinedMCU)\b",
                        re.M | re.I)


def tops_needing_modelsim():
    """Lower-case entity names of every testbench that instantiates an MCU top."""
    out = set()
    for tb in sorted((ROOT / "TB").rglob("*.vhd")):
        text = tb.read_text(errors="replace")
        if not MCU_ENTITY.search(text):
            continue
        for m in re.finditer(r"^\s*ENTITY\s+(\w+)\s+IS", text, re.M | re.I):
            out.add(m.group(1).lower())
    return out


def check_modelsim_switch(scripts, findings):
    need = tops_needing_modelsim()
    if not need:
        findings.append("no testbench instantiates an MCU top -- the MODELSIM "
                        "check found nothing to check, which is itself wrong")
        return 0
    n = 0
    for s in scripts:
        rel = s.relative_to(ROOT)
        for m in VSIM.finditer(s.read_text(errors="replace")):
            args = m.group("args")
            t = TOP.search(args)
            if not t or t.group("top").lower() not in need:
                continue
            n += 1
            # -gMODELSIM=0 is a deliberate, explicit choice and is left alone;
            # only a MISSING switch is the defect, because that is the one that
            # looks like every other line in the file.
            if "-gMODELSIM=" not in args:
                findings.append(
                    f"{rel}: `vsim{args}` elaborates {t.group('top')}, which "
                    f"instantiates an MCU top, WITHOUT -gMODELSIM=1 -- it will "
                    f"build the real altpll instead of the behavioural clocks")
    return n


# ---------------------------------------------------------------------------
# The clause 8 menu image now exists in THREE places, and nothing but this
# check keeps them equal:
#
#   SIM/RV32IMscMCU/menu/       what run_uart_menu.do simulates (the board build)
#   UART/                       the deliverable, loaded onto the board via ISMCE
#   209580208_211468582/UART/   the same, staged into the submission ZIP
#
# The report says "the program tested in simulation is the same program that
# runs on the board" and prints a character count taken from the DTCM text. If
# one copy is regenerated and another is not, that sentence quietly stops being
# true and the failure is invisible: every copy is a valid image, so nothing
# refuses to load and nothing reports an error -- the board simply runs a
# different program from the one the testbench scored. Same class as the .h/.hex
# confusion above, which is why it lives in the same tool.
#
# menusim/ is the SECOND data image of the SAME program: its ITCM must match
# byte for byte, and its DTCM must NOT (it carries the shortened BTCMPR0). Both
# directions are asserted -- an identical DTCM would mean the simulation build
# was never regenerated after the constant changed.
MENU_SRC = "SIM/RV32IMscMCU/menu"
MENU_COPIES = ("UART", "209580208_211468582/Benchmark Apps/UART/bin")
MENU_SIM = "SIM/RV32IMscMCU/menusim"


def _digest(path):
    import hashlib
    return hashlib.md5(path.read_bytes()).hexdigest()


def check_menu_images(findings):
    src = ROOT / MENU_SRC
    if not src.is_dir():
        return 0
    n = 0
    for name in ("ITCM.hex", "DTCM.hex"):
        ref = src / name
        if not ref.is_file():
            findings.append(f"{MENU_SRC}/{name}: MISSING -- it is the source "
                            f"the submitted menu images are copies of")
            continue
        want = _digest(ref)
        for rel in MENU_COPIES:
            other = ROOT / rel / name
            n += 1
            if not other.is_file():
                findings.append(f"{rel}/{name}: MISSING -- the clause 8 menu "
                                f"image is a submission deliverable")
            elif _digest(other) != want:
                findings.append(
                    f"{rel}/{name} DIFFERS from {MENU_SRC}/{name} -- the image "
                    f"on the board is not the one the testbench scored")

    sim = ROOT / MENU_SIM
    if sim.is_dir():
        for name, must_match in (("ITCM.hex", True), ("DTCM.hex", False)):
            a, b = src / name, sim / name
            if not (a.is_file() and b.is_file()):
                continue
            n += 1
            same = _digest(a) == _digest(b)
            if must_match and not same:
                findings.append(
                    f"{MENU_SIM}/{name} differs from {MENU_SRC}/{name} -- the "
                    f"two builds must be ONE program, only the data differs")
            if not must_match and same:
                findings.append(
                    f"{MENU_SIM}/{name} is IDENTICAL to {MENU_SRC}/{name} -- "
                    f"the simulation build should carry the shortened "
                    f"BTCMPR0, so it was probably not regenerated")
    return n


def main():
    findings = []
    checked = 0
    scripts = sorted(SIM.rglob("*.do"))
    if not scripts:
        sys.exit("no .do scripts found - run this from the repo root")

    n_vsim = check_modelsim_switch(scripts, findings)
    n_menu = check_menu_images(findings)

    for s in scripts:
        rel = s.relative_to(ROOT)
        for src, dst in sources(s.read_text()):
            # Destinations under the hardcoded init_file path are the ones that
            # decide which program runs; that is what this tool is about.
            if "app_bin" not in dst:
                continue
            checked += 1

            if not src.endswith(GOOD_SUFFIX):
                findings.append(
                    f"{rel}: stages '{src}' into {dst} -- an ITCM/DTCM source "
                    f"must be a .hex M9K-intel image"
                )
                continue
            if any(bad in src for bad in ("Hexadecimal-Text",)):
                findings.append(
                    f"{rel}: stages '{src}' -- Hexadecimal-Text images are a "
                    f"DIFFERENT program (RARS 0x3000 base), never loadable"
                )
                continue

            # Sources that are repo-relative (not the C:\ staging tree, which
            # only exists on the Windows machine) must actually be there.
            if src.startswith("C:/") or src.startswith("C:\\") or "$" in src:
                continue
            p = (s.parent / src).resolve()
            if not p.is_file():
                findings.append(f"{rel}: stages '{src}' -- FILE DOES NOT EXIST")

    print(f"checked {checked} app_bin staging copies across {len(scripts)} .do scripts")
    print(f"checked {n_vsim} whole-MCU vsim line(s) for -gMODELSIM")
    print(f"checked {n_menu} clause 8 menu image copy/copies for drift")
    if findings:
        print(f"\n{len(findings)} FINDING(S):")
        for f in findings:
            print(f"  - {f}")
        return 1
    print("clean: every staged image is an existing .hex M9K-intel/generated "
          "file, every whole-MCU vsim line sets MODELSIM explicitly, and the "
          "submitted menu images match the ones the testbench scored")
    return 0


if __name__ == "__main__":
    sys.exit(main())
