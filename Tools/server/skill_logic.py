#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""skill-logic — cài nghĩa cho các 技能逻辑ID của CY chưa có trong skillenginer (server riêng).

  skill_logic.py plan   --out <dir>                  dựng lua/<GameServer…> (file mới + file vá) + plan.json, KHÔNG chạm R
  skill_logic.py apply  --staging <dir> [--dry-run]  chép vào R, sao lưu từng file ở R/backups/skill-logic-<UTC>/
  skill_logic.py verify [--staging <dir>]            luac5.4 -p mọi file + test Lua đơn vị + kiểm đăng ký logic

Chạy trong WSL TLBB bằng root: python3 -B /mnt/c/TLBB/085/CY-Source/Tools/server/skill_logic.py <lệnh>
Nguồn Lua mới: Tools/server/skill_logic_lua/GameServer/…  (UTF-8 — Lua server là UTF-8, chỉ bảng configs/ mới là GBK).
Đặc tả: Docs/specs/server/skill-logic_vi.md.
"""
import argparse
import datetime
import json
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
R = '/home/ubuntu/cys-test-20260913'
GS = 'GameServer'
LUA_SRC = os.path.join(HERE, 'skill_logic_lua')
TESTS = os.path.join(HERE, 'skill_logic_tests.lua')
MARK = 'skill-logic'
SPEC_MODULE = 'scene.skill.human.skill_cy_spec'

# file mới (chép nguyên) — đường dẫn tương đối GameServer/
NEW_FILES = [
    'lualib/cy_skill_logic_spec.lua',
    'lualib/cy_skill_extra.lua',
    'lualib/cy_skill_summon.lua',            # skill-summon 17/09: thực thể triệu hồi (图腾/召唤物)
    'lualib/cy_skill_chain.lua',             # skill-logic-3 17/09: chuỗi lan / hút máu / hệ số giảm dần
    'lualib/cy_collection_bridge.lua',       # skill-logic-4 17/09: điều kiện/驱散 tra tập ID theo bảng CY
    'services/game/packet_domains/cy_combat.lua',   # skill-logic-5 17/09: lớp gói GCCharDoAction (xy_id 786)
    'services/scene/skill/human/skill_cy_spec.lua',
    'services/scene/skill/impact_logic/std_impact_115.lua',
    'services/scene/skill/impact_logic/std_impact_171.lua',
]

# logic impact mới (đăng ký trong lualib/impactenginer.lua)
IMPACT_LOGICS = {115: ('scene.skill.impact_logic.std_impact_115',
                       'sát thương = N % đòn đánh thường (伤害量缩放系数), theo mã CY StdImpact115_T @0xa5f2f8'),
                 171: ('scene.skill.impact_logic.std_impact_171',
                       'trạng thái có hẹn giờ (13 dòng: 九阳炽脉 13058, 九阴煞魄 13059, 各式刃影, 五绝计时) — '
                       'thiếu ô này thì eventenginer bỏ qua impact vì get_logic trả nil')}

EXTRA_CALL = '    pcall(require("cy_skill_extra").apply, self, obj_me, obj_tar, is_critical)  -- %s\n' % MARK


def read(path):
    with open(path, 'rb') as f:
        return f.read().decode('utf-8')


def spec_logic_ids():
    txt = read(os.path.join(LUA_SRC, GS, 'lualib/cy_skill_logic_spec.lua'))
    return sorted({int(m.group(1)) for m in re.finditer(r'(?m)^\[(\d+)\]\s*=\s*\{', txt)})


# ---------------------------------------------------------------- các phép vá
def patch_skillenginer(txt, ids):
    if MARK in txt:
        txt = re.sub(r'(?m)^\s*\[\d+\] = "%s",\s*--\s*%s\n' % (re.escape(SPEC_MODULE), MARK), '', txt)
    i = txt.index('skillenginer.id_logic_module = {')
    j = txt.index('\n}\n', i)
    lines = ''.join('    [%d] = "%s", -- %s\n' % (n, SPEC_MODULE, MARK) for n in ids)
    return txt[:j + 1] + lines + txt[j + 1:]


def patch_impactenginer(txt, logics):
    txt = re.sub(r'(?m)^[ \t]*\[\d+\] = "scene\.skill\.impact_logic\.std_impact_\d+", -- ' + MARK + r'.*\n', '', txt)
    i = txt.index('impactenginer.id_logic_module = {')
    j = txt.index('\n}\n', i)
    lines = ''.join('    [%d] = "%s", -- %s: %s\n' % (n, m, MARK, note) for n, (m, note) in sorted(logics.items()))
    return txt[:j + 1] + lines + txt[j + 1:]


def patch_tail(txt, anchor, call):
    """chèn `call` ngay trước dòng `end` cuối của hàm, tại vị trí `anchor`"""
    if MARK in txt:
        return txt
    k = txt.index(anchor)
    return txt[:k] + call + txt[k:]


PATCHES = [
    # (đường dẫn, anchor = đoạn ngay SAU chỗ chèn)
    ('services/scene/skill/human/skill_0.lua',
     'end\nfunction skill_0:effect_on_unit_each_tick(obj_me, obj_tar, is_critical)'),
    ('services/scene/skill/human/skill_80.lua',
     'end\n\nreturn skill_80'),
    ('services/scene/skill/human/skill_260.lua',
     '    return true\nend\n\nreturn skill_260'),
    ('services/scene/skill/human/skill_704.lua',
     'end\n\nreturn skill_704'),
]


# ---------------------------------------------------------------- skill-logic-4 (17/09)
# Ba file NGOÀI bộ cũ, mỗi file một khối vá nhỏ, đặt ngay trước dòng `return <module>` cuối file.

# 2912 催箭式 (唐门): ô thứ 5 của dòng impact CY mang nhãn `命中+` (28 dòng 逻辑ID 60 dùng nhãn này).
# Bản GL của std_impact_060 chỉ đọc 怒气增长修正/激发几率/给目标的效果/给自己的效果/每万蓝…/借力…
# Cách áp chép nguyên của std_impact_013 (946 dòng 逻辑ID 13 dùng cùng nhãn): cộng thẳng vào args.point.
# base:get_refix(imp, key, args, obj) gọi `get_refix_<key>(self, imp, args, obj)`;
# base:mark_modified_attr_dirty tự tìm mọi phương thức `get_refix_*` nên không cần khai báo thêm.
IMPACT_060_PATCH = '''
-- %s-4 (17/09/2026): nhãn `命中+` — ô CY thêm so với tlbb15 (2912 催箭式 = 37493..37508, 命中 +1460 ở cấp 16).
-- Cách áp giống std_impact_013:get_refix_attrib_hit; -1 là giá trị VÔ HIỆU của bảng nên bỏ qua.
function std_impact_060:get_refix_attrib_hit(imp, args)
    local value = imp.params and imp.params["命中+"] or 0
    value = math.floor(tonumber(value) or 0)
    if value == define.INVAILD_ID then
        return
    end
    args.point = (args.point or 0) + value
end

function std_impact_060:get_value_of_refix_attrib_hit(imp)
    return (imp.params and imp.params["命中+"]) or 0
end

function std_impact_060:set_value_of_refix_attrib_hit(imp, value)
    imp.params["命中+"] = value
end

''' % MARK

# `是否即刻生效一次` của SpecialObjData — 64 dòng đặt 1; riêng 3064 「万箭齐发」 có `陷阱专用标记 = 0`
# nên KHÔNG có đường kích hoạt nào khác (trigger_check đòi bit 1, on_time_over đòi bit 0).
TRAP_PATCH = '''
-- %s-4 (17/09/2026): ô `是否即刻生效一次` của SpecialObjData (110 dòng có ô này, 64 dòng đặt 1).
-- Bẫy 3064 「万箭齐发」 (bẫy của 2901, logic kỹ năng 736) có `陷阱专用标记 = 0` ⇒ `can_be_character_activate`
-- và `activate_when_fade_out` đều sai ⇒ không có đường nổ nào khác; chỉ ô này mới làm nó chạy.
-- Không gắn vào vòng đời chung của special_obj: NGƯỜI TẠO bẫy gọi `activate_at_once` ngay sau khi tạo,
-- nên các bẫy đang chạy (đặt bởi skill_260/261, std_impact_*, cy_four_combat) giữ nguyên hành vi cũ.
function trap:activate_at_once_flag(obj)
    local ok, data = pcall(obj.get_data_record, obj)
    if not ok or type(data) ~= "table" or type(data.descriptor) ~= "table" then
        return false
    end
    return (tonumber(data.descriptor["是否即刻生效一次"]) or 0) == 1
end

-- có mục tiêu hợp lệ trong 影响半径 chưa. Quét RIÊNG (không gọi `activate`) để không tiêu mất một lượt
-- `可激活次数` của những bẫy sống lâu như 2166/3022/3058 荡千军 khi quanh đó chưa có ai.
function trap:has_target_in_range(obj)
    local scene = obj:get_scene()
    local data = obj:get_data_record()
    if scene == nil or data == nil then
        return false
    end
    local owner = scene:get_obj_by_id(obj:get_owner_obj_id())
    if not owner then
        return false
    end
    local position = obj:get_world_pos()
    local targets = scene:scan({scaner = obj, obj = owner, x = position.x, y = position.y,
                                target_logic_by_stand = 1, radious = data.effect_radious,
                                count = data.affect_count})
    return type(targets) == "table" and #targets > 0
end

function trap:activate_at_once(obj)
    if obj == nil or obj._cy_trap_acted_now then
        return false
    end
    obj._cy_trap_acted_now = true          -- chỉ một lần cho mỗi vật thể, kể cả khi gọi lại
    local okf, flag = pcall(self.activate_at_once_flag, self, obj)
    if not okf or not flag then
        return false
    end
    local okt, has = pcall(self.has_target_in_range, self, obj)
    if not okt or not has then
        return false
    end
    local oka, err = pcall(self.activate, self, obj)
    if not oka then
        skynet.error("[trap] activate_at_once loi", err)
        return false
    end
    return true
end

''' % MARK

# Điều kiện/tiêu hao kiểu "tập ID" của SkillData CY phải tra bảng CY (xem lualib/cy_collection_bridge.lua).
CONDITION_CORE_PATCH = ('-- %s-4 (17/09/2026): điều kiện 0/2 và 驱散 9 tra THÊM tập ID của CY '
                        '(configs/IDCollections.txt là bản GL/HJS, khác nghĩa ở 128/376/388/389/499).\n'
                        'pcall(function() require("cy_collection_bridge").install(condition_delplete_core) end)\n\n'
                        % MARK)


# ---------------------------------------------------------------- skill-logic-5 (17/09)
# `services/game/packet.lua` nạp từng domain một; bộ sinh `split_packet.py` chỉ sinh các domain của nó,
# nên lớp gói do CY thêm để ở file riêng `packet_domains/cy_combat.lua` và nạp thêm MỘT dòng ở đây.
PACKET_ANCHOR = 'require("game.packet_domains.misc").bind(packet, bistream, bostream, gbk, define)\n'
PACKET_PATCH = ('\n-- %s-5 (17/09/2026): lớp gói CY thêm — GCCharDoAction `xy_id = 786` (hoạt ảnh con rối\n'
                '-- 离人偶 của 桃花岛, `lualib/cy_four_combat/action_packet.lua`). Trước lượt này `game.packet`\n'
                '-- không có lớp nào mang 786 (785 = GCStallItemPrice, 787 = CGPetExteriorCollectionRequest)\n'
                '-- ⇒ `net:send2client` nổ ở `self.packets[786] = nil` trong dịch vụ agent.\n'
                'require("game.packet_domains.cy_combat").bind(packet, bistream, bostream, gbk, define)\n'
                % MARK)


def patch_packet(txt):
    if MARK in txt:
        return txt
    k = txt.index(PACKET_ANCHOR) + len(PACKET_ANCHOR)
    return txt[:k] + PACKET_PATCH + txt[k:]


def patch_before_return(txt, ret_line, block):
    """chèn `block` ngay trước dòng `return <module>` cuối file (file không có dòng trắng cuối)"""
    if MARK in txt:
        return txt
    anchor = '\n' + ret_line
    k = txt.rindex(anchor)
    return txt[:k] + '\n' + block + ret_line.rstrip('\n') + txt[k + len(anchor):]


def build_patched(rel, src):
    if rel.endswith('impact_logic/std_impact_060.lua'):
        return patch_before_return(src, 'return std_impact_060', IMPACT_060_PATCH)
    if rel.endswith('special_obj/trap.lua'):
        return patch_before_return(src, 'return trap', TRAP_PATCH)
    if rel.endswith('services/game/packet.lua'):
        return patch_packet(src)
    if rel.endswith('condition_delplete_core.lua'):
        if MARK in src:
            return src
        k = src.rindex('\n-- 返回模块')
        return src[:k + 1] + CONDITION_CORE_PATCH + src[k + 1:]
    if rel.endswith('skill_0.lua'):
        return patch_tail(src, PATCHES[0][1], EXTRA_CALL.replace('    pcall', 'pcall'))
    if rel.endswith('skill_80.lua'):
        return patch_tail(src, PATCHES[1][1], EXTRA_CALL)
    if rel.endswith('skill_260.lua'):
        # skill_260:effect_on_unit_once(obj_me, _, is_critical) — đích của ô 给自己的buff là bản thân
        return patch_tail(src, PATCHES[2][1],
                          '    pcall(require("cy_skill_extra").apply, self, obj_me, obj_me, is_critical)  -- %s\n' % MARK)
    if rel.endswith('skill_704.lua'):
        return patch_tail(src, PATCHES[3][1], EXTRA_CALL)
    if rel.endswith('skill_840.lua'):
        return patch_skill_840(src)
    if rel.endswith('impactenginer.lua'):
        return patch_impactenginer(src, IMPACT_LOGICS)
    raise SystemExit('không biết vá %s' % rel)


def patch_skill_840(txt):
    """荡千军 (绝情谷): ô 瞬移BUFFid của SkillData CY là impact thuấn di; module chỉ đọc 瞬移效果/瞬移特效."""
    if MARK in txt:
        return txt
    old = ('function skill_840:get_instant_transport_impact(skill_info)\n'
           '    return skill_info:get_instant_transport_impact()\n'
           'end\n')
    new = ('function skill_840:get_instant_transport_impact(skill_info)\n'
           '    local v = skill_info:get_instant_transport_impact()\n'
           '    if v == nil or v < 0 then   -- %s: SkillData CY 4516 dùng nhãn 瞬移BUFFid, cfghelper không đọc\n'
           '        v = require("cy_skill_extra").value(skill_info, "瞬移BUFFid")\n'
           '    end\n'
           '    return v\n'
           'end\n') % MARK
    if old not in txt:
        # skill_2 là lớp cha: skill_840 kế thừa getter → thêm hàm riêng ngay sau khai báo lớp
        anchor = 'local skill_840 = class("skill_840", skill_2)\n'
        return txt.replace(anchor, anchor + '\n' + new, 1)
    return txt.replace(old, new, 1)


PATCH_FILES = ([p[0] for p in PATCHES] + ['services/scene/skill/human/skill_840.lua',
                                          'lualib/impactenginer.lua',
                                          # skill-logic-4 17/09 — BA file ngoài bộ cũ (ghi rõ trong HANDOFF)
                                          'services/scene/skill/impact_logic/std_impact_060.lua',
                                          'services/scene/special_obj/trap.lua',
                                          'services/scene/skill/condition_delplete_core.lua',
                                          # skill-logic-5 17/09 — file ngoài bộ cũ (ghi rõ trong HANDOFF)
                                          'services/game/packet.lua'])


# ---------------------------------------------------------------- lệnh
def cmd_plan(args):
    st = args.out
    os.makedirs(st, exist_ok=True)
    ids = spec_logic_ids()
    out = {}
    for rel in NEW_FILES:
        src = read(os.path.join(LUA_SRC, GS, rel))
        dst = os.path.join(st, 'lua', GS, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(src.encode('utf-8'))
        out[rel] = 'new'
    se = read(os.path.join(R, GS, 'lualib/skillenginer.lua'))
    new_se = patch_skillenginer(se, ids)
    dst = os.path.join(st, 'lua', GS, 'lualib/skillenginer.lua')
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, 'wb') as f:
        f.write(new_se.encode('utf-8'))
    out['lualib/skillenginer.lua'] = 'patched (+%d dòng id_logic_module)' % len(ids)
    for rel in PATCH_FILES:
        src = read(os.path.join(R, GS, rel))
        new = build_patched(rel, src)
        dst = os.path.join(st, 'lua', GS, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new.encode('utf-8'))
        out[rel] = 'patched' if new != src else 'không đổi (đã vá)'
    plan = {'logic_ids': ids, 'count': len(ids), 'files': out,
            'generated': datetime.datetime.utcnow().isoformat() + 'Z'}
    with open(os.path.join(st, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(plan, f, ensure_ascii=False, indent=1)
    print(json.dumps(plan, ensure_ascii=False, indent=1))


def staged(st):
    base = os.path.join(st, 'lua')
    out = []
    for dp, _, fns in os.walk(base):
        for fn in fns:
            p = os.path.join(dp, fn)
            out.append((p, os.path.relpath(p, base).replace('\\', '/')))
    return sorted(out, key=lambda x: x[1])


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'skill-logic-' + stamp)
    changed, same = [], 0
    for p, rel in staged(args.staging):
        dst = os.path.join(R, rel)
        new = open(p, 'rb').read()
        old = open(dst, 'rb').read() if os.path.exists(dst) else None
        if old == new:
            same += 1
            continue
        changed.append(rel)
        if args.dry_run:
            continue
        if old is not None:
            b = os.path.join(bdir, rel)
            os.makedirs(os.path.dirname(b), exist_ok=True)
            shutil.copy2(dst, b)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new)
    print(json.dumps({'changed': changed, 'unchanged': same, 'backup': None if args.dry_run else bdir,
                      'dry_run': bool(args.dry_run)}, ensure_ascii=False, indent=1))


def luac(paths):
    bad = []
    for p in paths:
        r = subprocess.run(['luac5.4', '-p', p], capture_output=True)
        if r.returncode != 0:
            bad.append((p, r.stderr.decode('utf-8', 'replace').strip()))
    return bad


def cmd_verify(args):
    base = os.path.join(args.staging, 'lua', GS) if args.staging else os.path.join(R, GS)
    rels = NEW_FILES + ['lualib/skillenginer.lua'] + PATCH_FILES
    paths = [os.path.join(base, r) for r in rels]
    res = {'base': base}
    missing = [r for r, p in zip(rels, paths) if not os.path.exists(p)]
    res['missing'] = missing
    res['luac'] = [{'file': p, 'err': e} for p, e in luac([p for p in paths if os.path.exists(p)])]
    ids = spec_logic_ids()
    se = read(os.path.join(base, 'lualib/skillenginer.lua'))
    reg = {int(m.group(1)) for m in re.finditer(r'\[(\d+)\] = "%s"' % re.escape(SPEC_MODULE), se)}
    res['spec_ids'] = len(ids)
    res['registered'] = len(reg)
    res['not_registered'] = sorted(set(ids) - reg)
    res['registered_without_spec'] = sorted(reg - set(ids))
    # mọi logic đã đăng ký phải chưa có module khác
    other = {int(m.group(1)): m.group(2) for m in re.finditer(r'\[(\d+)\] = "(scene\.skill\.[\w.]+)"', se)}
    res['conflicts'] = sorted(n for n in reg if other.get(n) != SPEC_MODULE)
    ie = read(os.path.join(base, 'lualib/impactenginer.lua'))
    ireg = {int(m.group(1)) for m in re.finditer(r'\[(\d+)\] = "scene\.skill\.impact_logic\.std_impact_\d+", -- %s' % MARK, ie)}
    res['impact_logics'] = sorted(IMPACT_LOGICS)
    res['impact_not_registered'] = sorted(set(IMPACT_LOGICS) - ireg)
    extra_ok = all(MARK in read(os.path.join(base, r)) for r in PATCH_FILES if os.path.exists(os.path.join(base, r)))
    res['patch_marks'] = extra_ok
    if os.path.exists(TESTS):
        r = subprocess.run(['lua5.4', TESTS, base, os.path.join(R, GS)], capture_output=True, cwd=HERE)
        res['tests_rc'] = r.returncode
        res['tests'] = r.stdout.decode('utf-8', 'replace').strip().splitlines()[-25:]
        if r.returncode != 0:
            res['tests_err'] = r.stderr.decode('utf-8', 'replace').strip()[-2000:]
    ok = (not res['luac'] and not missing and not res['not_registered'] and not res['conflicts']
          and not res['impact_not_registered'] and extra_ok and res.get('tests_rc', 0) == 0)
    res['ok'] = ok
    print(json.dumps(res, ensure_ascii=False, indent=1))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest='cmd', required=True)
    p = sub.add_parser('plan'); p.add_argument('--out', required=True); p.set_defaults(fn=cmd_plan)
    p = sub.add_parser('apply'); p.add_argument('--staging', required=True); p.add_argument('--dry-run', action='store_true'); p.set_defaults(fn=cmd_apply)
    p = sub.add_parser('verify'); p.add_argument('--staging'); p.set_defaults(fn=cmd_verify)
    a = ap.parse_args()
    sys.exit(a.fn(a) or 0)


if __name__ == '__main__':
    main()
