#!/usr/bin/env python3
"""pets-wild — chặn `assert` khi BẮT TRÂN THÚ lúc túi thú đã đầy.

## Lỗi

`services/scene/skill/human/skill_10.lua` (SkillTemplate 1 捕兽, 技能逻辑ID 10) gọi thẳng:

    obj_me:capture_pet(log_param, obj_tar)      -- services/scene/obj/human.lua:7826
        petmanager:create_guid_of_pet(self, pet)
        self:add_pet(pet:get_detail())          -- services/scene/obj/human.lua:6867
            local empty_index = container:get_empty_item_index()
            assert(empty_index ~= define.INVAILD_ID)     <-- NỔ Ở ĐÂY

`assert` trong service scene không chỉ làm hỏng lượt của người đó mà làm hỏng **cả scene**
(cùng lớp với `release.lua:10` và `runtime_adapter.lua:77`). Nhánh TRỨNG đã có chốt sẵn
(`script_base:TryCreatePet` → `get_pet_bag_container():cal_item_space()`), nhánh BẮT HOANG thì
không có chốt nào. Người chơi túi thú đầy đi bắt thêm một con là chạm đúng đường này.

## Bản vá (ba chỗ, đều nhỏ và có thẻ `CYS-PET`)

1. `human:capture_pet` — chốt TRƯỚC khi sinh guid: hết chỗ thì `notify_tips` + gửi
   `OR_BAG_OUT_OF_SPACE (-15)` rồi `return false`. `skill_10` nhận `false` và gửi
   `GCManipulatePetRet ret = MANIPULATEPET_RET_CAPTUREFALID` — đúng nghĩa "từ chối êm".
2. `human:add_pet` — bỏ `assert`, thay bằng ghi log + `return false`. Đây là lưới an toàn cuối
   cho MỌI người gọi (`capture_pet`, `add_pet_by_data_id`, hai nhánh đấu giá nguyên bảo
   `scenecore:auction_buy_after_do` / `auction_take_back_after_do` vốn cũng không có chốt).
3. `human:add_pet_by_data_id` — trả về kết quả THẬT của `add_pet` thay vì luôn `true`
   (trước đây trứng thất bại vẫn báo thành công cho script).

Không đổi hành vi khi túi còn chỗ: cùng thứ tự lời gọi, cùng giá trị trả về.

  pet_bagfull.py plan   [--out F]   in trạng thái từng neo, KHÔNG ghi gì
  pet_bagfull.py apply  [--out F] [--dry-run]
                                    sao lưu `R/backups/pet-bagfull-<UTC>/` rồi vá (idempotent)
  pet_bagfull.py verify [--out F]   khẳng định đã vá, `assert` đã biến mất, cú pháp Lua còn hợp lệ

Chạy trong WSL TLBB bằng root: `python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/pet_bagfull.py <lệnh>`.
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys

R = '/home/ubuntu/cys-test-20260913'
REL = 'GameServer/services/scene/obj/human.lua'
MARK = 'pet-bagfull'
TAG = 'CYS-PET'

# Mỗi mục: (tên, đoạn CŨ nguyên văn, đoạn MỚI). Đoạn cũ phải xuất hiện ĐÚNG MỘT lần.
PATCHES = [
    ('add_pet',
     """function human:add_pet(pet)
    local container = self:get_pet_bag_container()
    local empty_index = container:get_empty_item_index()
    assert(empty_index ~= define.INVAILD_ID)
    container:set_item(empty_index, pet)""",
     """function human:add_pet(pet)
    local container = self:get_pet_bag_container()
    local empty_index = container:get_empty_item_index()
    -- CYS-PET 17/09/2026: truoc day la assert(empty_index ~= define.INVAILD_ID). Tui thu day thi
    -- assert lam hong CA SCENE chu khong rieng nguoi choi do. Moi nguoi goi deu doc gia tri tra ve,
    -- nen tra false la du: capture_pet -> skill_10 gui CAPTUREFALID, add_pet_by_data_id tra false.
    if empty_index == define.INVAILD_ID then
        skynet.loge(string.format("[PET_BAG_FULL] guid= %s khong con o trong tui tran thu (size= %s)",
                                  tostring(self:get_guid()), tostring(container:get_size())))
        return false
    end
    container:set_item(empty_index, pet)"""),

    ('add_pet_by_data_id',
     """    petmanager:make_capture_pet_attrib(pet, is_rmb, growth_rate, false, true)
    self:add_pet(pet)
    return true, guid.m_uHighSection, guid.m_uLowSection
end""",
     """    petmanager:make_capture_pet_attrib(pet, is_rmb, growth_rate, false, true)
    -- CYS-PET: truoc day bo qua ket qua cua add_pet va luon tra true, nen script trung van bao
    -- "thanh cong" khi tui thu day (da tieu hao vat pham). Tra ve ket qua THAT.
    if not self:add_pet(pet) then
        return false
    end
    return true, guid.m_uHighSection, guid.m_uLowSection
