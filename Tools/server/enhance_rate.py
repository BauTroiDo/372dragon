#!/usr/bin/env python3
"""enhance_rate.py - ti le thanh cong cuong hoa dang la BINH PHUONG cot bang (server-data 17/09/2026).

VAN DE. `GameServer/lualib/script_base.lua` `LuaFnEquipEnhance` quay **hai lan**, moi lan cung xac suat
`currate/10000`, va chi thanh cong khi ca hai lan deu trung:

    local currate = downlvinfo.odd * losecount
    local sjrate = math.random(10000)
    if sjrate <= currate then              -- lan 1: P = currate/10000
        sjrate = math.random(10000)
        if sjrate > 10000 - currate then   -- lan 2: P = currate/10000  (viet nguoc lai cho giong khac)
            succ = true

==> P(thanh cong) = (currate/10000)^2. O cap 1 (`odd = 788`, `losecount = 1`) la **0,62 %** chu khong
phai 7,88 % nhu cot `成功率` cua `ItemEnhance.txt`.

VI SAO GOI LA LOI, KHONG PHAI THIET KE - ba dau hieu doc duoc tu chinh ma:

 1. **Chinh server khai bao ti le TUYEN TINH cho nguoi choi.** `LuaFnUpdateEquipEnhanceInfo` (cung file)
    gui len khung 117043021: `qhrate` (= `odd`), `losecount`, va
    `needcount = math.ceil((10000 - odd*losecount) / odd)` - so lan hong con lai cho toi khi chac chan
    thanh cong. Cong thuc `needcount` chi dung khi MOT lan quay o ti le `currate`.
 2. **Hai phep thu la mot phep thu viet hai kieu**: `sjrate <= currate` va `sjrate > 10000 - currate` co
    cung xac suat. Long mot dieu kien vao trong dieu kien tuong duong cua chinh no la dau van cua mot lan
    gop ma, khong phai mot luat choi (mot luat "hai cua" that su se dung hai ti le khac nhau).
 3. Ban server GOC `/home/ubuntu` **giong het** - nghia la loi nay co tu 0.85, khong phai do CY-Source
    gay ra. Sua o day la sua loi cu, va `revert` tra lai nguyen trang 0.85 trong mot lenh.

Lenh:

  enhance_rate.py audit
        chi doc: dang o giai doan nao (goc / probe / fix), cot `成功率` cua ItemEnhance, va bang so sanh
        ti le tuyen tinh vs binh phuong o 10 cap dau.
  enhance_rate.py apply --stage probe [--dry-run]
        THEM dong log `[CYS-ENH]` vao dung cho quay, **khong doi luat choi**. Dung de do "truoc khi sua".
  enhance_rate.py apply --stage fix [--dry-run]
        doi hai lan quay thanh MOT lan quay (giu nguyen dong log). Dung de do "sau khi sua".
  enhance_rate.py revert --backup DIR
        chep nguoc file da sao luu.
  enhance_rate.py analyze --log FILE [--log FILE ...] [--json F]
        doc cac dong `[CYS-ENH]` trong log Game2, tra: so lan thu, so lan thanh cong, ky vong theo hai
        mo hinh, ti so kha di, va **uoc luong so mu a** trong `p = (currate/10000)^a` kem khoang tin cay
        95 % (profile likelihood). `a ~ 1` = dung bang; `a ~ 2` = binh phuong.

Moi lan `apply` deu `luac -p` truoc khi ghi va sao luu vao `R/backups/enhance-rate-<UTC>/`.
CAN RESTART: `lualib/*.lua` chi duoc nap luc khoi dong skynet.

Chay trong WSL TLBB bang root:
    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/enhance_rate.py <lenh>
Dac ta: `Docs/specs/server/server-data_vi.md`.
"""
import argparse
import datetime
import json
import math
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cs3b_menpai import read_table, g  # noqa: E402

R = '/home/ubuntu/cys-test-20260913'
TARGET = 'GameServer/lualib/script_base.lua'
ITEM_ENHANCE = 'configs/ItemEnhance.txt'
MARK = 'CYS-ENH'

HEAD = (
    "    local succ = false\n"
    "\tlocal losecount = Equip:get_param(9, \"ushort\")\n"
    "\tlosecount = losecount + 1\n"
    "\tlocal currate = downlvinfo.odd * losecount\n"
)
TAIL = "\tEquip:set_param(9, losecount, \"ushort\")\n"

