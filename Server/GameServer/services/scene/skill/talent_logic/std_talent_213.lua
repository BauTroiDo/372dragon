local class = require "class"
local define = require "define"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_213 = class("std_talent_213", base)
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_213:get_skill_config(skill_id)
    local config = self.skills[skill_id]
    return config
end

function std_talent_213:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_213:on_damages(talent, level, damages, obj_me, caster_obj_id, is_critical)
    local p = self:get_refix_p(talent, level)
    local n = math.random(100)
    if n < p then
		if damages and damages.damage_rate then
			local idx = DAMAGE_TYPE_BACK[4]
			table.insert(damages[idx],{rate = p})
			damages.recover_hp_rate_enable = true
		end
    end
end

return std_talent_213