




local class = require "class"
local combat_core = require "scene.skill.combat_core"
local impact = require "scene.skill.impact"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local std_impact_102 = class("std_impact_102", base)

function std_impact_102:is_over_timed()
    return true
end

function std_impact_102:is_intervaled()
    return false
end

local function send_sub(scene, from, to, value, imp)
    if value < 0 then return end
    local imp_new = impact.new()
    imp_new:clean_up()
    scene:get_impact_enginer():init_impact_from_data(value, imp_new)
    imp_new:set_skill_id(imp:get_skill_id())
    imp_new:set_skill_level(imp:get_skill_level())
    if imp_new:get_logic_id() == DI_DamagesByValue_T.ID then
        combat_core.new():get_result_impact(from, to, imp_new)
    end
    scene:get_event_enginer():register_impact_event(to, from, imp_new, 0, imp:get_skill_id())
end

function std_impact_102:on_active(imp, obj)
    -- 激活产生效果 lên chính chủ nhân (native gửi cho param3 = chủ)
    send_sub(obj:get_scene(), obj, obj, util.num(imp, "激活产生效果", -1), imp)
end

function std_impact_102:on_fade_out(imp, obj)
    local radious = util.num(imp, "扫描半径", 10)
    local pos = obj:get_world_pos()
    local nearbys = obj:get_scene():scan({ obj = obj, x = pos.x, y = pos.y, radious = radious,
        target_logic_by_stand = 0, count = util.num(imp, "影响目标人数", 6) })
    local alive = obj:is_alive()
    local scene = obj:get_scene()
    for _, nb in ipairs(nearbys) do
        if nb:is_character_obj() and nb ~= obj then
            -- chủ còn sống → 消散效果; chủ chết → 死亡效果 (native: chọn theo IsAlive từng vòng)
            local value = alive and util.num(imp, "消散效果", -1) or util.num(imp, "死亡效果", -1)
            send_sub(scene, obj, nb, value, imp)
        end
    end
end

return std_impact_102
