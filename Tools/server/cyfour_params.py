# -*- coding: utf-8 -*-
"""Sửa các ô `params` của `cy_four_combat/native_config.lua` đang trỏ vào ID KHÔNG TỒN TẠI.

Vì sao cần: bộ sinh `native_config` phân giải các ô "ID hiệu ứng" sang ID phía client donor.
Với server này thì `resolve = đồng nhất` (xem đầu `native_config.lua`), nên vài khối bị lệch hẳn
sang một dải ID mà `configs/StandardImpact.txt` KHÔNG có dòng nào. Khi chạy tới đó:

    runtime_adapter.lua:77  assert -> "missing selected impact 60958"
    <- native.interval_167 <- std_impact_081.heart_beat, lặp MỖI 3 GIÂY MÃI MÃI,
    và buff 战可得威 có 总持续时间 = -1 (vĩnh viễn) nên nó lưu xuống Mongo và sống lại mỗi lần
    đăng nhập => nhân vật tự đầu độc, phải xoá tay `impact_list`.

Bằng chứng đo được (skill-logic-5, 17/09): impact SỐNG trên nhân vật có data_index 45184,
logic_id 8167, params 4554/4556/4557/4559 — đúng như bảng ghi; còn native_config ghi 60953-60962,
mà `StandardImpact` không có dòng nào trong 60950-60965 và CÓ ĐỦ 4550-4559.

LUẬT SỬA (chỉ sửa khi CẢ BA đúng, kiểm trên bảng SỐNG):
  1. Ô đó là ô "ID HIỆU ỨNG": phần 说明 của chính ô ấy trong dòng mẫu có chứa `效果`.
     (KHÔNG áp cho ô `初始技能`/`替换技能` của logic 171: đó là ID KỸ NĂNG, trùng dải với
      impact chỉ là ngẫu nhiên - sửa theo bảng sẽ SAI.)
  2. Giá trị native KHÔNG có dòng trong StandardImpact.
  3. Giá trị của bảng CÓ dòng trong StandardImpact.
  Ngoài ra bỏ qua mọi ô <= 1000 (tham số số học như 回调时间, 修正率).

KHÔNG đụng:
  - Mọi mục logic 99 (13305-13316): các ô lệch ở đó là ánh xạ CỐ Ý của đợt trap-recollide
    (2088-2099, 505/506 là dòng CY nhập mới) - native đúng, bảng là bản GL cũ.
  - Mọi mục logic 171 (13262/13263/49941/49943): ô lệch là ID kỹ năng, xem luật 1.
  - Ô `纪录陷阱的buffID` = 61032 của khối logic 99: native không tồn tại, nhưng giá trị bảng là 9
    (<= 1000) nên không nằm trong luật. Ghi ra `canh_bao` để người phụ trách trap xem.

  cyfour_params.py plan   [--out <json>]   in ra từng ô sẽ sửa, KHÔNG ghi
  cyfour_params.py apply  [--out <json>]   sao lưu rồi ghi (idempotent: chạy lại ra 0 ô)
  cyfour_params.py verify [--out <json>]   đọc lại bảng sống, khẳng định không còn ô nào phạm luật
"""
import argparse
import json
import os
import re
import shutil
import sys
import time

R = '/home/ubuntu/cys-test-20260913'
CFG = 'GameServer/lualib/cy_four_combat/native_config.lua'
SI = 'configs/StandardImpact.txt'
P0 = 27          # cột 参数1说明; mỗi ô 3 cột (说明, 参数值, 修正步长)
NPARAM = 16
MIN_ID = 1000    # ô <= 1000 coi là tham số số học, không phải ID

ENTRY_RE = re.compile(
    r'\[(\d+)\]=\{donor_id=(\d+),donor_logic=(\d+),step0=([-\d.eE+]+),params=\{([^}]*)\}\}')


def read_si(path):
    rows = {}
    for line in open(path, 'rb').read().decode('gbk', 'replace').split('\n'):
        c = line.split('\t')
        if c and c[0].strip().isdigit():
            rows[int(c[0].strip())] = c
    return rows


def cell(rows, rid, k):
    """(nhãn, 参数值) của ô thứ k (0-based) trong dòng rid.

    BẪY BẢNG: nhiều dòng bị LỆCH MỘT CỘT ở phần nhãn — nhãn của ô k nằm ở cột 修正步长 của ô k-1,
    còn cột 说明 của chính ô k thì RỖNG. Ví dụ dòng 45184: ô1 说明=回调时间, ô1 步长=给自己的效果1,
    ô2 说明=(rỗng), ô2 值=4555. Vì vậy nhãn = 说明 của ô k GHÉP với cột ngay trước nó.
    (Chính ô 4555/60958 này là ô làm `runtime_adapter.lua:77` assert, nên bỏ sót nó là hỏng việc.)
    """
    c = rows.get(rid)
    i = P0 + k * 3
    if not c or i + 1 >= len(c):
        return '', 0
    nhan = (c[i - 1] if k > 0 and i - 1 < len(c) else '') + '|' + c[i]
    v = c[i + 1].strip()
    try:
        return nhan, int(float(v)) if v else 0
    except ValueError:
        return nhan, 0


