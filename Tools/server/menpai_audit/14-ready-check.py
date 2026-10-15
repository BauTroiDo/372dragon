# chỉ đọc: mô phỏng một phần menpai_registry.check_ready bằng Python trên bảng server riêng (phái 0-15)
import json, os, re, subprocess, sys
sys.path.insert(0, os.path.dirname(__file__))
from tlbbtab import load, num, R

cfg = open(R + '/GameServer/lualib/cfghelper.lua', encoding='utf-8', errors='replace').read()
for name in ('read_base_value_table', 'read_attr_level_up_table', 'read_ability'):
    m = re.search(r'function cfghelper:%s\(\).*?load\("([^"]+)"' % name, cfg, re.S)
    print(name, m.group(1) if m else None)

st = json.load(open(os.path.join(os.path.dirname(__file__), '..', 'static-menpai.json'), encoding='utf-8'))
tn, trows = load(R + '/configs/SkillTemplate_V1.txt')
dn, drows = load(R + '/configs/SkillData_V1.txt')
sd_ids = {num(r[dn[0]]) for r in drows}
lvl_cols = [n for n in tn if re.match(r'心法(\d+)级对应的实际技能ID', n)]
print('level columns', len(lvl_cols), lvl_cols[:3])
sn, srows = load(R + '/configs/XinFaStudySpend_V1.txt')
pairs = len(srows[0]['消耗金钱']) if isinstance(srows[0]['消耗金钱'], list) else 1
print('XinFaStudySpend rows', len(srows), 'money columns', pairs, 'levels', [num(r['学习等级']) for r in srows[:4]], '...', num(srows[-1]['学习等级']))
ext = {11: dict(x7=87, x8=88, s7=[2921, 2922, 2923], qg=2942, quick=[2900, 2901, 2902]),
       12: dict(x7=95, x8=96, s7=[3451, 3452, 3453], qg=3518, quick=[3430, 3431, 3432]),
       13: dict(x7=103, x8=104, s7=[3821, 3822, 3823], qg=3836, quick=[3800, 3801, 3802]),
       14: dict(x7=111, x8=112, s7=[4542, 4543, 4544], qg=4547, quick=[4515, 4516, 4517])}
tmpl = {num(r['ID,(技能系的ID)']): r for r in trows}
out = {}
for mp in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '10', '11', '12', '13', '14', '15']:
    m = st[mp]; errs = []
    ids = sorted(x['id'] for x in m['xinfa'])
    if len(ids) != 8: errs.append('eight_xinfa_required:%d' % len(ids))
    if ids[6:8] != list(m['xinfa78']): errs.append('xinfa_order_mismatch %s vs %s' % (ids[6:8], m['xinfa78']))
    for x in ids:
        if x + 1 > pairs: errs.append('missing_xinfa_cost col %d' % (x + 1)); break
    miss_sd = []
    for s in m['skills']:
        r = tmpl[s['id']]
        for c in lvl_cols[:12]:
            v = num(r[c])
            if v is None or v not in sd_ids:
                miss_sd.append((s['id'], c, r[c])); break
        if s['xinfa'] not in (-1, None) and s['xinfa'] not in ids:
            errs.append('foreign_xinfa:%s' % s['id'])
    if miss_sd: errs.append('missing_skill_data x%d e.g. %s' % (len(miss_sd), miss_sd[:3]))
    if int(mp) in ext:
        e = ext[int(mp)]; own = {s['id']: s for s in m['skills']}
        for k in e['s7']:
            if k not in own or own[k]['xinfa'] != e['x7']: errs.append('invalid_special_skill:%d' % k)
        if e['qg'] not in own: errs.append('invalid_qinggong_skill')
        for k in e['quick']:
            if k not in own: errs.append('invalid_quick_skill:%d' % k)
    out[mp] = errs
    print(mp, m['name'], 'OK' if not errs else errs)
json.dump(out, open(os.path.join(os.path.dirname(__file__), '..', 'ready-check.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
