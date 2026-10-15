local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_485 = class("std_talent_485", base)
function std_talent_485:is_specific_impact(impact_id)
    return impact_id == 507
end

function std_talent_485:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_485:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local value = self:get_refix_value(talent, level)
        local mp = reciver:get_max_mp()
        local recover_mp = math.ceil(mp * value / 100)
        reciver:mana_increment(recover_mp, sender, false)
    end
end

return std_talent_485