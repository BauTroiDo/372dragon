#!/usr/bin/env python3
"""power-equip — chặn lỗi "mất sạch thuộc tính trang bị" khi trang bị mang viên ngọc lạ.

VÌ SAO (đo được, không phải rủi ro lý thuyết):

`GameServer/lualib/item.lua` `equip_data:get_gem_attrs()` duyệt `list_2[1..4]` (danh sách ngọc đã khảm),
tra `gem_config[id]` rồi dùng **thẳng** `config[chn]` mà KHÔNG kiểm `config == nil`. Hàm này được gọi ở
`lualib/db/human_attrib.lua:1753` bên trong `common_equip_effect_flush()`, tức mỗi lần tính lại thuộc
tính trang bị. Một ID ngọc có trong `list_2` nhưng thiếu dòng trong `configs/GemInfo.txt` sẽ ném
"attempt to index a nil value" ngay giữa `item_effect_flush` ⇒ **nhân vật mất toàn bộ thuộc tính do
trang bị cộng**. Cùng lớp lỗi với vụ `StandardImpact` thiếu 161 ID (xem `Docs/specs/net/item_vi.md`).

ID ngọc lạ đến từ đâu: `lualib/human_item_logic.lua gem_compound_item_index()` tính ID ngọc cấp kế tiếp
**thuần số học** (`item_index + 100000`, hoặc `+100001`) và chỉ chặn khi `quality > MAX_GEM_QUALITY[env]`
(= 8 với `publish_yu`). Nó KHÔNG kiểm `gem_info[new]` có tồn tại không. Đường vào là gói **893
`CGGemCompound`** → `scenecore:char_gem_compound` — gọi thẳng từ client, **không cần NPC**.
Đo trên bảng sống (`Build/Logs/2026-09-17-power-equip/gem-compound-audit.json`):
**30/417 công thức ghép cho ra ID không có dòng** (cả dải 肩 cấp 4 → cấp 5, ví dụ 50431001 → 50531001).

BẢN VÁ: thêm đúng một nhánh `if config == nil then ... else ... end` — bỏ qua viên ngọc lạ và in log
một lần cho mỗi ID. Không đổi số, không đổi công thức, không đổi hành vi của ngọc hợp lệ.

⚠ `lualib/*.lua` chỉ được nạp lúc khởi động dịch vụ skynet ⇒ **bản vá chỉ có hiệu lực sau lần restart
kế tiếp**. Công cụ này KHÔNG restart.

Lệnh:

  gem_guard.py audit                     đếm ID ngọc thiếu + liệt kê công thức ghép hỏng (chỉ đọc)
  gem_guard.py plan                      in đoạn trước/sau, cho biết đã vá hay chưa (chỉ đọc)
  gem_guard.py apply  [--dry-run]        sao lưu R/backups/gem-guard-<UTC>/ rồi ghi đè item.lua
  gem_guard.py verify                    kiểm bản vá có mặt, cân bằng `end`, và `luac`/`lua -p` cú pháp
  gem_guard.py revert --backup <dir>     trả lại item.lua từ một thư mục sao lưu

Idempotent: `apply` lần hai báo `nothing to do`.

Chạy trong WSL TLBB bằng root:
    python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/gem_guard.py <lệnh>
Đặc tả: `Docs/specs/net/power-equip_vi.md`.
"""
import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

R = '/home/ubuntu/cys-test-20260913'
TARGET = os.path.join(R, 'GameServer', 'lualib', 'item.lua')
CFG = os.path.join(R, 'configs')
MARK = 'gem-guard'

OLD = """function equip_data:get_gem_attrs()
    local gem_attrs = {}
    local gem_config = configenginer:get_config("gem_info")
    for i = 1, 4 do
        local id = self.list_2[i] or 0
        if id > 0 then
            local config = gem_config[id]
            for i = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP, define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS do
                local chn = define.CHN_ATTR_SHIFT[i]
                if chn then
                    local value = config[chn]
                    if value and value > 0 then
                        gem_attrs[i] = (gem_attrs[i] or 0) + value
                    end
                end
            end
        end
    end
    return gem_attrs
end"""

