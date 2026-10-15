#!/usr/bin/env python3
"""CY-Source Tools/game/dbc_compare_cy.py - DBC tables of CY 3.71.9609 (S4 Config.axp, S2 text) against the
Canonical/client_GL tables that Game.exe loads today (Registry/abi/dbc_inventory_gl.json).

Read only: S4 Config.axp is read in memory through Docs/evidence/assetinv/axp_index.py; S2 and Canonical files are
opened read-only. Output:
  Registry/abi/dbc_columns_cy.tsv      one row per CY column of every Game.exe table: type, CY header name (S2),
                                       aligned GL column (value agreement on common IDs) + GL struct member
  <out>/dbc_compare_cy.tsv             one row per Game.exe table: columns/rows/types/ID sets GL vs CY
  <out>/dbc_census_cy.tsv / .json      all tables by name: CY only / GL only / both (+ same column count)

Usage: python -B Tools/game/dbc_compare_cy.py --out <dir> [--registry Registry/abi]
"""
import argparse
import collections
import csv
import json
import os
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
MAIN = Path(r'C:\TLBB\085\CY-Source')
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(REPO / 'Docs' / 'evidence' / 'assetinv'))
import dbc_inventory as INV  # noqa: E402
import axp_index as AX  # noqa: E402

S4_CONFIG = Path(r'C:\TLBB\085\Tools\DATA NEW\CY Game\Data\Config.axp')
S2_CONFIG = Path(r'C:\TLBB\085\Tools\DATA NEW\DataCY31-08-26\Config')
GL_CONFIG = MAIN / 'Assets' / 'Canonical' / 'Data' / 'ConfigFolder'
INVENTORY = REPO / 'Registry' / 'abi' / 'dbc_inventory_gl.json'
GL_COLUMNS = REPO / 'Registry' / 'abi' / 'dbc_columns_gl.tsv'


class BytesTable(INV.Table):
    """INV.Table over in-memory bytes (the class reads a path)."""

    def __init__(self, raw, label, keep_rows=True):
        with tempfile.NamedTemporaryFile(delete=False, suffix='.txt') as f:
            f.write(raw)
            tmp = f.name
        try:
            super().__init__(tmp, keep_rows)
        finally:
            os.unlink(tmp)
        self.path = Path(label)


