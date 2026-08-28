"""
docx_builder.py -- a minimal, dependency-free OOXML writer for the project report.

WHY THIS EXISTS
    The final report has to be delivered as an EDITABLE .docx (Yehonatan's
    requirement), and this machine has no python-docx, no pandoc and no
    LibreOffice.  Writing the OOXML directly is the only route that works here,
    and it turns out to be the better one anyway: it lets the report be
    *generated* from the measured numbers rather than typed, so a re-measured
    Fitter report is one edit and one re-run, not a hunt through a Word file.

TEMPLATE, NOT A BLANK PAGE
    Everything that makes a Hebrew academic Word document look right --
    heading styles, list numbering, the theme's majorBidi font pairing, the
    footer with its PAGE field, A4 margins -- is taken verbatim from
    `Auxiliary/Lab 5/DOC/Report_lab5.docx`, the report this team already
    submitted and had accepted.  Only `word/document.xml` and `word/media/`
    are generated.  That is deliberate: the visual identity is inherited from
    an accepted submission instead of invented.

    Style IDs in that template (read out of its styles.xml):
        "1"  = heading 1      "21" = heading 2      "31" = heading 3
        "4"  = heading 4      "af" = List Paragraph

THE ONE THING THAT IS EASY TO GET WRONG: BIDI
    A mixed Hebrew/English technical paragraph needs two things or Word
    renders it scrambled:
      * the PARAGRAPH carries <w:bidi/>          (right-to-left flow)
      * every HEBREW RUN carries <w:rtl/>        (right-to-left run)
    Latin runs (signal names, file names, numbers) must NOT carry <w:rtl/>.
    `_runs()` below does that split automatically, which is why callers can
    pass plain strings and stop thinking about it.  Both facts were read off
    the template: 712 <w:bidi/> and 2333 <w:rtl/> in its document.xml.

NO TABLE OF CONTENTS
    Deliberately omitted -- Yehonatan is inserting it himself.  The heading
    styles are real Word heading styles, so Word's own "Insert > Table of
    Contents" will pick every section up with correct page numbers.
"""

import os
import re
import shutil
import struct
import zipfile

# ---------------------------------------------------------------------------
# geometry
# ---------------------------------------------------------------------------
EMU_PER_PX = 9525                      # 96 dpi
TWIP_CONTENT_WIDTH = 11906 - 1276 - 1276   # A4 minus the template's margins
MAX_IMG_EMU = TWIP_CONTENT_WIDTH * 635     # 1 twip = 635 EMU  -> 5,939,790

XML_HDR = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'

NS = (
    'xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" '
    'xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" '
    'xmlns:o="urn:schemas-microsoft-com:office:office" '
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
    'xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" '
    'xmlns:v="urn:schemas-microsoft-com:vml" '
    'xmlns:wp14="http://schemas.microsoft.com/office/word/2010/wordprocessingDrawing" '
    'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" '
    'xmlns:w10="urn:schemas-microsoft-com:office:word" '
    'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
    'xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml" '
    'xmlns:w15="http://schemas.microsoft.com/office/word/2012/wordml" '
    'xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup" '
    'xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk" '
    'xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" '
    'xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape" '
    'mc:Ignorable="w14 w15 wp14"'
)

FONT = ('<w:rFonts w:asciiTheme="majorBidi" w:hAnsiTheme="majorBidi" '
        'w:cstheme="majorBidi"/>')
MONO = '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas" w:cs="Consolas"/>'

