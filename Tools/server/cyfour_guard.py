#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""cyfour_guard — impact KHÔNG có mô tả thì BỎ QUA như CY, không assert (đang làm kẹt đăng nhập).

Bằng chứng mã CY (tlbb15 Server, tháo mã chỉ đọc — Build/re/skill-logic/impactcore_initfromdata*.asm.txt):
  Combat_Module::Impact_Module::ImpactCore_T::InitImpactFromData @0xa87fee
      imp[+4] = dataIndex; imp[+0x24] = level
      pData = GetImpactData(dataIndex)            ; call 0xa87ee6
      if (pData == NULL) { return 0; }            ; @0xa88080 je → @0xa880b6 mov eax,0 ; ret
      logic = GetLogic(&imp)                      ; call 0xa43425
      if (logic == NULL) { return 0; }            ; @0xa8809b je → @0xa880c2 mov eax,0
      return logic->Init(&imp, pData) == 1;
  Người gọi kiểm giá trị trả về rồi BỎ QUA (vd StdImpact115_T::OnActive @0xa5f415 `test eax,eax; jne`).
  ⇒ CY: thiếu mô tả hiệu ứng → không dựng impact, KHÔNG dừng chương trình.

Phía server riêng, `cy_four_combat/engine.lua:67` lại `assert(config.impacts[data_index], "unmapped
positional impact")`. Một buff cũ (kể cả đã hết hạn) trỏ tới Data_Index không có mô tả positional làm
`human.ctor → impact_data.init_from_db_data → register_impact → on_impact_activated` ném lỗi ⇒ nhân vật
KHÔNG đăng nhập được. Hai lớp vá (đều theo CY):

  1. `lualib/db/impact_data.lua`: bỏ qua buff lưu trong DB mà `data_index` không có dòng StandardImpact
     — đúng nhánh `GetImpactData(dataIndex) == NULL → return 0` của CY.
  2. `lualib/cy_four_combat/engine.lua`: `bridge:state` trả nil + ghi log MỘT LẦN cho mỗi data_index
     thay vì assert; mọi phương thức do `make_impact` sinh ra được bọc để khi thiếu mô tả thì trả giá trị
     trung tính (point/damage giữ nguyên, continuance_cal rơi về base, số đếm 0, cờ false).

  cyfour_guard.py plan --out <dir> | apply --staging <dir> [--dry-run] | verify [--staging <dir>]