NEW = """-- CYS-EQUIP 17/09/2026: nho ID ngoc la da lam hong get_gem_attrs (xem Tools/server/gem_guard.py).
local cys_gem_missing_logged = {}

function equip_data:get_gem_attrs()
    local gem_attrs = {}
    local gem_config = configenginer:get_config("gem_info")
    for i = 1, 4 do
        local id = self.list_2[i] or 0
        if id > 0 then
            local config = gem_config[id]
            -- CYS-EQUIP: `human_item_logic:gem_compound_item_index` tinh ID ngoc cap ke tiep thuan so
            -- hoc va KHONG kiem bang, nen co ID khong co dong trong GemInfo.txt (30 cong thuc, do live
            -- 17/09). Thieu guard nay thi `config[chn]` ben duoi nem "index a nil value" NGAY trong
            -- item_effect_flush => nhan vat mat SACH thuoc tinh trang bi.
            if config == nil then
                if not cys_gem_missing_logged[id] then
                    cys_gem_missing_logged[id] = true
                    print("[CYS-EQUIP] gem id khong co trong GemInfo.txt, bo qua:", id)
                end
            else
            for i = define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP, define.ITEM_ATTRIBUTE.IATTRIBUTE_BASE_MISS do
                local chn = define.CHN_ATTR_SHIFT[i]
                if chn then
                    local value = config[chn]
                    if value and value > 0 then
                        gem_attrs[i] = (gem_attrs[i] or 0) + value
                    end
                end
            end
            end
        end
    end
    return gem_attrs
end"""

TAG = 'CYS-EQUIP 17/09/2026: nho ID ngoc la'


def read_bytes(p):
    with open(p, 'rb') as f:
        return f.read()


def rows(table):
    with open(os.path.join(CFG, table), 'rb') as f:
        txt = f.read().decode('gbk', errors='replace')
    return [l.split('\t') for l in txt.replace('\r\n', '\n').split('\n')]


def gem_ids():
    return {int(r[0]) for r in rows('GemInfo.txt')[2:] if r and r[0].strip().isdigit()}


def max_gem_quality():
    env = 'publish_yu'
    try:
        m = re.search(r'env\s*=\s*"([^"]+)"',
                      open(os.path.join(R, 'GameServer', 'config_2'), encoding='utf-8',
                           errors='replace').read())
        if m:
            env = m.group(1)
    except OSError:
        pass
    src = open(os.path.join(R, 'GameServer', 'lualib', 'define.lua'),
               encoding='utf-8', errors='replace').read()
    m = re.search(r'define\.MAX_GEM_QUALITY\s*=\s*\{(.*?)\}', src, re.S)
    table = {}
    if m:
        for k, v in re.findall(r'\["?(\w+)"?\]\s*=\s*(\d+)', m.group(1)):
            table[k] = int(v)
    return env, table.get(env, 7)


def audit():
    have = gem_ids()
    name = {int(r[0]): r[7] for r in rows('GemInfo.txt')[2:]
            if r and r[0].strip().isdigit() and len(r) > 7}
    env, maxq = max_gem_quality()
    hong = []
    for idx in sorted(have):
        q = (idx % 10000000) // 100000 + 1
        if q > maxq:
            continue
        gi = idx % 1000
        new = idx + (100001 if gi >= 100 + q - 1 else 100000)
        if new not in have:
            hong.append({'tu': idx, 'ten': name.get(idx, ''), 'ra': new})
    shop_bad = set()
    for r in rows('ShopTable.txt')[2:]:
        if not r or not r[0].strip().isdigit():
            continue
        j = 27
        while j + 5 < len(r):
            pid = r[j].strip()
            if pid.isdigit() and int(pid) // 10000000 == 5 and int(pid) not in have:
                shop_bad.add((int(r[0]), int(pid)))
            j += 6
    return {'env': env, 'MAX_GEM_QUALITY': maxq, 'GemInfo_so_dong': len(have),
            'ghep_ra_ID_khong_ton_tai': len(hong), 'cong_thuc_hong': hong,
            'cua_hang_ban_ID_khong_ton_tai': sorted({s for s, _ in shop_bad}),
            'so_ID_hong_tren_cua_hang': len({i for _, i in shop_bad})}


