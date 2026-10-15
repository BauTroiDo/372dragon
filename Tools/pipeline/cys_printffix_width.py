# -*- coding: utf-8 -*-
"""CYS-PRINTFFIX: `％` (U+FF05) co GLYPH khong, va no rong hon `%` bao nhieu?

Dung dung bo do be rong cua `ui-fit` (FreeType, giong Font_FreeType cua CEGUI).

Chay: python -X utf8 Tools/pipeline/cys_printffix_width.py --out <file>.json
"""
import argparse
import io
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, '..', '..'))
sys.path.insert(0, os.path.join(REPO, 'Tools', 'ui-fit'))
sys.path.insert(0, HERE)

FW = u'％'   # ％
AS = u'%'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out')
    a = ap.parse_args()
    import cys_i18nscope_collide_fix as CF
    fonts = CF.load_fonts()
    rows = {}
    for name in sorted(fonts):
        f = fonts[name]
        rows[name] = {
            'pt': f.pt_size,
            'file': os.path.basename(f.path),
            'has_fullwidth': bool(f.has_glyph(FW)),
            'has_ascii': bool(f.has_glyph(AS)),
            'adv_fullwidth': f.advance(FW),
            'adv_ascii': f.advance(AS),
            'adv_space': f.advance(u' '),
        }
        # `50% gia` -> `50％ gia`: `% ` (2 ky tu) doi thanh `％ ` (2 ky tu)
        rows[name]['delta_px_per_site'] = rows[name]['adv_fullwidth'] - rows[name]['adv_ascii']
    missing = [n for n in rows if not rows[n]['has_fullwidth']]
    worst = max(rows.values(), key=lambda r: r['delta_px_per_site'])
    out = {'fonts': rows,
           'summary': {'n_fonts': len(rows),
                       'fonts_missing_fullwidth': missing,
                       'max_delta_px_per_site': worst['delta_px_per_site'],
                       'deltas': sorted(set(r['delta_px_per_site'] for r in rows.values()))}}
    if a.out:
        with io.open(a.out, 'w', encoding='utf-8') as fh:
            json.dump(out, fh, ensure_ascii=False, indent=1)
        print('da ghi', a.out)
    print(json.dumps(out['summary'], ensure_ascii=False, indent=1))
    for n in sorted(rows):
        r = rows[n]
        print('  %-18s pt=%-5s %-22s fullwidth=%s  %%=%dpx  ％=%dpx  delta=%+dpx'
              % (n, r['pt'], r['file'], 'CO ' if r['has_fullwidth'] else 'KHONG',
                 r['adv_ascii'], r['adv_fullwidth'], r['delta_px_per_site']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
