local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_149 = class("std_talent_149", base)
function std_talent_149:is_specific_impact(impact_id)
    return impact_id == 297
end

function std_talent_149:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_149:refix_impact(talent, level, imp)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 12 then
            local percent = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(imp)
            if logic then
                do
                    local rate = logic:get_value_of_refix_attrib_att_physics(imp)
                    rate = math.ceil(rate * (100 + percent) / 100)
                    logic:set_value_of_refix_attrib_att_physics(imp, rate)
                end
                do
                    local rate = logic:get_value_of_refix_attrib_def_physics(imp)
                    rate = math.ceil(rate * (100 + percent) / 100)
                    logic:set_value_of_refix_attrib_def_physics(imp, rate)
                end
                do
                    local rate = logic:get_value_of_refix_attrib_att_magic(imp)
                    rate = math.ceil(rate * (100 + percent) / 100)
                    logic:set_value_of_refix_attrib_att_magic(imp, rate)
                end
                do
                    local rate = logic:get_value_of_refix_attrib_def_magic(imp)
                    rate = math.ceil(rate * (100 + percent) / 100)
                    logic:set_value_of_refix_attrib_def_magic(imp, rate)
                end
            end
        end
    end
end

return std_talent_149