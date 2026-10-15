local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_283 = class("std_talent_283", base)
function std_talent_283:is_specific_impact(impact_id)
    return impact_id == 131
end

function std_talent_283:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_283:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 4 then
            local scene = sender:get_scene()
            local scene_type = scene:get_type()
            if scene_type == 1 or scene_type == 4 then
                impactenginer:send_impact_to_unit(reciver, 1447, sender, 0, false)
            end
        end
    end
end

return std_talent_283