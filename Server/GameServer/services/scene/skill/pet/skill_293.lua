local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_293 = class("skill_293", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function skill_293:get_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[1] or define.INVAILD_ID
end

function skill_293:get_tired_impact(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["疲劳buff的ID"] or define.INVAILD_ID
end

function skill_293:get_collection_id(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["合集ID"] or define.INVAILD_ID
end

function skill_293:get_reduce_time(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["ReduceTime"] or 0
end

function skill_293:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local skill_id = skill_info:get_skill_id()
    if skill_id >= 3499 and skill_id <= 3504 then
        if obj_me:get_obj_type() == "pet" then
            local damages = {}
            damages.hp_damage = obj_me:get_hp()
            damages[DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = damages.hp_damage
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = 100
			end
			for _,j in ipairs(DAMAGE_TYPE_POINT) do
				damages[j] = 0
			end
			for _,j in ipairs(DAMAGE_TYPE_BACK) do
				damages[j] = {}
			end
            obj_me:on_damages(damages, obj_me:get_obj_id(), false, define.INVAILD_ID)
        end
    end
    local params = obj_me:get_targeting_and_depleting_params()
    local value
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()
    value = self:get_impact(skill_info)
    if value ~= define.INVAILD_ID then
        -- print("skill_293:effect_on_unit_once impact obj_id =", obj_me:get_obj_id(), ";logic_id =", value)
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
    local owner = obj_me:get_owner()
    if owner then
        local collection_id = self:get_collection_id(skill_info)
        if collection_id ~= define.INVAILD_ID then
            local reduce_time = self:get_reduce_time(skill_info)
            owner:impact_reduce_continuance_in_specific_collection(collection_id, reduce_time)
        end
    end
end

return skill_293