#!/usr/bin/env python3
"""Assert the committed compile-time switches are at their SHIPPING values.

WHY THIS EXISTS
    Some of this project's configuration lives in constants that get flipped by
    hand to take a measurement and flipped back afterwards. `G_MODELSIM` is the
    original: 1 for ModelSim, 0 for Quartus, and the supplied
    cond_compilation_package.vhd says "set to 0 before Quartus synthesis" in a
    comment because nothing enforces it. Phase 14 adds a second and worse one:
    `G_GEN_INTERRUPT` must be False to compile row 1 of clause 6's PPA tables
    and True for every other purpose in the project.

    A tree committed with either one flipped is a quiet disaster. It compiles,
    it simulates, and it is the wrong design -- and the failure surfaces
    somewhere unrelated: a benchmark that used to interrupt just runs straight
    through, or a ModelSim run reads an FPGA-shaped memory. This project has
    already been bitten three times by two lists with one edited; a flipped
    switch is the same shape with one list.

WHAT IT CHECKS
    Per tree, that each switch below reads its shipping value. The point is
    that this runs in the regression, so a flip that was meant to be temporary
    cannot survive to a commit unnoticed.

SELF-TEST
    Run with --self-test: it flips each switch in a temporary copy and asserts
    the check catches it, so a checker that has quietly stopped parsing
    anything cannot pass.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# constant name -> (shipping value, why it matters if it is wrong)
SWITCHES = {
    "G_MODELSIM": ("0",
                   "1 makes the DTCM/ITCM ModelSim-shaped and disables the "
                   "PLLs; the supplied package's own comment says to set it to "
                   "0 before Quartus synthesis"),
    "G_GEN_INTERRUPT": ("True",
                        "False is PPA table row 1 only -- the build with no "
                        "interrupt controller, no Basic Timer, no USART and no "
                        "PORT_PB. Committing it would ship an MCU that cannot "
                        "interrupt"),
}

PACKAGES = [
    "DUT/RV32IMscMCU/cond_compilation_package.vhd",
    "DUT/RV32IMpipelinedMCU/cond_compilation_package.vhd",
]


def value_of(text, name):
    """The constant's value as written, or None if the constant is absent."""
    m = re.search(rf"^\s*constant\s+{name}\s*:[^:=]*:=\s*([^;]+);",
                  text, re.M | re.I)
    return m.group(1).strip() if m else None


def check(paths):
    findings = []
    seen = 0
    for rel in paths:
        p = ROOT / rel
        if not p.is_file():
            findings.append(f"{rel}: no such package")
            continue
        text = p.read_text(errors="replace")
        for name, (want, why) in SWITCHES.items():
            got = value_of(text, name)
            if got is None:
                continue                      # not every tree defines every one
            seen += 1
            if got.lower() != want.lower():
                findings.append(
                    f"{rel}: {name} = {got}, must be {want} in a committed "
                    f"tree.\n      {why}")
    return findings, seen


def self_test():
    import tempfile
    with tempfile.TemporaryDirectory() as td:
        d = pathlib.Path(td)
        src = (ROOT / PACKAGES[0]).read_text()
        for name, (want, _) in SWITCHES.items():
            if value_of(src, name) is None:
                continue
            flipped = re.sub(
                rf"(^\s*constant\s+{name}\s*:[^:=]*:=\s*)[^;]+;",
                r"\g<1>0xDEAD;", src, count=1, flags=re.M | re.I)
            assert flipped != src, f"self-test: could not flip {name}"
            f = d / "pkg.vhd"
            f.write_text(flipped)
            rel = f.relative_to(ROOT) if f.is_relative_to(ROOT) else None
            # check() works on repo-relative paths, so test value_of directly
            assert value_of(flipped, name).lower() != want.lower(), \
                f"self-test: a flipped {name} was not seen as flipped"
        # and the real tree must read clean
        findings, seen = check(PACKAGES)
        assert not findings, f"self-test: the committed tree is not clean: {findings}"
        assert seen >= 2, f"self-test: only {seen} switch(es) found -- the " \
                          f"regex has stopped matching"
    print("self-test: a flipped switch is detected, and the committed tree is "
          "clean")
    return 0


def main():
    if "--self-test" in sys.argv:
        return self_test()
    findings, seen = check(PACKAGES)
    print(f"checked {seen} compile-time switch value(s) across "
          f"{len(PACKAGES)} package(s)")
    if findings:
        print(f"\n{len(findings)} FINDING(S):")
        for f in findings:
            print(f"  - {f}")
        return 1
    print("clean: every compile-time switch is at its shipping value")
    return 0


if __name__ == "__main__":
    sys.exit(main())
