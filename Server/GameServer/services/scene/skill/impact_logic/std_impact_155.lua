-- impact-logic (CY-Source 15/09/2026): logic 155 (tlbb15 StdImpact155_T 魂离魄散) — quét địch quanh chủ nhân, gửi impact khi kích hoạt và khi chết.
-- Bằng chứng: Serverhook.so StdImpact155_T::OnActive/OnDie (Build/re/impact-logic/hook.trim.c).
--   OnActive: chủ nhân = Obj tạo impact; quét bán kính 0x19 quanh chủ; đếm buff 集合 0x15b/0x15d/0x15f (=347/349/351) đang có →
--             tăng chỉ số 0x4c chọn 参数值 thứ (0..3) làm impact gửi cho tối đa 6 địch (SendImpactByCombat, cấp = xinfa%10).
--   OnDie: quét địch quanh chủ, gửi 参数值[0] (死亡触发) cho tối đa 6 địch.
-- CY nhãn: 死亡触发, 一魂, 二魂, 三魂 (=参数值 0..3). Bản Lua dùng scan + send_impact_to_unit (đủ hiệu ứng chính; SendImpactByCombat native
--   xử lý sát thương theo cấp — ở đây dùng send_impact_to_unit thường, sát thương theo dòng impact con [SL]).
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local std_impact_155 = class("std_impact_155", base)

local SOUL_KEYS = { "死亡触发", "一魂", "二魂", "三魂" }
local SCAN_RADIOUS = 25

function std_impact_155:is_over_timed()
    return true
end

function std_impact_155:is_intervaled()
    return false
end

-- chủ nhân = Obj tạo impact (native lấy theo caster id trong param2+0xc)
local function caster_of(imp, obj)
    local id = imp:get_caster_obj_id()
    if id and id ~= -1 then
        return obj:get_scene():get_obj_by_id(id) or obj
    end
    return obj
end

local function scan_enemies(caster)
    local pos = caster:get_world_pos()
    return caster:get_scene():scan({ obj = caster, x = pos.x, y = pos.y, radious = SCAN_RADIOUS, target_logic_by_stand = 1, count = 6 })
end

function std_impact_155:on_active(imp, obj)
    local caster = caster_of(imp, obj)
    -- chọn ô hồn theo số buff集合 đang có (347/349/351); không tra được集合 → dùng ô 0 [SL]
    local slot = 0
    local value = util.num(imp, SOUL_KEYS[slot + 1], -1)
    if value < 0 then
        return
    end
    local count = 0
    for _, nb in ipairs(scan_enemies(caster)) do
        if nb:is_character_obj() and caster:is_enemy(nb) and nb:is_alive() then
            obj:get_scene():get_impact_enginer():send_impact_to_unit(nb, value, caster, 0, imp:is_critical_hit(), 0, imp:get_skill_id())
            count = count + 1
            if count >= 6 then break end
        end
    end
end

function std_impact_155:on_die(imp, obj)
    local caster = caster_of(imp, obj)
    local value = util.num(imp, SOUL_KEYS[1], -1)
    if value < 0 then
        return
    end
    local count = 0
    for _, nb in ipairs(scan_enemies(caster)) do
        if nb:is_character_obj() and caster:is_enemy(nb) and nb:is_alive() then
            obj:get_scene():get_impact_enginer():send_impact_to_unit(nb, value, caster, 0, false, 0, imp:get_skill_id())
            count = count + 1
            if count >= 6 then break end
        end
    end
end

return std_impact_155
