local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_261 = class("std_talent_261", base)

function std_talent_261:is_specific_skill(skill_id)
    return skill_id == 377
end

function std_talent_261:get_reifx_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_261:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_reifx_value(talent, level)
        local n = math.random(100)
        if n <= odd then
            local percent = 5
            local mp = sender:get_max_mp()
            local recover_mp = math.ceil(mp * percent / 100)
            sender:mana_increment(recover_mp, sender, false)
        end
    end
end

return std_talent_261