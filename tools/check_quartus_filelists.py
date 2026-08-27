#!/usr/bin/env python3
"""Assert every Quartus project's VHDL file list matches the design on disk.

Why this exists: on 2026-08-26 the pipelined project's `.qsf` still listed
`MUL16.vhd` and omitted `MULT_1.vhd`, `MULT_2.vhd` and `WRITEBACK.vhd` -- three
days after the 2026-08-23 pipeline re-import replaced them. `compile.do` was
corrected at the re-import; the `.qsf` was not. As committed the project could
not compile: a missing-file error plus three unbound components. There is no
`SEARCH_PATH` in these projects, so Quartus finds an entity only if the file is
listed, and a missing entry surfaces as "unbound component" a long way from its
cause.

It checks, per project:
  * every VHDL_FILE path exists;
  * every .vhd in the project's DUT directory is listed (or is explicitly
    waived below, with a reason);
  * the list has no duplicates;
  * the top-level entity named by the .qsf exists as an entity in a listed file.

AND, since 2026-08-27, the SAME CHECKS ON ModelSim's compile.do -- because the
bug recurred in the other direction. Phase 12B added six UART files to both
DUT trees and to both .qsf files, and to the single-cycle compile.do, and NOT
to the pipelined one: that tree would have failed to elaborate uart_periph.
Two lists, one edited, for the third time in this project. There are three
lists per tree now (.qsf, compile.do, the directory) and all three are checked
against each other here.

Run from the repo root:  python3 tools/check_quartus_filelists.py
Exit status 0 = clean, 1 = findings. No Quartus needed; runs on any machine.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

# project .qsf -> the DUT directory whose files it should cover
PROJECTS = {
    "Quartus/RV32IMscMCU/RV32IMscMCU.qsf": "DUT/RV32IMscMCU",
    "Quartus/RV32IMpipelinedMCU/RV32IMpipelinedMCU.qsf": "DUT/RV32IMpipelinedMCU",
}

# ModelSim's own file list, per tree. Same design directory, same question.
COMPILES = {
    "SIM/RV32IMscMCU/compile.do": "DUT/RV32IMscMCU",
    "SIM/RV32IMpipelinedMCU/compile.do": "DUT/RV32IMpipelinedMCU",
}

# Files deliberately NOT in a project, with the reason. A file listed here is
# not reported as missing from the .qsf -- but it still must exist on disk.
WAIVED = {
    ("DUT/RV32IMscMCU", "MUL16.vhd"):
        "instantiated by RV32IM_CORE via aux_package; verify before removing",
}

VCOM_FILE = re.compile(r"^\s*vcom\s+(?:-\S+\s+)*(\S+\.vhd)", re.M | re.I)


def check_compile_do(do_rel, dut_rel, findings):
    """The compile.do half: same three questions as the .qsf, on the same
    directory. Only DUT files are compared -- a compile.do also lists
    testbenches, which live elsewhere and are not this check's business."""
    do = ROOT / do_rel
    dut = ROOT / dut_rel
    if not do.is_file():
        findings.append(f"{do_rel}: no such compile script")
        return
    listed = VCOM_FILE.findall(do.read_text(errors="replace"))
    dut_names = []
    for p in listed:
        resolved = (do.parent / p).resolve()
        if not resolved.is_file():
            findings.append(
                f"{do_rel}: compiles '{p}' -- FILE DOES NOT EXIST "
                f"(vcom stops there and the rest of the run is meaningless)")
            continue
        try:
            rel = resolved.relative_to(ROOT)
        except ValueError:
            continue
        if str(rel.parent).replace("\\", "/") == dut_rel:
            dut_names.append(resolved.name)

    for n in sorted(set(dut_names)):
        if dut_names.count(n) > 1:
            findings.append(f"{do_rel}: compiles {n} {dut_names.count(n)} times")

    for f in sorted(dut.glob("*.vhd")):
        if f.name in dut_names:
            continue
        reason = WAIVED.get((dut_rel, f.name))
        if reason:
            print(f"  note {dut_rel}/{f.name} not compiled -- waived: {reason}")
            continue
        findings.append(
            f"{do_rel}: {dut_rel}/{f.name} exists but is NOT compiled -- "
            f"any entity in it elaborates as an unbound component, or the "
            f"whole design fails to load")

    print(f"checked {do_rel}: {len(dut_names)} design file(s) compiled, "
          f"{len(list(dut.glob('*.vhd')))} in {dut_rel}")

