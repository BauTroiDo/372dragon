local class = require "class"
local packet_def = require "game.packet"
local define = require "define"
local scriptenginer = require "scriptenginer":getinstance()
local petmanager = require "petmanager":getinstance()
local base = require "scene.skill.base"
local skill_10 = class("skill_10", base)

function skill_10:speical_operation_on_skill_start(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local obj_tar = self:get_target_obj(obj_me)
    if obj_tar == nil then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    if obj_tar:get_obj_type() ~= "pet" then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    obj_tar:add_capturer(obj_me)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

function skill_10:on_interrupt(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local obj_tar = self:get_target_obj(obj_me)
    if obj_tar == nil then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    if obj_tar == nil or not obj_tar:is_alive() or not obj_tar:is_active_obj() or "pet" ~= obj_tar:get_obj_type() then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    local msg = packet_def.GCManipulatePetRet.new()
    msg.guid = obj_tar:get_guid()
    msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_CAPTUREFALID
    obj_me:get_scene():send2client(obj_me, msg)
    obj_tar:del_capturer(obj_me)
    return true
end

function skill_10:effect_on_unit_once(obj_me, obj_tar)
    local params = obj_me:get_targeting_and_depleting_params()
    if obj_tar == nil or not obj_tar:is_alive() or not obj_tar:is_active_obj() or "pet" ~= obj_tar:get_obj_type() then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    if obj_me:get_obj_type() ~= "human" then
        return false
    end
    local log_param = {}
    local ret = obj_me:capture_pet(log_param, obj_tar)
    if ret then
        local msg = packet_def.GCManipulatePetRet.new()
        msg.guid = obj_tar:get_guid()
        msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_CAPTURESUCC
        obj_me:get_scene():send2client(obj_me, msg)
        obj_tar:send_capture_failed_to_others(obj_me)
        obj_tar:del_capturer(obj_me)
        petmanager:remove_pet(obj_tar:get_obj_id())
    else
        obj_tar:del_capturer(obj_me)
        local msg = packet_def.GCManipulatePetRet.new()
        msg.guid = obj_tar:get_guid()
        msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_CAPTUREFALID
        obj_me:get_scene():send2client(obj_me, msg)
    end
    return true
end

return skill_10