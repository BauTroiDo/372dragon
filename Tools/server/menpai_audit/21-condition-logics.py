# chỉ đọc: logic điều kiện/tiêu hao (条件和消耗逻辑) mà SkillData kỹ năng 15 phái dùng nhưng condition_delplete_core chưa đăng ký
import json, os, re, sys, collections
sys.path.insert(0, os.path.dirname(__file__))
from tlbbtab import load, num, R
src = open(R + '/GameServer/services/scene/skill/condition_delplete_core.lua', encoding='utf-8', errors='replace').read()
dfn = open(R + '/GameServer/lualib/define.lua', encoding='utf-8', errors='replace').read()
enum = dict(re.findall(r'(\w+)\s*=\s*(-?\d+)', re.search(r'ConditionAndDepleteID = \{(.*?)\}', dfn, re.S).group(1)))
reg = {int(enum[n]) for n in re.findall(r'logics\[define\.ConditionAndDepleteID\.(\w+)\]', src) if n in enum}
print('registered condition logics:', sorted(reg))
res = open(R + '/GameServer/lualib/cy_four_combat/resources.lua', encoding='utf-8', errors='replace').read()
print('cy_four resources mentions type:', sorted(set(re.findall(r'type\s*==\s*(\d+)', res)))[:20])
st = json.load(open(os.path.join(os.path.dirname(__file__), '..', 'static-menpai.json'), encoding='utf-8'))
tn, trows = load(R + '/configs/SkillTemplate_V1.txt')
dn, drows = load(R + '/configs/SkillData_V1.txt')
sd = {num(r[dn[0]]): r for r in drows}
tm = {num(r['ID,(技能系的ID)']): r for r in trows}
per = collections.defaultdict(set); labels = {}
for mp, m_ in st.items():
    for s in m_['skills']:
        if s['passive']:
            continue
        for lv in range(1, 5):
            d = sd.get(num(tm[s['id']]['心法%d级对应的实际技能ID' % lv]))
            if not d:
                continue
            lg = d['条件和消耗逻辑']; ds = d['条件或消耗参数说明']
            lg = lg if isinstance(lg, list) else [lg]; ds = ds if isinstance(ds, list) else [ds]
            for i, x in enumerate(lg):
                x = num(x)
                if x is not None and x >= 0 and x not in reg:
                    per[(int(mp), x)].add(s['id']); labels[x] = ds[i] if i < len(ds) else ''
for (mp, x), ids in sorted(per.items()):
    print('menpai', mp, 'logic', x, labels[x], 'templates', len(ids), sorted(ids)[:12])
