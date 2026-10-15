#!/usr/bin/env python3
"""menpai-fix — sửa lỗi kỹ năng môn phái trên SERVER RIÊNG (sau menpai-audit 15/09/2026).

  menpai_fix.py plan  --out <dir> [--fix storage,condition]   dựng staging (không chạm R): lua/GameServer/<rel> + plan.json
  menpai_fix.py apply --staging <dir> [--dry-run]              chép vào R (sao lưu R/backups/menpai-fix-<UTC>/), idempotent, luac5.4 -p
  menpai_fix.py test  [--staging <dir>]                        test Lua đơn vị (menpai_fix_tests.lua) với R + staging

Chạy trong WSL TLBB bằng root (python3 -B). Đặc tả: Docs/specs/server/menpai-fix_vi.md.
Sửa (mỗi --fix là một commit server):
  storage    Lỗi 2: lualib/cy_four_combat/storage.lua:27 số phái GL 15/16 → CY 13/14 (Serverhook GetMenPai()==0xd/0xe).
  condition  Lỗi 3: logic điều kiện/tiêu hao CY 16–21 theo mã tlbb15 (services/scene/skill/condition_cy.lua), bảng tập ID CY
             (lualib/cy_idcollections.lua sinh từ IDCollections client CY 3.71 + dòng thiếu từ tlbb15), condition_delplete_core:
             đăng ký + kiểu lạ → đạt như CDCore native thay vì assert.
Lỗi 1 (skill_cy_generic thiếu IMPACT_NUMBER) sửa trong Tools/server/server_impact_lua (áp bằng server_impact.py apply).
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
R = '/home/ubuntu/cys-test-20260913'
GS = 'GameServer'
LUA_SRC = os.path.join(HERE, 'menpai_fix_lua', GS)
TESTS = os.path.join(HERE, 'menpai_fix_tests.lua')
DATA_NEW = '/mnt/c/TLBB/085/Tools/DATA NEW/DataCY31-08-26'
CY_IDCOLL = DATA_NEW + '/Config/IDCollections.txt'
T15_IDCOLL = DATA_NEW + '/tlbb15/Public/Config/IDCollections.txt'
MARK = 'menpai-fix'


def patch_once(text, old, new, what):
    """thay đúng 1 lần (chịu CRLF); đã có `new` → giữ nguyên (idempotent)"""
    for o, n in ((old, new), (old.replace('\n', '\r\n'), new.replace('\n', '\r\n'))):
        if text.count(n) == 1 and n != o:
            return text
        if text.count(o) == 1:
            return text.replace(o, n)
    raise SystemExit('neo Lua không khớp đúng 1 lần: %s' % what)


def read_r(rel):
    return open(os.path.join(R, GS, rel), encoding='utf-8', newline='').read()


# ---------------------------------------------------------------- Lỗi 2
def fix_storage(files, plan):
    rel = 'lualib/cy_four_combat/storage.lua'
    t = read_r(rel)
    old = "    assert((id==328 and faction==15) or ((id==331 or id==332) and faction==16), 'resource/faction mismatch')\n"
    new = ("    -- %s: số phái CY (桃花岛 13, 绝情谷 14) như Serverhook MenPai_13/14 (GetMenPai()==0xd/0xe); GL cũ 15/16 làm assert mỗi nhịp tim\n"
           "    assert((id==328 and faction==13) or ((id==331 or id==332) and faction==14), 'resource/faction mismatch')\n") % MARK
    files[rel] = patch_once(t, old, new, 'storage.lua:27')
    plan['storage'] = {'file': rel, 'line': 27, 'old': 'faction 15/16 (GL)', 'new': 'faction 13/14 (CY)'}


# ---------------------------------------------------------------- Lỗi 3
def load_idcoll(path):
    raw = open(path, 'rb').read()
    lines = raw.split(b'\n')
    names = [c.decode('gbk', 'replace').strip() for c in lines[1].rstrip(b'\r').split(b'\t')]
    # client CY 3.71: dòng 2 lặp dòng kiểu (không có tên cột) → vị trí cố định như tlbb15: ID, 说明, 类型, 数量, ID1..ID30
    if '标识ID的分类ID' in names:
        assert names[:5] == ['标识ID的分类ID', '分类说明', '本行中所有ID的类型(必须填)', '本类中的ID数量', 'ID1'], names[:5]
    i_id, i_desc, i_type, i_n = 0, 1, 2, 3
    names = []
    out = {}
    for ln in lines[2:]:
        ln = ln.rstrip(b'\r')
        if not ln.strip() or ln.startswith(b'#'):
            continue
        c = ln.split(b'\t')
        try:
            cid, typ, n = int(c[i_id]), int(c[i_type]), int(c[i_n])
        except (ValueError, IndexError):
            continue
        ids = []
        for k in range(1, n + 1):
            j = names.index('ID%d' % k) if 'ID%d' % k in names else i_n + k
            try:
                ids.append(int(c[j]))
            except (ValueError, IndexError):
                pass
        out[cid] = {'type': typ, 'ids': ids, 'desc': c[i_desc].decode('gbk', 'replace')}
    return out


def gen_collections(plan):
    cy, t15 = load_idcoll(CY_IDCOLL), load_idcoll(T15_IDCOLL)
    rows = dict(cy)
    extra = sorted(k for k in t15 if k not in cy)
    for k in extra:
        rows[k] = dict(t15[k], src='tlbb15')
    body = ['-- SINH MÁY bởi Tools/server/menpai_fix.py (%s): tập ID CY cho logic điều kiện CY (scene.skill.condition_cy).' % MARK,
            '-- Nguồn: IDCollections client CY 3.71 (%d dòng) + dòng chỉ có ở tlbb15 Public/Config (%d: %s).' % (len(cy), len(extra), ','.join(map(str, extra))),
            '-- KHÔNG thay configs/IDCollections.txt của server (bản HJS/GL, Lua GL + StandardImpact tlbb15 còn dùng).',
            'return {']
    for k in sorted(rows):
        r = rows[k]
        desc = re.sub(r'[\r\n\]\[]', ' ', r['desc']).strip()
        ids = ', '.join('[%d] = true' % x for x in r['ids'])
        body.append('    [%d] = {type = %d, ids = {%s}}, -- %s%s' % (k, r['type'], ids, desc, ' (tlbb15)' if r.get('src') else ''))
    body.append('}')
    plan['collections'] = {'cy_rows': len(cy), 'tlbb15_only_added': extra, 'total': len(rows),
                           'check': {str(k): rows[k]['ids'] for k in (340, 376, 412, 414, 416, 426, 499, 511, 1, 5) if k in rows}}
    return '\n'.join(body) + '\n'


def fix_condition(files, plan):
    rel = 'services/scene/skill/condition_delplete_core.lua'
    t = read_r(rel)
    for phase in ('condition_check', 'deplete'):
        old = 'function condition_delplete_core:%s(obj_me, data)\n' % phase
        head = t.index(old.replace('\n', '\r\n') if old not in t else old)
        seg_end = t.index('assert(logic, type)', head)
        seg = t[head:seg_end]
        if '%s:' % MARK in seg:
            continue
        a = '    local logic = self.logics[type]'
        assert seg.count(a) == 1, (phase, seg)
        new_seg = seg.replace(a, '    -- %s: CDCore_T native — kiểu không có trong switch → đạt/không tiêu hao (trước: assert làm sập chiêu)\n'
                                 '    local logic = self.logics[type] or self.cy_default_logic' % MARK)
        if '\r\n' in seg:
            new_seg = new_seg.replace('\r\n', '\n').replace('\n', '\r\n')
        t = t[:head] + new_seg + t[seg_end:]
    anchor = '-- 返回模块\n'
    add = ('-- %s: logic điều kiện/tiêu hao CY 16–21 theo mã tlbb15 (16 = 消耗能量 桃花岛, không còn là C_UNIT_MUST_NOT_HAVE_IMPACT; '
           '18 mới là "bản thân không có impact thuộc tập")\n'
           'require("scene.skill.condition_cy").install(condition_delplete_core)\n\n') % MARK
    t = patch_once(t, anchor, add + anchor, 'condition_delplete_core install')
    files[rel] = t
    files['services/scene/skill/condition_cy.lua'] = open(os.path.join(LUA_SRC, 'services/scene/skill/condition_cy.lua'), encoding='utf-8').read()
    files['lualib/cy_idcollections.lua'] = gen_collections(plan)
    plan['condition'] = {'core': rel, 'module': 'services/scene/skill/condition_cy.lua', 'collections': 'lualib/cy_idcollections.lua'}


def cmd_plan(args):
    st = os.path.abspath(args.out)
    os.makedirs(st, exist_ok=True)
    files, plan = {}, {'fix': args.fix}
    for f in args.fix.split(','):
        {'storage': fix_storage, 'condition': fix_condition}[f](files, plan)
    for rel, text in files.items():
        p = os.path.join(st, 'lua', GS, rel)
        os.makedirs(os.path.dirname(p), exist_ok=True)
        with open(p, 'w', encoding='utf-8', newline='') as fh:
            fh.write(text)
    plan['files'] = sorted(files)
    json.dump(plan, open(os.path.join(st, 'plan.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(plan, ensure_ascii=False, indent=1)[:4000])


def staged(st):
    base = os.path.join(st, 'lua')
    for dp, _, fns in os.walk(base):
        for fn in fns:
            p = os.path.join(dp, fn)
            yield p, os.path.relpath(p, base).replace('\\', '/')


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'menpai-fix-' + stamp)
    changed, same, luac = [], 0, []
    for p, rel in sorted(staged(args.staging), key=lambda x: x[1]):
        dst = os.path.join(R, rel)
        new = open(p, 'rb').read()
        old = open(dst, 'rb').read() if os.path.exists(dst) else None
        if old == new:
            same += 1
            continue
        r = subprocess.run(['luac5.4', '-p', p], capture_output=True, text=True)
        if r.returncode != 0:
            sys.exit('luac lỗi (không ghi gì): %s %s' % (rel, r.stderr))
        changed.append(rel)
        if args.dry_run:
            continue
        if old is not None:
            bp = os.path.join(bdir, rel)
            os.makedirs(os.path.dirname(bp), exist_ok=True)
            open(bp, 'wb').write(old)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        open(dst, 'wb').write(new)
    for rel in ([] if args.dry_run else changed):
        r = subprocess.run(['luac5.4', '-p', os.path.join(R, rel)], capture_output=True, text=True)
        luac.append((rel, r.returncode))
    print(json.dumps({'dry_run': args.dry_run, 'changed': changed, 'unchanged': same, 'luac': luac,
                      'backup_dir': bdir if changed and not args.dry_run else None}, ensure_ascii=False, indent=1))


def cmd_test(args):
    cmd = ['lua5.4', TESTS, R] + ([os.path.join(os.path.abspath(args.staging), 'lua')] if args.staging else [])
    r = subprocess.run(cmd, capture_output=True, text=True)
    print(r.stdout[-4000:] + r.stderr[-2000:])
    sys.exit(r.returncode)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest='cmd', required=True)
    a = sub.add_parser('plan'); a.add_argument('--out', required=True); a.add_argument('--fix', default='storage,condition')
    a = sub.add_parser('apply'); a.add_argument('--staging', required=True); a.add_argument('--dry-run', action='store_true')
    a = sub.add_parser('test'); a.add_argument('--staging')
    args = ap.parse_args()
    {'plan': cmd_plan, 'apply': cmd_apply, 'test': cmd_test}[args.cmd](args)


if __name__ == '__main__':
    main()
