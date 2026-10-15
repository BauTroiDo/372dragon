local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_490 = class("std_talent_490", base)
function std_talent_490:is_specific_skill(skill_id)
    return skill_id == 377
end

function std_talent_490:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_490:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            local max_mp = human:get_max_mp()
            local percent = 4
            local mp_recover = math.ceil(max_mp * percent / 100)
            human:mana_increment(mp_recover, human, false)
        end
    end
end

return std_talent_490