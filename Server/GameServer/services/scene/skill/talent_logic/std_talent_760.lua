local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_760 = class("std_talent_760", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT

function std_talent_760:is_specific_skill(skill_id)
    return skill_id == 395
end

function std_talent_760:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_760:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local params = sender:get_targeting_and_depleting_params()
		if params:get_activated_skill() == skill_id then
			if not params:get_talent_id(756) then
				params:set_talent_id(756)
				local hit_count = params:get_target_count()
				if hit_count > 5 then
					hit_count = hit_count - 5
					local value = self:get_refix_value(talent, level)
					if value > 0 then
						hit_count = hit_count * value + 5
					end
				else
					hit_count = 5
				end
				local cool_downs = sender:get_cool_downs()
				local cd_value
				for id,cd in pairs(cool_downs) do
					cd_value = math.ceil(cd - cd * hit_count / 100)
					sender:set_cool_down(id, cd_value)
				end
			end
		end
	end
end

return std_talent_760