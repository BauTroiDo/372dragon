local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_576 = class("std_talent_576", base)
function std_talent_576:is_specific_skill(skill_id)
    return skill_id == 535
end

function std_talent_576:get_reifx_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_576:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local skill_info = sender:get_skill_info()
        local value = self:get_refix_value(talent, level)
        local p = skill_info:get_give_self_impact().p
        skill_info:set_give_self_impact_p(p + value)
    end
end

return std_talent_576