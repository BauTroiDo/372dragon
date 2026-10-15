local define = require "define"
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_467 = class("std_talent_467", base)

function std_talent_467:is_specific_skill(skill_id)
    return skill_id == 347
end

function std_talent_467:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local impact = 45930
        if impact ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
        end
    end
end

function std_talent_467:refix_impact(talent, level, imp, sender, reciver)
    if imp:get_impact_id() == 5482 then
        local logic = impactenginer:get_logic(imp)
        if logic and sender then
            local params = talent.params[level]
            local segment = sender:get_strike_point() // define.STRIKE_POINT_SEGMENT_SIZE
            segment = math.min(math.max(segment, 1), #params)
            local refix_value = -(params[segment] or 0)
            logic:set_rate_of_refix_attrib_def_physics(imp, refix_value)
        end
    end
end

return std_talent_467