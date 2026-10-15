local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_748 = class("std_talent_748", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_748:is_specific_skill(skill_id)
    return skill_id == 371
end

function std_talent_748:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_748:on_critical_hit_target(talent, level, sender, reciver, skill_id)
	if self:is_specific_skill(skill_id) then
		local value = self:get_refix_value(talent, level)
		if math.random(100) <= value then
			local max_mp = sender:get_max_mp()
			local mp_modify = max_mp * 2 / 100
			sender:mana_increment(mp_modify, sender)
		end
	end
end


return std_talent_748