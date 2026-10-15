local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_509 = class("std_talent_509", base)
function std_talent_509:is_specific_skill(skill_id)
    return skill_id == 406
end

function std_talent_509:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_509:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        skill_info:set_charge_time(3 * 1000)
        skill_info:set_target_count(12)
        local data_indexs = { 45964, 45965, 45966, 45967, 45968}
        local data_index = data_indexs[level] or define.INVAILD_ID
        if data_index ~= define.INVAILD_ID then
            skill_info:set_activate_once_impact_by_index(1, data_index)
        end
    end
end

function std_talent_509:is_specific_impact(impact_id)
    return impact_id == 5496
end

function std_talent_509:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value = self:get_refix_value(talent, level)
        imp:set_interval(value * 1000)
    end
end


return std_talent_509