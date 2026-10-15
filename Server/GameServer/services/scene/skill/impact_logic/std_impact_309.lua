local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impact = require "scene.skill.impact"
local SOT_XiaoYaoTraps_T = require "scene.skill.impact_logic.std_impact_052"
local std_impact_309 = class("std_impact_309", base)

function std_impact_309:is_over_timed()
    return false
end

function std_impact_309:is_intervaled()
    return false
end

function std_impact_309:get_refix_speed(imp, args)
    local value = imp.params["移动速度修正%（0为无效）"] or 0
    args.rate = (args.rate or 0) + value
end

function std_impact_309:get_value_of_refix_speed(imp)
    local value = imp.params["移动速度修正%（0为无效）"] or 0
    return value
end

function std_impact_309:set_value_of_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_309:get_impact_data_index(imp)
    local descriptor = imp.params
    return descriptor["纪录陷阱的buffID"]
end

function std_impact_309:get_trap_count_up_border(imp)
    local descriptor = imp.params
    return descriptor["同类陷阱数目上限"]
end

function std_impact_309:get_strengthen_trap_1_impact_need(imp)
    return imp.params["个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱1"] or define.INVAILD_ID
end

function std_impact_309:get_strengthen_trap_2_impact_need(imp)
    return imp.params["个体拥有这些buff（这个填个buff集合的ID）时使用强化陷阱2"] or define.INVAILD_ID
end

function std_impact_309:get_strengthen_trap_1_data_index(imp)
    return imp.params["强化陷阱1"] or define.INVAILD_ID
end

function std_impact_309:get_strengthen_trap_2_data_index(imp)
    return imp.params["强化陷阱2"] or define.INVAILD_ID
end

function std_impact_309:get_talent_default_trap_data_index(imp)
    return imp.params["陷阱数据ID增强"] or define.INVAILD_ID
end

function std_impact_309:get_talent_strengthen_trap_1_data_index(imp)
    return imp.params["强化陷阱1增强"] or define.INVAILD_ID
end

function std_impact_309:get_talent_strengthen_trap_2_data_index(imp)
    return imp.params["强化陷阱2增强"] or define.INVAILD_ID
end

function std_impact_309:have_talent_take_effect(obj_me)
    return obj_me:impact_have_impact_of_specific_impact_id(3874)
end

function std_impact_309:get_trap_data_index(skill_info, obj_me)
    if self:have_talent_take_effect(obj_me) then
        return self:get_talent_trap_data_index(skill_info, obj_me)
    else
        return self:get_no_talent_trap_data_index(skill_info, obj_me)
    end
end

function std_impact_309:get_talent_trap_data_index(skill_info, obj_me)
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

function std_impact_309:get_no_talent_trap_data_index(imp, obj_me)
    local collection_1 = self:get_strengthen_trap_1_impact_need(imp)
    if obj_me:impact_have_impact_in_specific_collection(collection_1) then
        local data_index = self:get_strengthen_trap_1_data_index(imp)
        if data_index ~= define.INVAILD_ID then
            return data_index
        end
    end
    local collection_2 = self:get_strengthen_trap_2_impact_need(imp)
    if obj_me:impact_have_impact_in_specific_collection(collection_2) then
        local data_index = self:get_strengthen_trap_2_data_index(imp)
        if data_index ~= define.INVAILD_ID then
            return data_index
        end
    end
    return self:get_default_trap_data_index(imp)
end

function std_impact_309:get_default_trap_data_index(imp)
    return imp.params["陷阱数据ID"] or define.INVAILD_ID
end
-- local skynet = require "skynet"
function std_impact_309:condition_check(obj_me, imp)
    local logic = SOT_XiaoYaoTraps_T.new()
    local max_trap_count = SOT_XiaoYaoTraps_T.MAX_TRAP_COUNT
    local trap_data_index = self:get_trap_data_index(imp, obj_me)
    local trap_count_up_border = self:get_trap_count_up_border(imp)
    local special_obj_data = configenginer:get_config("special_obj_data")
    local data = special_obj_data[trap_data_index]
    if data then
        local ntype = data.class
        local trap_imp = obj_me:impact_get_first_impact_of_specific_impact_id(SOT_XiaoYaoTraps_T.IMPACT_ID)
        if trap_imp then
            local all_type_count, this_type_count = logic:get_trap_count_of_specific_type(trap_imp, obj_me, ntype)
            if all_type_count >= max_trap_count or this_type_count >= trap_count_up_border then
                return false
            end
        end
    end
    return true
end

function std_impact_309:on_active(imp, obj_me, is_critical)
    if not self:condition_check(obj_me, imp) then
        return
    end
    local impact_data_index = self:get_impact_data_index(imp)
    if impact_data_index then
        local trap_data_index = self:get_trap_data_index(imp, obj_me)
        if trap_data_index > 0 then
			local skill_id = imp:get_skill_id()
			-- skynet.logi("skill_id = ",skill_id)
            local trap_obj = obj_me:skill_create_obj_specail(obj_me:get_world_pos(), trap_data_index,skill_id)
            assert(trap_obj, "Can't create Special Obj!")
            local continuance = trap_obj:get_continuance()
            continuance = math.ceil(continuance)
            trap_obj:set_continuance(continuance)
            local logic = SOT_XiaoYaoTraps_T.new()
            local new_impact = impact.new()
            local trap_imp = obj_me:impact_get_first_impact_of_specific_impact_id(SOT_XiaoYaoTraps_T.IMPACT_ID)
            if not trap_imp then
                impactenginer:init_impact_from_data(impact_data_index, new_impact)
                local result = logic:add_new_trap(new_impact, obj_me, trap_obj:get_obj_id())
                assert(result)
                eventenginer:register_impact_event(obj_me, obj_me, new_impact, 100, skill_id)
            else
                local result = logic:add_new_trap(trap_imp, obj_me, trap_obj:get_obj_id())
                assert(result)
            end
            self:register_active_obj(trap_obj,  obj_me, 500, skill_id)
        end
    end
end

return std_impact_309