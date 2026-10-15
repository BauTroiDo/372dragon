local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_588 = class("std_talent_588", base)
function std_talent_588:is_specific_skill(skill_id)
    return skill_id == 535
end

function std_talent_588:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_588:on_critical_hit_target(talent_config, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local skill_info = sender:get_skill_info()
        if skill_info then
            local value = self:get_refix_p(talent_config, level)
            local target = skill_info:get_give_target_impact()
            if target then
                local p = target.p or 0
                skill_info:set_give_target_impact_p(p + value)
            end
        end
    end
end

return std_talent_588