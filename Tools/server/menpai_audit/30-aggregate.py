#!/usr/bin/env python3
"""menpai-audit: gộp live-results.tsv (+ static-menpai.json, plan.json server-impact) -> aggregate.json + bảng markdown."""
import csv, json, os, subprocess, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
L = os.path.join(HERE, '..')
MENPAI = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '10', '11', '12', '13', '14', '15']
VI = {'0': 'Thiếu Lâm', '1': 'Minh Giáo', '2': 'Cái Bang', '3': 'Võ Đang', '4': 'Nga My', '5': 'Tinh Túc', '6': 'Đại Lý (Thiên Long)',
      '7': 'Thiên Sơn', '8': 'Tiêu Dao', '10': 'Mộ Dung', '11': 'Đường Môn', '12': 'Quỷ Cốc', '13': 'Đào Hoa Đảo', '14': 'Tuyệt Tình Cốc', '15': 'Ác Nhân Cốc'}
OR = {-1: 'ERROR', -2: 'DIE', -3: 'INVALID_SKILL', -4: 'TARGET_DIE', -5: 'LACK_MANA', -6: 'COOL_DOWNING', -7: 'NO_TARGET', -8: 'INVALID_TARGET',
      -9: 'OUT_RANGE', -16: 'WARNING(mục tiêu sai phe)', -17: 'BUSY', -24: 'NOT_ENOUGH_HP', -25: 'NOT_ENOUGH_RAGE', -26: 'NOT_ENOUGH_STRIKE_POINT',
      -27: 'NOT_ENOUGH_ITEM', -29: 'NO_LEVEL', -37: 'LIMIT_USE_SKILL', -38: 'INACTIVE_SKILL', -40: 'NEED_A_WEAPON', -41: 'NEED_HIGH_LEVEL_XINFA',
      -42: 'NEED_LEARN_SKILL_FIRST', -59: 'NEED_IN_STEALTH_MODE', -60: 'NOT_ENOUGH_ENERGY', -75: 'CAN_NOT_FIND_SPECIFIC_ITEM'}
BENIGN = {-4, -6, -17}


BASELINE_BUFFS = {'334'}  # có ở mọi phiên ngay khi vào cảnh (không do kỹ năng)
PRECOND = {-16, -8, -9, -10, -25, -26, -5}  # mục tiêu sai phe / tầm / nộ / liên kích / MP: điều kiện bot không tạo được


def decode(r, skill):
    d = os.path.join(L, '..', '..', '..', r['dir'].replace('/', os.sep))
    d = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', '..', '..', r['dir']))
    try:
        res = json.load(open(os.path.join(d, 'result.json'), encoding='utf-8'))
        fx = [f for f in os.listdir(d) if f.endswith('.bin')]
        if not fx:
            return {}
        out = subprocess.run([sys.executable, '-B', os.path.join(HERE, 'decode_fixture.py'), os.path.join(d, fx[0]), str(res['world']['my']), str(skill)],
                             capture_output=True, text=True).stdout
        return json.loads(out)
    except Exception as e:
        return {'error': str(e)}


SIGS = {'storage.lua:27': 'cy_four_storage_faction', 'skill_0.lua:72': 'cy_generic_IMPACT_NUMBER', 'condition_delplete_core.lua:708': 'condition_logic_missing'}


def errsig(r):
    p = os.path.normpath(os.path.join(HERE, '..', '..', '..', '..', r['dir'] + '-serverlog.txt'))
    try:
        t = open(p, encoding='utf-8', errors='replace').read()
    except OSError:
        return []
    sig = sorted({v for k, v in SIGS.items() if k in t})
    other = [l.strip()[:160] for l in t.splitlines() if ('attempt to' in l or 'nil value' in l) and not any(k in l for k in SIGS)]
    return sig + other[:2]


def classify(r, skill):
    combat = decode(r, skill)
    # chiêu được server nhận: có GCCharSkill_Send của mình cho đúng skill, hoặc server đặt hồi chiêu (GCCooldownUpdate) cho phiên đó
    sends = combat.get('my_skill_sends_of_skill', 0) or int(r['cooldown_entries'] or 0) > 0
    ors = {}
    for tok in (r['or_codes'] or '').split():
        code, n = tok.split('x')
        ors[int(code)] = int(n)
    bad = {k: v for k, v in ors.items() if k not in BENIGN}
    bself = {k: v for k, v in (combat.get('buffs_self') or {}).items() if k not in BASELINE_BUFFS}
    combat['buffs_self'] = bself
    eff = combat.get('dmg_hits', 0) or combat.get('heal_sum', 0) or bself or combat.get('buffs_other') or combat.get('direct_impacts_of_skill')
    sig = errsig(r)
    tb = any(s == 'cy_generic_IMPACT_NUMBER' or not s.startswith('cy_') for s in sig)  # lỗi heartbeat storage không do kỹ năng: tách riêng
    if tb:
        cls = 'loi_server'
    elif sends and eff:
        cls = 'chay'
    elif sends:
        cls = 'khong_tac_dung'
    elif bad and set(bad) <= PRECOND:
        cls = 'khong_kiem_duoc'
    elif bad:
        cls = 'tu_choi'
    else:
        cls = 'khong_gui'
    return cls, combat, ors


