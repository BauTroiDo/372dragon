local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local base = require "scene.skill.base"
local skill_11 = class("skill_11", base)

function skill_11:effect_on_unit_once(obj_me)
    local msg = packet_def.GCManipulatePetRet.new()
    msg.guid = obj_me:get_guid_of_call_up_pet()
    local result = obj_me:call_up_pet()
    if result < 0 then
        msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_CALLUPFALID
        obj_me:send_operate_result_msg(result)
    else
        msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_CALLUPSUCC
    end
    obj_me:get_scene():send2client(obj_me, msg)
    return true
end

return skill_11