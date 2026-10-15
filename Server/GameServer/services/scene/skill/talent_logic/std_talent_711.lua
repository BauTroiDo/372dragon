local class = require "class"
local define = require "define"
local base = require "scene.skill.talent_logic.base"
local std_talent_711 = class("std_talent_711", base)

function std_talent_711:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_711:refix_skill_info(talent, level, skill_info, human)
    if skill_info.id == 313 and human:impact_have_impact_of_specific_impact_id(581) then
        local value = self:get_refix_value(talent, level)
        if math.random(100) <= value then
            skill_info._711_reset = true
        end
    end
end

function std_talent_711:refix_skill_cool_down_time(talent, level, talent_id, skill_info, cool_down_time)
    if skill_info and skill_info._711_reset then
        skill_info._711_reset = nil
        cool_down_time = 0
    end
    return cool_down_time
end

return std_talent_711