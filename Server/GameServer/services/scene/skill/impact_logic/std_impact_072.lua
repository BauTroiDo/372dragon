local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_072 = class("std_impact_072", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_072:is_over_timed()
    return true
end

function std_impact_072:is_intervaled()
    return false
end

function std_impact_072:get_refix_damage_percent(imp)
    return ((imp.params["伤害修正率"] or 0) + 100) / 100
end


function std_impact_072:on_damages(imp, _, damages, _, is_critical)
	if damages and damages.damage_rate then
		local refix_damage_percent = imp.params["伤害修正率"]
		if refix_damage_percent and refix_damage_percent > 0 then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] * (100 + refix_damage_percent) / 100
			end
		end
	end
    -- if not is_critical then
        -- return
    -- end
    -- local refix_damage_percent = self:get_refix_damage_percent(imp)
    -- damages.hp_damage = 0
    -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
    -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
        -- damages[i] = math.floor((damages[i] or 0) * (refix_damage_percent))
        -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
    -- end
end

return std_impact_072