def esc(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


# ===========================================================================
# BIDI
# ===========================================================================
# Word lays text out with the Unicode Bidi Algorithm.  What <w:rtl/> on a run
# actually controls is the direction of that run's NEUTRAL characters -- the
# spaces, punctuation, parentheses and dashes.  Strong characters (Hebrew
# letters, Latin letters) resolve from their own Unicode class no matter what
# the flag says.  So getting mixed Hebrew/English right is entirely a question
# of putting each neutral in the run with the correct flag, and that is what
# this section computes.
#
# The rule this replaces -- "a neutral joins whatever segment came before it"
# -- is wrong in three ways that all showed up in the first draft:
#
#   "מרבבי (multiplexers)"        the '(' landed in the Hebrew run, and a
#                                 parenthesis at RTL level is MIRRORED, so it
#                                 rendered as ')' on the wrong side
#   "20.732 ns"                   the number was swallowed by the Hebrew run
#                                 and detached from its unit
#   "ב-EX, ולכן"                  the comma stayed in the Latin run and came
#                                 out on the wrong side of the Hebrew
#
# What is implemented here is the Unicode algorithm's W4, W7 and N1/N2 rules,
# with one deliberate departure documented at PHRASE below.
# ---------------------------------------------------------------------------

HEB = re.compile(r'[֐-׿יִ-ﭏ]')

# Characters that UBA W4 folds into a number when they sit between two digits,
# so "3.768", "02:51" and "8-16" survive as single left-to-right tokens.
_NUM_JOIN = set('.,:/- –−')

# European terminators (UBA W5): they join an adjacent number, which is what
# keeps "12.7%" from rendering as "%12.7".
_NUM_TERM = set('%‰°$€£#')

# A sign written directly against a digit belongs to the number.  Strict UBA
# leaves a LEADING sign neutral, which inside a Hebrew paragraph puts it on
# the wrong side -- "+503" comes out as "503+".  Same class of deliberate
# departure as PHRASE below, and for the same reason.
_NUM_SIGN = set('+-−±')

# Bidi controls a caller may have typed by hand.  They are stripped: this
# module decides direction, and a stray RLM would inject a strong R character
# into the middle of an identifier.
_CONTROLS = dict.fromkeys(map(ord, '‎‏‪‫‬'
                                   '⁦⁧⁨⁩'), None)


def _resolve(text, force_ltr=None, base='R'):
    """Per-character render direction ('R'/'L') for a paragraph whose base
    direction is `base`.

    `force_ltr[i]` marks characters inside a `code` span, whose non-Hebrew
    characters are treated as strong LTR so an identifier can never be pulled
    into the Hebrew direction.
    """
    n = len(text)
    cls = []
    for i, ch in enumerate(text):
        heb = bool(HEB.match(ch))
        if force_ltr and force_ltr[i] and not heb:
            cls.append('L')
        elif heb:
            cls.append('R')
        elif ch.isdigit():
            cls.append('EN')
        elif ch.isalpha():
            cls.append('L')
        else:
            cls.append('N')

    # W4 -- a single separator between two digits is part of the number.
    for i in range(1, n - 1):
        if (cls[i] == 'N' and text[i] in _NUM_JOIN
                and cls[i - 1] == 'EN' and cls[i + 1] == 'EN'):
            cls[i] = 'EN'

    # W5 -- a terminator touching a number joins it:  12.7%, 85C, 20°.
    i = 0
    while i < n:
        if cls[i] == 'N' and text[i] in _NUM_TERM:
            j = i
            while j < n and cls[j] == 'N' and text[j] in _NUM_TERM:
                j += 1
            if (i > 0 and cls[i - 1] == 'EN') or (j < n and cls[j] == 'EN'):
                for k in range(i, j):
                    cls[k] = 'EN'
            i = j
        else:
            i += 1

    # A sign written against a digit is part of that number (see _NUM_SIGN) --
    # but ONLY when nothing strong precedes it.  In "ו-0x2004" and "ל-115200"
    # the hyphen is a Hebrew prefix connector, not a minus, and it has to stay
    # neutral so it renders on the Hebrew side.
    for i in range(n):
        if (cls[i] == 'N' and text[i] in _NUM_SIGN
                and i + 1 < n and cls[i + 1] == 'EN'
                and (i == 0 or cls[i - 1] == 'N')):
            cls[i] = 'EN'

    # W7 -- a number whose nearest preceding strong character is Latin is part
    # of that Latin word:  0x2000, v1.1, Cyclone IV.
    last = None
    for i in range(n):
        if cls[i] in ('L', 'R'):
            last = cls[i]
        elif cls[i] == 'EN' and last == 'L':
            cls[i] = 'L'

    def side(c):
        return 'R' if c == 'R' else 'L'      # a number sides with Latin

    # N0 -- a matching bracket PAIR resolves as a unit, taking the direction
    # of the strong text it encloses.  Without this each bracket resolves on
    # its own from its own neighbours, and the one that lands at RTL level is
    # mirrored while its partner is not:  "KEY[3-1]" came out "[KEY[3-1", and
    # "(10%)" came out "(10%(".
    close = {'(': ')', '[': ']', '{': '}'}
    stack, pairs = [], []
    for i, ch in enumerate(text):
        if cls[i] != 'N':
            continue
        if ch in close:
            stack.append((i, close[ch]))
        elif stack and ch == stack[-1][1]:
            pairs.append((stack.pop()[0], i))
    for o, c in pairs:
        inner = {side(x) for x in cls[o + 1:c] if x != 'N'}
        if base in inner:
            cls[o] = cls[c] = base
        elif inner:
            cls[o] = cls[c] = inner.pop()

    # N1/N2 -- resolve each maximal gap of neutrals from what surrounds it.
    # A gap between two same-direction items takes that direction; anything
    # else -- including both boundaries between the scripts, and the start and
    # end of the paragraph -- takes the base direction.
    #
    # PHRASE: strict UBA says numbers "act as R" when resolving neighbouring
    # neutrals, which in a Hebrew paragraph puts the space in "20 MHz" at RTL
    # level and renders it "MHz 20".  Treating a number as siding with Latin
    # (see side() above) keeps the phrase reading left to right.  That is the
    # one deliberate departure from the standard here, and it is what an
    # author would otherwise have to force with LRM marks.
    i = 0
    while i < n:
        if cls[i] != 'N':
            i += 1
            continue
        j = i
        while j < n and cls[j] == 'N':
            j += 1
        before = cls[i - 1] if i > 0 else None
        after = cls[j] if j < n else None
        if before is not None and after is not None \
                and side(before) == side(after):
            fill = side(before)
        else:
            fill = base
        for k in range(i, j):
            cls[k] = fill
        i = j

    # A number that stayed EN renders left to right (bidi level 2), same as L.
    return ['R' if c == 'R' else 'L' for c in cls]


def _spans(text, bold, mono):
    """Split the inline markup into (text, bold, mono) spans.

        **bold**    -> bold
        `code`      -> Consolas, and forced LTR
    """
    out = []
    for part in re.split(r'(\*\*.+?\*\*|`[^`]+`)', text):
        if not part:
            continue
        if part.startswith('**') and part.endswith('**') and len(part) > 4:
            out.extend(_spans(part[2:-2], True, mono))
        elif part.startswith('`') and part.endswith('`') and len(part) > 2:
            out.append((part[1:-1], bold, True))
        else:
            out.append((part, bold, mono))
    return out


def _rpr(hebrew, bold=False, mono=False, size=None, color=None, italic=False):
    p = ['<w:rPr>']
    p.append(MONO if mono else FONT)
    if bold:
        p.append('<w:b/><w:bCs/>')
    if italic:
        p.append('<w:i/><w:iCs/>')
    if size:
        p.append(f'<w:sz w:val="{size}"/><w:szCs w:val="{size}"/>')
    p.append(f'<w:color w:val="{color or "000000"}"/>')
    if hebrew:
        p.append('<w:rtl/><w:lang w:bidi="he-IL"/>')
    p.append('</w:rPr>')
    return ''.join(p)


def _runs(text, bold=False, mono=False, size=None, color=None, italic=False,
          base='R'):
    """Text -> Word runs, each carrying <w:rtl/> iff it renders right-to-left.

    Direction is resolved over the WHOLE paragraph string, not per markup
    span, because a neutral's direction depends on the strong characters on
    both sides of it -- and those may live in a different span.  Resolving
    span-by-span is what produced the mirrored parenthesis in the first draft.

    `base` must match the paragraph's own direction: 'R' for the body, 'L' for
    the equation and code paragraphs, which are emitted without <w:bidi/>.
    """
    spans = _spans(text.translate(_CONTROLS), bold, mono)
    if not spans:
        return ''
    full = ''.join(s[0] for s in spans)
    force = [m for t, _, m in spans for _ in t]
    dirs = _resolve(full, force, base)

    out, pos = [], 0
    for txt, b, m in spans:
        i = 0
        while i < len(txt):
            d = dirs[pos + i]
            j = i + 1
            while j < len(txt) and dirs[pos + j] == d:
                j += 1
            sz = size if size is not None else (20 if m else None)
            out.append(
                '<w:r>' + _rpr(d == 'R', b, m, sz, color, italic)
                + f'<w:t xml:space="preserve">{esc(txt[i:j])}</w:t></w:r>')
            i = j
        pos += len(txt)
    return ''.join(out)


# ---------------------------------------------------------------------------
# image helpers
# ---------------------------------------------------------------------------
def _png_size(path):
    with open(path, 'rb') as fh:
        head = fh.read(32)
    if head[:8] == b'\x89PNG\r\n\x1a\n' and head[12:16] == b'IHDR':
        w, h = struct.unpack('>II', head[16:24])
        return w, h
    raise ValueError(f'not a PNG: {path}')


def _fit(px_w, px_h, frac):
    """Scale to `frac` of the text column, preserving aspect ratio."""
    target = int(MAX_IMG_EMU * frac)
    cx = min(px_w * EMU_PER_PX, target)
    cy = int(cx * px_h / px_w)
    return cx, cy


# ---------------------------------------------------------------------------
# document
# ---------------------------------------------------------------------------
class Doc:
    def __init__(self, template, root='.'):
        self.template = template
        self.root = root
        self.body = []
        self.images = []            # (rid, arcname, srcpath)
        self.fig_n = 0
        self.tab_n = 0
        self._img_id = 1
        self.missing = []           # figures asked for but not on disk

    # -- block helpers ------------------------------------------------------
    def _p(self, inner, style=None, jc=None, before=0, after=80,
           keep=False, bidi=True, ind=None):
        pr = ['<w:pPr>']
        if style:
            pr.append(f'<w:pStyle w:val="{style}"/>')
        if keep:
            pr.append('<w:keepNext/>')
        if bidi:
            pr.append('<w:bidi/>')
        if ind:
            pr.append(f'<w:ind w:left="{ind}"/>')
        pr.append(f'<w:spacing w:before="{before}" w:after="{after}"/>')
        if jc:
            pr.append(f'<w:jc w:val="{jc}"/>')
        pr.append('</w:pPr>')
        self.body.append('<w:p>' + ''.join(pr) + inner + '</w:p>')

    def h1(self, text):
        self.body.append('<w:p><w:pPr><w:pageBreakBefore/><w:pStyle w:val="1"/>'
                         '<w:bidi/></w:pPr>' + _runs(text) + '</w:p>')

    def h2(self, text):
        self._p(_runs(text), style='21', before=200, after=80)

    def h3(self, text):
        self._p(_runs(text), style='31', before=160, after=60)

    def h4(self, text):
        self._p(_runs(text), style='4', before=120, after=60)

    def p(self, text):
        self._p(_runs(text), jc='both', after=120)

    def bullet(self, text):
        self._p(_runs('•  ' + text), jc='both', after=60, ind=284)

    def note(self, text):
        """A visibly-marked gap: evidence that has to be captured on Windows."""
        self._p(_runs('[[ ' + text + ' ]]', color='C00000', bold=True,
                      size=20), jc='both', after=120)

    def eq(self, text):
        # base='L' because the paragraph is emitted without <w:bidi/>
        self._p(_runs(text, mono=True, size=20, base='L'), jc='center',
                before=80, after=80, bidi=False)

    def code(self, text):
        for line in text.split('\n'):
            self._p(_runs(line or ' ', mono=True, size=18, base='L'),
                    jc='left', after=0, bidi=False, ind=284)
        self.body.append('<w:p><w:pPr><w:spacing w:after="120"/></w:pPr></w:p>')

    def pagebreak(self):
        self.body.append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')

    # -- figures ------------------------------------------------------------
    def fig(self, path, caption, frac=0.86):
        full = os.path.join(self.root, path)
        if not os.path.exists(full):
            self.missing.append(path)
            self.note(f'איור חסר — נדרש צילום מסך: {path} · {caption}')
            return
        self.fig_n += 1
        rid = f'rId{100 + len(self.images)}'
        arc = f'media/img{len(self.images) + 1:03d}.png'
        self.images.append((rid, arc, full))
        cx, cy = _fit(*_png_size(full), frac)
        did = self._img_id
        self._img_id += 1
        drawing = (
            '<w:r><w:rPr><w:noProof/></w:rPr><w:drawing>'
            '<wp:inline distT="0" distB="0" distL="0" distR="0">'
            f'<wp:extent cx="{cx}" cy="{cy}"/>'
            '<wp:effectExtent l="0" t="0" r="0" b="0"/>'
            f'<wp:docPr id="{did}" name="Picture {did}"/>'
            '<wp:cNvGraphicFramePr><a:graphicFrameLocks '
            'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" '
            'noChangeAspect="1"/></wp:cNvGraphicFramePr>'
            '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
            '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
            '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
            f'<pic:nvPicPr><pic:cNvPr id="0" name="{esc(os.path.basename(path))}"/>'
            '<pic:cNvPicPr/></pic:nvPicPr>'
            f'<pic:blipFill><a:blip r:embed="{rid}"/>'
            '<a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
            f'<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="{cx}" cy="{cy}"/></a:xfrm>'
            '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
            '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r>')
        self._p(drawing, jc='center', before=160, after=40, keep=True)
        self._caption(f'איור {self.fig_n}: ', caption)

    def _caption(self, label, text):
        inner = (_runs(label, bold=True, size=19)
                 + _runs(text, size=19))
        self._p(inner, jc='center', after=160)

    # -- tables -------------------------------------------------------------
    def table(self, rows, caption, widths=None, header=True, align=None):
        """rows[0] is the header row.  `widths` are relative weights."""
        ncol = max(len(r) for r in rows)
        if widths is None:
            widths = [1] * ncol
        tot = sum(widths)
        cols = [int(TWIP_CONTENT_WIDTH * w / tot) for w in widths]

        border = ('<w:tblBorders>'
                  '<w:top w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>'
                  '<w:left w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>'
                  '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>'
                  '<w:right w:val="single" w:sz="4" w:space="0" w:color="7F7F7F"/>'
                  '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>'
                  '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>'
                  '</w:tblBorders>')
        out = ['<w:tbl><w:tblPr><w:bidiVisual/>'
               '<w:tblW w:w="0" w:type="auto"/><w:jc w:val="center"/>'
               '<w:tblLayout w:type="fixed"/>' + border +
               '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" '
               'w:firstColumn="1" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/>'
               '</w:tblPr><w:tblGrid>']
        for c in cols:
            out.append(f'<w:gridCol w:w="{c}"/>')
        out.append('</w:tblGrid>')

        for ri, row in enumerate(rows):
            hdr = header and ri == 0
            out.append('<w:tr><w:trPr><w:jc w:val="center"/>'
                       + ('<w:tblHeader/>' if hdr else '') + '</w:trPr>')
            for ci in range(ncol):
                cell = row[ci] if ci < len(row) else ''
                shade = ('<w:shd w:val="clear" w:color="auto" w:fill="EAEEF2"/>'
                         if hdr else '')
                jc = align[ci] if align and ci < len(align) else (
                    'center' if hdr else None)
                pr = ['<w:pPr><w:bidi/><w:spacing w:before="40" w:after="40"/>']
                if jc:
                    pr.append(f'<w:jc w:val="{jc}"/>')
                pr.append('</w:pPr>')
                lines = str(cell).split('\n')
                paras = ''.join(
                    '<w:p>' + ''.join(pr)
                    + _runs(ln, bold=hdr, size=19) + '</w:p>' for ln in lines)
                out.append(f'<w:tc><w:tcPr><w:tcW w:w="{cols[ci]}" w:type="dxa"/>'
                           + shade +
                           '<w:vAlign w:val="center"/></w:tcPr>'
                           + paras + '</w:tc>')
            out.append('</w:tr>')
        out.append('</w:tbl>')
        self.body.append(''.join(out))
        self.tab_n += 1
        self._caption(f'טבלה {self.tab_n}: ', caption)

    # -- output -------------------------------------------------------------
    def _document_xml(self):
        sect = ('<w:sectPr><w:footerReference w:type="default" r:id="rId7"/>'
                '<w:pgSz w:w="11906" w:h="16838"/>'
                '<w:pgMar w:top="1134" w:right="1276" w:bottom="1134" '
                'w:left="1276" w:header="680" w:footer="680" w:gutter="0"/>'
                '<w:cols w:space="720"/><w:bidi/>'
                '<w:docGrid w:linePitch="360"/></w:sectPr>')
        return (XML_HDR + f'<w:document {NS}><w:body>'
                + ''.join(self.body) + sect + '</w:body></w:document>')

    def _rels_xml(self):
        R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
        rows = [
            ('rId1', 'styles', 'styles.xml'),
            ('rId2', 'numbering', 'numbering.xml'),
            ('rId3', 'settings', 'settings.xml'),
            ('rId4', 'webSettings', 'webSettings.xml'),
            ('rId5', 'fontTable', 'fontTable.xml'),
            ('rId6', 'theme', 'theme/theme1.xml'),
            ('rId7', 'footer', 'footer1.xml'),
            ('rId8', 'footnotes', 'footnotes.xml'),
            ('rId9', 'endnotes', 'endnotes.xml'),
        ]
        x = [XML_HDR,
             '<Relationships xmlns="http://schemas.openxmlformats.org/package/'
             '2006/relationships">']
        for rid, typ, tgt in rows:
            x.append(f'<Relationship Id="{rid}" Type="{R}/{typ}" Target="{tgt}"/>')
        for rid, arc, _ in self.images:
            x.append(f'<Relationship Id="{rid}" Type="{R}/image" Target="{arc}"/>')
        x.append('</Relationships>')
        return ''.join(x)

    @staticmethod
    def _content_types():
        C = 'application/vnd.openxmlformats-officedocument.wordprocessingml'
        parts = [
            ('/word/document.xml', f'{C}.document.main+xml'),
            ('/word/styles.xml', f'{C}.styles+xml'),
            ('/word/numbering.xml', f'{C}.numbering+xml'),
            ('/word/settings.xml', f'{C}.settings+xml'),
            ('/word/webSettings.xml', f'{C}.webSettings+xml'),
            ('/word/fontTable.xml', f'{C}.fontTable+xml'),
            ('/word/footer1.xml', f'{C}.footer+xml'),
            ('/word/footnotes.xml', f'{C}.footnotes+xml'),
            ('/word/endnotes.xml', f'{C}.endnotes+xml'),
            ('/word/theme/theme1.xml',
             'application/vnd.openxmlformats-officedocument.theme+xml'),
            ('/docProps/core.xml',
             'application/vnd.openxmlformats-package.core-properties+xml'),
            ('/docProps/app.xml',
             'application/vnd.openxmlformats-officedocument.'
             'extended-properties+xml'),
        ]
        x = [XML_HDR,
             '<Types xmlns="http://schemas.openxmlformats.org/package/2006/'
             'content-types">',
             '<Default Extension="png" ContentType="image/png"/>',
             '<Default Extension="rels" ContentType="application/vnd.'
             'openxmlformats-package.relationships+xml"/>',
             '<Default Extension="xml" ContentType="application/xml"/>']
        for pn, ct in parts:
            x.append(f'<Override PartName="{pn}" ContentType="{ct}"/>')
        x.append('</Types>')
        return ''.join(x)

    @staticmethod
    def _core_xml(title, authors):
        dc = 'http://purl.org/dc/elements/1.1/'
        return (XML_HDR +
                '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/'
                'package/2006/metadata/core-properties" '
                f'xmlns:dc="{dc}" '
                'xmlns:dcterms="http://purl.org/dc/terms/" '
                'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
                f'<dc:title>{esc(title)}</dc:title>'
                f'<dc:creator>{esc(authors)}</dc:creator>'
                f'<cp:lastModifiedBy>{esc(authors)}</cp:lastModifiedBy>'
                '</cp:coreProperties>')

    @staticmethod
    def _app_xml():
        return (XML_HDR +
                '<Properties xmlns="http://schemas.openxmlformats.org/'
                'officeDocument/2006/extended-properties" '
                'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/'
                '2006/docPropsVTypes"><Application>Microsoft Office Word'
                '</Application></Properties>')

    def save(self, out, title, authors):
        keep = ['word/styles.xml', 'word/numbering.xml', 'word/settings.xml',
                'word/webSettings.xml', 'word/fontTable.xml',
                'word/theme/theme1.xml', 'word/footer1.xml',
                'word/footnotes.xml', 'word/endnotes.xml']
        src = zipfile.ZipFile(self.template)
        tmp = out + '.tmp'
        with zipfile.ZipFile(tmp, 'w', zipfile.ZIP_DEFLATED) as z:
            z.writestr('[Content_Types].xml', self._content_types())
            z.writestr('_rels/.rels', XML_HDR +
                       '<Relationships xmlns="http://schemas.openxmlformats.org/'
                       'package/2006/relationships">'
                       '<Relationship Id="rId1" Type="http://schemas.'
                       'openxmlformats.org/officeDocument/2006/relationships/'
                       'officeDocument" Target="word/document.xml"/>'
                       '<Relationship Id="rId2" Type="http://schemas.'
                       'openxmlformats.org/package/2006/relationships/metadata/'
                       'core-properties" Target="docProps/core.xml"/>'
                       '<Relationship Id="rId3" Type="http://schemas.'
                       'openxmlformats.org/officeDocument/2006/relationships/'
                       'extended-properties" Target="docProps/app.xml"/>'
                       '</Relationships>')
            for name in keep:
                z.writestr(name, src.read(name))
            z.writestr('docProps/core.xml', self._core_xml(title, authors))
            z.writestr('docProps/app.xml', self._app_xml())
            z.writestr('word/document.xml', self._document_xml())
            z.writestr('word/_rels/document.xml.rels', self._rels_xml())
            for _, arc, path in self.images:
                z.write(path, 'word/' + arc)
        src.close()
        shutil.move(tmp, out)
        return out
