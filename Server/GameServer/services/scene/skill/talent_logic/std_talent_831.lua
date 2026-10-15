local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_831 = class("std_talent_831", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_831:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_831:on_skill_miss_target(talent, level, sender, reciver, skill_id)
	if skill_id == 493 then
		if math.random(100) <= self:get_refix_value(talent, level) then
			local cool_down_id = skillenginer:get_skill_template(493,"cool_down_id")
			if cool_down_id then
				local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
				sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
			end
		end
	end
end


return std_talent_831