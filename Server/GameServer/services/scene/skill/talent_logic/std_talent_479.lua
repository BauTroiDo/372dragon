local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_479 = class("std_talent_479", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_479:is_specific_skill(skill_id)
    return skill_id == 365
end

function std_talent_479:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_479:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		if damages and damages.damage_rate then
			local add_dmg_mp_rate = self:get_refix_value(talent, level)
			if add_dmg_mp_rate > 0 then
				local idx = DAMAGE_TYPE_BACK[6]
				table.insert(damages[idx],{rate = add_dmg_mp_rate})
			end
		end
	
	
        -- local percent = self:get_refix_value(talent, level)
        -- local mana_damage = math.abs(math.ceil(damages.hp_damage * percent / 100))
        -- reciver:mana_increment(-1 * mana_damage, sender, false)
    end
end
return std_talent_479