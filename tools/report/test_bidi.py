#!/usr/bin/env python3
"""
test_bidi.py -- prove the mixed Hebrew/English text renders correctly.

    python3 tools/report/test_bidi.py

WHY A TEST AND NOT AN EYEBALL
    The bug this guards against is invisible in the source and invisible in a
    text dump of the .docx: the characters are all present and in logical
    order either way.  It only appears once Word REORDERS them for display.
    So the test reimplements that reordering -- Unicode Bidi Algorithm rule
    L2 plus mirroring -- and asserts on the visual result.

    Each maximal run of Hebrew is collapsed to <heb> in the expected string,
    because a Hebrew word's visual form is just its logical form reversed and
    that is never the thing under test.  What IS under test is where the
    Latin words, the numbers and the punctuation land relative to it.
"""

import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from report.docx_builder import _resolve, _spans, HEB, _CONTROLS   # noqa: E402

MIRROR = {'(': ')', ')': '(', '[': ']', ']': '[', '{': '}', '}': '{',
          '<': '>', '>': '<'}


def render(text, base='R'):
    """Logical text -> the visual left-to-right string Word will paint.

    Mirrors what the generator does: split the markup, resolve direction over
    the whole string, map R->level 1 and L->level 2 in an RTL paragraph, then
    apply UBA L2 (reverse contiguous sequences from the highest level down to
    the lowest odd level) and mirror the bracket characters at odd levels.
    """
    spans = _spans(text.translate(_CONTROLS), False, False)
    full = ''.join(s[0] for s in spans)
    force = [m for t, _, m in spans for _ in t]
    # in an LTR paragraph the roles swap: R is the embedded level
    lo, hi = ('R', 'L') if base == 'R' else ('L', 'R')
    lvl = [1 if d == lo else 2 for d in _resolve(full, force, base)]

    chars = list(full)
    for level in (2, 1):                     # highest level down to lowest odd
        i = 0
        while i < len(chars):
            if lvl[i] >= level:
                j = i
                while j < len(chars) and lvl[j] >= level:
                    j += 1
                chars[i:j] = chars[i:j][::-1]
                lvl[i:j] = lvl[i:j][::-1]
                i = j
            else:
                i += 1

    # mirroring applies to bracket characters resolved to an odd (RTL) level
    out = []
    for ch, lv in zip(chars, lvl):
        out.append(MIRROR[ch] if (lv % 2 and ch in MIRROR) else ch)

    # collapse each maximal Hebrew run
    res, i = [], 0
    while i < len(out):
        if HEB.match(out[i]):
            while i < len(out) and HEB.match(out[i]):
                i += 1
            res.append('<heb>')
        else:
            res.append(out[i])
            i += 1
    return ''.join(res)


# (logical text, expected visual)
#
# Read an expected string RIGHT TO LEFT to check it against the Hebrew: the
# rightmost item is the first one logically.  <heb> is one Hebrew word, so a
# three-word Hebrew phrase is three of them.  Brackets are correct when they
# curve toward the text they enclose in the PIXEL order shown -- "(x)" is
# right and ")x(" is wrong, whichever direction the surrounding text runs.
CASES = [
    # the mirrored-parenthesis bug: '(' must not sit in the Hebrew run
    ('מרבבי (multiplexers) בשלב',
     '<heb> (multiplexers) <heb>'),
    # a number must stay attached to its unit and read left to right
    ('בתדר 20 MHz בלבד',
     '<heb> 20 MHz <heb>'),
    # decimals, a comma inside an LTR phrase, and one that ends it
    ('השהיית הנתונים 20.732 ns, slack 4.198 ns',
     '20.732 ns, slack 4.198 ns <heb> <heb>'),
    # a comma between a Latin word and Hebrew belongs to the Hebrew side
    ('המסלול ב-EX, ולכן הוא קובע',
     '<heb> <heb> <heb> ,EX-<heb> <heb>'),
    # hyphenated prefix, the commonest construction in the document
    ('ליבת ה-pipeline מהירה',
     '<heb> pipeline-<heb> <heb>'),
    # an identifier in a code span: its brackets must NOT be mirrored
    ('האוגר `ex_mem_alu_res_q[13]` הוא היעד',
     '<heb> <heb> ex_mem_alu_res_q[13] <heb>'),
    # hex addresses and a slash-joined identifier list
    ('הכתובות 0x2000 ו-0x2004 שייכות ל-`IE`/`IFG`',
     'IE/IFG-<heb> <heb> 0x2004-<heb> 0x2000 <heb>'),
    # a parenthesised Hebrew aside containing a number
    ('הפער (סעיף 3.3) נסגר',
     '<heb> (3.3 <heb>) <heb>'),
    # percent must join its number (UBA W5), not detach to the far side
    ('שיפור של פי 1.98 לעומת 12.7% בלבד',
     '<heb> 12.7% <heb> 1.98 <heb> <heb> <heb>'),
    # a signed delta -- the sign must stay against the digits
    ('גידול של +503 יסודות לוגיים',
     '<heb> <heb> +503 <heb> <heb>'),
    # a sentence ending on a Latin word: the full stop goes to the far left
    ('הליבה מקבלת mclk.',
     '.mclk <heb> <heb>'),
    # bold markup must not disturb direction
    ('הערך הוא **132** הוראות',
     '<heb> 132 <heb> <heb>'),
    # a units phrase with a slash
    ('קצב של 115200 bit/s',
     '115200 bit/s <heb> <heb>'),
    # two Latin phrases separated by Hebrew keep their internal order
    ('בין MCU with GPIO לבין Pipelined MCU',
     'Pipelined MCU <heb> MCU with GPIO <heb>'),
    # a range and a parenthesised unit, both inside Hebrew
    ('הטווח 0x000–0x7FF (כתובת בית)',
     '(<heb> <heb>) 0x000–0x7FF <heb>'),
]


