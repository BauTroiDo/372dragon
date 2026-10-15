local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_181 = class("std_talent_181", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_181:is_specific_skill(skill_id)
    return skill_id == 541
end

function std_talent_181:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_181:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        impactenginer:send_impact_to_unit(reciver, 0, sender, 0, false, 0, skill_id)
    end
end

function std_talent_181:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		if damages and damages.damage_rate then
			local recover_hp_rate = self:get_refix_value(talent, level)
			if recover_hp_rate > 0 then
				local idx = DAMAGE_TYPE_BACK[4]
				table.insert(damages[idx],{rate = recover_hp_rate})
				damages.recover_hp_rate_enable = true
			end
		end
        -- local hp_damage = damages.hp_damage
        -- local rate = self:get_refix_value(talent, level)
        -- local absort_hp = math.ceil(hp_damage * rate / 100)
        -- sender:health_increment(absort_hp, sender, false)
    end
end
return std_talent_181