ORIG_BODY = (
    "\tlocal sjrate = math.random(10000)\n"
    "\tif sjrate <= currate then\n"
    "\t\tsjrate = math.random(10000)\n"
    "\t\tif sjrate > 10000 - currate then\n"
    "\t\t\tsucc = true\n"
    "\t\t\tqhlv = qhlv + 1\n"
    "\t\t\tlosecount = 0\n"
    "\t\t\tEquip:get_equip_data():set_enhancement_level(qhlv)\n"
    "\t\tend\n"
    "\tend\n"
)

PROBE_BODY = (
    "\t-- CYS-ENH 17/09/2026 (server-data): dau do do ti le cuong hoa. GIU NGUYEN luat choi hai lan quay.\n"
    "\tlocal trycount = losecount\n"
    "\tlocal sjrate = math.random(10000)\n"
    "\tlocal sjrate2 = 0\n"
    "\tif sjrate <= currate then\n"
    "\t\tsjrate2 = math.random(10000)\n"
    "\t\tif sjrate2 > 10000 - currate then\n"
    "\t\t\tsucc = true\n"
    "\t\t\tqhlv = qhlv + 1\n"
    "\t\t\tlosecount = 0\n"
    "\t\t\tEquip:get_equip_data():set_enhancement_level(qhlv)\n"
    "\t\tend\n"
    "\tend\n"
    "\tskynet.error(string.format(\"[CYS-ENH] rolls=2 odd=%d try=%d currate=%d r1=%d r2=%d succ=%s qhlv=%d\","
    " downlvinfo.odd, trycount, currate, sjrate, sjrate2, tostring(succ), qhlv))\n"
)

FIX_BODY = (
    "\t-- CYS-ENH 17/09/2026 (server-data): MOT lan quay, dung bang `ItemEnhance` cot `成功率`.\n"
    "\t-- Ban cu quay HAI lan (`sjrate <= currate` roi `sjrate > 10000 - currate`), moi lan cung xac suat\n"
    "\t-- currate/10000, nen ti le that la BINH PHUONG cot bang (cap 1: 0,62 % thay vi 7,88 %).\n"
    "\t-- Chinh server cung mau thuan: LuaFnUpdateEquipEnhanceInfo gui `qhrate` va `needcount` cho khung\n"
    "\t-- 117043021 theo cong thuc chi dung khi quay MOT lan. Xem Tools/server/enhance_rate.py.\n"
    "\tlocal trycount = losecount\n"
    "\tlocal sjrate = math.random(10000)\n"
    "\tif sjrate <= currate then\n"
    "\t\tsucc = true\n"
    "\t\tqhlv = qhlv + 1\n"
    "\t\tlosecount = 0\n"
    "\t\tEquip:get_equip_data():set_enhancement_level(qhlv)\n"
    "\tend\n"
    "\tskynet.error(string.format(\"[CYS-ENH] rolls=1 odd=%d try=%d currate=%d r1=%d succ=%s qhlv=%d\","
    " downlvinfo.odd, trycount, currate, sjrate, tostring(succ), qhlv))\n"
)

STAGES = {'goc': ORIG_BODY, 'probe': PROBE_BODY, 'fix': FIX_BODY}


# ------------------------------------------------------------------- doc ma

def read_src(root=R):
    with open(os.path.join(root, TARGET), 'r', encoding='utf-8', newline='') as f:
        return f.read()


def current_stage(src):
    for name, body in STAGES.items():
        if HEAD + body + TAIL in src:
            return name
    return None


def swap(src, want):
    stage = current_stage(src)
    if stage is None:
        raise SystemExit('khong tim thay khoi quay cua LuaFnEquipEnhance o dang biet truoc '
                         '-> TU CHOI sua (co ai da sua tay?)')
    if stage == want:
        return None, stage
    return src.replace(HEAD + STAGES[stage] + TAIL, HEAD + STAGES[want] + TAIL, 1), stage


# ------------------------------------------------------------------- audit

def enhance_table(root=R):
    """{(slot, level): odd} tu ItemEnhance.txt - `odd` la cot ti le thanh cong."""
    t = read_table(os.path.join(root, ITEM_ENHANCE))
    names = [g(x) for x in t['names']]
    col = None
    for i, n in enumerate(names):
        if '成功率' in n:
            col = i
            break
    return names, col, t


