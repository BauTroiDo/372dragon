local class = require "class"
local define = require "define"
local impactenginer  = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_516 = class("std_impact_516", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_516:is_over_timed()
    return true
end

function std_impact_516:is_intervaled()
    return false
end

function std_impact_516:get_impact_damage_percent(imp)
	return imp.params["伤害百分率"] or 0
end

function std_impact_516:set_impact_damage_percent(imp,value)
	imp.params["伤害百分率"] = value
end

function std_impact_516:get_impact_damage_injury_rate(imp)
	return imp.params["受到伤害百分率"] or 0
end

function std_impact_516:set_impact_damage_injury_rate(imp,value)
	imp.params["受到伤害百分率"] = value
end

function std_impact_516:get_affect_skill_collection_id(imp)
    return imp.params["影响或生效的技能集合ID"] or define.INVAILD_ID
end

function std_impact_516:get_affect_skill_id(imp)
    return imp.params["指定生效技能"] or define.INVAILD_ID
end

function std_impact_516:on_damage_target(imp, obj, target, damages,skill_id)
	local need_skill = self:get_affect_skill_id(imp)
	if need_skill ~= -1 then
		if need_skill ~= skill_id then
			return
		end
	end
    -- local in_collection = true
    -- local collection_id = self:get_affect_skill_collection_id(imp)
    -- if collection_id ~= define.INVAILD_ID then
        -- in_collection = skillenginer:is_skill_in_collection(skill_id, collection_id)
    -- end
    -- if not in_collection then
        -- return
    -- end
    local refix_damage_percent = self:get_impact_damage_percent(imp)
	if refix_damage_percent ~= 0 then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + refix_damage_percent
			end
		end
	end
end
function std_impact_516:on_damages(imp, obj, damages, caster_obj_id)
    local refix_damage_percent = self:get_impact_damage_injury_rate(imp)
	if refix_damage_percent ~= 0 then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + refix_damage_percent
			end
		end
	end
end

return std_impact_516