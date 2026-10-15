# -*- coding: utf-8 -*-
"""CYS-SKILL78 — công cụ CHẨN ĐOÁN cổng `can_use_this_skill_in_this_status` của server riêng.

**KẾT LUẬN 19/09/2026: KHÔNG CÓ LỖI, KHÔNG CÓ BẢN VÁ.** Vật phẩm có `技能编号 = 78` bị trả
`OR_U_CANNT_DO_THIS_RIGHT_NOW (-44)` vì nhân vật đo **đang cưỡi thú** (một impact `logic_id = 14`
vĩnh viễn đặt `CanAction1 = 0` và `骑乘ID = 1220`). Cho bot xuống ngựa thì đúng vật phẩm đó
dùng được ngay. Vì vậy `FIX = None` là **cố ý** — đừng điền vào.

Đường chặn trên luồng dùng vật phẩm: `services/scene/ai/human.lua:447` →
`services/scene/obj/character.lua:930` `character:can_use_this_skill_in_this_status`
(cờ đọc ở dòng 937 và 952), rồi `ai/human.lua:448` gửi `-44`.

CẢNH BÁO: `GameServer/**` do **dịch vụ scene** nạp lúc khởi động (`scenecore.lua:38`
`require "scene.obj.human"`), KHÔNG nạp lười ⇒ sửa file ở đây **chỉ có tác dụng sau khi
restart server**. Muốn dò nóng thì dùng `inject` của skynet console
(`Build/Logs/2026-09-19-skill78-flags/scripts/60-probe-inject.lua`).

Lệnh:
  python3 Tools/server/skill78_flags.py status            # hiện trạng thái file
  python3 Tools/server/skill78_flags.py diag              # chèn log chẩn đoán (KHÔNG đổi hành vi)
  python3 Tools/server/skill78_flags.py fix               # áp bản vá thật
  python3 Tools/server/skill78_flags.py revert            # trả về nguyên bản
  python3 Tools/server/skill78_flags.py clearcache        # xoá code-cache skynet (console 16002)

Mọi lần ghi đều sao lưu sang `R/backups/skill78-flags-<UTC>/`.
File đích là `GameServer/**` nhưng dịch vụ `obj` được `newservice` lại ở MỖI lần đăng nhập,
nên `clearcache` + đăng nhập mới là đủ; KHÔNG restart server.
"""
import argparse
import datetime
import io
import json
import os
import shutil
import socket
import sys

R = '/home/ubuntu/cys-test-20260913'
TARGET = os.path.join(R, 'GameServer/services/scene/obj/character.lua')
BACKUP_ROOT = os.path.join(R, 'backups')
MARK = 'CYS-SKILL78'

HEAD = 'function character:can_use_this_skill_in_this_status(skill_id)\n'
TAIL = '\nfunction character:impact_forbidden_this_skill'

ORIG = '''function character:can_use_this_skill_in_this_status(skill_id)
    -- print("character:can_use_this_skill_in_this_status skill_id =", skill_id)
    local template = self:get_skill_template(skill_id)
\tif not template then
\t\treturn false
\tend
    if skill_id ~= 74 then
        if template.disable_by_flag_1 then
            local can_action_1 = self:get_attrib("can_action_1")
            -- print("can_action_1 =", can_action_1)
            if can_action_1 == 0 then
                return false
            end
        end
        if template.disable_by_flag_2 then
            local can_action_2 = self:get_attrib("can_action_2")
            -- print("can_action_2 =", can_action_2)
            if can_action_2 == 0 then
                return false
            end
        end
    end
    if template.disable_by_flag_3 then
        local ride_model = self:get_attrib("ride_model") or define.INVAILD_ID
        -- print("ride_model =", ride_model)
        if ride_model ~= define.INVAILD_ID then
            return false
        end
    end
    if self:impact_forbidden_this_skill(skill_id) then
        return false
    end
    return true
end
'''

