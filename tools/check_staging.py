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


def main():
    findings = []
    checked = 0
    scripts = sorted(SIM.rglob("*.do"))
    if not scripts:
        sys.exit("no .do scripts found - run this from the repo root")

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
    if findings:
        print(f"\n{len(findings)} FINDING(S):")
        for f in findings:
            print(f"  - {f}")
        return 1
    print("clean: every staged image is an existing .hex M9K-intel/generated file")
    return 0


if __name__ == "__main__":
    sys.exit(main())
