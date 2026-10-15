"""cy_layout_fit.py - Vietnamese labels that do not fit their CY frame (cy-gui-2, 14/09/2026).

Vietnamese runs ~1.6-2.2x wider than the Chinese it replaces; the CY frames are laid out for Chinese. The project rule
(tlbb-ui-relayout-project, 2026-08) is: never widen containers by ratio - shorten the translation instead. This script
finds the labels to shorten:

  * every window of the chosen layouts whose Text is `#{KEY}` (StrDictionary) or literal text is resolved to its
    Vietnamese value (CanonicalCY StrDictionary.txt + Registry/i18n overrides);
  * the window's pixel width comes from the nested UnifiedAreaRect/AbsoluteRect/UnifiedSize chain (root 1024x768);
  * the text width is estimated per character (Noto Sans 13 px: Latin ~6.6 px, Han ~13 px, digits ~7 px, space 3.5)
    scaled by the window Font size; a label is reported when est_width > window_width * tolerance.

Output: TSV (key, zh, vi, window, layout, width_px, est_px, max_chars) - the input of `cy_translate.py shorten`,
which asks the API for a version at most max_chars long and stores it in Registry/i18n/cy_vi_override.tsv as `#KEY`
(dictionary) or the zh text (layout literal). Buttons/checkbox captions and single-line StaticText only (multi-line
text windows wrap).

usage: python -B cy_layout_fit.py [--layouts LogOn,SelectServer,...] [--all] [--out fit.tsv] [--tolerance 1.0]
"""
import argparse
import collections
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import cy_gui_dict as GDICT     # noqa: E402

CYS = r'C:\TLBB\085\CY-Source'
IFACE = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'InterfaceFolder')
DICT = os.path.join(CYS, 'Assets', 'CanonicalCY', 'Data', 'ConfigFolder', 'StrDictionary.txt')
SCREEN = (1024.0, 768.0)
DEFAULT_LAYOUTS = ('LogOn', 'SelectServer', 'SelectRole', 'CreateRole', 'MainMenuBar', 'MainMenuBar_2',
                   'MainMenuBar_3', 'MainMenuBar_4', 'PlayerFrame', 'TargetFrame', 'MiniMap', 'ChatFrame',
                   'SystemFrame', 'SelfEquip', 'PlayerPackage', 'Skill', 'ActionSkill', 'Pet', 'Mission',
                   'PlayerQuicklyEnter', 'Team', 'Friend', 'Guild', 'MsgBox', 'MessageBox', 'Talk', 'Bank',
                   'NpcShop', 'Shop', 'Achievement', 'Exterior', 'Agname', 'Title', 'Setup', 'SystemSetup')
NUM = r'(-?\d+(?:\.\d+)?)'
RECT4 = re.compile(r'\{\s*\{' + NUM + r'\s*,' + NUM + r'\}\s*,\s*\{' + NUM + r'\s*,' + NUM + r'\}\s*,\s*\{' + NUM +
                   r'\s*,' + NUM + r'\}\s*,\s*\{' + NUM + r'\s*,' + NUM + r'\}\s*\}')
DIM2 = re.compile(r'\{\s*\{' + NUM + r'\s*,' + NUM + r'\}\s*,\s*\{' + NUM + r'\s*,' + NUM + r'\}\s*\}')
ABS4 = re.compile(r'l:' + NUM + r'\s+t:' + NUM + r'\s+r:' + NUM + r'\s+b:' + NUM)
NUMS = re.compile(NUM)
KEYREF = re.compile(r'^#\{([^}]+)\}$')
HAN = re.compile(r'[\u4e00-\u9fff]')
TOK = GDICT.TOK
TEXT_TYPES = ('SimpleText', 'StaticText', 'Button', 'CheckBox', 'Checkbox', 'RadioButton', 'Text', 'ButtonNULL',
              'ButtonCommon', 'ButtonArrow', 'TabButton', 'ImageCheckBox', 'Title')


def decode_xml(data):
    if data[:2] in (b'\xff\xfe', b'\xfe\xff'):
        return data[2:].decode('utf-16-le' if data[:2] == b'\xff\xfe' else 'utf-16-be')
    if data[:3] == b'\xef\xbb\xbf':
        return data[3:].decode('utf-8')
    return data.decode('utf-8')


def est_width(text, font_px):
    """Estimated pixel width of the rendered text at font_px (Noto Sans; TLBB colour/format tokens stripped)."""
    plain = TOK.sub('', text)
    w = 0.0
    for c in plain:
        if HAN.search(c) or ord(c) > 0x2e80:
            w += 1.0
        elif c == ' ':
            w += 0.27
        elif c.isdigit():
            w += 0.55
        elif c.isupper():
            w += 0.62
        elif c in 'ilj|.,:;\'':
            w += 0.26
        elif c in 'mwMW':
            w += 0.82
        else:
            w += 0.51
    return w * font_px


