#!/usr/bin/env python3
r"""menpai-verify: gộp kết quả kiểm live kỹ năng 15 phái -> aggregate.json + bảng markdown.

Bản chạy lại được của `30-aggregate.py` (menpai-audit 15/09): mọi đường dẫn là tham số, không còn giả định
thư mục bằng chứng của một ngày. Phân loại từng kỹ năng giữ nguyên luật của đợt audit để số liệu so được
trực tiếp với `Build/Logs/2026-09-15-menpai-audit/aggregate-table.txt`.

  python -X utf8 aggregate_check.py --results DIR1\live-results.tsv [DIR2\live-results.tsv ...] --static DIR\static-menpai.json
                                    [--out DIR\aggregate.json] [--table DIR\table.md] [--repo C:\TLBB\085\CY-Source]
                                    [--menpai 0,1,...] [--label "sau khi sửa"]

Cột bảng: chạy / gửi chiêu không tác dụng / bị từ chối / không kiểm được (mục tiêu) / lỗi server.
"""
import argparse
import collections
import csv
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def find_repo(start):
    """Gốc cây chứa bằng chứng: đi lên từ live-results.tsv tới thư mục có cả Src và Tools.

    Cột `dir` của TSV là đường dẫn tương đối gốc cây chính; bản chép công cụ này có thể nằm trong worktree,
    nên không suy ra gốc từ vị trí script (worktree không có Build/Logs).
    """
    d = os.path.dirname(os.path.abspath(start))
    while True:
        if os.path.isdir(os.path.join(d, 'Src')) and os.path.isdir(os.path.join(d, 'Tools')):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return os.path.abspath(os.path.join(HERE, '..', '..', '..'))
        d = parent
MENPAI_ALL = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '10', '11', '12', '13', '14', '15']
VI = {'0': 'Thiếu Lâm', '1': 'Minh Giáo', '2': 'Cái Bang', '3': 'Võ Đang', '4': 'Nga My', '5': 'Tinh Túc',
      '6': 'Đại Lý (Thiên Long)', '7': 'Thiên Sơn', '8': 'Tiêu Dao', '10': 'Mộ Dung', '11': 'Đường Môn',
      '12': 'Quỷ Cốc', '13': 'Đào Hoa Đảo', '14': 'Tuyệt Tình Cốc', '15': 'Ác Nhân Cốc'}
OR = {-1: 'ERROR', -2: 'DIE', -3: 'INVALID_SKILL', -4: 'TARGET_DIE', -5: 'LACK_MANA', -6: 'COOL_DOWNING',
      -7: 'NO_TARGET', -8: 'INVALID_TARGET', -9: 'OUT_RANGE', -16: 'WARNING(mục tiêu sai phe)', -17: 'BUSY',
      -24: 'NOT_ENOUGH_HP', -25: 'NOT_ENOUGH_RAGE', -26: 'NOT_ENOUGH_STRIKE_POINT', -27: 'NOT_ENOUGH_ITEM',
      -29: 'NO_LEVEL', -37: 'LIMIT_USE_SKILL', -38: 'INACTIVE_SKILL', -40: 'NEED_A_WEAPON',
      -41: 'NEED_HIGH_LEVEL_XINFA', -42: 'NEED_LEARN_SKILL_FIRST', -44: 'CANNT_DO_THIS_RIGHT_NOW',
      -59: 'NEED_IN_STEALTH_MODE', -60: 'NOT_ENOUGH_ENERGY', -75: 'CAN_NOT_FIND_SPECIFIC_ITEM'}
BENIGN = {-4, -6, -17}
BASELINE_BUFFS = {'334'}          # có sẵn khi vào cảnh, không do kỹ năng
PRECOND = {-16, -8, -9, -10, -25, -26, -5}  # điều kiện bot không tạo được (phe/tầm/nộ/liên kích/MP)
SIGS = {'storage.lua:27': 'cy_four_storage_faction', 'skill_0.lua:72': 'cy_generic_IMPACT_NUMBER',
        'condition_delplete_core.lua:708': 'condition_logic_missing'}


def session_dir(repo, rel):
    return os.path.normpath(os.path.join(repo, rel.replace('/', os.sep)))


