local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_263 = class("std_talent_263", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_263:is_specific_skill(skill_id)
    return skill_id == 372
end

function std_talent_263:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_263:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local percent = self:get_refix_value(talent, level)
		if percent > 0 then
			local max_mp = sender:get_attrib("mp_max") or 0
			if max_mp > 0 then
				local recover = math.ceil(max_mp * percent / 100)
				if recover > 0 then
					sender:mana_increment(recover, sender)
				end
			end
		end
    end
end
return std_talent_263