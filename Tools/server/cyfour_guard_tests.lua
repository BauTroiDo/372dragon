-- skill-logic: test cho bản vá "impact không có mô tả thì BỎ QUA như CY" (cy_four_combat/engine.lua + db/impact_data.lua)
--   lua5.4 Tools/server/cyfour_guard_tests.lua <gốc GameServer đã vá> [<gốc dự phòng>]
local roots = {}
for i = 1, 2 do
    local b = arg[i]
    if b then
        if not b:match("GameServer$") then b = b .. "/GameServer" end
        roots[#roots + 1] = b .. "/lualib/?.lua"
        roots[#roots + 1] = b .. "/services/?.lua"
    end
end
assert(#roots > 0, "can duong dan GameServer")
package.path = table.concat(roots, ";") .. ";" .. package.path

LOGS = {}
package.preload["skynet"] = function()
    return {logi = function(...) LOGS[#LOGS + 1] = table.concat({...}, " ") end,
            loge = print, logd = function() end, error = print}
end
package.preload["game.packet"] = function() return {} end
package.preload["define"] = function() return {INVAILD_ID = -1} end

-- native giả lập: đếm số lần được gọi, và nổ nếu bị gọi với state = nil
NATIVE_CALLS = 0
local function native_fn(_, state)
    assert(state ~= nil, "native bi goi voi state = nil")
    NATIVE_CALLS = NATIVE_CALLS + 1
    return 111
end
package.preload["cy_four_combat.native"] = function()
    return setmetatable({new_impact = function(donor, values) return {donor = donor, values = values} end},
                        {__index = function() return native_fn end})
end
package.preload["cy_four_combat.numeric"] = function()
    return {float2int = function(x) return math.floor(x) end, f32 = function(x) return x end}
end
package.preload["scene.skill.impact_logic.base"] = function()
    local class = require "class"
    local b = class("impact_base_mock")
    function b:continuance_cal() return "base_continuance" end
    function b:on_active() return "base_on_active" end
    return b
end

local class = require "class"
local engine = require "cy_four_combat.engine"

local pass, fail = 0, 0
local function test(name, fn)
    LOGS, NATIVE_CALLS = {}, 0
    local ok, e = pcall(fn)
    if ok then pass = pass + 1; print("PASS " .. name)
    else fail = fail + 1; print("FAIL " .. name .. ": " .. string.sub(tostring(e), 1, 300)) end
end
local function eq(a, b, m) if a ~= b then error((m or "") .. " expected " .. tostring(b) .. " got " .. tostring(a), 2) end end

local DESC = {donor_id = 4465, donor_logic = 148, step0 = 0,
              params = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16}}

local function make_bridge(ids)
    local cfg = {impacts = {}, disabled_logic_ids = {[171] = true},
                 float2int_verified = true, critical_bonus_hook_verified = true,
                 final_damage_hook_verified = true, talents_enabled = false,
                 tao_logic168_base_ready = true}
    for _, id in ipairs(ids or {}) do cfg.impacts[id] = DESC end
    local ctx = setmetatable({mark_attr_dirty = function() end},
                             {__index = function() return function() return 0 end end})
    return engine.new(cfg, ctx)
end

local function fake_impact(data_index)
    return {get_data_index = function() return data_index end,
            get_continuance = function() return 1000 end,
            get_caster_obj_id = function() return 7 end,
            get_skill_id = function() return 1 end}
end

test("state: có mô tả → dựng state, gọi được native", function()
    local b = make_bridge({4465})
    local s = b:state(fake_impact(4465))
    assert(s ~= nil, "phai co state")
    eq(s.donor, 4465)
end)

test("state: KHÔNG có mô tả → trả nil, KHÔNG ném lỗi (như CY InitImpactFromData trả 0)", function()
    local b = make_bridge({4465})
    local s = b:state(fake_impact(99999))
    eq(s, nil)
    eq(#LOGS, 1, "phai ghi log mot lan")
    b:state(fake_impact(99999))
    b:state(fake_impact(99999))
    eq(#LOGS, 1, "khong duoc spam log cho cung data_index")
    b:state(fake_impact(88888))
    eq(#LOGS, 2, "data_index khac thi ghi them mot lan")
end)

test("logic 148: thiếu mô tả → critical_damage_bonus giữ nguyên point, native KHÔNG bị gọi", function()
    local b = make_bridge({4465})
    local l = b:make_impact(148)
    eq(l:critical_damage_bonus(fake_impact(99999), 42), 42)
    eq(NATIVE_CALLS, 0)
    l:mark_modified_attr_dirty(fake_impact(99999), {})
    eq(NATIVE_CALLS, 0)
end)

test("logic 148: có mô tả → vẫn gọi native như cũ", function()
    local b = make_bridge({4465})
    local l = b:make_impact(148)
    eq(l:critical_damage_bonus(fake_impact(4465), 42), 111)
    assert(NATIVE_CALLS > 0, "phai goi native")
end)

test("logic 149: thiếu mô tả → on_final_damage giữ nguyên sát thương", function()
    local b = make_bridge({4465})
    local l = b:make_impact(149)
    eq(l:on_final_damage(fake_impact(99999), {}, {}, 777, {critical = false}), 777)
    eq(NATIVE_CALLS, 0)
end)

test("logic 52: thiếu mô tả → add_new_trap = false, đếm bẫy = 0", function()
    local b = make_bridge({4465})
    local l = b:make_impact(52)
    eq(l:add_new_trap(fake_impact(99999), {}, 5), false)
    eq(l:get_trap_count_of_specific_type(fake_impact(99999), {}, 1), 0)
    eq(NATIVE_CALLS, 0)
end)

test("logic 167: thiếu mô tả → refix_power_by_rate = false, continuance_cal rơi về base", function()
    local b = make_bridge({4465})
    local l = b:make_impact(167)
    eq(l:refix_power_by_rate(fake_impact(99999), 30), false)
    local l99 = b:make_impact(99)
    eq(l99:continuance_cal(fake_impact(99999), {}, 10), "base_continuance")
    eq(NATIVE_CALLS, 0)
end)

test("critical_bonus: danh sách buff có impact thiếu mô tả vẫn tính được", function()
    local b = make_bridge({4465})
    b:make_impact(148)
    local owner = {get_impact_list = function()
        local a, c = fake_impact(99999), fake_impact(4465)
        a.get_logic_id = function() return 8148 end
        c.get_logic_id = function() return 8148 end
        return {a, c}
    end}
    local point = b:critical_bonus(owner, 5)
    eq(point, 111, "impact thieu mo ta bi bo qua, impact co mo ta van tinh")
end)


-- ---------------------------------------------------------------- không còn vòng tham chiếu
local function max_depth(t, seen, d)
    seen = seen or {}; d = d or 1
    if type(t) ~= "table" or seen[t] then return d end
    seen[t] = true
    local m = d
    for k, v in pairs(t) do
        if type(v) == "table" then
            local x = max_depth(v, seen, d + 1)
            if x > m then m = x end
        end
    end
    seen[t] = nil
    return m
end

test("state KHÔNG nằm trên đối tượng impact (không còn vòng → skynet đóng gói được)", function()
    local b = make_bridge({4465})
    local imp = fake_impact(4465)
    b:state(imp)
    eq(imp._cy_four_native, nil, "khong duoc gan len impact")
    local cache = require "cy_four_combat.state_cache"
    assert(cache[imp] ~= nil, "state phai nam o bang phu")
    eq(cache[imp].engine_impact, imp, "state van tro ve impact (runtime_adapter can)")
    -- đồ thị của impact phải NÔNG (trước đây imp -> state -> imp -> … vô hạn)
    assert(max_depth(imp) < 5, "do sau = " .. max_depth(imp))
end)

test("impact:clean_up xoá mục trong kho trạng thái", function()
    local b = make_bridge({4465})
    local imp = fake_impact(4465)
    b:state(imp)
    local cache = require "cy_four_combat.state_cache"
    assert(cache[imp] ~= nil)
    cache[imp] = nil                     -- đúng việc mà impact:clean_up làm
    eq(cache[imp], nil)
end)

print(string.format("cyfour_guard_tests: %d dat, %d loi", pass, fail))
os.exit(fail == 0 and 0 or 1)
