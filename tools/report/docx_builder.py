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

HEB = re.compile(r'[֐-׿]')


def esc(s):
    return (s.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'))


# ---------------------------------------------------------------------------
# run splitting -- the bidi core
# ---------------------------------------------------------------------------
def _classify(ch):
    if '֐' <= ch <= '׿':
        return 'H'
    if ch.isalpha():
        return 'L'
    return 'N'                                  # digits, punctuation, space


def _segments(text):
    """Split into (is_hebrew, chunk).  Neutrals stick to what came before."""
    out = []
    cur, kind = '', None
    for ch in text:
        c = _classify(ch)
        if c == 'N':
            cur += ch
            continue
        if kind is None:
            kind = c
            cur += ch
        elif c == kind:
            cur += ch
        else:
            out.append((kind, cur))
            kind, cur = c, ch
    if cur:
        out.append((kind if kind else 'L', cur))
    # leading neutrals with no letters at all
    if not out and text:
        out = [('L', text)]
    return [(k == 'H', v) for k, v in out]


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


def _runs(text, bold=False, mono=False, size=None, color=None, italic=False):
    """Text -> a run sequence with <w:rtl/> only on the Hebrew parts.

    Two inline markers are honoured so callers can write ordinary strings:
        **bold**    -> bold run
        `code`      -> Consolas run, and never marked rtl (identifiers are
                       Latin, and a monospace identifier that picked up an
                       rtl run would render its brackets mirrored)
    """
    out = []
    for part in re.split(r'(\*\*.+?\*\*|`[^`]+`)', text):
        if not part:
            continue
        b, m = bold, mono
        if part.startswith('**') and part.endswith('**') and len(part) > 4:
            # re-enter so a `code` span nested inside a bold span still
            # becomes monospace instead of leaking its backticks
            out.append(_runs(part[2:-2], True, mono, size, color, italic))
            continue
        elif part.startswith('`') and part.endswith('`') and len(part) > 2:
            part, m = part[1:-1], True
            sz = size if size else 20
            out.append('<w:r>' + _rpr(False, b, True, sz, color, italic)
                       + f'<w:t xml:space="preserve">{esc(part)}</w:t></w:r>')
            continue
        for is_heb, chunk in _segments(part):
            out.append(
                '<w:r>' + _rpr(is_heb, b, m, size, color, italic)
                + f'<w:t xml:space="preserve">{esc(chunk)}</w:t></w:r>')
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
        self._p(_runs(text, mono=True, size=20), jc='center',
                before=80, after=80, bidi=False)

    def code(self, text):
        for line in text.split('\n'):
            self._p(_runs(line or ' ', mono=True, size=18), jc='left',
                    after=0, bidi=False, ind=284)
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
