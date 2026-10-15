local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_069 = class("std_impact_069", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_069:is_over_timed()
    return true
end

function std_impact_069:is_intervaled()
    return false
end

function std_impact_069:get_affect_skill_collection_id(imp)
    return imp.params["影响的技能集合ID(-1代表所有技能)"] or -1
end

function std_impact_069:get_refix_damage_percent(imp)
    return ((imp.params["伤害修正率"] or 0) + 100) / 100
end


function std_impact_069:on_damages(imp, obj, damages)
    -- local refix_damage_percent = self:get_refix_damage_percent(imp)
	if damages and damages.damage_rate then
		local refix_damage_percent = imp.params["伤害修正率"] or 0
		if refix_damage_percent ~= 0 then
			local collection_id = self:get_affect_skill_collection_id(imp)
			local in_collection = true
			if collection_id ~= define.INVAILD_ID then
				in_collection = impactenginer:is_impact_in_collection(imp, collection_id)
			end
			if in_collection then
				if damages and damages.damage_rate then
					for _,key in ipairs(DAMAGE_TYPE_RATE) do
						damages[key] = damages[key] * (100 + refix_damage_percent) / 100
					end
				end
				-- damages.hp_damage = 0
				-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
				-- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
					-- damages[i] = math.floor((damages[i] or 0) * (refix_damage_percent))
					-- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
				-- end
			end
		end
	end
end

return std_impact_069