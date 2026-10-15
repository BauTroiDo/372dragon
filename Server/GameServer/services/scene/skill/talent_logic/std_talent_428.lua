local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_428 = class("std_talent_428", base)
function std_talent_428:is_specific_skill(skill_id)
    return skillenginer:is_skill_in_collection(skill_id, 56)
end

function std_talent_428:get_trigger_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_428:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    local imp = obj_tar:impact_get_first_impact_of_specific_impact_id(3831)
    if imp then
        if self:is_specific_skill(skill_id) then
            local percent = self:get_trigger_percent(talent, level)
            local n = math.random(100)
            if n <= percent then
                local logic = impactenginer:get_logic(imp)
                if logic then
                    logic:set_take_effect_count(imp, 0)
                end
            end
        end
    end
end

return std_talent_428