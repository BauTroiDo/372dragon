local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_384 = class("std_talent_384", base)
function std_talent_384:is_specific_impact(data_index)
    return data_index >= 21453 and data_index <= 21468
end

function std_talent_384:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_384:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 5 then
            local logic = impactenginer:get_logic(imp)
            local value = logic:get_hp_modify_percent(imp)
            local percent = self:get_refix_value(talent, level)
            value = math.ceil(value * (100 + percent) / 100)
            logic:set_hp_modify_percent(imp, value)
        end
    end
end

return std_talent_384