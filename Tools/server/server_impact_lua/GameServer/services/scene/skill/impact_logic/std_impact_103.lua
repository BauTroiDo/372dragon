




local class = require "class"
local combat_core = require "scene.skill.combat_core"
local impact = require "scene.skill.impact"
local base = require "scene.skill.impact_logic.base"
local util = require "scene.skill.impact_logic.cy_impact_util"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local std_impact_103 = class("std_impact_103", base)

function std_impact_103:is_over_timed()
    return true
end

function std_impact_103:is_intervaled()
    return true
end

-- 目标选择标记: -1 địch → target_logic_by_stand 1; 2 (đồng minh+đội) → 0; khác → nil (giữ như 086)
local function stand_of(imp)
    local v = util.num(imp, "目标选择标记：-1:敌人,0:中立,1:友好,2:友好+队友;", -1)
    if v == -1 then return 1 elseif v == 2 then return 0 end
    return 1
end

function std_impact_103:on_interval_over(imp, obj)
    local radious = util.num(imp, "扫描半径", 5)
    local pos = obj:get_world_pos()
    local nearbys = obj:get_scene():scan({ obj = obj, x = pos.x, y = pos.y, radious = radious,
        target_logic_by_stand = stand_of(imp), count = util.num(imp, "影响目标人数", 6) })
    local scene = obj:get_scene()
    local eventenginer = scene:get_event_enginer()
    for _, nb in ipairs(nearbys) do
        if nb:is_character_obj() and obj:is_enemy(nb) and nb:is_alive() then
            for i = 1, 3 do
                local value = util.num(imp, "子效果" .. i, -1)
                if value ~= -1 then
                    local imp_new = impact.new()
                    imp_new:clean_up()
                    scene:get_impact_enginer():init_impact_from_data(value, imp_new)
                    if imp:is_critical_hit() then imp_new:mark_critical_hit_flag() end
                    imp_new:set_skill_id(imp:get_skill_id())
                    imp_new:set_skill_level(imp:get_skill_level())
                    if imp_new:get_logic_id() == DI_DamagesByValue_T.ID then
                        combat_core.new():get_result_impact(obj, nb, imp_new)
                    end
                    eventenginer:register_impact_event(nb, obj, imp_new, 0, imp:get_skill_id())
                end
            end
        end
    end
end

return std_impact_103
