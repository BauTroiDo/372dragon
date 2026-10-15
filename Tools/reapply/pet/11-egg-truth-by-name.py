#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""pet-gc512 (18/09): su that ve trung tran thu CY tren server rieng, do THEO TEN.

Dau vao: configs/CommonItem.txt (ID + ten CY), configs/PetAttrTable.txt (ID + ten tran thu, da nhap 8 651 dong),
scripts/obj/commonitem/300027.lua (g_petList 0.85). Cau hoi cho TUNG trung CY ("...珍兽蛋：X"):
  1. server dispatch no toi file nao (cot 13)?  2. file do co muc g_petList khong?  3. con no ra co ten X khong?
  4. neu sai/thieu: trong PetAttrTable co DUY NHAT mot con ten "X宝宝" (trung thuong) / "变异X" (变异珍兽蛋) / "X" khong?

  wsl -d TLBB -- python3 /mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-18-pet-gc512/scripts/11-egg-truth-by-name.py
"""
import io, re, os, collections, json

R = '/home/ubuntu/cys-test-20260913'
CFG = os.path.join(R, 'configs')
ITEM_DIR = os.path.join(R, 'Game_2', 'Script', 'scripts', 'obj', 'commonitem')
OUT = '/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-18-pet-gc512'


def rd(p):
    return io.open(p, 'rb').read().decode('gbk', 'replace').replace('\r\n', '\n')


items = {}
for l in rd(os.path.join(CFG, 'CommonItem.txt')).split('\n'):
    c = l.split('\t')
    if len(c) > 13 and re.fullmatch(r'\d+', c[0].strip()):
        items[int(c[0])] = {'name': c[6].strip(), 'lv': c[8].strip(), 'script': c[13].strip()}
pets = {}
by_name = collections.defaultdict(list)
for l in rd(os.path.join(CFG, 'PetAttrTable.txt')).split('\n'):
    c = l.split('\t')
    if len(c) > 2 and re.fullmatch(r'\d+', c[0].strip()):
        pets[int(c[0])] = c[1].strip()
        by_name[c[1].strip()].append(int(c[0]))

# g_petList of every dispatched-able file: item -> list of (file, pet ids, type, level, line)
entries = collections.defaultdict(list)
files_present = set(fn[:-4] for fn in os.listdir(ITEM_DIR) if fn.endswith('.lua'))
for fn in sorted(os.listdir(ITEM_DIR)):
    if not fn.endswith('.lua'):
        continue
    src = rd(os.path.join(ITEM_DIR, fn))
    if 'g_petList' not in src:
        continue
    for m in re.finditer(r'^(g_petList\[(\d+)\]\s*=\s*\{\s*type=(\d+),\s*dataId=(\d+)(?:,\s*level=(\d+))?[^\n]*)$', src, re.M):
        entries[int(m.group(2))].append({'file': fn, 'pets': [int(m.group(4))], 'type': m.group(3), 'level': m.group(5) or '', 'line': m.group(1).strip()})
    multi = collections.defaultdict(list)
    for m in re.finditer(r'g_petList\[(\d+)\]\.dataIds\[\d+\]\s*=\s*\{dataId=(\d+)', src):
        multi[int(m.group(1))].append(int(m.group(2)))
    for item, ids in multi.items():
        entries[item].append({'file': fn, 'pets': ids, 'type': 'multi', 'level': '', 'line': ''})

egg_re = re.compile(r'珍兽蛋')
eggs = {i: m for i, m in items.items() if egg_re.search(m['name'])}
print('CY items with 珍兽蛋 in the name:', len(eggs))
print('by script column:', collections.Counter(m['script'] for m in eggs.values()))


def split_core(iname):
    for sep in ('：', ':'):
        if sep in iname:
            return iname.split(sep, 1)[1].strip()
    return iname.strip()


def wanted_names(iname):
    core = split_core(iname)
    if iname.startswith('变异'):
        return ['变异' + core, core, core + '宝宝']
    return [core + '宝宝', core, '变异' + core]


def pet_matches(iname, pname):
    core = split_core(iname)
    return core and (core in pname)


rows = []
cls = collections.Counter()
for item in sorted(eggs):
    m = eggs[item]
    sfile = m['script'] + '.lua'
    have_file = m['script'] in files_present
    ents = [e for e in entries.get(item, []) if e['file'] == sfile]
    other = [e for e in entries.get(item, []) if e['file'] != sfile]
    hatch = [(pid, pets.get(pid, '?')) for e in ents for pid in e['pets']]
    ok = bool(hatch) and all(pet_matches(m['name'], pn) for _, pn in hatch)
    cand = []
    for wn in wanted_names(m['name']):
        if wn in by_name:
            cand = [(pid, wn) for pid in by_name[wn]]
            break
    if not have_file:
        k = 'script_file_missing'
    elif not ents:
        k = 'no_entry_in_dispatched_file'
    elif ok:
        k = 'OK_name_matches'
    else:
        k = 'entry_hatches_other_pet'
    cls[k] += 1
    rows.append({'item': item, 'name': m['name'], 'lv': m['lv'], 'script': m['script'], 'class': k,
                 'hatch': hatch, 'other_files': [(e['file'], e['pets']) for e in other],
                 'candidates_by_name': cand, 'lines': [e['line'] for e in ents]})
print(json.dumps(cls, ensure_ascii=False))
with io.open(os.path.join(OUT, 'egg-truth-by-name.json'), 'w', encoding='utf-8') as f:
    json.dump({'eggs': len(eggs), 'classes': cls, 'rows': rows}, f, ensure_ascii=False, indent=1)
with io.open(os.path.join(OUT, 'egg-truth-by-name.tsv'), 'w', encoding='utf-8', newline='\n') as f:
    f.write('item\tname\tlv\tscript\tclass\thatch\tcandidates_by_name\tother_files\n')
    for r in rows:
        f.write('%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' % (r['item'], r['name'], r['lv'], r['script'], r['class'],
                json.dumps(r['hatch'], ensure_ascii=False), json.dumps(r['candidates_by_name'], ensure_ascii=False),
                json.dumps(r['other_files'], ensure_ascii=False)))
for k in ('entry_hatches_other_pet', 'no_entry_in_dispatched_file', 'script_file_missing'):
    print('---', k)
    for r in rows:
        if r['class'] == k:
            print(r['item'], r['name'], 'lv', r['lv'], 'script', r['script'], 'hatch', r['hatch'], 'cand', r['candidates_by_name'], 'other', r['other_files'])
