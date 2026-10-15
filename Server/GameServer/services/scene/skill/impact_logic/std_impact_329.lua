local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_329 = class("std_impact_329", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_329:is_over_timed()
    return true
end

function std_impact_329:is_intervaled()
    return false
end

function std_impact_329:get_accuracy_rate_up(imp)
    return imp.params["命中率+"] or 0
end

function std_impact_329:get_specific_skill_damage_up(imp)
    return imp.params["指定技能伤害提升率"] or 0
end

function std_impact_329:get_specific_skill_id(imp)
    return imp.params["提升伤害技能ID"] or define.INVAILD_ID
end

function std_impact_329:on_damage_target(imp, obj, target, damages, skill_id)
    if self:get_specific_skill_id(imp) == skill_id then
        local rate_up = self:get_specific_skill_damage_up(imp)
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + rate_up
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * (100 + rate_up) / 100)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

function std_impact_329:refix_skill(imp, obj, skill_info)
    local rate_up = self:get_accuracy_rate_up(imp)
    local accuracy_up_rate = skill_info:get_accuracy_rate_up()
    skill_info:set_accuracy_rate_up(accuracy_up_rate + rate_up)
end

return std_impact_329