def main():
    st = json.load(open(os.path.join(L, 'static-menpai.json'), encoding='utf-8'))
    rows = list(csv.DictReader(open(os.path.join(L, 'live-results.tsv'), encoding='utf-8-sig'), delimiter='\t'))
    last = {}
    for r in rows:
        last[(r['menpai'], int(r['skill']))] = r
    agg, items = {}, []
    for mp in MENPAI:
        m = st[mp]
        learn = set(m['learn_ids'])
        act = [s for s in m['skills'] if s['id'] in learn and not s['passive']]
        act30 = [s for s in act if (s['xinfa_req'] or 0) <= 30]
        pas = [s for s in m['skills'] if s['id'] in learn and s['passive']]
        c = collections.Counter(); orc = collections.Counter(); stat_c = collections.Counter(); cross = collections.Counter()
        for s in act30:
            r = last.get((mp, s['id']))
            st4 = (s.get('static') or {}).get('4', {}).get('after') or 'ok*'
            stat_c[st4 or '-'] += 1
            if not r:
                c['chua_kiem'] += 1
                continue
            cls, combat, ors = classify(r, s['id'])
            c[cls] += 1
            cross[(st4 or '-', cls)] += 1
            for k, v in ors.items():
                if k not in BENIGN:
                    orc[k] += 1
            items.append({'menpai': int(mp), 'skill': s['id'], 'name': s['name'], 'xinfa': s['xinfa'], 'xinfa_req': s['xinfa_req'], 'targeting': s['targeting'],
                          'stand': s['stand'], 'friendly': s['friendly'], 'static_lv4': st4, 'static_why': (s.get('static') or {}).get('4', {}).get('why'),
                          'logic': (s.get('static') or {}).get('4', {}).get('logic'), 'logic_installed': (s.get('static') or {}).get('4', {}).get('logic_installed'), 'errsig': errsig(r), 'class': cls, 'ors': ors,
                          'dmg_hits': combat.get('dmg_hits'), 'dmg_sum': combat.get('dmg_sum'), 'dmg_max': combat.get('dmg_max'),
                          'buffs_self': combat.get('buffs_self'), 'buffs_other': combat.get('buffs_other'), 'direct_impacts': combat.get('direct_impacts_of_skill'), 'heal_sum': combat.get('heal_sum'),
                          'kill': r['kills'], 'casts': r['casts'], 'traceback': r['log_traceback'], 'dir': r['dir']})
        agg[mp] = {'name': m['name'], 'vi': VI[mp], 'active_total': len(act), 'active_req_le30': len(act30), 'passive': len(pas),
                   'live': dict(c), 'or_codes': {'%d %s' % (k, OR.get(k, '')): v for k, v in orc.items()}, 'static_lv4': dict(stat_c),
                   'static_vs_live': {'%s->%s' % k: v for k, v in cross.items()}}
    json.dump({'menpai': agg, 'items': items}, open(os.path.join(L, 'aggregate.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    tot = collections.Counter()
    print('| Phái | chủ động (≤30 / tổng) | kiểm live | chạy | gửi chiêu không tác dụng | bị từ chối | không kiểm được (mục tiêu) | lỗi server | tĩnh lv4 ok/một phần/không/không ô impact |')
    print('|---|---|---|---|---|---|---|---|---|')
    for mp in MENPAI:
        a = agg[mp]; lv = a['live']
        n = sum(v for k, v in lv.items() if k != 'chua_kiem')
        for k, v in lv.items():
            tot[k] += v
        tot['act30'] += a['active_req_le30']; tot['act'] += a['active_total']; tot['n'] += n
        s4 = a['static_lv4']
        print('| %s %s (%s) | %d / %d | %d | %d | %d | %d | %d | %d | %d/%d/%d/%d |' % (mp, a['name'], a['vi'], a['active_req_le30'], a['active_total'], n, lv.get('chay', 0),
              lv.get('khong_tac_dung', 0), lv.get('tu_choi', 0) + lv.get('khong_gui', 0), lv.get('khong_kiem_duoc', 0), lv.get('loi_server', 0),
              s4.get('ok', 0) + s4.get('ok*', 0), s4.get('partial', 0), s4.get('none', 0), s4.get('no_impact_param', 0)))
    print('| **Tổng** | %d / %d | %d | %d | %d | %d | %d | %d | |' % (tot['act30'], tot['act'], tot['n'], tot['chay'], tot['khong_tac_dung'], tot['tu_choi'] + tot['khong_gui'], tot['khong_kiem_duoc'], tot['loi_server']))
    for mp in MENPAI:
        print(mp, agg[mp]['or_codes'], agg[mp]['static_vs_live'])


if __name__ == '__main__':
    main()





