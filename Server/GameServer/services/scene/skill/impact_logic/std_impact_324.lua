local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_324 = class("std_impact_324", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_324:is_over_timed()
    return true
end

function std_impact_324:is_intervaled()
    return false
end

function std_impact_324:get_be_damage_up(imp)
    return imp.params["受到伤害+"] or 0
end


function std_impact_324:get_skill_mind_attck_rate_up(imp)
    return imp.params["会心一击率+"] or 0
end

function std_impact_324:on_damages(imp, reciver, damages)
    local up = self:get_be_damage_up(imp)
	if damages and damages.damage_rate then
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] + up
		end
	end
	-- else
		-- damages.hp_damage = 0
		-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
		-- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
			-- damages[i] = math.floor((damages[i] or 0) * (100 + up) / 100)
			-- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
		-- end
	-- end
end

function std_impact_324:refix_critical_rate(imp, critical_rate)
    critical_rate = critical_rate + self:get_skill_mind_attck_rate_up(imp) / 100
    return critical_rate
end

return std_impact_324