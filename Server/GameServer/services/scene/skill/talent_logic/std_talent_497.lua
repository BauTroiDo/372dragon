local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_497 = class("std_talent_497", base)

function std_talent_497:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_497:on_impact_get_combat_result(talent, level, imp, combat_core, attacker, defencer)
    if imp:get_logic_id() == 3 then
        local skill_id = imp:get_skill_id()
        if skill_id == 395 then
            local value = self:get_refix_value(talent, level)
            local add_magic_attack = combat_core:get_additional_attack_magic()
            add_magic_attack = add_magic_attack + value
            combat_core:set_additional_attack_magic(add_magic_attack)
        end
    end
end

return std_talent_497