def cmd_audit(args):
    src = read_src()
    stage = current_stage(src)
    names, col, t = enhance_table()
    rows = []
    for r in t['rows'][:12]:
        try:
            odd = int(g(r[col]))
        except (ValueError, TypeError):
            continue
        rows.append((g(r[0]), g(r[1]) if len(r) > 1 else '', odd))
    print(json.dumps({
        'file': os.path.join(R, TARGET),
        'giai_doan': stage or 'KHONG NHAN RA',
        'cot_ti_le': (col, names[col] if col is not None else None),
        'so_dong_ItemEnhance': len(t['rows']),
    }, ensure_ascii=False, indent=2))
    print()
    print('%-8s %-8s %-10s %-12s %-12s' % ('dong', 'cot2', 'odd', 'tuyen tinh', 'binh phuong'))
    for a, b, odd in rows:
        p = odd / 10000.0
        print('%-8s %-8s %-10d %-12s %-12s' % (a, b, odd, '%.4f %%' % (p * 100), '%.4f %%' % (p * p * 100)))
    print()
    print('E[so lan thu de len 1 cap] o dong dau (pity counter tang dan):')
    if rows:
        odd = rows[0][2]
        for lbl, a in (('tuyen tinh', 1.0), ('binh phuong', 2.0)):
            s, e = 1.0, 1.0
            for k in range(1, 200):
                p = min(1.0, (min(odd * k, 10000) / 10000.0) ** a)
                s *= (1 - p)
                e += s
                if s <= 0:
                    break
            print('   %-12s %.3f lan' % (lbl, e))
    return 0


# ------------------------------------------------------------------- apply

def luac_ok(path):
    for exe in ('luac', 'luac5.4'):
        r = subprocess.run([exe, '-p', path], capture_output=True)
        if r.returncode == 0:
            return True, ''
    return False, (r.stderr or r.stdout).decode('utf-8', 'replace')[:300]


def cmd_apply(args):
    src = read_src()
    new, stage = swap(src, args.stage)
    if new is None:
        print(json.dumps({'ket_qua': 'da o giai doan nay roi', 'giai_doan': stage},
                         ensure_ascii=False))
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'enhance-rate-%s' % stamp)
    if args.dry_run:
        print(json.dumps({'dry_run': True, 'tu': stage, 'sang': args.stage,
                          'byte_truoc': len(src), 'byte_sau': len(new)}, ensure_ascii=False))
        return 0
    os.makedirs(os.path.join(bdir, os.path.dirname(TARGET)), exist_ok=True)
    tmp = os.path.join(bdir, '_check.lua')
    with open(tmp, 'w', encoding='utf-8', newline='') as f:
        f.write(new)
    ok, err = luac_ok(tmp)
    os.remove(tmp)
    if not ok:
        raise SystemExit('luac -p HONG: %s' % err)
    shutil.copyfile(os.path.join(R, TARGET), os.path.join(bdir, TARGET))
    with open(os.path.join(R, TARGET), 'w', encoding='utf-8', newline='') as f:
        f.write(new)
    res = {'sao_luu': bdir, 'tu': stage, 'sang': args.stage,
           'byte_truoc': len(src), 'byte_sau': len(new)}
    with open(os.path.join(bdir, 'apply.json'), 'w', encoding='utf-8') as f:
        json.dump(res, f, ensure_ascii=False, indent=2)
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0


def cmd_revert(args):
    src = os.path.join(args.backup, TARGET)
    if not os.path.exists(src):
        raise SystemExit('khong thay %s' % src)
    shutil.copyfile(src, os.path.join(R, TARGET))
    ok, err = luac_ok(os.path.join(R, TARGET))
    print(json.dumps({'da_chep_nguoc': TARGET, 'tu': args.backup, 'luac': ok, 'loi': err},
                     ensure_ascii=False))
    return 0


def cmd_verify(args):
    src = read_src()
    stage = current_stage(src)
    ok, err = luac_ok(os.path.join(R, TARGET))
    res = {'giai_doan': stage, 'luac': ok, 'loi': err,
           'ok': stage is not None and ok}
    print(json.dumps(res, ensure_ascii=False, indent=2))
    return 0 if res['ok'] else 1


# ------------------------------------------------------------------- analyze

LINE = re.compile(r'\[CYS-ENH\] rolls=(\d+) odd=(\d+) try=(\d+) currate=(\d+) '
                  r'r1=(\d+)(?: r2=(\d+))? succ=(true|false) qhlv=(\d+)')


