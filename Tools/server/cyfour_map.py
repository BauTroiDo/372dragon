#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cyfour_map — thêm mục descriptor cho các dòng StandardImpact MỚI dùng logic donor của cy_four_combat.

Vì sao: `cy_four_combat/engine.lua:67` làm
    assert(self.config.impacts[imp:get_data_index()], "unmapped positional impact")
nên MỌI dòng StandardImpact có 逻辑ID thuộc nhóm donor (≥ 8000) phải có mục trong
`lualib/cy_four_combat/native_config.lua` bảng `impacts={}`. impact-data thêm dòng mới (nhân bản dòng CY
đã có) nhưng bảng positional chưa có Data_Index mới → sập khi nạp buff lúc đăng nhập và khi dùng chiêu.

  cyfour_map.py check                     đối chiếu dữ liệu, KHÔNG ghi gì (in các dòng thiếu + lệch)
  cyfour_map.py plan  --out <dir>         dựng native_config.lua mới (không chạm R)
  cyfour_map.py apply --staging <dir>     chép vào R, sao lưu R/backups/cyfour-map-<UTC>/
  cyfour_map.py verify                    0 dòng logic donor nào thiếu mục; luac sạch

Quy tắc dựng mục (giữ nguyên ngữ nghĩa donor):
    impacts[id_mới] = <descriptor của dòng mẫu, chép NGUYÊN: donor_id, donor_logic, step0, params>

