local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_067 = class("std_talent_067", base)
function std_talent_067:is_plastron_skill(skill_id)
    return skill_id == 383
end

function std_talent_067:is_specific_impact(data_index)
    return data_index >= 1246 and data_index <= 1257
end

function std_talent_067:get_cost_percent(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_067:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_plastron_skill(skill_id) then
        local rate = self:get_cost_percent(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:set_cost_percent(imp, rate)
        end
    end
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = logic:get_mp_modify(imp)
            value = value * 2
            logic:set_mp_modify(imp, value)
        end
    end
end

return std_talent_067