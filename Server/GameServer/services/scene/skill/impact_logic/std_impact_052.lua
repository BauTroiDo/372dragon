local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_052 = class("std_impact_052", base)
std_impact_052.IMPACT_ID = 186
std_impact_052.MAX_TRAP_COUNT = 8
std_impact_052.IDX_TRAP_START = 1
std_impact_052.IDX_TRAP_END = std_impact_052.IDX_TRAP_START + std_impact_052.MAX_TRAP_COUNT

function std_impact_052:is_over_timed()
    return true
end

function std_impact_052:is_intervaled()
    return false
end

function std_impact_052:get_trap_by_index(imp, idx)
    if idx >= std_impact_052.IDX_TRAP_START and idx <= std_impact_052.IDX_TRAP_END then
        return imp:get_param_by_index(idx)
    end
end

function std_impact_052:set_trap_by_index(imp, idx, obj_id)
    if idx >= std_impact_052.IDX_TRAP_START and idx <= std_impact_052.IDX_TRAP_END then
        return imp:set_param_by_index(idx, obj_id)
    end
end

function std_impact_052:add_new_trap(imp, obj_me, id)
    local find = false
    for i = std_impact_052.IDX_TRAP_START, std_impact_052.IDX_TRAP_END do
        local trap_obj_id = self:get_trap_by_index(imp, i)
        local obj_trap = obj_me:get_scene():get_obj_by_id(trap_obj_id)
        if obj_trap then
            if not obj_trap:get_obj_type() == "special" then
                find = true
            end
        else
            find = true
        end
        if find then
            self:set_trap_by_index(imp, i, id)
            return true
        end
    end
    return false
end

function std_impact_052:get_trap_count_of_specific_type(imp, obj_me, type)
    local all_type_count= 0
    local this_type_count = 0
    for i = std_impact_052.IDX_TRAP_START, std_impact_052.IDX_TRAP_END do
        local trap_obj_id = self:get_trap_by_index(imp, i)
        local trap_obj = obj_me:get_scene():get_obj_by_id(trap_obj_id)
        if trap_obj then
            if trap_obj:get_obj_type() == "special" then
                if not trap_obj:is_fade_out() then
                    local data = trap_obj:get_data_record()
                    if data then
                        all_type_count = all_type_count + 1
                        -- 调试输出已屏蔽
                        -- print("data.class =", data.class, ";type =", type)
                        if data.class == type then
                            this_type_count = this_type_count + 1
                        end
                    else
                        self:set_trap_by_index(imp, i, define.INVAILD_ID)
                    end
                end
            end
        end
    end
    return all_type_count, this_type_count
end

function std_impact_052:special_heart_beat_check(imp, obj_me)
    local count = 0
    for i = std_impact_052.IDX_TRAP_START, std_impact_052.IDX_TRAP_END do
        local trap_obj_id = self:get_trap_by_index(imp, i)
        local trap_obj = obj_me:get_scene():get_obj_by_id(trap_obj_id)
        if trap_obj then
            if trap_obj:get_obj_type() == "special" then
                if trap_obj:is_fade_out() then
                    self:set_trap_by_index(imp, i, define.INVAILD_ID)
                else
                    count = count + 1
                end
            else
                self:set_trap_by_index(imp, i, define.INVAILD_ID)
            end
        else
            self:set_trap_by_index(imp, i, define.INVAILD_ID)
        end
    end
    if count > 0 then
        if imp:get_continuance() >= 0 then
            imp:set_continuance(-1)
            imp:set_continuance_elapsed(0)
        end
    else
        if imp:get_continuance() == -1 then
            imp:set_continuance(10000)
            imp:set_continuance_elapsed(0)
        end
    end
    return true
end

return std_impact_052