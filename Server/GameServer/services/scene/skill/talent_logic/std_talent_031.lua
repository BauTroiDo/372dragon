local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_031 = class("std_talent_031", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local impact_id = 346
function std_talent_031:is_specific_skill(skill_id)
    return skill_id == 281
end

function std_talent_031:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_031:on_damages(talent, level, damages, obj_me, caster_obj_id)
    local percent = self:get_value(talent, level)
    local sender = obj_me:get_scene():get_obj_by_id(caster_obj_id)
    if sender then
        if sender:impact_have_impact_of_specific_impact_id(impact_id) then
			if damages and damages.damage_rate then
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] - percent
				end
			end
			-- else
				-- damages.hp_damage = 0
				-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
				-- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
					-- damages[i] = math.floor((damages[i] or 0) * (100 - percent) / 100)
					-- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
				-- end
			-- end
        end
    end
end

return std_talent_031