DIAG = '''function character:can_use_this_skill_in_this_status(skill_id)
    -- print("character:can_use_this_skill_in_this_status skill_id =", skill_id)
    local template = self:get_skill_template(skill_id)
    local _cys78 = (skill_id == 78 or skill_id == 197) --CYS-SKILL78 diag
    if _cys78 then --CYS-SKILL78 diag
        skynet.error("[CYS-SKILL78] enter skill=", tostring(skill_id),
            " obj=", tostring(self.get_obj_id and self:get_obj_id()),
            " tpl=", tostring(template ~= nil),
            " f1=", tostring(template and template.disable_by_flag_1),
            " f2=", tostring(template and template.disable_by_flag_2),
            " f3=", tostring(template and template.disable_by_flag_3),
            " can1=", tostring(self:get_attrib("can_action_1")),
            " can2=", tostring(self:get_attrib("can_action_2")),
            " ride=", tostring(self:get_attrib("ride_model")),
            " INVAILD=", tostring(define.INVAILD_ID))
    end --CYS-SKILL78 diag
\tif not template then
        if _cys78 then skynet.error("[CYS-SKILL78] BLOCK no_template skill=", tostring(skill_id)) end --CYS-SKILL78 diag
\t\treturn false
\tend
    if skill_id ~= 74 then
        if template.disable_by_flag_1 then
            local can_action_1 = self:get_attrib("can_action_1")
            -- print("can_action_1 =", can_action_1)
            if can_action_1 == 0 then
                if _cys78 then skynet.error("[CYS-SKILL78] BLOCK can_action_1 skill=", tostring(skill_id)) end --CYS-SKILL78 diag
                return false
            end
        end
        if template.disable_by_flag_2 then
            local can_action_2 = self:get_attrib("can_action_2")
            -- print("can_action_2 =", can_action_2)
            if can_action_2 == 0 then
                if _cys78 then skynet.error("[CYS-SKILL78] BLOCK can_action_2 skill=", tostring(skill_id)) end --CYS-SKILL78 diag
                return false
            end
        end
    end
    if template.disable_by_flag_3 then
        local ride_model = self:get_attrib("ride_model") or define.INVAILD_ID
        -- print("ride_model =", ride_model)
        if ride_model ~= define.INVAILD_ID then
            if _cys78 then skynet.error("[CYS-SKILL78] BLOCK ride_model skill=", tostring(skill_id), " ride=", tostring(ride_model)) end --CYS-SKILL78 diag
            return false
        end
    end
    if self:impact_forbidden_this_skill(skill_id) then
        if _cys78 then skynet.error("[CYS-SKILL78] BLOCK impact_forbidden skill=", tostring(skill_id)) end --CYS-SKILL78 diag
        return false
    end
    if _cys78 then skynet.error("[CYS-SKILL78] PASS skill=", tostring(skill_id)) end --CYS-SKILL78 diag
    return true
end
'''

# Bản vá thật được điền sau khi chẩn đoán chỉ ra ô nào sai (xem --fix-body).
FIX = None


def read():
    return io.open(TARGET, encoding='utf-8').read()


def block(text):
    i = text.index(HEAD)
    j = text.index(TAIL, i)
    return i, j, text[i:j]


def state():
    t = read()
    _, _, b = block(t)
    if b == ORIG:
        return 'ORIG'
    if b == DIAG:
        return 'DIAG'
    if FIX and b == FIX:
        return 'FIX'
    return 'KHAC'


def backup(tag):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    d = os.path.join(BACKUP_ROOT, 'skill78-flags-%s-%s' % (tag, stamp))
    os.makedirs(d, exist_ok=True)
    shutil.copy2(TARGET, os.path.join(d, 'character.lua'))
    return d


def write_block(new, tag):
    t = read()
    i, j, old = block(t)
    if old == new:
        return {'changed': False, 'state': state()}
    d = backup(tag)
    out = t[:i] + new + t[j:]
    with io.open(TARGET, 'w', encoding='utf-8', newline='') as f:
        f.write(out)
    return {'changed': True, 'backup': d, 'bytes_truoc': len(t.encode('utf-8')),
            'bytes_sau': len(out.encode('utf-8')), 'state': state()}


def clearcache(port=16002):
    s = socket.create_connection(('127.0.0.1', port), timeout=10)
    s.settimeout(4)
    out = []
    try:
        try:
            out.append(s.recv(65536).decode('utf-8', 'replace'))
        except socket.timeout:
            pass
        s.sendall(b'clearcache\n')
        while True:
            try:
                d = s.recv(65536)
            except socket.timeout:
                break
            if not d:
                break
            out.append(d.decode('utf-8', 'replace'))
    finally:
        s.close()
    return ''.join(out).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=['status', 'diag', 'fix', 'revert', 'clearcache'])
    a = ap.parse_args()
    if a.cmd == 'status':
        print(json.dumps({'file': TARGET, 'state': state()}, ensure_ascii=False))
        return 0
    if a.cmd == 'clearcache':
        print(json.dumps({'console': clearcache()}, ensure_ascii=False))
        return 0
    if a.cmd == 'diag':
        r = write_block(DIAG, 'diag')
    elif a.cmd == 'revert':
        r = write_block(ORIG, 'revert')
    else:
        if FIX is None:
            print('chua co ban va FIX', file=sys.stderr)
            return 2
        r = write_block(FIX, 'fix')
    r['console'] = clearcache()
    print(json.dumps(r, ensure_ascii=False))
    return 0


if __name__ == '__main__':
    sys.exit(main())
