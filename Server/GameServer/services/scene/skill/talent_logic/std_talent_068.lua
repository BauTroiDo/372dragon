local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_068 = class("std_talent_068", base)
std_talent_068.skills = {
    [281] = { geter = "get_attack_phy", seter = "set_attack_phy" },
    [311] = { geter = "get_attack_phy", seter = "set_attack_phy" },
    [341] = { geter = "get_attack_phy", seter = "set_attack_phy" },
    [371] = { geter = "get_attack_magic", seter = "set_attack_magic" },
    [401] = { geter = "get_attack_magic", seter = "set_attack_magic" },
    [431] = { geter = "get_attack_magic", seter = "set_attack_magic" },
    [491] = { geter = "get_attack_phy", seter = "set_attack_phy" },
    [521] = { geter = "get_attack_magic", seter = "set_attack_magic" },
    [760] = { geter = "get_attack_magic", seter = "set_attack_magic"},
    [788] = { geter = "get_attack_magic", seter = "set_attack_magic" },
}

function std_talent_068:get_skill_config(skill_id)
    local config = self.skills[skill_id]
    return config
end

function std_talent_068:get_refix_power(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_068:on_impact_get_combat_result(talent, level, imp)
    if imp:get_logic_id() == 3 then
        local skill_id = imp:get_skill_id()
        local config = self:get_skill_config(skill_id)
        if config  then
            local percent = self:get_refix_power(talent, level)
            local logic = impactenginer:get_logic(imp)
            if logic then
                local damage = logic[config.geter](logic, imp)
                damage = math.ceil(damage * ( 100 + percent) / 100)
                logic[config.seter](logic, imp, damage)
            end
        end
    end
end

return std_talent_068