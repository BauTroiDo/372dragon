local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local impact = require "scene.skill.impact"
local SOT_XiaoYaoTraps_T = require "scene.skill.impact_logic.std_impact_052"
local base = require "scene.skill.base"
local skill_260 = class("skill_260", base)

function skill_260:get_impact_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["纪录陷阱的buffID"]
end

function skill_260:get_default_trap_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["陷阱数据ID"]
end

function skill_260:get_trap_count_up_border(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["同类陷阱数目上限"]
end

function skill_260:get_strengthen_trap_1_impact_need(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱1"] or define.INVAILD_ID
end

function skill_260:get_strengthen_trap_2_impact_need(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱2"] or define.INVAILD_ID
end

function skill_260:get_strengthen_trap_1_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["强化陷阱1"] or define.INVAILD_ID
end

function skill_260:get_strengthen_trap_2_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["强化陷阱2"] or define.INVAILD_ID
end

function skill_260:get_talent_default_trap_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["陷阱数据ID增强"] or define.INVAILD_ID
end

function skill_260:get_talent_strengthen_trap_1_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["强化陷阱1增强"] or define.INVAILD_ID
end

function skill_260:get_talent_strengthen_trap_2_data_index(skill_info)
    local descriptor = skill_info:get_descriptor()
    return descriptor["强化陷阱2增强"] or define.INVAILD_ID
end

function skill_260:have_talent_take_effect(obj_me)
    return obj_me:impact_have_impact_of_specific_impact_id(3874)
end

function skill_260:get_trap_data_index(skill_info, obj_me)
    if self:have_talent_take_effect(obj_me) then
        return self:get_talent_trap_data_index(skill_info, obj_me)
    else
        return self:get_no_talent_trap_data_index(skill_info, obj_me)
    end
end

function skill_260:get_talent_trap_data_index(skill_info, obj_me)
    local collection_1 = self:get_strengthen_trap_1_impact_need(skill_info)
    if obj_me:impact_have_impact_in_specific_collection(collection_1) then
        local data_index = self:get_talent_strengthen_trap_1_data_index(skill_info)
        if data_index ~= define.INVAILD_ID then
            return data_index
        end
    end
    local collection_2 = self:get_strengthen_trap_2_impact_need(skill_info)
    if obj_me:impact_have_impact_in_specific_collection(collection_2) then
        local data_index = self:get_talent_strengthen_trap_2_data_index(skill_info)
        if data_index ~= define.INVAILD_ID then
            return data_index
        end
    end
    return self:get_talent_default_trap_data_index(skill_info)
end

function skill_260:get_no_talent_trap_data_index(skill_info, obj_me)
    local collection_1 = self:get_strengthen_trap_1_impact_need(skill_info)
    if obj_me:impact_have_impact_in_specific_collection(collection_1) then
        local data_index = self:get_strengthen_trap_1_data_index(skill_info)
        if data_index ~= define.INVAILD_ID then
            return data_index
        end
    end
    local collection_2 = self:get_strengthen_trap_2_impact_need(skill_info)
    if obj_me:impact_have_impact_in_specific_collection(collection_2) then
        local data_index = self:get_strengthen_trap_2_data_index(skill_info)
        if data_index ~= define.INVAILD_ID then
            return data_index
        end
    end
    return self:get_default_trap_data_index(skill_info)
end

function skill_260:specific_condition_check(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local logic = SOT_XiaoYaoTraps_T.new()
    local max_trap_count = SOT_XiaoYaoTraps_T.MAX_TRAP_COUNT
    local trap_data_index = self:get_trap_data_index(skill_info, obj_me)
    local trap_count_up_border = self:get_trap_count_up_border(skill_info)
    local special_obj_data = configenginer:get_config("special_obj_data")
    local data = special_obj_data[trap_data_index]
    assert(data, trap_data_index)
    local ntype = data.class
    local imp = obj_me:impact_get_first_impact_of_specific_impact_id(SOT_XiaoYaoTraps_T.IMPACT_ID)
    if imp then
        local all_type_count, this_type_count = logic:get_trap_count_of_specific_type(imp, obj_me, ntype)
        print("all_type_count =", all_type_count, ";max_trap_count =", max_trap_count, ";this_type_count =", this_type_count, ";trap_count_up_border =", trap_count_up_border)
        if all_type_count >= max_trap_count or this_type_count >= trap_count_up_border then
            params:set_errcode(define.OPERATE_RESULT.OR_TOO_MANY_TRAPS)
            return false
        end
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

function skill_260:effect_on_unit_once(obj_me, _, is_critical)
    local skill_info = obj_me:get_skill_info()
	local skill_id = skill_info:get_skill_id()
	if 544 == skill_id then
		skill_id = -1
	end
    local impact_data_index = self:get_impact_data_index(skill_info)
    local trap_data_index = self:get_trap_data_index(skill_info, obj_me)
    assert(impact_data_index > 0, impact_data_index)
    assert(trap_data_index > 0, trap_data_index)
    local trap_obj = obj_me:skill_create_obj_specail(obj_me:get_world_pos(),trap_data_index,skill_id)
    assert(trap_obj, "Can't create Special Obj!")
	-- trap_obj:set_skill_id(skill_id)
    trap_obj:set_power_refix_by_rate(skill_info:get_power_refix_by_rate())
    trap_obj:set_power_refix_by_value(skill_info:get_power_refix_by_value())
    local continuance = trap_obj:get_continuance()
    continuance = continuance + skill_info:get_time_refix_by_rate() * continuance / 100
    continuance = continuance + skill_info:get_time_refix_by_value()
    continuance = math.ceil(continuance)
    trap_obj:set_continuance(continuance)
    local logic = SOT_XiaoYaoTraps_T.new()
    local new_impact = impact.new()
    local imp = obj_me:impact_get_first_impact_of_specific_impact_id(SOT_XiaoYaoTraps_T.IMPACT_ID)
    if imp == nil then
        impactenginer:init_impact_from_data(impact_data_index, new_impact)
        local result = logic:add_new_trap(new_impact, obj_me, trap_obj:get_obj_id())
        assert(result)
        self:register_impact_event(obj_me, obj_me, new_impact, 100, is_critical)
    else
        local result = logic:add_new_trap(imp, obj_me, trap_obj:get_obj_id())
        assert(result)
    end
    self:register_active_obj(trap_obj,  obj_me, 500, skill_id)
    pcall(require("cy_skill_extra").apply, self, obj_me, obj_me, is_critical)  -- skill-logic
    return true
end

return skill_260