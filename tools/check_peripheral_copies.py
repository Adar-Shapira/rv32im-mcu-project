#!/usr/bin/env python3
"""Assert the peripheral files duplicated between the two MCU trees stay identical.

WHY THIS EXISTS
    Clause 10 Table 1 requires DUT/RV32IMscMCU and DUT/RV32IMpipelinedMCU to
    each contain their design VHDL files, so the peripherals genuinely exist
    TWICE -- there is no shared folder to point both at. As of Adar's beee0a7
    all eleven duplicated files are byte-identical, which is what makes every
    single-cycle verification result (tb_basic_timer, tb_interrupt_ctrl,
    tb_div_unit, tb_addr_decoder, run_uart ...) transfer to the pipeline
    unchanged.

    That is worth protecting mechanically, because the failure mode is silent
    and this project has already been bitten by exactly its shape: 5d540c0
    found the pipeline's .qsf listing a file Phase 3D had deleted, because
    compile.do had been corrected and the .qsf had not. Two lists, one edited.
    Here it would be two copies of BASIC_TIMER.vhd, one fixed -- ModelSim
    would pass on whichever tree the fix landed in and fail on the other, or
    worse, both would pass and the boards would differ.

WHAT IT DOES
    Compares every .vhd present in BOTH trees. A file that exists in only one
    tree is fine and expected (the cores differ); a file present in both and
    DIFFERENT is an error, unless it is listed in ALLOWED_TO_DIFFER below with
    a reason.

    Exits non-zero on any unexplained difference, so it can join the
    regression the way check_quartus_filelists.py and check_staging.py do.

SELF-TEST
    Run with --self-test: it fabricates a one-line difference in a temporary
    copy of the pair and asserts that the comparison catches it, so a checker
    that has quietly stopped comparing anything cannot pass.
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SC = ROOT / "DUT" / "RV32IMscMCU"
PIPE = ROOT / "DUT" / "RV32IMpipelinedMCU"

# Files that legitimately differ between the trees, each with its reason.
# A file may only be here if the difference is a DESIGN decision, not drift.
ALLOWED_TO_DIFFER = {
    # the cores and their own support are different designs, not copies
    "CONTROL.vhd":                     "the pipeline's decoder is a rewrite, not a derivative",
    "DMEMORY.vhd":                     "pipelined memory stage",
    "EXECUTE.vhd":                     "pipelined execute stage",
    "IDECODE.vhd":                     "pipelined decode stage",
    "IFETCH.vhd":                      "pipelined fetch stage",
    "aux_package.vhd":                 "each tree declares its own components",
    "const_package.vhd":               "each tree's own constants",
    "cond_compilation_package.vhd":    "each tree's own switches",
    "PLL.vhd":                         "wizard output, may differ per project",
}


def compare(sc_dir, pipe_dir):
    """Returns (identical, differing, only_sc, only_pipe) as sorted name lists."""
    sc = {p.name for p in sc_dir.glob("*.vhd")}
    pp = {p.name for p in pipe_dir.glob("*.vhd")}
    identical, differing = [], []
    for name in sorted(sc & pp):
        a = (sc_dir / name).read_bytes()
        b = (pipe_dir / name).read_bytes()
        (identical if a == b else differing).append(name)
    return identical, differing, sorted(sc - pp), sorted(pp - sc)


# ---------------------------------------------------------------------------
# GENERATED EXPECTATION PACKAGES, added 2026-08-27 with Phase 11B.
#
# Clause 10 Table 1 also gives each MCU its own TB folder, so a generated
# expectation package exists twice for the same reason a peripheral does. These
# two are not "allowed to differ, probably fine" -- they are DATA, produced by
# one generator run from one table, and the ONLY reason the pipeline's suite
# means anything is that it scores the identical expectations. A drift here
# would not fail loudly: it would quietly compare the pipeline against numbers
# the single-cycle core was never held to, and both runs would print PASS.
#
# The testbenches themselves are correctly NOT here: they differ by design
# (different instantiation, different observation ports), which is the whole
# content of tb_isa_directed's header.
GENERATED_PKGS = {
    "isa_expected_pkg.vhd":  "tools/gen_isa_test.py writes both copies",
    "gpio_expected_pkg.vhd": "tools/gen_gpio_test.py -- same rule",
}

TB_SC = ROOT / "TB" / "RV32IMscMCU"
TB_PIPE = ROOT / "TB" / "RV32IMpipelinedMCU"


def check_generated_pkgs():
    """Returns a list of findings; empty is clean."""
    findings = []
    for name, why in sorted(GENERATED_PKGS.items()):
        a, b = TB_SC / name, TB_PIPE / name
        if not a.is_file():
            findings.append(f"TB/RV32IMscMCU/{name} is missing ({why})")
            continue
        if not b.is_file():
            findings.append(
                f"TB/RV32IMpipelinedMCU/{name} is missing -- the pipeline's "
                f"suite cannot score the same expectations without it ({why})")
            continue
        if a.read_bytes() != b.read_bytes():
            findings.append(
                f"{name} DIFFERS between the TB trees. It is generated data, "
                f"not hand-written: re-run the generator rather than editing "
                f"either copy ({why})")
    return findings


def self_test():
    import shutil, tempfile
    with tempfile.TemporaryDirectory() as td:
        t = pathlib.Path(td)
        a, b = t / "sc", t / "pipe"
        a.mkdir(); b.mkdir()
        (a / "X.vhd").write_text("entity X is end X;\n")
        (b / "X.vhd").write_text("entity X is end X;\n")
        ident, diff, _, _ = compare(a, b)
        assert ident == ["X.vhd"] and diff == [], "self-test: equal pair not seen as equal"
        (b / "X.vhd").write_text("entity X is end X;  -- drifted\n")
        ident, diff, _, _ = compare(a, b)
        assert diff == ["X.vhd"] and ident == [], "self-test: a real difference was NOT caught"
        # and a file in only one tree must not be reported as a difference
        (a / "Y.vhd").write_text("y\n")
        ident, diff, only_a, only_b = compare(a, b)
        assert only_a == ["Y.vhd"] and diff == ["X.vhd"], "self-test: one-sided file mishandled"
    print("self-test: the comparison catches a one-line drift and tolerates "
          "one-sided files")
    return 0


def main():
    if "--self-test" in sys.argv:
        return self_test()

    if not PIPE.is_dir():
        print(f"no pipeline tree at {PIPE} -- nothing to compare")
        return 0

    identical, differing, only_sc, only_pipe = compare(SC, PIPE)
    unexplained = [n for n in differing if n not in ALLOWED_TO_DIFFER]

    print(f"{len(identical)} file(s) byte-identical in both trees")
    print(f"{len(differing)} file(s) differ, {len(unexplained)} of them unexplained")
    print(f"{len(only_sc)} only in RV32IMscMCU, {len(only_pipe)} only in "
          f"RV32IMpipelinedMCU")

    pkg_findings = check_generated_pkgs()
    print(f"{len(GENERATED_PKGS)} generated expectation package(s) checked "
          f"across the TB trees, {len(pkg_findings)} finding(s)")

    if unexplained:
        print("")
        print("UNEXPLAINED DIFFERENCES -- a shared peripheral has drifted, or a")
        print("new legitimate difference needs a line in ALLOWED_TO_DIFFER:")
        for n in unexplained:
            print(f"  {n}")
            print(f"    diff '{SC / n}' '{PIPE / n}'")

    if pkg_findings:
        print("")
        print("GENERATED EXPECTATION PACKAGES:")
        for f in pkg_findings:
            print(f"  {f}")

    if unexplained or pkg_findings:
        return 1

    print("clean: every peripheral shared by both trees is byte-identical, so")
    print("the single-cycle verification results apply to the pipeline unchanged;")
    print("and both trees score the same generated expectations")
    return 0


if __name__ == "__main__":
    sys.exit(main())
