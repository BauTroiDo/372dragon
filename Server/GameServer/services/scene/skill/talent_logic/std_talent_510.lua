local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_510 = class("std_talent_510", base)
function std_talent_510:is_specific_skill(skill_id)
    return skill_id == 426
end

function std_talent_510:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_510:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        if reciver:get_obj_type() == "human" then
            if sender:is_teammate(reciver) then
                local odd = self:get_refix_value(talent, level)
                local n = math.random(1, 100)
                if n <= odd then
                    reciver:impact_cancel_impact_in_specific_collection(281)
                    reciver:impact_cancel_impact_in_specific_collection(43)
                end
            end
        end
    end
end

return std_talent_510