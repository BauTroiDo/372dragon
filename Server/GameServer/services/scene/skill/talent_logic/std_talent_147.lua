local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_147 = class("std_talent_147", base)
function std_talent_147:is_specific_skill(skill_id)
    return skill_id == 471
end

function std_talent_147:get_refix_power(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_147:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id)  then
        if imp:get_logic_id() == 3 then
            local percent = self:get_refix_power(talent, level)
            local logic = impactenginer:get_logic(imp)
            if logic then
                do
                    local damage = logic:get_damage_phy(imp)
                    damage = math.ceil(damage * ( 100 + percent) / 100)
                    logic:set_damage_phy(imp, damage)
                end
                do
                    local damage = logic:get_damage_magic(imp)
                    damage = math.ceil(damage * ( 100 + percent) / 100)
                    logic:set_damage_magic(imp, damage)
                end
            end
        end
    end
end

return std_talent_147