def ids_of(t):
    return [r[0] for r in t.rows]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--registry', default=str(REPO / 'Registry' / 'abi'))
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    inv = json.loads(INVENTORY.read_text(encoding='utf-8'))
    loaded = [r for r in inv['tables'] if 'ours' in r or 'other' in r]
    glcols = collections.defaultdict(dict)
    with open(GL_COLUMNS, encoding='utf-8') as f:
        for r in csv.DictReader(f, delimiter='\t'):
            glcols[r['file']][int(r['column'])] = (r['struct'], r['member'])

    axp = AX.Axp(str(S4_CONFIG))
    s4_list = {n.lower(): n for n, _ in (axp.file_list() or [])}

    def s4_table(name):
        real = s4_list.get(name.lower())
        if not real:
            return None
        got = axp.payload_full(real, maxlen=512 << 20)
        return None if got is None else BytesTable(got[1], 'S4:Config.axp:' + real)

    def s2_table(name):
        p = S2_CONFIG / name.replace('/', os.sep)
        return INV.Table(p) if p.is_file() else None

    def gl_table(name):
        p = GL_CONFIG / name.replace('/', os.sep)
        return INV.Table(p) if p.is_file() else None

    rows, colrows = [], []
    for rec in sorted(loaded, key=lambda r: r['file']):
        name = rec['file']
        if name.startswith('<'):
            continue
        gl, cy, s2 = gl_table(name), s4_table(name), s2_table(name)
        row = {'file': name, 'loader': 'OpenAllDataBase' if 'ours' in rec else 'other',
               'gl_format': gl.format if gl else '', 'gl_cols': len(gl.types) if gl else '',
               'gl_rows': gl.records if gl else '', 'cy_format': cy.format if cy else '',
               'cy_cols': len(cy.types) if cy else '', 'cy_rows': cy.records if cy else '',
               's2_cols': len(s2.types) if s2 else '', 's2_rows': s2.records if s2 else ''}
        if gl and cy:
            row['same_cols'] = int(len(gl.types) == len(cy.types))
            row['same_types'] = int(gl.types == cy.types)
            gi, ci = set(ids_of(gl)), set(ids_of(cy))
            row['ids_common'] = len(gi & ci)
            row['ids_gl_only'] = len(gi - ci)
            row['ids_cy_only'] = len(ci - gi)
            pairs, common = INV.align(cy, gl) if len(gi & ci) else ([], 0)
            row['aligned_by_values'] = len(pairs)
            # fill gaps between value-aligned anchors when both gaps have the same length and the same column types
            # (constant columns never align by values); marked with score 'gap'
            anchors = [(-1, -1)] + [(a, b) for a, b, s in pairs] + [(len(cy.types), len(gl.types))]
            filled = []
            for (a0, b0), (a1, b1) in zip(anchors, anchors[1:]):
                if a1 - a0 == b1 - b0 and a1 - a0 > 1 and \
                        all(cy.types[a0 + k] == gl.types[b0 + k] for k in range(1, a1 - a0)):
                    filled += [[a0 + k, b0 + k, 'gap'] for k in range(1, a1 - a0)]
            pairs = sorted(pairs + filled)
            row['aligned_cols'] = len(pairs)
            row['cy_cols_unmapped'] = len(cy.types) - len(pairs)
            row['gl_cols_unmapped'] = len(gl.types) - len(pairs)
            row['identity_map'] = int(all(a == b for a, b, s in pairs) and len(pairs) == len(cy.types) == len(gl.types))
            # identical content check on common IDs over aligned columns
            gmap = {r[0]: r for r in gl.rows}
            diff_rows = 0
            for r in cy.rows:
                g = gmap.get(r[0])
                if g is not None and (len(r) != len(g) or any(r[a] != g[b] for a, b, s in pairs)):
                    diff_rows += 1
            row['common_rows_differing'] = diff_rows
            amap = {a: (b, s) for a, b, s in pairs}
        else:
            amap = {}
        names = (s2.names if s2 and s2.names and cy and len(s2.types) == len(cy.types) else None)
        if cy:
            for c, t in enumerate(cy.types):
                b, s = amap.get(c, ('', ''))
                st, mem = glcols.get(name, {}).get(b, ('', '')) if b != '' else ('', '')
                colrows.append((name, c, t, (names[c] if names and c < len(names) else ''), b, s, st, mem))
        rows.append(row)

    hdr = ['file', 'loader', 'gl_format', 'gl_cols', 'gl_rows', 'cy_format', 'cy_cols', 'cy_rows', 's2_cols',
           's2_rows', 'same_cols', 'same_types', 'ids_common', 'ids_gl_only', 'ids_cy_only', 'aligned_by_values',
           'aligned_cols',
           'cy_cols_unmapped', 'gl_cols_unmapped', 'identity_map', 'common_rows_differing']
    with open(out / 'dbc_compare_cy.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('\t'.join(hdr) + '\n')
        for r in rows:
            f.write('\t'.join(str(r.get(h, '')) for h in hdr) + '\n')
    with open(Path(args.registry) / 'dbc_columns_cy.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('# CY 3.71.9609 (S4 Config.axp) columns of the tables Game.exe loads. CY client tables carry no column\n'
                '# names (S2 text header row 2 repeats the types), so cy_name is empty unless S2 has a name row;\n'
                '# gl_column = aligned client_GL column: value agreement on common IDs (Tools/game/dbc_inventory.align,\n'
                '# score 0..1) or align_score "gap" = equal-length, equal-type gap between two value anchors;\n'
                '# generated by Tools/game/dbc_compare_cy.py\n')
        f.write('file\tcy_column\ttype\tcy_name\tgl_column\talign_score\tgl_struct\tgl_member\n')
        for r in colrows:
            f.write('\t'.join(str(x).replace('\t', ' ').replace('\n', ' ') for x in r) + '\n')

    # census of all tables by name
    gl_all = {str(p.relative_to(GL_CONFIG)).replace('\\', '/').lower() for p in GL_CONFIG.rglob('*.txt')}
    cy_all = {n for n in s4_list if n.endswith('.txt')}
    both = gl_all & cy_all
    census = {'cy_tables': len(cy_all), 'gl_tables': len(gl_all), 'both': len(both), 'cy_only': len(cy_all - gl_all),
              'gl_only': len(gl_all - cy_all)}
    same_cols = 0
    ctsv = []
    for n in sorted(gl_all | cy_all):
        g = gl_table(n) if n in gl_all else None
        c = s4_table(n) if n in cy_all else None
        gc = len(g.types) if g else ''
        cc = len(c.types) if c else ''
        if g and c and gc == cc:
            same_cols += 1
        ctsv.append((n, 'both' if g and c else ('gl_only' if g else 'cy_only'), gc, g.records if g else '', cc,
                     c.records if c else ''))
    census['both_same_column_count'] = same_cols
    loaded_stats = collections.Counter()
    for r in rows:
        if r.get('cy_format'):
            loaded_stats['cy_present'] += 1
        if r.get('same_cols') == 1:
            loaded_stats['same_cols'] += 1
        if r.get('same_types') == 1:
            loaded_stats['same_types'] += 1
        if r.get('identity_map') == 1:
            loaded_stats['identity_map'] += 1
        if r.get('common_rows_differing') == 0 and r.get('ids_cy_only') == 0 and r.get('ids_gl_only') == 0 and \
                r.get('identity_map') == 1:
            loaded_stats['identical_content'] += 1
    census['game_exe_tables'] = len(rows)
    census['game_exe_tables_stats'] = dict(loaded_stats)
    with open(out / 'dbc_census_cy.tsv', 'w', encoding='utf-8', newline='\n') as f:
        f.write('table\tpresence\tgl_cols\tgl_rows\tcy_cols\tcy_rows\n')
        for r in ctsv:
            f.write('\t'.join(str(x) for x in r) + '\n')
    (out / 'dbc_census_cy.json').write_text(json.dumps(census, ensure_ascii=False, indent=1), encoding='utf-8')
    print(json.dumps(census, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