VHDL_FILE = re.compile(r"^\s*set_global_assignment\s+-name\s+VHDL_FILE\s+(\S+)", re.M)
TOP_ENTITY = re.compile(r"^\s*set_global_assignment\s+-name\s+TOP_LEVEL_ENTITY\s+(\S+)", re.M)
ENTITY_DECL = re.compile(r"^\s*ENTITY\s+(\w+)\s+IS", re.M | re.I)


def main():
    findings = []
    for qsf_rel, dut_rel in PROJECTS.items():
        qsf = ROOT / qsf_rel
        dut = ROOT / dut_rel
        if not qsf.is_file():
            findings.append(f"{qsf_rel}: no such .qsf")
            continue
        if not dut.is_dir():
            findings.append(f"{dut_rel}: no such DUT directory")
            continue

        text = qsf.read_text(errors="replace")
        listed_paths = VHDL_FILE.findall(text)

        # 1. every listed path resolves
        listed_names = []
        for p in listed_paths:
            resolved = (qsf.parent / p).resolve()
            listed_names.append(resolved.name)
            if not resolved.is_file():
                findings.append(
                    f"{qsf_rel}: lists '{p}' -- FILE DOES NOT EXIST "
                    f"(Quartus stops on this before reporting anything else)"
                )

        # 2. duplicates
        for n in sorted(set(listed_names)):
            if listed_names.count(n) > 1:
                findings.append(
                    f"{qsf_rel}: lists {n} {listed_names.count(n)} times"
                )

        # 3. every design file is listed
        for f in sorted(dut.glob("*.vhd")):
            if f.name in listed_names:
                continue
            reason = WAIVED.get((dut_rel, f.name))
            if reason:
                print(f"  note {dut_rel}/{f.name} not in project -- waived: {reason}")
                continue
            findings.append(
                f"{qsf_rel}: {dut_rel}/{f.name} exists but is NOT listed -- "
                f"there is no SEARCH_PATH, so any entity in it will be reported "
                f"as an unbound component"
            )

        # 4. the top-level entity is declared in one of the listed files
        tops = TOP_ENTITY.findall(text)
        if not tops:
            findings.append(f"{qsf_rel}: no TOP_LEVEL_ENTITY assignment")
        else:
            top = tops[-1].strip('"')
            declared = set()
            for p in listed_paths:
                resolved = (qsf.parent / p).resolve()
                if resolved.is_file():
                    declared.update(
                        e.lower() for e in ENTITY_DECL.findall(
                            resolved.read_text(errors="replace"))
                    )
            if top.lower() not in declared:
                findings.append(
                    f"{qsf_rel}: TOP_LEVEL_ENTITY '{top}' is not declared in any "
                    f"listed file"
                )

        print(f"checked {qsf_rel}: {len(listed_paths)} VHDL_FILE entries, "
              f"{len(list(dut.glob('*.vhd')))} files in {dut_rel}")

    for do_rel, dut_rel in COMPILES.items():
        check_compile_do(do_rel, dut_rel, findings)

    if findings:
        print(f"\n{len(findings)} FINDING(S):")
        for f in findings:
            print(f"  - {f}")
        return 1
    print("clean: every Quartus project AND every ModelSim compile script "
          "covers its whole design directory")
    return 0


if __name__ == "__main__":
    sys.exit(main())
