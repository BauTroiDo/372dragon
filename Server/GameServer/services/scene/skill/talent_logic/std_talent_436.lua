local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_436 = class("std_talent_436", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_436:is_add_damage_skill(skill_id)
    return skill_id == 282
end

function std_talent_436:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_436:on_damage_target(talent, level, id, sender, _, damages, skill_id)
    if self:is_add_damage_skill(skill_id) then
		if damages and damages.damage_rate then
			local recover_hp_rate = self:get_refix_value(talent, level)
			if recover_hp_rate > 0 then
				local idx = DAMAGE_TYPE_BACK[4]
				table.insert(damages[idx],{rate = recover_hp_rate})
				damages.recover_hp_rate_enable = true
			end
		end
	
        -- local percent = self:get_refix_value(talent, level)
        -- local recover_hp = math.abs(math.ceil(damages.hp_damage * percent / 100))
        -- sender:health_increment(recover_hp, sender, false)
    end
end
return std_talent_436