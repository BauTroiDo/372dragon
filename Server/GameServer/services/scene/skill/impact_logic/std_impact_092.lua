local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_092 = class("std_impact_092", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
function std_impact_092:is_over_timed()
    return true
end

function std_impact_092:is_intervaled()
    return false
end

function std_impact_092:get_affect_skill_collection_id(imp)
    return imp.params["|影响的技能集合ID(-1代表所有技能)"]
end

function std_impact_092:get_refix_monster_damage_percent(imp)
    return ((imp.params["|伤害修正率(NPC)"] or 0) + 100) / 100
end

function std_impact_092:set_value_of_refix_monster_damage_percent(imp, value)
    imp.params["|伤害修正率(NPC)"] = value
end

function std_impact_092:get_value_of_refix_monster_damage_percent(imp)
    return imp.params["|伤害修正率(NPC)"] or 0
end

function std_impact_092:get_refix_human_damage_percent(imp)
    return ((imp.params["|伤害修正率(HUMAN)"] or 0) + 100) / 100
end

function std_impact_092:set_value_of_refix_human_damage_percent(imp, value)
    imp.params["|伤害修正率(HUMAN)"] = value
end

function std_impact_092:get_value_of_refix_human_damage_percent(imp)
    return imp.params["|伤害修正率(HUMAN)"] or 0
end

function std_impact_092:on_damages(imp, obj, damages, caster_obj_id, is_critical, skill_id, need_refix_imp)
    local collection_id = self:get_affect_skill_collection_id(imp)
    local refix_damage_percent
    if obj:get_obj_type() == "human" then
        -- refix_damage_percent = self:get_refix_human_damage_percent(imp)
		refix_damage_percent = imp.params["|伤害修正率(HUMAN)"] or 0
    else
        -- refix_damage_percent = self:get_refix_monster_damage_percent(imp)
		refix_damage_percent = imp.params["|伤害修正率(NPC)"] or 0
    end
    -- print("std_impact_092:on_damages refix_damage_percent =", refix_damage_percent)
    local in_collection = true
    if need_refix_imp and collection_id ~= define.INVAILD_ID then
        in_collection = impactenginer:is_impact_in_collection(need_refix_imp, collection_id)
    end
    -- print("std_impact_092:on_damages in_collection =", in_collection)
    if in_collection then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] * (100 + refix_damage_percent) / 100
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

return std_impact_092