def patched(txt):
    return TAG in txt


def apply_patch(dry):
    raw = read_bytes(TARGET)
    txt = raw.decode('utf-8', errors='strict')
    if patched(txt):
        print(json.dumps({'ket_qua': 'nothing to do', 'ly_do': 'da co ban va'}, ensure_ascii=False))
        return 0
    if txt.count(OLD) != 1:
        print(json.dumps({'ket_qua': 'TU CHOI',
                          'ly_do': 'doan goc xuat hien %d lan (can dung 1)' % txt.count(OLD)},
                         ensure_ascii=False))
        return 2
    new = txt.replace(OLD, NEW, 1)
    if dry:
        print(json.dumps({'ket_qua': 'dry-run', 'byte_truoc': len(raw),
                          'byte_sau': len(new.encode('utf-8'))}, ensure_ascii=False))
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(TARGET, os.path.join(bak, 'item.lua'))
    with open(TARGET, 'wb') as f:
        f.write(new.encode('utf-8'))
    print(json.dumps({'ket_qua': 'da va', 'sao_luu': bak,
                      'byte_truoc': len(raw), 'byte_sau': len(new.encode('utf-8')),
                      'luu_y': 'lualib chi nap luc khoi dong => CAN RESTART moi co hieu luc'},
                     ensure_ascii=False, indent=1))
    return 0


def verify():
    txt = read_bytes(TARGET).decode('utf-8', errors='replace')
    rec = {'co_ban_va': patched(txt), 'co_doan_moi': NEW in txt}
    lua = None
    for exe in ('luac', 'luac5.4', 'luac5.3', 'lua', 'lua5.4', 'lua5.3'):
        if shutil.which(exe):
            lua = exe
            break
    if lua:
        args = [lua, '-p', TARGET] if lua.startswith('luac') else [lua, '-e',
                                                                   'assert(loadfile("%s"))' % TARGET]
        p = subprocess.run(args, capture_output=True, text=True)
        rec['cu_phap'] = {'lenh': ' '.join(args), 'ma_thoat': p.returncode,
                          'loi': (p.stderr or '').strip()[:400]}
    else:
        rec['cu_phap'] = 'khong co luac/lua tren may; bo qua'
    rec['audit'] = audit()
    print(json.dumps(rec, ensure_ascii=False, indent=1))
    return 0 if rec['co_ban_va'] else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('audit', 'plan', 'apply', 'verify', 'revert'))
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--backup', default='')
    a = ap.parse_args()
    if a.cmd == 'audit':
        print(json.dumps(audit(), ensure_ascii=False, indent=1))
        return 0
    if a.cmd == 'plan':
        txt = read_bytes(TARGET).decode('utf-8', errors='replace')
        print(json.dumps({'file': TARGET, 'da_va': patched(txt),
                          'so_lan_gap_doan_goc': txt.count(OLD),
                          'audit': audit()}, ensure_ascii=False, indent=1))
        return 0
    if a.cmd == 'apply':
        return apply_patch(a.dry_run)
    if a.cmd == 'verify':
        return verify()
    if a.cmd == 'revert':
        if not a.backup:
            sys.exit('--backup <dir> bat buoc')
        src = os.path.join(a.backup, 'item.lua')
        if not os.path.exists(src):
            sys.exit('khong thay %s' % src)
        shutil.copy2(src, TARGET)
        print(json.dumps({'ket_qua': 'da tra lai', 'tu': src}, ensure_ascii=False))
        return 0
    return 0


if __name__ == '__main__':
    sys.exit(main())
