# chỉ đọc: tiêu hao (条件和消耗) của SkillData cấp 1-4 cho vài template
import os, sys, re
sys.path.insert(0, os.path.dirname(__file__))
from tlbbtab import load, num, R
tn, trows = load(R + '/configs/SkillTemplate_V1.txt')
dn, drows = load(R + '/configs/SkillData_V1.txt')
sd = {num(r[dn[0]]): r for r in drows}
tm = {num(r['ID,(技能系的ID)']): r for r in trows}
ids = [int(x) for x in sys.argv[1].split(',')]
for t in ids:
    r = tm[t]
    out = []
    for lv in range(1, 5):
        d = sd.get(num(r['心法%d级对应的实际技能ID' % lv]))
        if not d:
            out.append('lv%d: no SD' % lv); continue
        logic = d['条件和消耗逻辑']; desc = d['条件或消耗参数说明']; vals = d['条件或消耗参数值']
        logic = logic if isinstance(logic, list) else [logic]
        desc = desc if isinstance(desc, list) else [desc]
        vals = vals if isinstance(vals, list) else [vals]
        parts = []
        vi = 0
        for i, lg in enumerate(logic):
            if lg not in ('', '-1'):
                parts.append('%s:%s=%s' % (lg, desc[i] if i < len(desc) else '', vals[vi:vi + 2]))
            vi += 2
        out.append('lv%d SD%s %s' % (lv, d[dn[0]], ' '.join(parts)))
    print(t, r['技能名字$1$'], '|', ' ; '.join(out))
print('header cost cols', [n for n in dn if '消耗' in n or '条件' in n][:10])
