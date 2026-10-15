local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_205 = class("std_talent_205", base)

function std_talent_205:is_specific_skill(skill_id)
    return skill_id == 281
end

function std_talent_205:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_205:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local percent = self:get_refix_percent(talent, level)
        local n = math.random(100)
        if n < percent then
            local recover_hp = math.ceil(sender:get_max_hp() * 1 / 100)
            sender:health_increment(recover_hp, sender, false)
        end
    end
end

return std_talent_205