# -*- coding: utf-8 -*-
"""table_keys.py - restore resource-key cells of client tables to GBK (CY-Source data track D1).

Why: the 2026-08-24 UTF-8 migration converted display text of the client tables to UTF-8, and with it some
RESOURCE KEY columns (material / obj / mesh / skeleton / texture / effect / particle / locator names). The
engine passes table bytes through unchanged while all.material / all.obj / all.effect / file names are GBK
(Docs/08 muc 1.2-1.4), so such a key never resolves (e.g. ItemVisualChar material cells, avatar composer
R16: colour variants render with the wrong material).

Rule, evidence-based:
  cell    a STRING cell whose bytes are non-ASCII valid UTF-8 is split into tokens at ';' ',' ':' '|' and
          white space. A token "resolves" when its bytes name a material (all.material + MaterialTemplates.zip),
          object (all.obj, case-insensitive), effect, particle system, skill, locator (all.obj <Locator name>)
          or file (any file of the data root, case-insensitive base name).
          convert = every non-ASCII token resolves once re-encoded as GBK (gb18030 if gbk cannot) and not as
          UTF-8; display = no token does; partial = some do; resolves-as-is = the UTF-8 bytes already resolve.
  column  a (table, column) is a KEY column when convert / (convert + partial + display) >= 0.5 and
          convert >= 5; a column with fewer convert cells is a key column only if it resolves to the kind
          of a strong key column of the same table (the colour-slot columns of ItemVisualChar). Display
          columns whose short names happen to equal a resource name (mount names such as "虎", monster
          names, StrReplace) therefore stay UTF-8.
  change  in a key column every non-ASCII UTF-8 cell (convert, partial, display) is re-encoded to GBK as a
          whole; the names that still do not resolve are reported (missing material etc.).
Writing: DBC tables (00 CC BB DD) - new GBK strings appended to the string pool, cells repointed, pool-size
field updated; nothing else moves. Text tables - cell bytes replaced in place (tabs, CRLF untouched). The
input is always the BASE table bytes, so the result is deterministic.

  python table_keys.py --data <Data root> [--report out.tsv]      read-only plan
"""
import argparse
import collections
import os
import re
import struct
import sys
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
TESTS = os.path.join(os.path.dirname(os.path.dirname(HERE)), 'Tests')
for _p in (HERE, TESTS):
    if _p not in sys.path:
        sys.path.insert(0, _p)
import tlbbfmt as F  # noqa: E402
from validators import common as VC  # noqa: E402

DBC_MAGIC = b'\x00\xcc\xbb\xdd'
_SPLIT = re.compile(rb'([;,:|\s]+)')
_INT_CELL = re.compile(rb'\s*-?\d+\s*$')
STRONG_MIN = 5
KEY_RATIO = 0.5


class Resolver:
    """Name sets of one data root; scripts may be given as bytes (planned state)."""

    def __init__(self, root, scripts=None, extra_files=()):
        scripts = scripts or {}

        def script(kind):
            if kind in scripts:
                return scripts[kind]
            with open(os.path.join(root, VC.SCRIPTS[kind]), 'rb') as f:
                return f.read()
        self.sets = {}
        for kind in ('material', 'effect', 'particle', 'skill'):
            names = set()
            blocks, _ = VC.script_spans(script(kind))
            for hdr, s, e in blocks:
                nm, _p = VC.def_name(kind, hdr)
                if nm:
                    names.add(nm)
            self.sets[kind] = names
        mats = set(VC.BUILTIN_MATS)
        zp = os.path.join(root, VC.TEMPLATES_ZIP)
        if os.path.exists(zp):
            with zipfile.ZipFile(zp) as z:
                for n in z.namelist():
                    if n.lower().endswith('.material'):
                        for m in re.finditer(rb'(?m)^\s*(?:abstract\s+)?material\s+([^\s:{]+)', z.read(n)):
                            mats.add(m.group(1))
        self.sets['material'] |= mats
        objdata = script('obj')
        self.sets['obj'] = {nm.lower() for nm, s, e in VC.obj_spans(objdata)}
        self.sets['locator'] = set(re.findall(rb'<Locator\s+name="([^"]*)"', objdata))
        files = set()
        for dp, dn, fn in os.walk(root):
            for f in fn:
                files.add(F.key_of(VC.gbk_name(f)))
        for f in extra_files:
            files.add(F.key_of(F.base_of(f)))
        self.sets['file'] = files

    def kinds(self, token):
        out = [k for k in ('material', 'effect', 'particle', 'skill', 'locator') if token in self.sets[k]]
        if token.lower() in self.sets['obj']:
            out.append('obj')
        if F.key_of(F.base_of(token)) in self.sets['file']:
            out.append('file')
        return out


