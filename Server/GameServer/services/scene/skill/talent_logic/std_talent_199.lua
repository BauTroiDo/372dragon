local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_199 = class("std_talent_199", base)
std_talent_199.skills = {
    [281] = { geter = "get_defence_physics", seter = "set_additional_defence_physics" },
    [311] = { geter = "get_defence_physics", seter = "set_additional_defence_physics" },
    [341] = { geter = "get_defence_physics", seter = "set_additional_defence_physics" },
    [371] = { geter = "get_defence_magic", seter = "set_additional_defence_magic" },
    [401] = { geter = "get_defence_magic", seter = "set_additional_defence_magic" },
    [431] = { geter = "get_defence_magic", seter = "set_additional_defence_magic" },
    [491] = { geter = "get_defence_physics", seter = "set_additional_defence_physics" },
    [521] = { geter = "get_defence_magic", seter = "set_additional_defence_magic" },
    [760] = { geter = "get_defence_magic", seter = "set_additional_defence_magic"},
    [788] = { geter = "get_defence_magic", seter = "set_additional_defence_magic"},
}

function std_talent_199:get_skill_config(skill_id)
    local config = self.skills[skill_id]
    return config
end

function std_talent_199:get_refix_pro(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_199:get_refix_power(talent, level)
    local params = talent.params[level]
    return params[2] or 0
end

function std_talent_199:on_impact_get_combat_result(talent, level, imp, combat_core, attacker, defencer)
    if imp:get_logic_id() == 3 then
        local pro = self:get_refix_pro(talent, level)
        local n = math.random(100)
        if n < pro then
            local skill_id = imp:get_skill_id()
            local config = self:get_skill_config(skill_id)
            if config  then
                local percent = self:get_refix_power(talent, level)
                local defence = defencer[config.geter](defencer)
                defence = math.floor(defence * (percent) / 100)
                combat_core[config.seter](combat_core, -1 * defence)
            end
        end
    end
end

return std_talent_199