KHÔNG dựng `params` từ ô 参数值 thô của bảng: bộ sinh native_config đã phân giải các ô kiểu
"ID hiệu ứng" sang ID phía native (vd [4465] params[2] = 60958 trong khi bảng ghi 4555), nên dựng lại
từ bảng sẽ trỏ sai hiệu ứng. Đổi lại, `check` kiểm bằng DỮ LIỆU rằng dòng mới đúng là bản nhân bản
của dòng mẫu trong chính bảng (cùng 逻辑ID, cùng 16 ô 参数值, cùng 修正步长) và in ra mọi chỗ khác.
"""
import argparse
import ast
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

R = '/home/ubuntu/cys-test-20260913'
CFG = 'GameServer/lualib/cy_four_combat/native_config.lua'
SI = 'configs/StandardImpact.txt'
MAP_TSV = '/mnt/c/TLBB/085/CY-Source/Build/Logs/2026-09-16-impact-data/cyfour-map.tsv'
MARK = 'skill-logic cyfour-map'
# 17/09: hai overlay được nạp ở integration.lua:5-7 (phase2.configure -> phase3 -> release.configure)
# TRƯỚC khi dựng bridge. Chúng cấp cả mục mô tả `impacts` lẫn `resolve.impacts` cho 7 ID mà
# native_config.lua không có. Công cụ này PHẢI đọc chúng, nếu không sẽ báo "còn thiếu 7" gây hiểu nhầm.
# Xem Docs/specs/server/cy-four-mapping_vi.md.
OVERLAYS = ['GameServer/lualib/cy_four_combat/phase2_config.lua',
            'GameServer/lualib/cy_four_combat/release_config.lua']
DONOR_MIN = 8000          # 逻辑ID >= 8000 = nhóm donor của cy_four (xem skillenginer/impactenginer assert)
NPARAM = 16
P0 = 27                   # cột 参数1说明; mỗi ô 3 cột (说明, 参数值, 修正步长)

ENTRY_RE = re.compile(
    r'\[(\d+)\]=\{donor_id=(\d+),donor_logic=(\d+),step0=([-\d.eE+]+),params=\{([^}]*)\}\}')


def g(b):
    return b.decode('gbk', 'replace')


def read_si(path):
    """{id: {'logic': int, 'params': [16 int], 'step0': float}}"""
    data = open(path, 'rb').read()
    lines = [l.rstrip(b'\r') for l in data.split(b'\n')]
    out = {}
    for l in lines[2:]:
        if not l.strip():
            continue
        c = l.split(b'\t')
        try:
            i = int(g(c[0]).strip())
        except Exception:
            continue

        def num(idx, cast=int):
            if idx >= len(c):
                return cast(0)
            s = g(c[idx]).strip()
            if s == '':
                return cast(0)
            try:
                return cast(float(s)) if cast is int else cast(s)
            except Exception:
                return cast(0)
        try:
            logic = int(g(c[2]).strip())
        except Exception:
            continue
        out[i] = {'logic': logic,
                  'params': [num(P0 + 1 + 3 * k) for k in range(NPARAM)],
                  'step0': num(P0 + 2, float)}
    return out


def read_cfg(path):
    txt = open(path, 'rb').read().decode('utf-8')
    entries = {}
    for m in ENTRY_RE.finditer(txt.replace(' ', '')):
        entries[int(m.group(1))] = {
            'donor_id': int(m.group(2)), 'donor_logic': int(m.group(3)),
            'step0': float(m.group(4)),
            'params': [int(float(x)) for x in m.group(5).split(',') if x != '']}
    return txt, entries


def read_overlay(path):
    """ID impact do overlay cấp: cả bảng mô tả ["impacts"] lẫn ánh xạ ["resolve"]["impacts"]."""
    try:
        txt = open(path, 'rb').read().decode('utf-8')
    except OSError:
        return set(), set()
    flat = txt.replace(' ', '')
    desc = set()
    # BẪY: chỗ `["impacts"]={` ĐẦU TIÊN nằm trong `["resolve"]={["impacts"]={...` (bảng ánh xạ),
    # không phải bảng mô tả. Chọn đúng chỗ có `["donor_id"]` ngay sau đó.
    m = next((x for x in re.finditer(r'\["impacts"\]=\{', flat)
              if flat[x.end():x.end() + 40].find('["donor_id"]') >= 0), None)
    if m:
        seg, depth, i = '', 1, m.end()
        while i < len(flat) and depth:
            ch = flat[i]
            depth += (ch == '{') - (ch == '}')
            if depth:
                seg += ch
            i += 1
        desc = {int(x) for x in re.findall(r'\[(\d+)\]=\{\["donor_id"\]', seg)}
    res = set()
    m = re.search(r'\["resolve"\]=\{\["impacts"\]=\{([^}]*)\}', flat)
    if m:
        res = {int(a) for a, _ in re.findall(r'\[(\d+)\]=(\d+)', m.group(1))}
    return desc, res


def read_overlays():
    desc, res = set(), set()
    for rel in OVERLAYS:
        d, r = read_overlay(os.path.join(R, rel))
        desc |= d
        res |= r
    return desc, res


def read_map(path):
    rows = []
    with open(path, encoding='utf-8-sig') as f:
        head = f.readline().rstrip('\n').split('\t')
        for line in f:
            if not line.strip():
                continue
            c = line.rstrip('\n').split('\t')
            rows.append(dict(zip(head, c)))
    return rows


def fmt_entry(key, e):
    return '  [%d]={donor_id=%d,donor_logic=%d,step0=%s,params={%s}},' % (
        key, e['donor_id'], e['donor_logic'],
        ('%g' % e['step0']) if e['step0'] % 1 else ('%.1f' % e['step0']),
        ','.join(str(int(v)) for v in e['params']))


def build(args):
    si = read_si(os.path.join(R, SI))
    txt, cfg = read_cfg(os.path.join(R, CFG))
    rows = read_map(MAP_TSV)
    add, issues, skipped = {}, [], []
    for r in rows:
        new = int(r['impact_id_moi'])
        donor = int(r['dong_mau_goc_da_anh_xa'])
        if new in cfg:
            skipped.append(('da co muc', new))
            continue
        if donor not in cfg:
            issues.append(('dong mau KHONG co muc trong native_config', new, donor))
            continue
        if new not in si:
            issues.append(('dong moi KHONG co trong StandardImpact', new, donor))
            continue
        d = cfg[donor]
        s = si[new]
        # 逻辑ID trong StandardImpact = 8000 + donor_logic của native_config (nhóm donor cy_four)
        if s['logic'] - DONOR_MIN != d['donor_logic']:
            issues.append(('lech logic: dong moi %d vs donor %d (+8000)' % (s['logic'], d['donor_logic']), new, donor))
            continue
        # Descriptor được chép NGUYÊN của dòng mẫu: `params` trong native_config KHÔNG phải ô
        # 参数值 thô của bảng (vd [4465] có params[2]=60958 trong khi bảng ghi 4555) — bộ sinh đã
        # phân giải các ô kiểu "ID hiệu ứng" sang ID phía native. Vì vậy chép nguyên là cách duy
        # nhất giữ đúng ngữ nghĩa; đổi sang số thô của bảng sẽ trỏ sai hiệu ứng.
        e = {'donor_id': d['donor_id'], 'donor_logic': d['donor_logic'],
             'step0': d['step0'], 'params': list(d['params'])}
        # kiểm bằng DỮ LIỆU: dòng mới phải là bản nhân bản của dòng mẫu trong chính bảng
        sd = si.get(donor)
        if sd is None:
            issues.append(('dong mau KHONG co trong StandardImpact', new, donor))
        elif s['params'] != sd['params'] or abs(s['step0'] - sd['step0']) > 1e-9 or s['logic'] != sd['logic']:
            issues.append(('CANH BAO: dong moi KHAC dong mau trong bang (xem lai truoc khi ap)', new, donor))
        add[new] = e
    # mọi dòng logic donor trong bảng mà thiếu mục (không chỉ 158 dòng của TSV)
    unmapped = sorted(i for i, v in si.items() if v['logic'] >= DONOR_MIN and i not in cfg and i not in add)
    # các dòng cy_four vốn đã thiếu mục từ TRƯỚC lượt impact-data (guigu/tao dùng đường "literal impacts",
    # không qua bảng positional) — không thuộc phạm vi sửa này
    pre = sorted(i for i in unmapped if i not in {int(r['impact_id_moi']) for r in rows})
    # ... nhưng phần lớn/tất cả số đó do overlay cấp lúc khởi động, KHÔNG phải lỗ hổng dữ liệu
    ov_desc, ov_res = read_overlays()
    ov = ov_desc | ov_res
    pre_overlay = [i for i in pre if i in ov]
    pre_that = [i for i in pre if i not in ov]
    return si, txt, cfg, add, issues, skipped, unmapped, pre, pre_overlay, pre_that


def cmd_check(args):
    si, txt, cfg, add, issues, skipped, unmapped, pre, pre_overlay, pre_that = build(args)
    print(json.dumps({'muc_san_co': len(cfg), 'dong_TSV': len(read_map(MAP_TSV)),
                      'se_them': len(add), 'bo_qua_da_co': len(skipped),
                      'canh_bao': len(issues), 'con_thieu_sau_khi_them': len(unmapped),
                      'trong_do_thieu_tu_truoc': pre,
                      'do_overlay_cap_khi_khoi_dong': pre_overlay,
                      'THIEU_THAT_SU': pre_that},
                     ensure_ascii=False, indent=1))
    if pre_overlay:
        print('  GHI CHU: %d ID tren do phase2_config/release_config cap luc khoi dong '
              '(integration.lua:5-7) => KHONG phai lo hong, va THEM TAY vao native_config.lua '
              'se lam release.lua:10 assert => hong scene. Xem Docs/specs/server/cy-four-mapping_vi.md'
              % len(pre_overlay))
    for kind, new, donor in issues[:40]:
        print('  %-55s moi=%d mau=%d' % (kind, new, donor))
    if unmapped:
        print('  CON THIEU:', unmapped[:40])
    return 0 if not [i for i in unmapped if i not in pre] and not pre_that else 1


def cmd_plan(args):
    si, txt, cfg, add, issues, skipped, unmapped, pre, pre_overlay, pre_that = build(args)
    if not add:
        print(json.dumps({'se_them': 0, 'ghi_chu': 'khong co gi de them'}, ensure_ascii=False))
    clean = re.sub(r'(?m)^\s*--\s*' + re.escape(MARK) + r'.*\n', '', txt)
    clean = re.sub(r'(?m)^\s*\[\d+\]=\{donor_id=\d+,donor_logic=\d+,step0=[-\d.eE+]+,params=\{[^}]*\}\},\s*--\s*'
                   + re.escape(MARK) + r'\n', '', clean)
    i = clean.index('impacts={')
    j = clean.index('\n},disabled_logic_ids=', i)
    lines = ['  -- %s (16/09/2026): dòng StandardImpact mới của impact-data dùng logic donor cy_four;' % MARK,
             '  -- donor_id/donor_logic lấy từ dòng mẫu đã có mục, step0/params lấy từ CHÍNH dòng mới.']
    for k in sorted(add):
        lines.append(fmt_entry(k, add[k]) + ' -- ' + MARK)
    new_txt = clean[:j + 1] + '\n'.join(lines) + '\n' + clean[j + 1:]
    dst = os.path.join(args.out, CFG)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, 'wb') as f:
        f.write(new_txt.encode('utf-8'))
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump({'added': sorted(add), 'count': len(add), 'issues': issues,
                   'unmapped_after': unmapped, 'pre_existing_unmapped': pre}, f, ensure_ascii=False, indent=1)
    print(json.dumps({'se_them': len(add), 'canh_bao': len(issues), 'con_thieu': len(unmapped),
                      'file': dst}, ensure_ascii=False, indent=1))


def cmd_apply(args):
    src = os.path.join(args.staging, CFG)
    dst = os.path.join(R, CFG)
    new = open(src, 'rb').read()
    old = open(dst, 'rb').read()
    if new == old:
        print(json.dumps({'changed': False}, ensure_ascii=False))
        return
    if args.dry_run:
        print(json.dumps({'changed': True, 'dry_run': True}, ensure_ascii=False))
        return
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'cyfour-map-' + stamp)
    os.makedirs(os.path.join(bdir, os.path.dirname(CFG)), exist_ok=True)
    shutil.copy2(dst, os.path.join(bdir, CFG))
    with open(dst, 'wb') as f:
        f.write(new)
    print(json.dumps({'changed': True, 'backup': bdir}, ensure_ascii=False))


def cmd_verify(args):
    base = os.path.join(args.staging, CFG) if args.staging else os.path.join(R, CFG)
    si = read_si(os.path.join(R, SI))
    txt, cfg = read_cfg(base)
    unmapped = sorted(i for i, v in si.items() if v['logic'] >= DONOR_MIN and i not in cfg)
    pre = sorted(i for i in unmapped if i not in {int(x['impact_id_moi']) for x in read_map(MAP_TSV)})
    new_unmapped = [i for i in unmapped if i not in pre]
    r = subprocess.run(['luac5.4', '-p', base], capture_output=True)
    lua_ok = r.returncode == 0
    # bảng phải nạp được và mục mới phải đọc đúng
    loaded = subprocess.run(['lua5.4', '-e',
                             'local t=dofile(%r); local n=0; for _ in pairs(t.impacts) do n=n+1 end; print(n)' % base],
                            capture_output=True)
    # mục mới phải trùng KHÍT descriptor của dòng mẫu (kiểm bằng chính bảng ánh xạ)
    bad = []
    for r in read_map(MAP_TSV):
        n, d = int(r['impact_id_moi']), int(r['dong_mau_goc_da_anh_xa'])
        if n not in cfg:
            bad.append(('thieu muc', n, d))
        elif cfg[n] != cfg.get(d):
            bad.append(('khac descriptor dong mau', n, d))
    res_bad = bad[:10]
    res = {'file': base, 'muc': len(cfg), 'muc_sai': len(bad), 'muc_sai_vi_du': res_bad,
           'cyfour_unmapped': len(new_unmapped),
           'unmapped_ids': new_unmapped[:20], 'pre_existing_unmapped': pre, 'luac_ok': lua_ok,
           'lua_load_count': loaded.stdout.decode().strip(), 'lua_load_rc': loaded.returncode}
    if not lua_ok:
        res['luac_err'] = r.stderr.decode('utf-8', 'replace').strip()
    res['ok'] = lua_ok and loaded.returncode == 0 and not new_unmapped and not bad
    print(json.dumps(res, ensure_ascii=False, indent=1))
    return 0 if res['ok'] else 1


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('check'); p.set_defaults(fn=cmd_check)
    p = sub.add_parser('plan'); p.add_argument('--out', required=True); p.set_defaults(fn=cmd_plan)
    p = sub.add_parser('apply'); p.add_argument('--staging', required=True); p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('verify'); p.add_argument('--staging'); p.set_defaults(fn=cmd_verify)
    a = ap.parse_args()
    sys.exit(a.fn(a) or 0)


if __name__ == '__main__':
    main()
