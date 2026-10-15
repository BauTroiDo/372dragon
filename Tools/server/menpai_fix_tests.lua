-- menpai-fix: test Lua đơn vị (lua5.4) cho logic điều kiện CY 16–21 (scene.skill.condition_cy) + vá storage/condition_delplete_core.
--   lua5.4 Tools/server/menpai_fix_tests.lua <gốc_server_riêng> [<staging>/lua]
-- Nạp module từ staging (nếu có) rồi server riêng; define/cy_four_combat.callbacks giả lập. Thoát 0 khi mọi test đạt.
local root = assert(arg[1], "cần đường dẫn gốc server riêng")
local staging = arg[2]
local paths = {}
for _, r in ipairs(staging and {staging, root} or {root}) do
    paths[#paths + 1] = r .. "/GameServer/lualib/?.lua"
    paths[#paths + 1] = r .. "/GameServer/services/?.lua"
end
package.path = table.concat(paths, ";") .. ";" .. package.path

package.preload["define"] = function()
    return {INVAILD_ID = -1, OPERATE_RESULT = {OR_OK = 0, OR_LACK_MANA = -5, OR_INVALID_TARGET = -8, OR_U_CANNT_DO_THIS_RIGHT_NOW = -44},
            ConditionAndDepleteID = {CD_INVALID = -1, C_UNIT_MUST_HAVE_IMPACT = 0, C_UNIT_HP_MUST_LESS_THAN_BY_RATE = 1, C_TARGET_MUST_HAVE_IMPACT = 2,
                C_TARGET_LEVEL_MUST_LESS_THAN_BY_VALUE = 3, CD_MANA_BY_VALUE = 4, CD_MANA_BY_RATE = 5, CD_RAGE_BY_RATE = 6, CD_STRIKE_POINT_BY_SEGMENT = 7,
                D_ALL_RAGE = 8, D_CANCEL_SPECIFIC_IMPACT = 9, C_TARGET_MUST_BE_MY_SPOUSE = 10, CD_HP_BY_RATE = 11, C_HP_BY_RATE = 12, CD_HP_BY_VALUE = 13,
                CD_FLOWER_BY_VALUE = 14, C_UNIT_MUST_NOT_HAVE_IMPACT = 16},
            STRIKE_POINT_SEGMENT_SIZE = 3}
end
local DOLL = -1
package.preload["cy_four_combat.callbacks"] = function() return {get_doll_id = function() return DOLL end} end
package.preload["cy_four_combat.resources"] = function() return {dispatch = function() return false end} end

local pass, fail = 0, 0
local function test(name, fn)
    local ok, e = pcall(fn)
    if ok then pass = pass + 1; print("PASS " .. name) else fail = fail + 1; print("FAIL " .. name .. ": " .. string.sub(tostring(e), 1, 400)) end
end
local function eq(a, b, msg) if a ~= b then error((msg or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end

local BRIDGE = nil
local function imp(mutex) return {get_mutex_id = function() return mutex end} end
local function human(o)
    o = o or {}
    local h = {menpai = o.menpai or 0, res = o.res or {}, impacts = o.impacts or {}, skill = o.skill or 1, err = nil, objs = o.objs or {}, target = o.target}
    local params = {set_errcode = function(_, c) h.err = c end, get_target_obj = function() return h.target end}
    local info = {get_skill_id = function() return h.skill end}
    function h:get_obj_type() return o.type or "human" end
    function h:get_menpai() return self.menpai end
    function h:get_cy_four_resource(id) return self.res[id] or 0 end
    function h:set_cy_four_resource(id, v) self.res[id] = v end
    function h:get_impact_list() return self.impacts end
    function h:get_skill_info() return info end
    function h:get_targeting_and_depleting_params() return params end
    function h:get_scene()
        return {get_obj_by_id = function(_, id) return h.objs[id] end,
                get_impact_enginer = function() return {cy_four_bridge = BRIDGE} end}
    end
    return h
end

local core = require "scene.skill.condition_delplete_core"
local C = require "scene.skill.condition_cy"
local coll = require "cy_idcollections"

test("tập ID CY: 340 桃花岛共情技能 (tlbb15), 376 九阴 {151}, 499 {2631}, 414 拘魂·地 {9093}", function()
    eq(coll[340].ids[3806], true); eq(coll[340].ids[3801], nil, "八列之舞 không thuộc 340")
    eq(coll[376].ids[151], true); eq(coll[499].ids[2631], true); eq(coll[414].ids[9093], true)
end)

test("core: đăng ký 16–21 + kiểu lạ không assert", function()
    for _, t in ipairs({16, 17, 18, 19, 20, 21}) do assert(core.logics[t], "thiếu " .. t) end
    local h = human()
    eq(core:condition_check(h, {type = 99, params = {1, 2}}), true, "kiểu lạ đạt")
    eq(core:deplete(h, {type = 99, params = {1, 2}}), true)
    eq(core:condition_check(h, {type = 21, params = {1, -1}}), true, "21 需要天机点 như native: đạt")
end)

test("18: bản thân có impact MutexID ∈ tập → không đạt (-44)", function()
    local h = human({menpai = 4, impacts = {imp(151)}})
    eq(core:condition_check(h, {type = 18, params = {376, -1}}), false); eq(h.err, -44)
    h.impacts = {imp(152)}
    eq(core:condition_check(h, {type = 18, params = {376, -1}}), true); eq(h.err, 0)
    local m = human({type = "monster", impacts = {imp(151)}})
    eq(core:condition_check(m, {type = 18, params = {376, -1}}), true, "không phải người chơi → bỏ qua như hook")
end)

test("20: bản thân không có impact thuộc tập → không đạt; 19 đếm impact mục tiêu", function()
    local h = human({menpai = 11})
    eq(core:condition_check(h, {type = 20, params = {5, -1}}), false)
    h.impacts = {imp(3)}
    eq(core:condition_check(h, {type = 20, params = {5, -1}}), true)
    local tar = human({impacts = {imp(1), imp(2)}})
    h.objs[7] = tar; h.target = 7
    eq(core:condition_check(h, {type = 19, params = {5, 3}}), false, "2 < 3")
    eq(core:condition_check(h, {type = 19, params = {5, 2}}), true)
end)

test("16 桃花岛: chỉ kỹ năng ∈ 340; thiếu 共情 hoặc không có con rối → không đạt; trừ khi thành công qua hàng chờ", function()
    local h = human({menpai = 13, skill = 3806, res = {[328] = 1000 * 10000 + 100}})
    DOLL = 5
    eq(core:condition_check(h, {type = 16, params = {140, 140}}), false, "100 < 140")
    h.res[328] = 1000 * 10000 + 200
    eq(core:condition_check(h, {type = 16, params = {140, 140}}), true)
    DOLL = -1
    eq(core:condition_check(h, {type = 16, params = {140, 140}}), false, "cần con rối")
    DOLL = 5
    BRIDGE = {resources = {pending = {}}}
    eq(core:deplete(h, {type = 16, params = {140, 140}}), true)
    eq(h.res[328], 1000 * 10000 + 200, "chưa trừ trước khi dùng thành công")
    eq(BRIDGE.resources.pending[h].costs[8016].need, 140)
    BRIDGE = nil
    core:deplete(h, {type = 16, params = {140, 140}})
    eq(h.res[328], 1000 * 10000 + 60, "không có bridge → trừ ngay")
    local b = human({menpai = 13, skill = 3801})
    eq(core:condition_check(b, {type = 16, params = {50, 50}}), true, "八列之舞 ∉ 340 → không kiểm (native)")
    local other = human({menpai = 14, skill = 3806})
    eq(core:condition_check(other, {type = 16, params = {140, 140}}), true, "phái khác → bỏ qua")
end)

test("17 绝情谷: 刀意 %10 < p0 → không đạt; chỉ trừ ở 4530/4533/4534/4538", function()
    local h = human({menpai = 14, skill = 4530, res = {[331] = 31}})
    eq(core:condition_check(h, {type = 17, params = {2, -1}}), false)
    h.res[331] = 32
    eq(core:condition_check(h, {type = 17, params = {2, -1}}), true)
    core:deplete(h, {type = 17, params = {2, -1}})
    eq(h.res[331], 30)
    h.skill = 4535; h.res[331] = 32
    core:deplete(h, {type = 17, params = {1, -1}})
    eq(h.res[331], 32, "4535 (废弃) không có trong danh sách trừ native")
    local x = human({menpai = 13, skill = 4530})
    eq(core:condition_check(x, {type = 17, params = {2, -1}}), true, "phái khác → bỏ qua")
end)

test("storage: phái CY 13/14 nhận tài nguyên, 15/16 bị từ chối", function()
    local S = require "cy_four_combat.storage"
    local o = {get_menpai = function() return 13 end}
    S.set(o, 328, 10000080); eq(S.get(o, 328), 10000080)
    local j = {get_menpai = function() return 14 end}
    S.set(j, 331, 33); S.set(j, 332, 4); eq(S.get(j, 331), 33)
    local bad = {get_menpai = function() return 15 end}
    eq(pcall(S.set, bad, 328, 1), false, "phái 15 (恶人谷 CY) không có 共情")
end)

print(string.format("menpai_fix_tests: %d đạt, %d hỏng", pass, fail))
os.exit(fail == 0 and 0 or 1)
