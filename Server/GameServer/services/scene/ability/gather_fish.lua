local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local base = require "scene.ability.generic_gather"
local gather_fish = class("gather_fish", base)

function gather_fish:can_use_ability(human)
    local res = self.super.can_use_ability(self, human)
    if res ~= define.OPERATE_RESULT.OR_OK then
        return res
    end
    return define.OPERATE_RESULT.OR_OK
end

function gather_fish:on_proc_over(human)
    local ability_opera = human:get_ability_opera()
    local item_box_id = ability_opera.obj
    if item_box_id == define.INVAILD_ID then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
    local scene = human:get_scene()
    local item_box = scene:get_obj_by_id(item_box_id)
    if item_box == nil then
        return define.OPERATE_RESULT.OR_INVALID_TARGET
    end
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
            self:on_proc_failure(human)
        else
            ret = scene:get_grow_point_enginer():call_script_open_box_func(script_id, human:get_obj_id(), item_box:get_obj_id())
            if ret == 1 then
                self:on_proc_failure(human)
            end
            local res = human:get_ai():push_command_use_ability()
            local msg = packet_def.GCAbilityResult.new()
            msg.ability = ability_opera.ability_id
            msg.prescription = define.INVAILD_ID
            msg.result = res
            scene:send2client(human, msg)
            return self:on_proc_success(human)
        end
    else
        self:on_proc_success(human)
    end
end

return gather_fish
