local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local base = require "scene.skill.base"
local skill_17 = class("skill_17", base)

function skill_17:ctor()

end

function skill_17:specific_condition_check(obj_me)
    local container = obj_me:get_pet_bag_container()
    local pet_guid = obj_me:get_guid_of_soul_melting_pet()
    local pet = container:get_pet_by_guid(pet_guid)
    local pet_equip_container = pet:get_equip_container()
    local equip = pet_equip_container:get_item(define.PET_EQUIP.PEQUIP_SOUL)
    if equip == nil then
        obj_me:notify_tips("要融魂的宠物没有装备兽魂")
        return false
    end
    return true
end

function skill_17:effect_on_unit_once(obj_me)
    local msg = packet_def.GCManipulatePetRet.new()
    msg.guid = obj_me:get_guid_of_soul_melting_pet()
    local result = obj_me:pet_soul_melting()
    if result < 0 then
        msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_SOULMELTINGFAILED
        obj_me:send_operate_result_msg(result)
    else
        msg.ret = define.ENUM_MANIPULATEPET_RET.MANIPULATEPET_RET_SOULMELTINGSUCC
    end
    obj_me:get_scene():send2client(obj_me, msg)
    return true
end

return skill_17