"""
import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys

R = '/home/ubuntu/cys-test-20260913'
GS = 'GameServer'
MARK = 'skill-logic guard'
ENGINE = 'lualib/cy_four_combat/engine.lua'
IMPDB = 'lualib/db/impact_data.lua'
GUARDCACHE = 'lualib/cy_four_combat/state_cache.lua'
JUE = 'lualib/cy_four_combat/jue_cast_guard.lua'
IMPACT = 'services/scene/skill/impact.lua'

CACHE_SRC = """-- %s (16/09/2026): kho trạng thái native của cy_four, ĐỂ NGOÀI đối tượng impact.
--
-- Trước đây `engine.lua` lưu `imp._cy_four_native = state` và `state.engine_impact = imp` → vòng tham
-- chiếu. `human:get_save_data()` đóng gói `impacts:get_list()` (chính các đối tượng impact sống) gửi
-- từ scene về msgagent, nên skynet báo `serialize can't pack too depth table` và msgagent bị giết
-- (client rớt). Để state ở bảng phụ khoá YẾU thì đồ thị của impact lại phẳng, đóng gói được;
-- state vẫn sống đúng bằng tuổi của impact.
local M = setmetatable({}, {__mode = "k"})
return M
""" % MARK
TESTS = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'cyfour_guard_tests.lua')

STATE_OLD = """    function bridge:state(imp)
        local state=imp._cy_four_native
        if not state or state.target_id~=imp:get_data_index() then
            local source=assert(self.config.impacts[imp:get_data_index()],"unmapped positional impact")"""

STATE_NEW = """    -- %s: CY (ImpactCore_T::InitImpactFromData @0xa87fee) trả 0 khi không có mô tả hiệu ứng và người
    -- gọi bỏ qua; ở đây cũng BỎ QUA (trả nil) + ghi log một lần cho mỗi data_index, KHÔNG assert —
    -- assert cũ làm nhân vật mang buff cũ không đăng nhập được (human.ctor → init_from_db_data).
    bridge.missing_descriptor_logged = {}
    function bridge:descriptor(imp)
        local id=imp:get_data_index()
        local source=self.config.impacts[id]
        if not source and not self.missing_descriptor_logged[id] then
            self.missing_descriptor_logged[id]=true
            require("skynet").logi("[cy_four] bo qua impact khong co mo ta positional, data_index =",id)
        end
        return source
    end
    function bridge:state(imp)
        local state=require("cy_four_combat.state_cache")[imp]
        if not state or state.target_id~=imp:get_data_index() then
            local source=self:descriptor(imp)
            if not source then return nil end""" % MARK

WRAP_OLD = """        self.impacts[id+8000]=logic.new()
        return self.impacts[id+8000]
    end
    function bridge:critical_bonus(owner,point)"""

WRAP_NEW = """        -- %s: bọc mọi phương thức — impact không có mô tả positional thì trả giá trị TRUNG TÍNH
        -- (như CY: không dựng được impact thì coi như hiệu ứng không tồn tại), không ném lỗi.
        local neutral={
            critical_damage_bonus=function(_,_,point) return point end,
            on_final_damage=function(_,_,_,_,damage) return damage end,
            on_final_damage_target=function(_,_,_,_,damage) return damage end,
            continuance_cal=function(self_,imp,owner,delta) return base.continuance_cal(self_,imp,owner,delta) end,
            add_new_trap=function() return false end,
            get_trap_count_of_specific_type=function() return 0 end,
            refix_power_by_rate=function() return false end,
        }
        local raw={}
        for name,fn in pairs(logic) do
            -- chỉ bọc phương thức do CHÍNH lớp này định nghĩa (khác bản của base), tức các phương thức
            -- gọi b:state; phương thức kế thừa nguyên của base giữ nguyên.
            if type(fn)=="function" and base[name]~=fn and name~="is_over_timed"
               and name~="is_intervaled" and name~="new" and name~="ctor" then
                raw[name]=fn
            end
        end
        for name,fn in pairs(raw) do
            logic[name]=function(self_,imp,...)
                if type(imp)=="table" and imp.get_data_index and not b:descriptor(imp) then
                    local n=neutral[name]
                    if n then return n(self_,imp,...) end
                    return nil
                end
                return fn(self_,imp,...)
            end
        end
        self.impacts[id+8000]=logic.new()
        return self.impacts[id+8000]
    end
    function bridge:critical_bonus(owner,point)""" % MARK

DB_OLD = """		local logic_id = imp_data.logic_id
		if not logic_id
		or logic_id < 0
		or logic_id == 86 then
			table.remove(impacts,i)"""

DB_NEW = """		local logic_id = imp_data.logic_id
		-- %s: CY ImpactCore_T::InitImpactFromData @0xa87fee — không có dòng StandardImpact cho
		-- data_index thì trả 0 và người gọi bỏ qua. Buff lưu trong DB trỏ tới dòng đã biến mất
		-- (bảng impact đổi) sẽ làm nhân vật không đăng nhập được, nên bỏ ở đây luôn.
		local di = imp_data.data_index
		local has_row = true
		if di then
			local ok_cfg, eng = pcall(function() return require("impactenginer"):getinstance() end)
			if ok_cfg and eng and type(eng.std_impact_config) == "table" then
				has_row = eng.std_impact_config[di] ~= nil
			end
		end
		if not has_row then
			require("skynet").logi("[impact_data] bo qua buff luu san khong con dong StandardImpact, data_index =", di)
			table.remove(impacts,i)
		elseif not logic_id
		or logic_id < 0
		or logic_id == 86 then
			table.remove(impacts,i)""" % MARK


def read(path):
    with open(path, 'rb') as f:
        return f.read().decode('utf-8')


STORE_OLD = "            imp._cy_four_native=state"
STORE_NEW = '            require("cy_four_combat.state_cache")[imp]=state   -- ' + MARK

JUE_OLD = "   local state=imp._cy_four_native"
JUE_NEW = '   local state=require("cy_four_combat.state_cache")[imp]   -- ' + MARK

IMPACT_OLD = 'function impact:clean_up()\n    self._cy_four_native = nil'
IMPACT_NEW = ('function impact:clean_up()\n'
              '    require("cy_four_combat.state_cache")[self] = nil   -- ' + MARK + '\n'
              '    self._cy_four_native = nil')


def patch_engine(txt):
    if MARK in txt:
        return txt
    if STATE_OLD not in txt:
        raise SystemExit('khong tim thay bridge:state cu')
    if WRAP_OLD not in txt:
        raise SystemExit('khong tim thay cho boc make_impact')
    if STORE_OLD not in txt:
        raise SystemExit('khong tim thay cho luu state')
    txt = txt.replace(STATE_OLD, STATE_NEW, 1)
    txt = txt.replace(STORE_OLD, STORE_NEW, 1)
    return txt.replace(WRAP_OLD, WRAP_NEW, 1)


def patch_jue(txt):
    if MARK in txt:
        return txt
    if JUE_OLD not in txt:
        raise SystemExit('khong tim thay cho doc state trong jue_cast_guard')
    return txt.replace(JUE_OLD, JUE_NEW, 1)


def patch_impact(txt):
    if MARK in txt:
        return txt
    if IMPACT_OLD not in txt:
        raise SystemExit('khong tim thay impact:clean_up')
    return txt.replace(IMPACT_OLD, IMPACT_NEW, 1)


def patch_db(txt):
    if MARK in txt:
        return txt
    if DB_OLD not in txt:
        raise SystemExit('khong tim thay vong loc init_from_db_data')
    return txt.replace(DB_OLD, DB_NEW, 1)


FILES = [(ENGINE, patch_engine), (IMPDB, patch_db), (JUE, patch_jue), (IMPACT, patch_impact)]
NEW_FILES = [(GUARDCACHE, CACHE_SRC)]


def cmd_plan(args):
    out = {}
    for rel, src in NEW_FILES:
        dst = os.path.join(args.out, 'lua', GS, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(src.encode('utf-8'))
        out[rel] = 'moi'
    for rel, fn in FILES:
        src = read(os.path.join(R, GS, rel))
        new = fn(src)
        dst = os.path.join(args.out, 'lua', GS, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new.encode('utf-8'))
        out[rel] = 'patched' if new != src else 'khong doi (da va)'
    with open(os.path.join(args.out, 'plan.json'), 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=1)
    print(json.dumps(out, ensure_ascii=False, indent=1))


def cmd_apply(args):
    stamp = datetime.datetime.utcnow().strftime('%Y%m%dT%H%M%SZ')
    bdir = os.path.join(R, 'backups', 'cyfour-guard-' + stamp)
    changed = []
    for rel, _ in FILES + NEW_FILES:
        src = os.path.join(args.staging, 'lua', GS, rel)
        dst = os.path.join(R, GS, rel)
        new = open(src, 'rb').read()
        old = open(dst, 'rb').read() if os.path.exists(dst) else None
        if new == old:
            continue
        changed.append(rel)
        if args.dry_run:
            continue
        if old is not None:
            os.makedirs(os.path.join(bdir, os.path.dirname(rel)), exist_ok=True)
            shutil.copy2(dst, os.path.join(bdir, rel))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, 'wb') as f:
            f.write(new)
    print(json.dumps({'changed': changed, 'backup': None if args.dry_run else bdir,
                      'dry_run': bool(args.dry_run)}, ensure_ascii=False, indent=1))


def cmd_verify(args):
    base = os.path.join(args.staging, 'lua', GS) if args.staging else os.path.join(R, GS)
    res = {'base': base, 'luac': [], 'marks': {}}
    for rel, _ in NEW_FILES:
        p = os.path.join(base, rel)
        r = subprocess.run(['luac5.4', '-p', p], capture_output=True)
        if r.returncode != 0:
            res['luac'].append({'file': rel, 'err': r.stderr.decode('utf-8', 'replace').strip()})
        res['marks'][rel] = os.path.exists(p)
    for rel, _ in FILES:
        p = os.path.join(base, rel)
        r = subprocess.run(['luac5.4', '-p', p], capture_output=True)
        if r.returncode != 0:
            res['luac'].append({'file': rel, 'err': r.stderr.decode('utf-8', 'replace').strip()})
        res['marks'][rel] = MARK in read(p)
    if os.path.exists(TESTS):
        r = subprocess.run(['lua5.4', TESTS, base, os.path.join(R, GS)], capture_output=True)
        res['tests_rc'] = r.returncode
        res['tests'] = r.stdout.decode('utf-8', 'replace').strip().splitlines()[-12:]
        if r.returncode != 0:
            res['tests_err'] = r.stderr.decode('utf-8', 'replace').strip()[-1500:]
    res['ok'] = (not res['luac'] and all(res['marks'].values()) and res.get('tests_rc', 0) == 0)
    print(json.dumps(res, ensure_ascii=False, indent=1))
    return 0 if res['ok'] else 1


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
