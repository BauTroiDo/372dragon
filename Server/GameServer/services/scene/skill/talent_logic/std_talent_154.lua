local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_154 = class("std_talent_154", base)

function std_talent_154:is_specific_skill(skill_id)
    return skill_id == 469
end

function std_talent_154:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_154:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_skill(imp:get_skill_id()) then
        if imp:get_logic_id() == 5 then
            local logic = impactenginer:get_logic(imp)
            local mp_modify_percent = logic:get_mp_modify_percent(imp)
            local percent = self:get_refix_value(talent, level)
            local mp_max = reciver:get_max_mp()
            local mp_damage = math.ceil(mp_max * mp_modify_percent / 100)
            local hp_damage = math.ceil(mp_damage * percent / 100)
            reciver:health_increment(hp_damage, sender, false)
        end
    end
end

return std_talent_154