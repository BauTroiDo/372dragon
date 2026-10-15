local class = require "class"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_313 = class("std_impact_313", base)

function std_impact_313:is_over_timed()
    return true
end

function std_impact_313:is_intervaled()
    return false
end

function std_impact_313:get_remaind_dist(imp)
    return imp.params["剩余移动距离"]
end

function std_impact_313:set_remaind_dist(imp, dist)
    imp.params["剩余移动距离"] = dist
end

function std_impact_313:get_give_impact_id(imp)
    return imp.params["获得效果"]
end

function std_impact_313:on_logic_move(imp, human, dist)
    local remaind_dist = self:get_remaind_dist(imp)
    remaind_dist = remaind_dist - dist
    if remaind_dist < 0 then
        local data_index = self:get_give_impact_id(imp)
        impactenginer:send_impact_to_unit(human, data_index, human, 0, false, 0)
        human:on_impact_fade_out(imp)
        human:remove_impact(imp)
    else
        self:set_remaind_dist(imp, remaind_dist)
    end
end

return std_impact_313