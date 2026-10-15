local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_830 = class("std_talent_830", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

-- function std_talent_830:is_specific_skill(skill_id)
    -- return skill_id == 319
-- end

function std_talent_830:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_830:on_skill_miss_target(talent, level, obj_me, reciver, skill_id)
	local value = self:get_refix_value(talent, level)
	if value > 0 then
		local imp = obj_me:impact_get_first_impact_of_specific_data_index_2(2420,2431)
		if imp then
			local logic = impactenginer:get_logic(imp)
			if logic then
				logic:set_next_attack_hit_rate_increase(imp,value / 100)
			end
		end
	end
end


return std_talent_830