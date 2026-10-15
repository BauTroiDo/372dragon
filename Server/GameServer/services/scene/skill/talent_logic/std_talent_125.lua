local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_125 = class("std_talent_125", base)
function std_talent_125:is_specific_impact(impact_id)
    return impact_id == 152
end

function std_talent_125:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_125:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local new_imp = impact.new()
        new_imp:clean_up()
        impactenginer:init_impact_from_data(0, new_imp)
        if new_imp:get_logic_id() == DI_DamagesByValue_T.ID then
            local co = combat_core.new()
            co:get_result_impact(sender, reciver, new_imp)
            local value = self:get_refix_value(talent, level)
            local logic = impactenginer:get_logic(new_imp)
            logic:set_damage_posion(new_imp, value)
        end
        eventenginer:register_impact_event(reciver, sender, new_imp, 0, define.INVAILD_ID)
    end
end

return std_talent_125