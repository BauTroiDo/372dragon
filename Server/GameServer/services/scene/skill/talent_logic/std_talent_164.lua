local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_164 = class("std_talent_164", base)

function std_talent_164:is_specific_impact(data_index)
    return data_index >= 2285 and data_index <= 2296
end

function std_talent_164:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_164:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        if imp:get_logic_id() == 3 then
            local logic = impactenginer:get_logic(imp)
            local direct_damage = logic:get_damage_direct(imp)
            local value = self:get_refix_value(talent, level)
            logic:set_damage_direct(imp, direct_damage + value)
        end
    end
end

return std_talent_164