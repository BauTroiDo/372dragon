local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_336 = class("std_impact_336", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE


function std_impact_336:is_over_timed()
    return true
end

function std_impact_336:is_intervaled()
    return false
end

function std_impact_336:get_skill_damage_reduce_rate(imp)
    return imp.params["减少对珍兽伤害"] or 0
end

function std_impact_336:on_damage_target(imp, sender, reciver, damages, skill_id)
    if reciver:get_obj_type() == "pet" then
        local reduce = self:get_skill_damage_reduce_rate(imp)
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + reduce
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * (100 - reduce) / 100)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

return std_impact_336