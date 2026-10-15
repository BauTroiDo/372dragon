local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_014 = class("std_talent_014", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skills = {
    [342] = { get = "get_damage_posion", set = "set_damage_posion" },
    [365] = { get = "get_damage_posion", set = "set_damage_posion" },
    [282] = { get = "get_damage_light", set = "set_damage_light" },
    [283] = { get = "get_damage_light", set = "set_damage_light" },
    [535] = { get = "get_damage_fire", set = "set_damage_fire" },
}
function std_talent_014:is_specific_skill(skill_id)
    return skills[skill_id] ~= nil
end

function std_talent_014:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_014:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        if imp:get_logic_id() == 3 then  -- std_impact_003 的 logic_id
            local logic = impactenginer:get_logic(imp)
            if logic then
                local value = self:get_value(talent, level)
                local config = skills[skill_id]
                local getter = logic[config.get]
                local setter = logic[config.set]
                value = value + getter(logic, imp)
                setter(logic, imp, value)
            end
        end
    end
end


return std_talent_014