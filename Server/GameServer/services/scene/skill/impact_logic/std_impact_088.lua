local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local ModifyHpMpRageStrikePointByValue_T = require "scene.skill.impact_logic.std_impact_004"
local eventenginer = require "eventenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_088 = class("std_impact_088", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_088:is_over_timed()
    return true
end

function std_impact_088:is_intervaled()
    return false
end

function std_impact_088:get_trigger_odd_when_damage_target(imp)
    return imp.params["伤害目标时的激发几率"]
end

function std_impact_088:get_trigger_odd_when_critical_hit_target(imp)
    return imp.params["会心一击时的激发几率"]
end

function std_impact_088:get_trigger_odd_when_on_damages(imp)
    return imp.params["受到伤害时的激发几率"]
end

function std_impact_088:get_affect_skill_collection_id(imp)
    return imp.params["影响或生效的技能集合ID"]
end

function std_impact_088:get_refix_damage(imp)
    return imp.params["伤害修正率，填100相当于将伤害放大到2倍"]
end

function std_impact_088:get_sub_impact_give_self_1(imp)
    return imp.params["给自己的子效果1"]
end

function std_impact_088:get_sub_impact_give_self_2(imp)
    return imp.params["给自己的子效果2"]
end

function std_impact_088:get_sub_impact_give_target_1(imp)
    return imp.params["给目标或攻击者的子效果1"]
end

function std_impact_088:get_sub_impact_give_target_2(imp)
    return imp.params["给目标或攻击者的子效果2"]
end

function std_impact_088:get_extra_damage_point(imp)
    return imp.params["无属性附加伤害点数"] or 0
end

function std_impact_088:on_damage_target(imp, obj, target, damages, skill_id)
    -- print("std_impact_088:on_damage_target")
    local collection_id = self:get_affect_skill_collection_id(imp)
    local in_collection = true
    if collection_id ~= define.INVAILD_ID then
        in_collection = skillenginer:is_skill_in_collection(skill_id, collection_id)
    end
    if not in_collection then
        return
    end
	local rate = self:get_refix_damage(imp)
	rate = rate or 0
	if rate > 0 then
		for _,key in ipairs(DAMAGE_TYPE_RATE) do
			damages[key] = damages[j] * (100 + rate) / 100
		end
	end
    local odd = self:get_trigger_odd_when_damage_target(imp)
    local num = math.random(100)
    if num <= odd then
        do
            local value = self:get_sub_impact_give_target_1(imp)
            if value ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(target, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
            end
        end
        do
            local value = self:get_sub_impact_give_target_2(imp)
            if value ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(target, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
            end
        end
        do
            local value = self:get_sub_impact_give_self_1(imp)
            if value ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(obj, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
            end
        end
        do
            local value = self:get_sub_impact_give_self_2(imp)
            if value ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(obj, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
            end
        end
        do
			local damage = self:get_extra_damage_point(imp)
			if damage > 0 then
				if damages and damages.damage_rate then
					local idx = DAMAGE_TYPE_POINT[7]
					damages[idx] = damages[idx] + damage
				end
            -- local damage_hp_point = -1 * self:get_extra_damage_point(imp)
            -- target:health_increment(damage_hp_point, obj, false)
			end
        end
    end
end

-- function std_impact_088:refix_impact(imp, obj_me, need_refix_imp)
    -- if need_refix_imp:get_logic_id() == DI_DamagesByValue_T.ID then
        -- local collection_id = self:get_affect_skill_collection_id(imp)
        -- local in_collection = true
        -- if collection_id ~= define.INVAILD_ID then
            -- in_collection = skillenginer:is_skill_in_collection(need_refix_imp:get_skill_id(), collection_id)
        -- end
        -- if not in_collection then
            -- return
        -- end
        -- local logic = impactenginer:get_logic(need_refix_imp)
        -- local value = self:get_refix_damage(imp)
        -- value = value or 0
        -- logic:refix_skill_power_by_rate(need_refix_imp, value)
    -- end
-- end

return std_impact_088