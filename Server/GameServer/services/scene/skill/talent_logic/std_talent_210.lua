local class = require "class"
local define = require "define"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_210 = class("std_talent_210", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_210:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_210:on_damages(talent, level, damages, obj_me, caster_obj_id, is_critical)
    local percent = self:get_refix_percent(talent, level)
	if damages and damages.damage_rate then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] - percent
			end
		end
	end
	-- else
		-- damages.hp_damage = 0
		-- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
			-- if damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY == i or damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC == i then
				-- damages[i] = math.floor((damages[i] or 0) * (100 - percent) / 100)
			-- end
			-- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
		-- end
	-- end
end

return std_talent_210