def to_gbk(u):
    s = u.decode('utf-8')
    for codec in ('gbk', 'gb18030'):
        try:
            return s.encode(codec)
        except UnicodeEncodeError:
            continue
    return None


def analyse(cell, res):
    """-> dict(status, new, tokens=[(gbk token, kinds)], unresolved=[gbk tokens]) for a STRING cell."""
    if not any(b >= 0x80 for b in cell):
        return {'status': 'ascii'}
    try:
        cell.decode('utf-8')
    except UnicodeDecodeError:
        return {'status': 'gbk'}
    parts = _SPLIT.split(cell)
    out, toks, unresolved = [], [], []
    ok = bad = asis = 0
    for i, p in enumerate(parts):
        if i % 2 == 1 or not any(b >= 0x80 for b in p):
            out.append(p)
            continue
        if res.kinds(p):
            asis += 1
        g = to_gbk(p)
        if g is None:
            return {'status': 'unencodable'}
        kg = res.kinds(g)
        toks.append((g, kg))
        if kg:
            ok += 1
        else:
            bad += 1
            unresolved.append(g)
        out.append(g)
    if asis:
        status = 'resolves-as-is'
    elif ok and not bad:
        status = 'convert'
    elif ok:
        status = 'partial'
    else:
        status = 'display'
    return {'status': status, 'new': b''.join(out), 'tokens': toks, 'unresolved': unresolved}


# ------------------------------------------------------------------ table walking
def parse_dbc(raw):
    nf, nr, psz = struct.unpack_from('<3I', raw, 4)
    codes = struct.unpack_from('<%dI' % nf, raw, 16)
    start = 16 + 4 * nf
    return nf, nr, psz, codes, start, start + 4 * nf * nr


def iter_string_cells(raw):
    """-> (fmt, [(row, id, col, bytes)]) for every STRING cell (DBC type 2; text: non INT/FLOAT columns)."""
    cells = []
    if raw[:4] == DBC_MAGIC:
        nf, nr, psz, codes, start, pool_off = parse_dbc(raw)
        pool = raw[pool_off:]
        vals = struct.unpack_from('<%di' % (nf * nr), raw, start)
        for r in range(nr):
            rid = vals[r * nf] if codes[0] == 0 else None
            for c in range(nf):
                if codes[c] != 2:
                    continue
                off = vals[r * nf + c] & 0xFFFFFFFF
                if off >= len(pool):
                    continue
                e = pool.find(b'\x00', off)
                cells.append((r, rid, c, pool[off:e if e >= 0 else len(pool)]))
        return 'dbc', cells
    lines = raw.split(b'\n')
    types = [t.strip().upper() for t in lines[0].rstrip(b'\r').split(b'\t')] if lines else []
    for li, ln in enumerate(lines[1:], 1):
        body = ln[:-1] if ln.endswith(b'\r') else ln
        if not body:
            continue
        cv = body.split(b'\t')
        if not _INT_CELL.match(cv[0]):
            continue
        rid = int(cv[0])
        for c, v in enumerate(cv):
            if c < len(types) and types[c] in (b'INT', b'FLOAT'):
                continue
            cells.append((li, rid, c, v))
    return 'text', cells


def plan_table(raw, res):
    """-> (fmt, changes, columns). changes: dicts row,id,col,old,new,status,unresolved,tokens."""
    fmt, cells = iter_string_cells(raw)
    per = collections.defaultdict(list)
    for r, rid, c, v in cells:
        a = analyse(v, res)
        if a['status'] in ('ascii', 'gbk'):
            continue
        per[c].append((r, rid, v, a))
    columns = {}
    for c, lst in per.items():
        st = collections.Counter(a['status'] for _r, _i, _v, a in lst)
        denom = st['convert'] + st['partial'] + st['display']
        kinds = collections.Counter(k for _r, _i, _v, a in lst if a['status'] == 'convert'
                                    for _t, ks in a['tokens'] for k in ks[:1])
        columns[c] = {'counts': dict(st), 'ratio': (st['convert'] / denom) if denom else 0.0,
                      'kind': kinds.most_common(1)[0][0] if kinds else '', 'key': False}
    strong_kinds = set()
    for c, info in columns.items():
        if info['ratio'] >= KEY_RATIO and info['counts'].get('convert', 0) >= STRONG_MIN:
            info['key'] = True
            strong_kinds.add(info['kind'])
    for c, info in columns.items():
        if not info['key'] and info['ratio'] >= KEY_RATIO and info['counts'].get('convert', 0) >= 1 \
                and info['kind'] in strong_kinds:
            info['key'] = True
            info['weak'] = True
    changes = []
    for c, lst in per.items():
        if not columns[c]['key']:
            continue
        for r, rid, v, a in lst:
            if a['status'] in ('convert', 'partial', 'display'):
                changes.append({'row': r, 'id': rid, 'col': c, 'old': v, 'new': a['new'], 'status': a['status'],
                                'unresolved': a['unresolved'], 'tokens': a['tokens']})
    changes.sort(key=lambda x: (x['row'], x['col']))
    return fmt, changes, columns