def decode(repo, row, skill):
    d = session_dir(repo, row['dir'])
    try:
        res = json.load(open(os.path.join(d, 'result.json'), encoding='utf-8'))
        fx = [f for f in os.listdir(d) if f.endswith('.bin')]
        if not fx:
            return {}
        out = subprocess.run([sys.executable, '-X', 'utf8', '-B', os.path.join(HERE, 'decode_fixture.py'),
                              os.path.join(d, fx[0]), str(res['world']['my']), str(skill)],
                             capture_output=True, text=True, encoding='utf-8').stdout
        return json.loads(out)
    except Exception as exc:                                    # noqa: BLE001 - bằng chứng thiếu thì ghi lý do
        return {'error': str(exc)}


def errsig(repo, row):
    path = session_dir(repo, row['dir']) + '-serverlog.txt'
    try:
        text = open(path, encoding='utf-8', errors='replace').read()
    except OSError:
        return []
    sig = sorted({v for k, v in SIGS.items() if k in text})
    other = [l.strip()[:160] for l in text.splitlines()
             if ('attempt to' in l or 'nil value' in l) and not any(k in l for k in SIGS)]
    return sig + other[:2]


def classify(repo, row, skill):
    combat = decode(repo, row, skill)
    sends = combat.get('my_skill_sends_of_skill', 0) or int(row['cooldown_entries'] or 0) > 0
    ors = {}
    for tok in (row['or_codes'] or '').split():
        code, n = tok.split('x')
        ors[int(code)] = int(n)
    bad = {k: v for k, v in ors.items() if k not in BENIGN}
    bself = {k: v for k, v in (combat.get('buffs_self') or {}).items() if k not in BASELINE_BUFFS}
    combat['buffs_self'] = bself
    eff = (combat.get('dmg_hits', 0) or combat.get('heal_sum', 0) or bself
           or combat.get('buffs_other') or combat.get('direct_impacts_of_skill'))
    sig = errsig(repo, row)
    # lỗi nhịp tim storage.lua không do kỹ năng -> không tính là lỗi server của chiêu
    fatal = any(s == 'cy_generic_IMPACT_NUMBER' or not s.startswith('cy_') for s in sig)
    if fatal:
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
    return cls, combat, ors, sig


def build(args):
    static = json.load(open(args.static, encoding='utf-8'))
    last = {}
    for path in args.results:                                  # nhiều file: file sau đè file trước
        for r in csv.DictReader(open(path, encoding='utf-8-sig'), delimiter='\t'):
            if r.get('skill'):
                last[(r['menpai'], int(r['skill']))] = r       # trong một file, lượt sau đè lượt trước
    menpai = [m.strip() for m in args.menpai.split(',') if m.strip()]
    agg, items = {}, []
    for mp in menpai:
        m = static[mp]
        learn = set(m['learn_ids'])
        act = [s for s in m['skills'] if s['id'] in learn and not s['passive']]
        act30 = [s for s in act if (s['xinfa_req'] or 0) <= args.xinfa_level]
        passive = [s for s in m['skills'] if s['id'] in learn and s['passive']]
        c, orc, stat_c, cross = collections.Counter(), collections.Counter(), collections.Counter(), collections.Counter()
        for s in act30:
            r = last.get((mp, s['id']))
            st4 = (s.get('static') or {}).get('4', {}).get('after') or 'ok*'
            stat_c[st4 or '-'] += 1
            if not r:
                c['chua_kiem'] += 1
                continue
            cls, combat, ors, sig = classify(args.repo, r, s['id'])
            c[cls] += 1
            cross[(st4 or '-', cls)] += 1
            for k in ors:
                if k not in BENIGN:
                    orc[k] += 1
            items.append({'menpai': int(mp), 'skill': s['id'], 'name': s['name'], 'xinfa': s['xinfa'],
                          'xinfa_req': s['xinfa_req'], 'targeting': s['targeting'], 'stand': s['stand'],
                          'friendly': s['friendly'], 'static_lv4': st4,
                          'static_why': (s.get('static') or {}).get('4', {}).get('why'),
                          'logic': (s.get('static') or {}).get('4', {}).get('logic'),
                          'logic_installed': (s.get('static') or {}).get('4', {}).get('logic_installed'),
                          'errsig': sig, 'class': cls, 'ors': ors, 'time': r.get('time'),
                          'dmg_hits': combat.get('dmg_hits'), 'dmg_sum': combat.get('dmg_sum'),
                          'dmg_max': combat.get('dmg_max'), 'buffs_self': combat.get('buffs_self'),
                          'buffs_other': combat.get('buffs_other'),
                          'direct_impacts': combat.get('direct_impacts_of_skill'), 'heal_sum': combat.get('heal_sum'),
                          'kill': r['kills'], 'casts': r['casts'], 'traceback': r['log_traceback'], 'dir': r['dir']})
        agg[mp] = {'name': m['name'], 'vi': VI.get(mp, mp), 'active_total': len(act), 'active_req_le30': len(act30),
                   'passive': len(passive), 'live': dict(c),
                   'or_codes': {'%d %s' % (k, OR.get(k, '')): v for k, v in orc.items()},
                   'static_lv4': dict(stat_c), 'static_vs_live': {'%s->%s' % k: v for k, v in cross.items()}}
    return agg, items, menpai


