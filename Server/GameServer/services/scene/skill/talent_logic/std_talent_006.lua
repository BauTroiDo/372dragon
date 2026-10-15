local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_006 = class("std_talent_006", base)

function std_talent_006:is_specific_impact(imp)
    return imp:get_impact_id() == 10
end

function std_talent_006:is_specific_skill(skill_id)
    return skill_id == 351
end

function std_talent_006:get_recover_rate(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_006:refix_impact(talent, level, imp, sender)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        if self:is_specific_impact(imp) then
            local odd = 35
            local rate = self:get_recover_rate(talent, level)
            --self:get_odd(talent, level)
            local num = math.random(100)
            if num <= odd then
                local hp_health = math.ceil(sender:get_max_hp() * rate / 100)
                sender:health_increment(hp_health, sender, false, nil)
            end
        end
    end
end

return std_talent_006