end"""),

    ('capture_pet',
     """function human:capture_pet(logparam, pet)
    if pet:get_owner() then
        self:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    local result = petmanager:create_guid_of_pet(self, pet)""",
     """function human:capture_pet(logparam, pet)
    if pet:get_owner() then
        self:send_operate_result_msg(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- CYS-PET 17/09/2026: chot y het nhanh TRUNG (script_base:TryCreatePet). Khong co chot thi
    -- add_pet nem assert va lam hong ca scene. Tu choi EM: bao nguoi choi + ma loi, skill_10 se
    -- gui GCManipulatePetRet ret = MANIPULATEPET_RET_CAPTUREFALID.
    if self:get_pet_bag_container():cal_item_space() < 1 then
        self:notify_tips("Túi Trân thú đã đầy, không thể thu phục thêm.")
        self:send_operate_result_msg(define.OPERATE_RESULT.OR_BAG_OUT_OF_SPACE)
        return false
    end
    local result = petmanager:create_guid_of_pet(self, pet)"""),
]


def read(path):
    with open(path, 'rb') as f:
        return f.read()


def eol_variants(text, crlf):
    return text.replace('\n', '\r\n') if crlf else text


def status(data):
    """-> [(ten, 'da_va' | 'chua_va' | 'KHONG_TIM_THAY' | 'NEO_TRUNG')]"""
    txt = data.decode('utf-8', 'replace')
    crlf = '\r\n' in txt
    out = []
    for name, old, new in PATCHES:
        o, n = eol_variants(old, crlf), eol_variants(new, crlf)
        if n in txt:
            out.append((name, 'da_va', txt.count(n)))
        elif txt.count(o) == 1:
            out.append((name, 'chua_va', 1))
        elif txt.count(o) > 1:
            out.append((name, 'NEO_TRUNG', txt.count(o)))
        else:
            out.append((name, 'KHONG_TIM_THAY', 0))
    return out, crlf


def lua_syntax(path):
    for exe in ('luac5.4', 'luac', 'lua5.4', 'lua'):
        try:
            if exe.startswith('luac'):
                r = subprocess.run([exe, '-p', path], capture_output=True, text=True)
            else:
                r = subprocess.run([exe, '-e',
                                    'local f,e=loadfile(%r) if not f then io.stderr:write(e) os.exit(1) end' % path],
                                   capture_output=True, text=True)
            return {'tool': exe, 'rc': r.returncode, 'stderr': r.stderr.strip()[:400]}
        except FileNotFoundError:
            continue
    return {'tool': None, 'rc': None, 'stderr': 'khong co lua/luac trong WSL'}


def cmd_plan(args):
    path = os.path.join(R, REL)
    st, crlf = status(read(path))
    out = {'file': path, 'crlf': crlf, 'anchors': [{'name': n, 'state': s, 'count': c} for n, s, c in st],
           'se_va': [n for n, s, _ in st if s == 'chua_va'],
           'da_va': [n for n, s, _ in st if s == 'da_va'],
           'loi': [n for n, s, _ in st if s in ('KHONG_TIM_THAY', 'NEO_TRUNG')]}
    emit(out, args)
    return 1 if out['loi'] else 0


def cmd_apply(args):
    path = os.path.join(R, REL)
    data = read(path)
    st, crlf = status(data)
    bad = [n for n, s, _ in st if s in ('KHONG_TIM_THAY', 'NEO_TRUNG')]
    if bad:
        print(json.dumps({'error': 'neo khong dung', 'anchors': bad}, ensure_ascii=False))
        return 1
    todo = [n for n, s, _ in st if s == 'chua_va']
    if not todo:
        emit({'file': path, 'changed': [], 'note': 'da va tu truoc, khong lam gi'}, args)
        return 0
    txt = data.decode('utf-8', 'replace')
    for name, old, new in PATCHES:
        if name not in todo:
            continue
        txt = txt.replace(eol_variants(old, crlf), eol_variants(new, crlf), 1)
    new_data = txt.encode('utf-8')
    if args.dry_run:
        emit({'file': path, 'dry_run': True, 'changed': todo,
              'bytes': [len(data), len(new_data)]}, args)
        return 0
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bak = os.path.join(R, 'backups', '%s-%s' % (MARK, stamp))
    os.makedirs(bak, exist_ok=True)
    shutil.copy2(path, os.path.join(bak, 'human.lua'))
    with open(path, 'wb') as f:
        f.write(new_data)
    emit({'file': path, 'backup': bak, 'changed': todo,
          'bytes': [len(data), len(new_data)], 'lua_syntax': lua_syntax(path)}, args)
    return 0


def cmd_verify(args):
    path = os.path.join(R, REL)
    data = read(path)
    st, _ = status(data)
    txt = data.decode('utf-8', 'replace')
    errors = []
    for n, s, _ in st:
        if s != 'da_va':
            errors.append('neo %s: %s' % (n, s))
    # Chỉ tính DÒNG LỆNH thật, không tính chữ `assert(...)` nằm trong chú thích của chính bản vá.
    live_assert = [i + 1 for i, ln in enumerate(txt.split('\n'))
                   if ln.strip() == 'assert(empty_index ~= define.INVAILD_ID)']
    if live_assert:
        errors.append('assert cu van con o dong %s' % live_assert)
    syn = lua_syntax(path)
    if syn['rc'] not in (0, None):
        errors.append('cu phap Lua hong: %s' % syn['stderr'])
    out = {'file': path, 'anchors': [{'name': n, 'state': s} for n, s, _ in st],
           'lua_syntax': syn, 'errors': errors,
           'status': 'PASS' if not errors else 'FAIL'}
    emit(out, args)
    return 0 if out['status'] == 'PASS' else 1


def emit(obj, args):
    text = json.dumps(obj, ensure_ascii=False, indent=1)
    print(text)
    if args.out:
        with open(args.out, 'w', encoding='utf-8') as f:
            f.write(text)


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    for name, fn in (('plan', cmd_plan), ('apply', cmd_apply), ('verify', cmd_verify)):
        p = sub.add_parser(name)
        p.add_argument('--out', default='')
        if name == 'apply':
            p.add_argument('--dry-run', action='store_true')
        p.set_defaults(fn=fn)
    args = ap.parse_args()
    sys.exit(args.fn(args) or 0)


if __name__ == '__main__':
    main()
