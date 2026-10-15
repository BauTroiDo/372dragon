local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_501 = class("std_talent_501", base)
function std_talent_501:is_specific_impact(impact_id)
    return impact_id == 145
end

function std_talent_501:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_501:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            local max_hp = sender:get_max_hp()
            local shield_up_hp = math.ceil(max_hp * value / 100)
            local shield_hp = logic:get_shield_hp(imp)
            shield_hp = shield_hp + shield_up_hp
            logic:set_shield_hp(imp, shield_hp)
        end
    end
end

return std_talent_501