def loglik(att, a):
    s = 0.0
    for c, ok in att:
        p = min(1.0, (min(c, 10000) / 10000.0) ** a)
        p = min(max(p, 1e-12), 1 - 1e-12)
        s += math.log(p) if ok else math.log(1 - p)
    return s


def profile_ci(att, lo=0.05, hi=8.0, step=0.001):
    """Khoang tin cay 95 % cho so mu a bang profile likelihood (nguong chi-binh-phuong 3.841/2)."""
    best_a, best_l = None, -1e18
    a = lo
    grid = []
    while a <= hi:
        l = loglik(att, a)
        grid.append((a, l))
        if l > best_l:
            best_a, best_l = a, l
        a += step
    thr = best_l - 1.920729
    inside = [x for x, l in grid if l >= thr]
    return best_a, (min(inside) if inside else None), (max(inside) if inside else None), best_l


def cmd_analyze(args):
    att, rolls, nlines = [], set(), 0
    first_try = []
    for p in args.log:
        with open(p, 'rb') as f:
            data = f.read().decode('utf-8', 'replace')
        for m in LINE.finditer(data):
            nlines += 1
            rolls.add(int(m.group(1)))
            c, ok, tr = int(m.group(4)), m.group(7) == 'true', int(m.group(3))
            att.append((c, ok))
            if tr == 1:
                first_try.append((c, ok))
    if not att:
        raise SystemExit('khong thay dong [CYS-ENH] nao trong %s' % args.log)
    n, k = len(att), sum(1 for _c, o in att if o)
    e_lin = sum(min(1.0, min(c, 10000) / 10000.0) for c, _o in att)
    e_sq = sum(min(1.0, min(c, 10000) / 10000.0) ** 2 for c, _o in att)
    ll_lin, ll_sq = loglik(att, 1.0), loglik(att, 2.0)
    a_hat, a_lo, a_hi, ll_best = profile_ci(att)
    res = {
        'so_dong_log': nlines, 'rolls_trong_log': sorted(rolls),
        'so_lan_thu': n, 'so_lan_thanh_cong': k,
        'ky_vong_neu_TUYEN_TINH': round(e_lin, 2),
        'ky_vong_neu_BINH_PHUONG': round(e_sq, 2),
        'logL_tuyen_tinh': round(ll_lin, 3), 'logL_binh_phuong': round(ll_sq, 3),
        'logLR_tuyen_tinh_tru_binh_phuong': round(ll_lin - ll_sq, 3),
        'so_mu_a_uoc_luong': round(a_hat, 3),
        'KTC95_a': [None if a_lo is None else round(a_lo, 3),
                    None if a_hi is None else round(a_hi, 3)],
        'ket_luan': ('dung bang (a ~ 1)' if a_lo is not None and a_lo <= 1.0 <= a_hi else
                     ('binh phuong (a ~ 2)' if a_lo is not None and a_lo <= 2.0 <= a_hi else
                      'khong khop mo hinh nao')),
    }
    if first_try:
        nf, kf = len(first_try), sum(1 for _c, o in first_try if o)
        cf = first_try[0][0]
        res['lan_thu_dau_tien'] = {
            'so_lan': nf, 'thanh_cong': kf,
            'ti_le_thuc_nghiem': round(kf / nf, 4),
            'currate_hay_gap': cf,
            'cot_bang': round(min(cf, 10000) / 10000.0, 4),
            'binh_phuong_cot': round((min(cf, 10000) / 10000.0) ** 2, 4),
        }
    print(json.dumps(res, ensure_ascii=False, indent=2))
    if args.json:
        with open(args.json, 'w', encoding='utf-8') as f:
            json.dump({**res, 'thu': att}, f, ensure_ascii=False, indent=2)
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('audit'); p.set_defaults(fn=cmd_audit)
    p = sub.add_parser('apply'); p.add_argument('--stage', required=True, choices=sorted(STAGES))
    p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('revert'); p.add_argument('--backup', required=True); p.set_defaults(fn=cmd_revert)
    p = sub.add_parser('verify'); p.set_defaults(fn=cmd_verify)
    p = sub.add_parser('analyze'); p.add_argument('--log', action='append', required=True)
    p.add_argument('--json'); p.set_defaults(fn=cmd_analyze)
    a = ap.parse_args()
    sys.exit(a.fn(a))


if __name__ == '__main__':
    main()
