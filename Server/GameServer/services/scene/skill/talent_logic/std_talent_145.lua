local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local std_talent_145 = class("std_talent_145", base)
function std_talent_145:is_specific_skill(skill_id)
    return skill_id == 461
end

function std_talent_145:get_refix_power(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_145:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id)  then
		if imp:get_logic_id() == DI_DamagesByValue_T.ID then
			local percent = self:get_refix_power(talent, level)
			local logic = impactenginer:get_logic(imp)
			if logic then
				do
					local damage = logic:get_damage_phy(imp)
					damage = math.ceil(damage * ( 100 + percent) / 100)
					logic:set_damage_phy(imp, damage)
				end
				do
					local damage = logic:get_damage_magic(imp)
					damage = math.ceil(damage * ( 100 + percent) / 100)
					logic:set_damage_magic(imp, damage)
				end
			end
        end
    end
end

return std_talent_145