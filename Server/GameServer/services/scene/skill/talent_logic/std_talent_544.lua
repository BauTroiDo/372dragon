local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_544 = class("std_talent_544", base)
function std_talent_544:is_specific_skill(skill_id)
    return skill_id == 475
end

function std_talent_544:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_544:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    if self:is_specific_skill(skill_id) then
        local skill_info = human:get_skill_info()
        if skill_info then
            local value = self:get_refix_value(talent, level)
            local p = skill_info:get_give_target_impact().p
            skill_info:set_give_target_impact_p(p + value)
        end
    end
end

return std_talent_544