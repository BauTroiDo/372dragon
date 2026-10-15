# chỉ đọc: kỹ năng/tâm pháp 15 phái trên server riêng -> static-menpai.json
import json, os, sys, collections
sys.path.insert(0, os.path.dirname(__file__))
from tlbbtab import load, num, R

OUT = os.path.join(os.path.dirname(__file__), '..', 'static-menpai.json')
MENPAI = [0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 15]
NAME = {0: '少林', 1: '明教', 2: '丐帮', 3: '武当', 4: '峨嵋', 5: '星宿', 6: '大理', 7: '天山', 8: '逍遥', 10: '慕容',
        11: '唐门', 12: '鬼谷', 13: '桃花岛', 14: '绝情谷', 15: '恶人谷'}
X78 = {0: (55, 72), 1: (56, 73), 2: (57, 74), 3: (58, 75), 4: (59, 76), 5: (60, 77), 6: (61, 78), 7: (62, 79), 8: (63, 80),
       10: (70, 71), 15: (119, 120), 11: (87, 88), 12: (95, 96), 13: (103, 104), 14: (111, 112)}

tn, trows = load(R + '/configs/SkillTemplate_V1.txt')
xn, xrows = load(R + '/configs/XinFa_V1.txt')
if '--headers' in sys.argv:
    for i, n in enumerate(tn):
        print(i, n)
    sys.exit(0)

plan = json.load(open('/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-14-server-impact/staging-6/plan.json', encoding='utf-8'))
static = collections.defaultdict(dict)
for it in plan['faction_lowlevel']['items']:
    static[it['tid']][it['level']] = {'after': it['after'], 'why': it.get('why_after'), 'logic': it.get('skill_logic'),
                                      'logic_installed': it.get('skill_logic_installed'), 'sd': it.get('skill_data')}

xinfa = collections.defaultdict(list)
for r in xrows:
    xid, mp = num(r['心法ID']), num(r['门派ID'])
    if xid is None:
        continue
    xinfa[mp].append({'id': xid, 'name': r['心法名称$1$'], 'direct': num(r['是否直接学会']), 'lvl_limit': num(r['升级人物等级限制'])})

out = {}
for mp in MENPAI:
    xs = sorted(xinfa.get(mp, []), key=lambda x: x['id'])
    base_x = [x['id'] for x in xs if x['id'] not in X78[mp]]
    skills = []
    for r in trows:
        if num(r['门派']) != mp:
            continue
        t = {'id': num(r['ID,(技能系的ID)']), 'name': r['技能名字$1$'], 'xinfa': num(r['心法ID']),
             'xinfa_req': num(r['技能的心法等级限制']), 'class_by_user': num(r['技能类型按使用者划分']),
             'passive': num(r['主动技能还是被动技能']) == 1, 'direct': num(r['是否直接学会']) == 1,
             'need_learn': num(r['使用前是否需要学会']) == 1, 'targeting': num(r['目标选择逻辑']),
             'stand': num(r['目标和使用者阵营关系']), 'friendly': num(r['技能友好度,=0为中性技能,>0为正面技能,<0为 负面技能']),
             'skill_type': num(r['技能类型']), 'cooldown_id': num(r['冷却ID']), 'range_max': num(r['最大射程(m)']),
             'need_weapon': num(r['需要拿武器']), 'skill_class': num(r['招式类型'])}
        t['static'] = static.get(t['id'], {})
        skills.append(t)
    learn = sorted({s['id'] for s in skills if s['direct'] or (s['class_by_user'] == 0 and s['xinfa'] in base_x)})
    out[mp] = {'name': NAME[mp], 'xinfa': xs, 'base_xinfa': base_x, 'xinfa78': X78[mp], 'skills': skills, 'learn_ids': learn}
    act = [s for s in skills if s['id'] in learn and not s['passive']]
    act30 = [s for s in act if (s['xinfa_req'] or 0) <= 30]
    print(mp, NAME[mp], 'xinfa', len(xs), 'base', base_x, 'templates', len(skills), 'learn', len(learn),
          'active', len(act), 'active_req<=30', len(act30))
json.dump(out, open(OUT, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
