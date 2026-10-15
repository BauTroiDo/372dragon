local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_706 = class("std_talent_706", base)
-- local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
-- local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

-- function std_talent_706:is_specific_skill(skill_id)
    -- return skill_id == 319
-- end

function std_talent_706:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end
function std_talent_706:on_skill_miss_target(talent, level, obj_me, reciver, skill_id)
	local value = self:get_refix_value(talent, level)
	if value > 0 then
		local imp = obj_me:impact_get_mutex_id(121)
		if imp then
			local logic = impactenginer:get_logic(imp)
			if logic then
				value = value + logic:get_value_of_refix_attrib_hit(imp)
				logic:set_value_of_refix_attrib_hit(imp,value)
			end
		end
	end
end


return std_talent_706