def parse_layout(text):
    """[(type, name, text, font, width_px)] for the windows with a Text property (nested rects resolved)."""
    out = []
    stack = [(SCREEN[0], SCREEN[1])]
    pos = 0
    tag = re.compile(r'<Window\s+Type="([^"]+)"\s+Name="([^"]+)"\s*>|</Window>|<Property\s+Name="([^"]+)"\s+Value="([^"]*)"\s*/>')
    cur = None
    for m in tag.finditer(text):
        if m.group(0) == '</Window>':
            if cur:
                out.append(cur)
                cur = None
            if len(stack) > 1:
                stack.pop()
            continue
        if m.group(1):
            if cur:
                out.append(cur)
            parent = stack[-1]
            cur = {'type': m.group(1), 'name': m.group(2), 'text': None, 'font': '', 'w': parent[0], 'h': parent[1]}
            stack.append((parent[0], parent[1]))
            continue
        if not cur:
            continue
        pn, pv = m.group(3), m.group(4)
        parent = stack[-2] if len(stack) > 1 else stack[-1]
        if pn == 'Text':
            cur['text'] = pv
        elif pn == 'Font':
            cur['font'] = pv
        elif pn == 'UnifiedAreaRect':
            nums = NUMS.findall(pv)          # CY layouts drop closing braces now and then: count numbers only
            if len(nums) == 8:
                xs, xo, ys, yo, xe, xeo, ye, yeo = map(float, nums)
                cur['w'] = (xe - xs) * parent[0] + (xeo - xo)
                cur['h'] = (ye - ys) * parent[1] + (yeo - yo)
                stack[-1] = (cur['w'], cur['h'])
        elif pn == 'UnifiedSize':
            nums = NUMS.findall(pv)
            if len(nums) == 4:
                xs, xo, ys, yo = map(float, nums)
                cur['w'] = xs * parent[0] + xo
                cur['h'] = ys * parent[1] + yo
                stack[-1] = (cur['w'], cur['h'])
        elif pn == 'AbsoluteRect':
            r = ABS4.search(pv)
            if r:
                left, top, right, bottom = map(float, r.groups())
                cur['w'] = right - left
                cur['h'] = bottom - top
                stack[-1] = (cur['w'], cur['h'])
        elif pn == 'AbsoluteSize':
            r = re.search(r'w:' + NUM + r'\s+h:' + NUM, pv)
            if r:
                cur['w'], cur['h'] = float(r.group(1)), float(r.group(2))
                stack[-1] = (cur['w'], cur['h'])
    if cur:
        out.append(cur)
    return [(c['type'], c['name'], c['text'], c['font'], c['w'], c['h']) for c in out if c['text']]


def font_px(font_name):
    m = re.search(r'(\d+(?:\.\d+)?)', font_name or '')
    return float(m.group(1)) if m else 13.0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--layouts', default=','.join(DEFAULT_LAYOUTS))
    ap.add_argument('--all', action='store_true')
    ap.add_argument('--out', default=os.path.join(CYS, 'Build', 'Logs', 'cy_layout_fit.tsv'))
    ap.add_argument('--tolerance', type=float, default=1.0)
    ap.add_argument('--dict', default=DICT)
    args = ap.parse_args()
    vi_dict = GDICT.load_text_dict(args.dict)
    extra = GDICT.Extra()
    zh_dict = {}
    # the CY Chinese source of every key (from the S4 archive) - so the report shows zh next to vi
    try:
        sys.path.insert(0, os.path.join(CYS, 'Docs', 'evidence', 'assetinv'))
        import axp_index as AX
        a = AX.Axp(r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data\Config.axp')
        _, raw = a.payload_full('StrDictionary.txt', 256 << 20)
        a.f.close()
        for kb, vb in GDICT.parse_binary_dbc(raw):
            zh_dict.setdefault(kb.decode('gbk'), vb.decode('gbk', 'replace'))
    except Exception as ex:      # report without zh when the archive is not readable here
        print('zh source unavailable:', ex, file=sys.stderr)
    layouts = []
    if args.all:
        for dp, _d, fs in os.walk(IFACE):
            for fn in fs:
                if fn.lower().endswith('.layout.xml'):
                    layouts.append(os.path.join(dp, fn))
    else:
        for name in args.layouts.split(','):
            p = os.path.join(IFACE, name, name + '.layout.xml')
            if os.path.exists(p):
                layouts.append(p)
    rows = []
    seen = set()
    stats = collections.Counter()
    for path in layouts:
        with open(path, 'rb') as f:
            try:
                text = decode_xml(f.read())
            except UnicodeDecodeError:
                continue
        lname = os.path.basename(path).split('.')[0]
        for typ, name, tval, font, w, h in parse_layout(text):
            short = typ.split('/')[-1]
            if not any(t in short for t in TEXT_TYPES):
                continue
            if h > 40:               # multi-line text windows wrap
                continue
            m = KEYREF.match(tval.strip())
            if m:
                key = m.group(1)
                vi = extra.by_key(key) or vi_dict.get(key)
                zh = zh_dict.get(key, '')
                ident = '#' + key
            else:
                if not HAN.search(TOK.sub('', tval)) and tval not in extra.over_zh:
                    continue
                key, zh = '', tval
                vi = extra.lookup(tval) or tval
                ident = tval
            if vi is None:
                continue
            stats['labels'] += 1
            if HAN.search(TOK.sub('', vi)):
                stats['still_han'] += 1
            fpx = font_px(font)
            est = est_width(vi, fpx)
            if w <= 0 or est <= w * args.tolerance:
                continue
            if (ident, lname) in seen:
                continue
            seen.add((ident, lname))
            stats['overflow'] += 1
            max_chars = max(3, int(w / (fpx * 0.55)))
            rows.append((ident, zh, vi, name, lname, int(w), int(est), max_chars, short))
    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, 'w', encoding='utf-8', newline='\n') as f:
        f.write('ident\tzh\tvi\twindow\tlayout\twidth_px\test_px\tmax_chars\ttype\n')
        for r in sorted(rows, key=lambda r: (r[4], r[3])):
            f.write('\t'.join(str(x) for x in r) + '\n')
    print(dict(stats), 'layouts', len(layouts), '->', args.out)


if __name__ == '__main__':
    main()
