local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_691 = class("std_talent_691", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT


function std_talent_691:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_691:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
	local value = self:get_refix_value(talent, level)
	if value and value > 0 then
		reciver:impact_set_first_impact_of_specific_impact_id(3831,"reduce_damage",value)
	end
end

return std_talent_691