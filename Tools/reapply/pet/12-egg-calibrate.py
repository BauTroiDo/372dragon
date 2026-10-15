#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""pet-gc512: hieu chuan quy tac "trung lv L, ten X -> dong PetAttrTable nao" bang 274 trung DA DUNG.
In header PetAttrTable, vai dong mau, va cot nao cua dong tran thu bang lv cua trung o nhom OK.

  wsl -d TLBB -- python3 /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-18-pet-gc512/scripts/12-egg-calibrate.py
"""
import io, re, os, json, collections

R = '/home/ubuntu/cys-test-20260913'
CFG = os.path.join(R, 'configs')
OUT = '/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-18-pet-gc512'


def rd(p):
    return io.open(p, 'rb').read().decode('gbk', 'replace').replace('\r\n', '\n')


lines = rd(os.path.join(CFG, 'PetAttrTable.txt')).split('\n')
hdr = [l.split('\t') for l in lines[:3]]
print('header rows:')
for h in hdr:
    print('  ', ' | '.join('%d:%s' % (i, c.strip()) for i, c in enumerate(h)))
rows = {}
for l in lines:
    c = l.split('\t')
    if len(c) > 2 and re.fullmatch(r'\d+', c[0].strip()):
        rows[int(c[0])] = [x.strip() for x in c]
print('rows', len(rows))
print('sample 3000..3020:')
for pid in range(3000, 3021):
    if pid in rows:
        print('  ', pid, rows[pid][:12])
print('sample 咩小萌宝宝:')
for pid, r in rows.items():
    if r[1] == '咩小萌宝宝':
        print('  ', pid, r[:12])

truth = json.load(io.open(os.path.join(OUT, 'egg-truth-by-name.json'), encoding='utf-8'))
ok = [r for r in truth['rows'] if r['class'] == 'OK_name_matches']
colhits = collections.Counter()
diffs = collections.Counter()
for r in ok:
    lv = r['lv']
    for pid, _ in r['hatch']:
        row = rows.get(pid)
        if not row:
            continue
        for i, c in enumerate(row):
            if c == lv:
                colhits[i] += 1
print('columns equal to egg lv over OK eggs:', colhits.most_common(8))
# candidate level column: the most frequent one
if colhits:
    col = colhits.most_common(1)[0][0]
    for r in ok:
        for pid, _ in r['hatch']:
            row = rows.get(pid)
            if row:
                try:
                    diffs[int(row[col]) - int(r['lv'])] += 1
                except ValueError:
                    diffs['nan'] += 1
    print('pet[col %d] - egg lv distribution:' % col, diffs.most_common(10))
# multiplicity of same-name pets
names = collections.Counter(r[1] for r in rows.values())
print('pet names total', len(names), 'with >1 ids', sum(1 for n, c in names.items() if c > 1))
