#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""ride-finish (18/09/2026) — 5 ban va MA server rieng di kem ride_axis.py (truc ID thu cuoi theo CY).

    python3 -B Tools/reapply/ride/ride_server_patch.py audit                 chi doc
    python3 -B Tools/reapply/ride/ride_server_patch.py apply                 sao luu + va + luac -p
    python3 -B Tools/reapply/ride/ride_server_patch.py revert --backup DIR   hoan tac

Moi ban va la thay mot doan chu DUY NHAT (kiem "dung 1 lan" truoc khi ghi), co dau `CYS-RIDE-FINISH`
de idempotent. `services/*.lua` + `lualib/*.lua` chi nap luc skynet khoi dong => chi co hieu luc SAU restart.

  P1 lualib/cfghelper.lua          read_exterior_ride doc them cot `速度125` (bac 125 cua CY: 照夜白/香鬃乌).
                                   Khong co dong nay: nguoi so huu ride bac 125 => get_riders_max_speed_up = 125
                                   => impacts[125] nil => MOI thu cuoi cua ho khong len.
  P2 lualib/script_base.lua        LuaFnGetExteriorRideIDByVisual: CY co 10 模型索引 dung chung 2–3 ride
                                   (紫电 47/232 …); pairs() tra ngau nhien => item cap ride khac nhau moi lan.
                                   Chon xac dinh: uu tien 门派 == -1, roi id nho nhat.
  P3 services/scene/scenecore.lua  char_auto_ride: (a) dang cuoi ma bam lai => XUONG THU (ky nang 21 cua 0.85 la
                                   nut bat/tat: skill_14:start_charging go impact 99) roi ack — truoc day chi ack,
                                   nut "thu ve" cua CY khong lam gi; (b) chua chon / KHONG SO HUU / khong co impact
                                   => bao nguoi choi (#{...} StrDictionary CY) thay vi im lang; (c) log timeout dung so.
                                   char_exterior_request cat 3: chi cho CHON thu da so huu (hoac -1 = bo chon).
  P4 services/scene/skill/human/skill_14.lua  khong co impact cho bac => log + bao, va chan nil khi ride id la.
  P5 lualib/define.lua             ADD_EQUIP_BUFF HEQUIP_RIDER MINID/MAXID 174 (GL 飒露紫) -> 264 (CY, cung mesh).
"""
import argparse
import os
import shutil
import subprocess
import sys
import time

ROOT = '/home/ubuntu/cys-test-20260913'
MARK = 'CYS-RIDE-FINISH'


def u(s):
    return s.encode('utf-8')


PATCHES = [
    # cfghelper.lua dung CRLF (cac file khac LF) — khop tung byte
    dict(id='P1', file='GameServer/lualib/cfghelper.lua',
         old=u('                [90] = conf["速度90"],\r\n            }\r\n'),
         new=u('                [90] = conf["速度90"],\r\n'
               '                [125] = conf["速度125"],    -- CYS-RIDE-FINISH: bac 125 cua CY (照夜白/香鬃乌), cot cuoi bang\r\n'
               '            }\r\n')),
    dict(id='P2', file='GameServer/lualib/script_base.lua',
         old=u('function script_base:LuaFnGetExteriorRideIDByVisual(visual)\n'
               '    local exterior_ride = configenginer:get_config("exterior_ride")\n'
               '    for _, er in pairs(exterior_ride) do\n'
               '        if er.model == visual then\n'
               '            return er.id\n'
               '        end\n'
               '    end\n'
               'end\n'),
         new=u('function script_base:LuaFnGetExteriorRideIDByVisual(visual)\n'
               '    -- CYS-RIDE-FINISH: CY co 10 模型索引 dung chung cho 2-3 dong ride (紫电 47/232, 玄天狐 173/仿·175 ...).\n'
               '    -- pairs() tra dong NGAU NHIEN => cung mot item cap ride khac nhau moi lan. Chon xac dinh:\n'
               '    -- uu tien 门派 == -1 (ai cung dung duoc), roi id nho nhat (47 nam trong RideCollection, 232 thi khong).\n'
               '    local exterior_ride = configenginer:get_config("exterior_ride")\n'
               '    local best\n'
               '    for _, er in pairs(exterior_ride) do\n'
               '        if er.model == visual then\n'
               '            if not best\n'
               '            or ((er.menpai == -1) and (best.menpai ~= -1))\n'
               '            or (((er.menpai == -1) == (best.menpai == -1)) and er.id < best.id) then\n'
               '                best = er\n'
               '            end\n'
               '        end\n'
               '    end\n'
               '    return best and best.id\n'
               'end\n')),
    # P3a v1 (18/09 03:29) di qua ky nang 21; v2 go impact 99 truc tiep (y het human:reverse_ride va
    # skill_14:start_charging) — khong phu thuoc dieu kien ky nang / trang thai AI. Muc P3a_v1to2 chi de nang
    # file da mang v1; file goc thi bo qua (optional).
    dict(id='P3a_v1to2', file='GameServer/services/scene/scenecore.lua', optional=True,
         old=u('        skynet.logi("[DIAG_RIDE_PK] RIDE_DISMOUNT ride_model=", tostring(ride_model))\n'
               '        local pos_d = obj_me:get_world_pos()\n'
               '        obj_me:get_ai():push_command_use_skill(21, obj_me:get_obj_id(), pos_d.x, pos_d.y, obj_me:get_dir(), obj_me:get_guid())\n'),
         new=u('        skynet.logi("[DIAG_RIDE_PK] RIDE_DISMOUNT ride_model=", tostring(ride_model))\n'
               '        local imp_ride = obj_me:impact_get_first_impact_of_specific_class_id(define.RIDE_IMPACT_ID)\n'
               '        if imp_ride then\n'
               '            obj_me:on_impact_fade_out(imp_ride)\n'
               '            obj_me:remove_impact(imp_ride)\n'
               '            obj_me:send_refresh_attrib()\n'
               '        else\n'
               '            local pos_d = obj_me:get_world_pos()\n'
               '            obj_me:get_ai():push_command_use_skill(21, obj_me:get_obj_id(), pos_d.x, pos_d.y, obj_me:get_dir(), obj_me:get_guid())\n'
               '        end\n')),
    dict(id='P3a', file='GameServer/services/scene/scenecore.lua',
         old=u('    if ride_model ~= define.INVAILD_ID then\n'
               '        local ret = packet_def.GCCharAutoRide.new()\n'
               '        ret.flag = flag\n'
               '        self:send2client(obj_me, ret)\n'
               '        return\n'
               '    end\n'
               '\n'
               '    -- 必须有选中的坐骑\n'),
         new=u('    if ride_model ~= define.INVAILD_ID then\n'
               '        -- CYS-RIDE-FINISH: dang cuoi ma bam lai = XUONG THU. Client CY goi cung mot ham host cho ca\n'
               '        -- "召唤(1)" lan "收回(0)" (Ride.lua:425 CallInOutRide), va ky nang 21 cua 0.85 von la nut bat/tat:\n'
               '        -- skill_14:start_charging gap ride_model ~= -1 thi go impact 99. Truoc day nhanh nay chi ack.\n'
               '        skynet.logi("[DIAG_RIDE_PK] RIDE_DISMOUNT ride_model=", tostring(ride_model))\n'
               '        local imp_ride = obj_me:impact_get_first_impact_of_specific_class_id(define.RIDE_IMPACT_ID)\n'
               '        if imp_ride then\n'
               '            obj_me:on_impact_fade_out(imp_ride)\n'
               '            obj_me:remove_impact(imp_ride)\n'
               '            obj_me:send_refresh_attrib()\n'
               '        else\n'
               '            local pos_d = obj_me:get_world_pos()\n'
               '            obj_me:get_ai():push_command_use_skill(21, obj_me:get_obj_id(), pos_d.x, pos_d.y, obj_me:get_dir(), obj_me:get_guid())\n'
               '        end\n'
               '        local function wait_dismount(retry)\n'
               '            local rm = obj_me:get_ride_model() or define.INVAILD_ID\n'
               '            if rm == define.INVAILD_ID then\n'
               '                local ret = packet_def.GCCharAutoRide.new()\n'
               '                ret.flag = flag\n'
               '                self:send2client(obj_me, ret)\n'
               '            elseif retry < 20 then\n'
               '                skynet.timeout(10, function() wait_dismount(retry + 1) end)\n'
               '            else\n'
               '                skynet.logi("[DIAG_RIDE_PK] RIDE_DISMOUNT_TIMEOUT ride_model van la ", tostring(rm))\n'
               '            end\n'
               '        end\n'
               '        skynet.timeout(10, function() wait_dismount(0) end)\n'
               '        return\n'
               '    end\n'
               '\n'
               '    -- 必须有选中的坐骑\n')),
    dict(id='P3b', file='GameServer/services/scene/scenecore.lua',
         old=u('        skynet.logi("[DIAG_RIDE_PK] RIDE_ABORT ly do=CHUA CHON/KICH HOAT THU (get_ride vo hieu)")\n'
               '        return\n'
               '    end\n'),
         new=u('        skynet.logi("[DIAG_RIDE_PK] RIDE_ABORT ly do=CHUA CHON/KICH HOAT THU (get_ride vo hieu)")\n'
               '        obj_me:notify_tips("#{WGTJ_201222_106}")    -- CYS-RIDE-FINISH: bao nguoi choi thay vi im lang\n'
               '        return\n'
               '    end\n'
               '    -- CYS-RIDE-FINISH: phai SO HUU (exterior.rides), khong chi CHON (attrib.ride). Khong so huu thi\n'
               '    -- get_riders_max_speed_up() = 0 => impacts[0] nil => ky nang 21 khong tao impact => truoc day IM LANG.\n'
               '    if not obj_me:have_this_ride(ride) then\n'
               '        skynet.logi("[DIAG_RIDE_PK] RIDE_ABORT ly do=KHONG SO HUU ride=", tostring(ride))\n'
               '        obj_me:notify_tips("#{ZQGZ_110512_25}")\n'
               '        return\n'
               '    end\n'
               '    local ride_conf = configenginer:get_config("exterior_ride")[ride]\n'
               '    local max_speed_up = obj_me:get_riders_max_speed_up()\n'
               '    local ride_imp = ride_conf and ride_conf.impacts and ride_conf.impacts[max_speed_up]\n'
               '    if not ride_imp or ride_imp == define.INVAILD_ID then\n'
               '        skynet.logi("[DIAG_RIDE_PK] RIDE_ABORT ly do=KHONG CO IMPACT ride=", tostring(ride), " bac=", tostring(max_speed_up))\n'
               '        obj_me:notify_tips("#{ZQGZ_110512_20}")\n'
               '        return\n'
               '    end\n')),
    # P3e (18/09 04:00, sau do (d)): ky nang 21 co 冷却时间 3000 ms (SkillData_V1 dong 21) — len ngay sau khi xuong
    # thi push_command_use_skill tra OR_COOL_DOWNING (-6, client da hien) nhung char_auto_ride van doi 4,6 s roi bao
    # "chua hoc ky thuat" sai nghia. Kiem hoi truoc, bao dung ma, khong doi.
    dict(id='P3e', file='GameServer/services/scene/scenecore.lua',
         old=u('    -- 通过技能系统触发骑乘技能(skill 21)\n'),
         new=u('    -- CYS-RIDE-FINISH: ky nang 21 con hoi (冷却 3000 ms) => bao OR_COOL_DOWNING ngay, khong doi 4,6 s roi bao sai\n'
               '    if obj_me.is_skill_cool_down and not obj_me:is_skill_cool_down(21) then\n'
               '        skynet.logi("[DIAG_RIDE_PK] RIDE_ABORT ly do=KY NANG 21 CON HOI (3000 ms)")\n'
               '        obj_me:send_operate_result_msg(define.OPERATE_RESULT.OR_COOL_DOWNING)\n'
               '        return\n'
               '    end\n'
               '    -- 通过技能系统触发骑乘技能(skill 21)\n')),
    dict(id='P3c', file='GameServer/services/scene/scenecore.lua',
         old=u('            skynet.logi("[DIAG_RIDE_PK] RIDE_TIMEOUT skill 21 khong tao ra impact cuoi thu sau 15 lan cho")\n'
               '            return\n'),
         new=u('            skynet.logi("[DIAG_RIDE_PK] RIDE_TIMEOUT skill 21 khong tao ra impact cuoi thu sau ", tostring(retry), " lan cho")    -- CYS-RIDE-FINISH\n'
               '            obj_me:notify_tips("#{ZQGZ_110512_20}")\n'
               '            return\n')),
    dict(id='P3d', file='GameServer/services/scene/scenecore.lua',
         old=u('            elseif option.unknow_1 == 3 then\n'
               '                obj_me:set_ride(index)\n'),
         new=u('            elseif option.unknow_1 == 3 then\n'
               '                -- CYS-RIDE-FINISH: chi cho CHON thu da SO HUU (hoac -1 = bo chon); khong thi bao va giu nguyen\n'
               '                if index == define.INVAILD_ID or obj_me:have_this_ride(index) then\n'
               '                    obj_me:set_ride(index)\n'
               '                else\n'
               '                    skynet.logi("[DIAG_RIDE_PK] SELECT_ABORT ly do=KHONG SO HUU ride=", tostring(index))\n'
               '                    obj_me:notify_tips("#{ZQGZ_110512_25}")\n'
               '                end\n')),
    dict(id='P4', file='GameServer/services/scene/skill/human/skill_14.lua',
         old=u('\t\tlocal value = exterior_ride_conf[ride].impacts[max_speed_up] or define.INVAILD_ID\n'
               '\t\tif value ~= define.INVAILD_ID then\n'),
         new=u('\t\t-- CYS-RIDE-FINISH: chan nil khi ride id khong con trong bang (doi truc ID), va bao khi khong co impact\n'
               '\t\tlocal ride_conf = exterior_ride_conf[ride]\n'
               '\t\tlocal value = (ride_conf and ride_conf.impacts and ride_conf.impacts[max_speed_up]) or define.INVAILD_ID\n'
               '\t\tif value == define.INVAILD_ID then\n'
               '\t\t\tskynet.logi("[DIAG_RIDE_PK] SKILL21_NO_IMPACT ride=", tostring(ride), " bac=", tostring(max_speed_up))\n'
               '\t\t\tobj_tar:notify_tips("#{ZQGZ_110512_25}")\n'
               '\t\tend\n'
               '\t\tif value ~= define.INVAILD_ID then\n')),
    dict(id='P5', file='GameServer/lualib/define.lua',
         old=u('[define.HUMAN_EQUIP.HEQUIP_RIDER] = {MINID = 174,MAXID = 174,BUFFID = 63000},'),
         new=u('[define.HUMAN_EQUIP.HEQUIP_RIDER] = {MINID = 264,MAXID = 264,BUFFID = 63000}, -- CYS-RIDE-FINISH: 174 (GL 飒露紫) -> 264 (CY, cung mesh)'),
         count=2),
]


def luac_ok(path):
    for exe in ('luac5.4', 'luac5.3', 'luac'):
        try:
            r = subprocess.run([exe, '-p', path], capture_output=True)
            return r.returncode == 0, '%s rc=%d %s' % (exe, r.returncode, r.stderr.decode('utf-8', 'replace')[:300])
        except FileNotFoundError:
            continue
    return True, 'khong co luac (bo qua)'


def state(p, data):
    n = data.count(p['old'])
    applied = p['new'] in data
    want = p.get('count', 1)
    if applied:
        return 'DA VA'
    if n == want:
        return 'AP DUNG DUOC'
    if p.get('optional') and n == 0:
        return 'BO QUA (khong co doan cu, tuy chon)'
    return 'KHONG KHOP (thay %d lan, mong doi %d)' % (n, want)


def audit():
    rc = 0
    for p in PATCHES:
        path = os.path.join(ROOT, p['file'])
        data = open(path, 'rb').read()
        st = state(p, data)
        print('%-4s %-45s %s' % (p['id'], p['file'], st))
        if st.startswith('KHONG'):
            rc = 1
    return rc


def apply():
    stamp = time.strftime('%Y%m%dT%H%M%SZ', time.gmtime())
    backup = os.path.join(ROOT, 'backups', 'ride-finish-code-' + stamp)
    files = sorted(set(p['file'] for p in PATCHES))
    contents = {}
    for f in files:
        contents[f] = open(os.path.join(ROOT, f), 'rb').read()
    changed = set()
    for p in PATCHES:
        data = contents[p['file']]
        st = state(p, data)
        if st == 'DA VA' or st.startswith('BO QUA'):
            print(p['id'], st.lower())
            continue
        if not st.startswith('AP DUNG'):
            print('KHONG va', p['id'], st)
            return 2
        contents[p['file']] = data.replace(p['old'], p['new'])
        changed.add(p['file'])
        print(p['id'], 'va')
    if not changed:
        print('khong co gi de va (idempotent)')
        return 0
    os.makedirs(backup, exist_ok=True)
    for f in changed:
        src = os.path.join(ROOT, f)
        dst = os.path.join(backup, f)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(src, dst)
        tmp = src + '.cys-tmp'
        open(tmp, 'wb').write(contents[f])
        ok, note = luac_ok(tmp)
        if not ok:
            os.remove(tmp)
            print('luac THAT BAI cho', f, note, '— khong ghi gi')
            return 3
        os.replace(tmp, src)
        print('ghi', f, note)
    print('sao luu:', backup)
    return 0


def revert(backup):
    n = 0
    for dirpath, _, names in os.walk(backup):
        for name in names:
            src = os.path.join(dirpath, name)
            rel = os.path.relpath(src, backup)
            dst = os.path.join(ROOT, rel)
            shutil.copy2(src, dst)
            print('tra lai', rel)
            n += 1
    return 0 if n else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('cmd', choices=('audit', 'apply', 'revert'))
    ap.add_argument('--backup')
    a = ap.parse_args()
    if a.cmd == 'audit':
        return audit()
    if a.cmd == 'apply':
        return apply()
    if not a.backup:
        sys.exit('revert can --backup DIR')
    return revert(a.backup)


if __name__ == '__main__':
    sys.exit(main())