LATIN = __import__('re').compile(r'[A-Za-z][A-Za-z0-9_./\\]*[A-Za-z0-9_]')


def sweep():
    """Render EVERY string the report actually emits and check two invariants.

    Hand-picked cases only prove what you thought to ask.  This walks the real
    document instead, and asserts the two things that break when bidi is
    wrong: a Latin token must survive intact in the visual order, and a
    bracket pair must still enclose its content once mirroring has been
    applied.
    """
    import report.docx_builder as B
    import report.report_content as C

    seen, real = [], B._runs

    def spy(text, *a, **k):
        seen.append(text)
        return real(text, *a, **k)

    B._runs = spy
    try:
        doc = B.Doc(os.path.join(os.path.dirname(__file__), '..', '..',
                                 'Auxiliary', 'Lab 5', 'DOC',
                                 'Report_lab5.docx'),
                    root=os.path.join(os.path.dirname(__file__), '..', '..'))
        # report_content resolved _runs at import time in two helpers
        C._runs = spy
        C.build(doc)
    finally:
        B._runs = real

    problems = []
    for text in seen:
        if not text.strip():
            continue
        vis = render(text)
        plain = text.translate(B._CONTROLS).replace('**', '')
        plain = plain.replace('`', '')

        # 1. every Latin token survives contiguously
        for tok in LATIN.findall(plain):
            if len(tok) > 2 and tok not in vis:
                problems.append((text, vis, f'token split: {tok!r}'))
                break

        # 2. brackets enclose their content in pixel order
        depth = 0
        for ch in vis:
            if ch in '([{':
                depth += 1
            elif ch in ')]}':
                depth -= 1
                if depth < 0:
                    problems.append((text, vis, 'bracket pair inverted'))
                    break
        else:
            balanced = all(plain.count(a) == plain.count(b)
                           for a, b in (('(', ')'), ('[', ']'), ('{', '}')))
            if depth != 0 and balanced:
                problems.append((text, vis, 'bracket pair unbalanced'))

    print(f'\nswept {len(seen)} strings from the real report')
    for text, vis, why in problems[:12]:
        print(f'  PROBLEM ({why})')
        print(f'    logical : {text[:110]}')
        print(f'    visual  : {vis[:110]}')
    if problems:
        print(f'  {len(problems)} problem string(s)')
    else:
        print('  every Latin token intact, every bracket pair well formed')
    return len(problems)


def main():
    bad = 0
    for text, want in CASES:
        got = render(text)
        ok = got == want
        bad += not ok
        print(('  ok   ' if ok else '  FAIL ') + repr(text))
        if not ok:
            print(f'         expected : {want}')
            print(f'         got      : {got}')
    print()
    if bad:
        print(f'{bad} of {len(CASES)} cases FAILED')
    else:
        print(f'all {len(CASES)} bidi cases render correctly')
    return 1 if (bad + sweep()) else 0


if __name__ == '__main__':
    sys.exit(main())
