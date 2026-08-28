#!/usr/bin/env python3
"""
gen_report.py -- build DOC/Final_report.docx.

    python3 tools/gen_report.py

WHY THE REPORT IS GENERATED AND NOT TYPED
    Every PPA number in it was read off a Quartus screenshot and every cycle
    count off a ModelSim wave.  Those will be re-measured (the interrupt
    benchmarks have no captures yet, and the SignalTap work has not started).
    Keeping the report in a script means a re-measured Fitter report is one
    edit here and one re-run -- not a hunt through a Word file for the four
    places a number appears.

    The .docx it writes is a normal, fully editable Word document.  Edit it by
    hand freely; just remember that re-running this overwrites it.

TEMPLATE
    Styles, numbering, theme and the page-numbered footer come from
    `Auxiliary/Lab 5/DOC/Report_lab5.docx` -- the report this team already
    submitted.  Only the body and the images are generated.

TABLE OF CONTENTS
    Not emitted on purpose: Yehonatan is inserting it.  The headings are real
    Word heading styles, so References > Table of Contents picks them all up.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from report.docx_builder import Doc                       # noqa: E402
from report import report_content as C                    # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TEMPLATE = os.path.join(ROOT, 'Auxiliary', 'Lab 5', 'DOC', 'Report_lab5.docx')
OUT = os.path.join(ROOT, 'DOC', 'Final_report.docx')


def main():
    if not os.path.exists(TEMPLATE):
        sys.exit(f'template not found: {TEMPLATE}')

    doc = Doc(TEMPLATE)
    doc.root = ROOT
    C.build(doc)
    doc.save(OUT, C.TITLE, C.AUTHORS)

    print(f'wrote {os.path.relpath(OUT, ROOT)}')
    print(f'  figures : {doc.fig_n}')
    print(f'  tables  : {doc.tab_n}')
    print(f'  images  : {len(doc.images)} embedded, '
          f'{os.path.getsize(OUT) / 1e6:.1f} MB')
    if doc.missing:
        print(f'\n  {len(doc.missing)} figure(s) referenced but not on disk -- '
              'each is marked in red in the document:')
        for m in doc.missing:
            print(f'    - {m}')


if __name__ == '__main__':
    main()