def apply_changes(raw, fmt, changes):
    """New table bytes with the changes applied (see module doc)."""
    if not changes:
        return raw
    if fmt == 'dbc':
        nf, nr, psz, codes, start, pool_off = parse_dbc(raw)
        out = bytearray(raw)
        add = bytearray()
        offsets = {}
        base = len(raw) - pool_off
        for ch in changes:
            new = ch['new']
            if new not in offsets:
                offsets[new] = base + len(add)
                add += new + b'\x00'
            struct.pack_into('<I', out, start + 4 * (ch['row'] * nf + ch['col']), offsets[new])
        out += add
        struct.pack_into('<I', out, 12, psz + len(add))
        return bytes(out)
    lines = raw.split(b'\n')
    by_line = collections.defaultdict(dict)
    for ch in changes:
        by_line[ch['row']][ch['col']] = ch
    for li, mods in by_line.items():
        ln = lines[li]
        cr = ln.endswith(b'\r')
        cells = (ln[:-1] if cr else ln).split(b'\t')
        for c, ch in mods.items():
            if cells[c] != ch['old']:
                raise ValueError('table cell differs from the plan: line %d col %d' % (li, c))
            cells[c] = ch['new']
        lines[li] = b'\t'.join(cells) + (b'\r' if cr else b'')
    return b'\n'.join(lines)


def plan_folder(cfg_dir, res):
    """All *.txt tables of a ConfigFolder -> {rel: dict(fmt, raw, changes, columns)} (tables with changes)."""
    out = {}
    for dp, dn, fn in os.walk(cfg_dir):
        dn.sort()
        for f in sorted(fn):
            if not f.lower().endswith('.txt'):
                continue
            rel = os.path.relpath(os.path.join(dp, f), cfg_dir)
            with open(os.path.join(dp, f), 'rb') as fh:
                raw = fh.read()
            try:
                fmt, changes, columns = plan_table(raw, res)
            except (struct.error, ValueError, IndexError):
                continue
            if changes:
                out[rel] = {'fmt': fmt, 'raw': raw, 'changes': changes, 'columns': columns}
    return out


def tsv_rows(plan, prefix='ConfigFolder\\'):
    for rel, t in sorted(plan.items()):
        for ch in t['changes']:
            yield (prefix + rel, t['fmt'], ch['row'], ch['id'], ch['col'],
                   'resolved' if not ch['unresolved'] else 'unresolved',
                   ch['old'].decode('utf-8', 'replace'), ch['old'].hex(), ch['new'].hex(),
                   '; '.join('%s=%s' % (VC.disp(t_), '/'.join(k) or 'MISSING') for t_, k in ch['tokens']))


TSV_HEADER = ('table', 'format', 'row', 'id', 'col', 'check', 'old_text', 'old_hex_utf8', 'new_hex_gbk',
              'tokens (gbk name = resolves in)')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', required=True)
    ap.add_argument('--report')
    a = ap.parse_args()
    res = Resolver(a.data)
    plan = plan_folder(os.path.join(a.data, 'ConfigFolder'), res)
    tot = collections.Counter()
    for rel, t in sorted(plan.items()):
        keys = {c: '%s %.2f %s%s' % (i['kind'], i['ratio'], i['counts'], ' weak' if i.get('weak') else '')
                for c, i in t['columns'].items() if i['key']}
        un = sum(1 for ch in t['changes'] if ch['unresolved'])
        tot['cells'] += len(t['changes'])
        tot['unresolved'] += un
        print('%-28s %-4s %5d cells (%d unresolved) key columns %s' % (rel, t['fmt'], len(t['changes']), un, keys))
    print('totals', dict(tot))
    if a.report:
        with open(a.report, 'w', encoding='utf-8-sig', newline='\n') as f:
            f.write('\t'.join(TSV_HEADER) + '\n')
            for r in tsv_rows(plan):
                f.write('\t'.join(str(x) for x in r) + '\n')


if __name__ == '__main__':
    main()
