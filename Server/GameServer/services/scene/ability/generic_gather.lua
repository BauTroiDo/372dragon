local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local human_item_logic = require "human_item_logic"
local scriptenginer = require "scriptenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local base = require "scene.ability.base"
local generic_gather = class("generic_gather", base)

function generic_gather:can_use_ability(human)
    local res = generic_gather.super.can_use_ability(self, human)
    if res ~= define.OPERATE_RESULT.OR_OK then
        return res
    end
    local ability_opera = human:get_ability_opera()
    local obj_id = ability_opera.obj
    if obj_id == define.INVAILD_ID then
        assert(false)
    end
    local scene = human:get_scene()
    local item_box = scene:get_obj_by_id(obj_id)
    if item_box:get_obj_type() ~= "itembox" then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    if not item_box:can_pick_box(human:get_guid()) then
        return define.OPERATE_RESULT.OR_FAILURE
    end
    local item_box_type = item_box:get_type()
    local grow_point = configenginer:get_config("grow_point")
    grow_point = grow_point[item_box_type]
    assert(grow_point, item_box_type)
    local script_id = grow_point["脚本ID"] or define.INVAILD_ID
    if script_id ~= define.INVAILD_ID then
        return scene:get_grow_point_enginer():call_script_open_box_func(script_id, human:get_obj_id(), item_box:get_obj_id())
    end
    return define.OPERATE_RESULT.OR_OK
end

function generic_gather:on_proc_over(human)
    local ability_opera = human:get_ability_opera()
    local obj_id = ability_opera.obj
    if obj_id == define.INVAILD_ID then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    local scene = human:get_scene()
    local item_box = scene:get_obj_by_id(obj_id)
    if item_box:get_obj_type() ~= "itembox" then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    local item_box_type = item_box:get_type()
    local grow_point = configenginer:get_config("grow_point")
    grow_point = grow_point[item_box_type]
    assert(grow_point, item_box_type)
    local script_id = grow_point["脚本ID"] or define.INVAILD_ID
    if script_id ~= define.INVAILD_ID then
        local ret = scene:get_grow_point_enginer():call_script_proc_over_func(script_id, human:get_obj_id(), item_box:get_obj_id())
        if ret == 1 then
            return self:on_proc_failure(human)
        else
            return self:on_proc_success(human)
        end
    else
        return self:on_proc_success(human)
    end
end

function generic_gather:on_proc_success(human)
    local ability_opera = human:get_ability_opera()
    local obj_id = ability_opera.obj
    if obj_id == define.INVAILD_ID then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    local scene = human:get_scene()
    local item_box = scene:get_obj_by_id(obj_id)
    if item_box:get_obj_type() == "itembox" then
        if item_box:get_item_count() > 0 then
            if not item_box:get_open_flag() then
                item_box:set_open_flag(true)
            end
            local msg = packet_def.GCBoxItemList.new()
            local container = item_box:get_container()
            local list = {}
            local item_list = container:get_item_data()
            for i = 0, container:get_size() do
                local item = item_list[i]
                if item then
                    table.insert(list, item:copy_raw_data())
                end
            end
            msg.m_objID = item_box:get_obj_id()
            msg.size = #list
            msg.item_list = list
            msg.item_box_type = item_box:get_item_box_type()
            scene:send2client(human, msg)
        else
            local item_box_type = item_box:get_type()
            local grow_point = configenginer:get_config("grow_point")
            grow_point = grow_point[item_box_type]
            assert(grow_point, item_box_type)
            local script_id = grow_point["脚本ID"] or define.INVAILD_ID
            if script_id ~= define.INVAILD_ID then
                local ret = scene:get_grow_point_enginer():call_script_recycle_func(script_id, human:get_obj_id(), item_box:get_obj_id())
                if ret == 1 then
                    item_box:recycle()
                end
            end
        end
    else
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    return define.OPERATE_RESULT.OR_OK
end

return generic_gather
