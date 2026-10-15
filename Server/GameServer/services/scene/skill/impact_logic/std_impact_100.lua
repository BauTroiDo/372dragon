local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_100 = class("std_impact_100", base)

function std_impact_100:is_over_timed()
    return true
end

function std_impact_100:is_intervaled()
    return false
end

function std_impact_100:get_odds(imp)
    return imp.params["生效几率"]
end

function std_impact_100:get_effect_id(imp)
    return imp.params["生效效果"]
end

function std_impact_100:get_effect_range(imp)
    return imp.params["生效距离"]
end

function std_impact_100:on_active(imp, obj)
    local value = self:get_effect_id(imp)
    local position = obj:get_world_pos()
    local radious = self:get_effect_range(imp)
    local operate = {obj = obj, x = position.x, y = position.y, radious = radious, target_logic_by_stand = 1}
    local nearbys = obj:get_scene():scan(operate)
    for _, nb in ipairs(nearbys) do
        -- 调试输出已屏蔽
        -- print("nb.classname =", nb.classname)
        if nb:is_character_obj() then
           if obj:is_enemy(nb) and nb:is_alive() then
                impactenginer:send_impact_to_unit(nb, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
           end
        end
    end
end

return std_impact_100