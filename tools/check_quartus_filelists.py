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

# Files deliberately NOT in a project, with the reason. A file listed here is
# not reported as missing from the .qsf -- but it still must exist on disk.
WAIVED = {
    ("DUT/RV32IMscMCU", "MUL16.vhd"):
        "instantiated by RV32IM_CORE via aux_package; verify before removing",
}

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

    if findings:
        print(f"\n{len(findings)} FINDING(S):")
        for f in findings:
            print(f"  - {f}")
        return 1
    print("clean: every project's file list matches its design directory")
    return 0


if __name__ == "__main__":
    sys.exit(main())
