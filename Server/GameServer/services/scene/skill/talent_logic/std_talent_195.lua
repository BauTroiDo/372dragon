local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_191 = class("std_talent_191", base)

function std_talent_191:is_specific_skill(skill_id)
    return skill_id == 545
end

function std_talent_191:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_191:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_refix_value(talent, level)
        local num = math.random(100)
        if num <= odd then
            sender:rage_increment(20, sender)
        end
    end
end

return std_talent_191