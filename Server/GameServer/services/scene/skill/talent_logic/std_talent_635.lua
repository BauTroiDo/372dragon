local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_635 = class("std_talent_635", base)
function std_talent_635:is_specific_skill(skill_id)
    return skill_id == 797
end

function std_talent_635:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_635:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_skill(imp:get_skill_id()) then
        if imp:get_logic_id() == 3 then
            local value = self:get_refix_value(talent, level)
			imp:add_point_params("damage_point",value)
            -- local logic = impactenginer:get_logic(imp)
            -- local cold_damage = logic:get_attack_direct(imp)
            -- local value = self:get_refix_value(talent, level)
            -- logic:set_attack_direct(imp, cold_damage + value)
        end
    end
end

return std_talent_635