def table(agg, menpai, label):
    out = []
    if label:
        out.append('Bảng kiểm 15 phái — %s' % label)
        out.append('')
    out.append('| Phái | chủ động (≤30 / tổng) | kiểm live | chạy | gửi chiêu không tác dụng | bị từ chối | '
               'không kiểm được (mục tiêu) | lỗi server | tĩnh lv4 ok/một phần/không/không ô impact |')
    out.append('|---|---|---|---|---|---|---|---|---|')
    tot = collections.Counter()
    for mp in menpai:
        a = agg[mp]
        lv = a['live']
        n = sum(v for k, v in lv.items() if k != 'chua_kiem')
        for k, v in lv.items():
            tot[k] += v
        tot['act30'] += a['active_req_le30']
        tot['act'] += a['active_total']
        tot['n'] += n
        s4 = a['static_lv4']
        out.append('| %s %s (%s) | %d / %d | %d | %d | %d | %d | %d | %d | %d/%d/%d/%d |'
                   % (mp, a['name'], a['vi'], a['active_req_le30'], a['active_total'], n, lv.get('chay', 0),
                      lv.get('khong_tac_dung', 0), lv.get('tu_choi', 0) + lv.get('khong_gui', 0),
                      lv.get('khong_kiem_duoc', 0), lv.get('loi_server', 0),
                      s4.get('ok', 0) + s4.get('ok*', 0), s4.get('partial', 0), s4.get('none', 0),
                      s4.get('no_impact_param', 0)))
    out.append('| **Tổng** | %d / %d | %d | %d | %d | %d | %d | %d | |'
               % (tot['act30'], tot['act'], tot['n'], tot['chay'], tot['khong_tac_dung'],
                  tot['tu_choi'] + tot['khong_gui'], tot['khong_kiem_duoc'], tot['loi_server']))
    out.append('')
    out.append('Mã từ chối và đối chiếu tĩnh→live theo phái:')
    for mp in menpai:
        out.append('- %s %s: %s %s' % (mp, agg[mp]['vi'], agg[mp]['or_codes'], agg[mp]['static_vs_live']))
    return '\n'.join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--results', required=True, nargs='+',
                    help='một hay nhiều live-results.tsv; file sau đè kết quả của cùng (phái, kỹ năng)')
    ap.add_argument('--static', required=True, help='static-menpai.json (11-static-menpai.py)')
    ap.add_argument('--out', help='aggregate.json (mặc định cạnh --results)')
    ap.add_argument('--table', help='bảng markdown (mặc định cạnh --results)')
    ap.add_argument('--repo', default='', help='gốc cây chứa bằng chứng (mặc định: suy ra từ --results)')
    ap.add_argument('--menpai', default=','.join(MENPAI_ALL))
    ap.add_argument('--xinfa-level', type=int, default=30)
    ap.add_argument('--label', default='')
    args = ap.parse_args()
    args.repo = args.repo or find_repo(args.results[0])
    base = os.path.dirname(os.path.abspath(args.results[-1]))
    args.out = args.out or os.path.join(base, 'aggregate.json')
    args.table = args.table or os.path.join(base, 'table.md')
    agg, items, menpai = build(args)
    json.dump({'menpai': agg, 'items': items, 'results': [os.path.abspath(p) for p in args.results], 'label': args.label},
              open(args.out, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    text = table(agg, menpai, args.label)
    open(args.table, 'w', encoding='utf-8', newline='\n').write(text + '\n')
    print(text)
    return 0


if __name__ == '__main__':
    sys.exit(main())
