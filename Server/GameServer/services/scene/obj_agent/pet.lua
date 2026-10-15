local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local actionenginer = require "actionenginer":getinstance()
local item_container = require "item_container"
local ai_pet = require "scene.ai.pet"
local character = require "scene.obj_agent.character"
local pet = class("pet", character)

function pet:ctor(data)
    self.obj_address = skynet.newservice("obj", "pet", data)
end

function pet:do_move(handle, pos_tar)
    skynet.send(self.obj_address, "lua", "do_move", handle, pos_tar)
end

function pet:get_obj_type()
    return skynet.call(self.obj_address, "lua", "get_obj_type")
end

function pet:set_die_time(timer)
    skynet.send(self.obj_address, "lua", "set_die_time",timer)
end

function pet:update(...)
    skynet.send(self.obj_address, "lua", "update", ...)
end

function pet:set_cool_down(id, cool_down_time)
    skynet.send(self.obj_address, "lua", "set_cool_down", id, cool_down_time)
end

function pet:rage_increment()

end

function pet:send_refresh_attrib(send_all, type)
    skynet.send(self.obj_address, "lua", "send_refresh_attrib", send_all, type)
end

function pet:other_ask_info(who)
    skynet.send(self.obj_address, "lua", "other_ask_info", who)
end

function pet:get_attrib(attr)
    return skynet.call(self.obj_address, "lua", "get_attrib", attr)
end

function pet:get_model()
    return skynet.call(self.obj_address, "lua", "get_model")
end

function pet:get_name()
    return skynet.call(self.obj_address, "lua", "get_name")
end

function pet:get_take_level()
    return skynet.call(self.obj_address, "lua", "get_take_level")
end

function pet:get_wuxing()
    return skynet.call(self.obj_address, "lua", "get_wuxing")
end

function pet:sendmsg_refresh_attrib()

end

function pet:get_speed()
    return skynet.call(self.obj_address, "lua", "get_speed")
end

function pet:get_ai_type()
    return skynet.call(self.obj_address, "lua", "get_ai_type")
end

function pet:get_stealth_level()
    return skynet.call(self.obj_address, "lua", "get_stealth_level")
end

function pet:get_titles()
    return skynet.call(self.obj_address, "lua", "get_titles")
end

function pet:get_occupant_guid()
    return 0
end

function pet:is_npc()
    return false
end

function pet:is_enemy(other)
    return skynet.call(self.obj_address, "lua", "is_enemy", other)
end

function pet:get_owner_obj_id()
    return skynet.call(self.obj_address, "lua", "get_owner_obj_id")
end

function pet:get_owner()
    local id = self:get_owner_obj_id()
    return self:get_scene():get_obj_by_id(id)
end

function pet:get_creator()
    return self:get_owner()
end

function pet:get_my_master()
    return self:get_owner()
end

function pet:create_new_obj_packet()
    return skynet.call(self.obj_address, "lua", "create_new_obj_packet")
end

function pet:get_world_pos()
    return skynet.call(self.obj_address, "lua", "get_world_pos")
end

function pet:mark_attrib_refix_dirty(attr)
    skynet.call(self.obj_address, "lua", "mark_attrib_refix_dirty", attr)
end

function pet:get_exp()
    return skynet.call(self.obj_address, "lua", "get_exp")
end

function pet:set_exp(exp)
    skynet.send(self.obj_address, "lua", "set_exp", exp)
end

function pet:set_happiness(happiness)
    skynet.send(self.obj_address, "lua", "set_exp", exp)
end

function pet:on_be_skill(sender, skill_id, behaviortype)
    skynet.send(self.obj_address, "lua", "on_be_skill", sender, skill_id, behaviortype)
end

function pet:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    skynet.send(self.obj_address, "lua", "on_damages", damages, caster_obj_id, is_critical, skill_id, imp)
end

function pet:add_exp(add)
    skynet.send(self.obj_address, "lua", "add_exp", add)
end

function pet:set_used_procreate_count(count)
    skynet.send(self.obj_address, "lua", "set_used_procreate_count", count)
end

function pet:get_used_procreate_count()
    return skynet.call(self.obj_address, "lua", "get_used_procreate_count")
end

function pet:get_remain_procreate_count()
    return skynet.call(self.obj_address, "lua", "get_remain_procreate_count")
end

function pet:get_equip_container()
    return skynet.call(self.obj_address, "lua", "get_equip_container")
end

function pet:get_equips()
    return skynet.call(self.obj_address, "lua", "get_equips")
end

function pet:have_skill(skill)
    return skynet.call(self.obj_address, "lua", "have_skill", skill)
end

function pet:client_can_use_skill(skill)
    return skynet.call(self.obj_address, "lua", "client_can_use_skill", skill)
end

function pet:item_flush()
    skynet.send(self.obj_address, "lua", "item_flush")
end

function pet:set_capture_protect(occupantguid)
    skynet.call(self.obj_address, "lua", "set_capture_protect", occupantguid)
end

function pet:add_capturer(capturer)
    skynet.call(self.obj_address, "lua", "add_capturer", capturer)
end

function pet:del_capturer(capturer)
    skynet.call(self.obj_address, "lua", "del_capturer", capturer)
end

function pet:send_capture_failed_to_others(capturer)
    skynet.send(self.obj_address, "lua", "send_capture_failed_to_others", capturer)
end

function pet:set_detail(detail)
    skynet.call(self.obj_address, "lua", "set_detail", detail)
end

function pet:get_detail()
    return skynet.call(self.obj_address, "lua", "get_detail")
end

function pet:get_pet()
    return self
end

function pet:get_team_id()
    if self.owner == nil then
        return define.INVAILD_ID
    end
    return self.owner:get_team_id()
end

function pet:get_dw_jinjie_effect_details(id)
    return 0
end
function pet:get_attack_traits_type()
    return skynet.call(self.obj_address, "lua", "get_attack_traits_type")
end


return pet
