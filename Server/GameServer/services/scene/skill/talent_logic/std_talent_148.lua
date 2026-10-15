local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_148 = class("std_talent_148", base)
function std_talent_148:is_specific_skill(skill_id)
    return skill_id == 471
end

function std_talent_148:get_refix_power(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_148:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id)  then
        if imp:get_logic_id() == 11 then
            local percent = self:get_refix_power(talent, level)
            local logic = impactenginer:get_logic(imp)
            if logic then
                do
                    local att = logic:get_value_of_refix_attrib_att_physics(imp)
                    att = math.ceil(att * ( 100 + percent) / 100)
                    logic:set_value_of_refix_attrib_att_physics(imp, att)
                end
                do
                    local att = logic:get_value_of_refix_attrib_att_magic(imp)
                    att = math.ceil(att * ( 100 + percent) / 100)
                    logic:set_value_of_refix_attrib_att_magic(imp, att)
                end
            end
        end
    end
end

return std_talent_148