def read_cfg(path):
    txt = open(path, 'rb').read().decode('utf-8')
    out = {}
    for m in ENTRY_RE.finditer(txt.replace(' ', '')):
        out[int(m.group(1))] = {
            'donor': int(m.group(2)), 'logic': int(m.group(3)),
            'params': [int(float(x)) for x in m.group(5).split(',') if x != ''],
            'raw': m.group(0)}
    return txt, out


def build():
    rows = read_si(os.path.join(R, SI))
    txt, cfg = read_cfg(os.path.join(R, CFG))
    fixes, canh_bao = [], []
    for n in sorted(cfg):
        d = cfg[n]
        for k in range(min(len(d['params']), NPARAM)):
            a = d['params'][k]
            desc, b = cell(rows, d['donor'], k)
            if a == b or a in rows or b not in rows:
                continue
            chung = {'muc': n, 'donor': d['donor'], 'logic': d['logic'], 'o': k + 1,
                     'mo_ta': desc.strip(), 'native': a, 'bang': b}
            if '效果' not in desc:
                chung['ly_do'] = 'o KHONG phai "hieu ung" -> khong sua theo luat 1'
                canh_bao.append(chung)
            elif a <= MIN_ID or b <= MIN_ID:
                chung['ly_do'] = 'gia tri <= %d -> coi la tham so so hoc' % MIN_ID
                canh_bao.append(chung)
            else:
                fixes.append(chung)
    return rows, txt, cfg, fixes, canh_bao


def rewrite(txt, cfg, fixes):
    """Thay `params={...}` của từng mục. `raw` đã bỏ dấu cách nên phải dò lại vị trí thật."""
    by_entry = {}
    for f in fixes:
        by_entry.setdefault(f['muc'], []).append(f)
    out = txt
    for n, fs in by_entry.items():
        params = list(cfg[n]['params'])
        for f in fs:
            params[f['o'] - 1] = f['bang']
        old = cfg[n]['raw']
        new = re.sub(r'params=\{[^}]*\}', 'params={%s}' % ','.join(str(v) for v in params), old)
        idx = out.replace(' ', '').find(old)
        if idx < 0:
            raise SystemExit('khong tim thay muc [%d] trong file' % n)
        real = seen = 0
        while seen < idx:
            if out[real] != ' ':
                seen += 1
            real += 1
        end, seen = real, 0
        while seen < len(old):
            if out[end] != ' ':
                seen += 1
            end += 1
        out = out[:real] + new + out[end:]
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('plan', 'apply', 'verify'))
    ap.add_argument('--out', default='')
    args = ap.parse_args()
    rows, txt, cfg, fixes, canh_bao = build()
    rec = {'lenh': args.cmd, 'dong_StandardImpact': len(rows), 'muc_native_config': len(cfg),
           'so_o_sua': len(fixes), 'so_muc_sua': len(set(f['muc'] for f in fixes)),
           'so_canh_bao': len(canh_bao), 'canh_bao': canh_bao, 'sua': fixes}
    if args.cmd == 'apply' and fixes:
        src = os.path.join(R, CFG)
        bak = os.path.join(R, 'backups',
                           'cyfour-params-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()))
        os.makedirs(bak, exist_ok=True)
        shutil.copy2(src, os.path.join(bak, 'native_config.lua'))
        open(src, 'wb').write(rewrite(txt, cfg, fixes).encode('utf-8'))
        rec['sao_luu'] = bak
        _, cfg2 = read_cfg(src)
        rec['kiem_lai'] = all(cfg2[f['muc']]['params'][f['o'] - 1] == f['bang'] for f in fixes)
    if args.cmd == 'verify':
        rec['ok'] = not fixes
    print(json.dumps({k: v for k, v in rec.items() if k not in ('sua', 'canh_bao')},
                     ensure_ascii=False, indent=1))
    for f in fixes[:20]:
        print('  SUA  [%d] donor=%d logic=%d o%-2d %-22s %d -> %d'
              % (f['muc'], f['donor'], f['logic'], f['o'], f['mo_ta'][:22], f['native'], f['bang']))
    if len(fixes) > 20:
        print('  ... tong %d o se sua' % len(fixes))
    for c in canh_bao[:10]:
        print('  BO QUA [%d] o%-2d %-22s %d -> %d : %s'
              % (c['muc'], c['o'], c['mo_ta'][:22], c['native'], c['bang'], c['ly_do']))
    if len(canh_bao) > 10:
        print('  ... tong %d canh bao' % len(canh_bao))
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as fh:
            json.dump(rec, fh, ensure_ascii=False, indent=1)
    return 0 if (args.cmd != 'verify' or not fixes) else 1


if __name__ == '__main__':
    sys.exit(main())
