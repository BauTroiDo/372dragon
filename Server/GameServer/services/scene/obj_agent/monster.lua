local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local configenginer = require "configenginer":getinstance()
local ai_monster = require "scene.ai.monster"
local character = require "scene.obj.character"
local monster_db_attr = require "db.monster_attrib"
local db_impact = require "db.impact_data"
local monster = class("monster", character)

function monster:ctor(data)
    self.obj_address = skynet.newservice("obj", "monster", data)
end

function monster:init()
    return skynet.call(self.obj_address, "lua", "init")
end

function monster:set_die_time(timer)
    skynet.send(self.obj_address, "lua", "set_die_time",timer)
end

function monster:set_top_monster()
    skynet.send(self.obj_address, "lua", "set_top_monster")
end

function monster:empty_top_monster()
    skynet.send(self.obj_address, "lua", "empty_top_monster")
end

function monster:update(...)
    skynet.send(self.obj_address, "lua", "update", ...)
end

function monster:get_aoi_mode()
    return "wm"
end

function monster:get_group_id()
    return skynet.call(self.obj_address, "lua", "get_group_id")
end

function monster:get_active_time()
    return skynet.call(self.obj_address, "lua", "get_active_time")
end

function monster:send_refresh_attrib()
    skynet.send(self.obj_address, "lua", "send_refresh_attrib")
end

function monster:on_obj_enter_view(obj)
    skynet.send(self.obj_address, "lua", "on_obj_enter_view", obj)
end

function monster:set_attrib(...)
    skynet.call(self.obj_address, "lua", "set_attrib", ...)
end

function monster:get_impact_list()
    return skynet.call(self.obj_address, "lua", "get_impact_list")
end

function monster:get_detail_attribs()
    return skynet.call(self.obj_address, "lua", "get_detail_attribs")
end

function monster:get_name()
    return skynet.call(self.obj_address, "lua", "get_name")
end

function monster:get_model()
    return skynet.call(self.obj_address, "lua", "get_model")
end

function monster:get_script_id()
    return skynet.call(self.obj_address, "lua", "get_script_id")
end

function monster:get_respawn_pos()
    return skynet.call(self.obj_address, "lua", "get_respawn_pos")
end

function monster:get_pos_range()
    return skynet.call(self.obj_address, "lua", "get_pos_range")
end

function monster:get_obj_type()
     return "monster"
end

function monster:get_stealth_level()
    return skynet.call(self.obj_address, "lua", "get_stealth_level")
end

function monster:get_speed()
    return skynet.call(self.obj_address, "lua", "get_speed")
end

function monster:get_base_ai()
    return skynet.call(self.obj_address, "lua", "get_base_ai")
end

function monster:get_ai_script()
    return skynet.call(self.obj_address, "lua", "get_ai_script")
end

function monster:get_attack_traits_type()
    return skynet.call(self.obj_address, "lua", "get_attack_traits_type")
end

function monster:get_attack_anim_time()
    return skynet.call(self.obj_address, "lua", "get_attack_anim_time")
end

function monster:get_base_exp()
    return skynet.call(self.obj_address, "lua", "get_base_exp")
end

function monster:set_group_id(id)
    skynet.send(self.obj_address, "lua", "set_group_id", id)
end

function monster:get_group_id()
    return skynet.call(self.obj_address, "lua", "get_group_id")
end

function monster:set_fight_with_npc_flag(flag)
    skynet.send(self.obj_address, "lua", "set_fight_with_npc_flag", flag)
end

function monster:set_ai_type(ai_type)
    skynet.send(self.obj_address, "lua", "set_ai_type", ai_type)
end

function monster:set_ai_script(ai_script)
    skynet.send(self.obj_address, "lua", "set_ai_script", ai_script)
end

function monster:get_fight_with_npc_flag()
    return skynet.call(self.obj_address, "lua", "get_fight_with_npc_flag")
end

function monster:set_script_timer(delta_time)
    skynet.call(self.obj_address, "lua", "set_script_timer", delta_time)
end

function monster:default_event(who)
    skynet.call(self.obj_address, "lua", "default_event", who)
end

function monster:event_request(who, ...)
    skynet.call(self.obj_address, "lua", "event_request", who, ...)
end

function monster:get_ai_type() 
    return skynet.call(self.obj_address, "lua", "get_ai_type")
end

function monster:is_npc()
    return skynet.call(self.obj_address, "lua", "is_npc")
end

function monster:is_enemy(other)
    return skynet.call(self.obj_address, "lua", "is_enemy", other)
end

function monster:add_owner_drop_item(obj, item)
    skynet.call(self.obj_address, "lua", "add_owner_drop_item", obj, item)
end

function monster:caculate_owner_list()
    return skynet.call(self.obj_address, "lua", "caculate_owner_list")
end

function monster:rage_increment()

end

function monster:set_occipant_guid(guid)
    skynet.send(self.obj_address, "lua", "set_occipant_guid", guid)
end

function monster:set_team_occipant_guid(guid)
    skynet.send(self.obj_address, "lua", "set_team_occipant_guid", guid)
end

function monster:get_occupant_guid()
    return skynet.call(self.obj_address, "lua", "get_occupant_guid")
end

function monster:get_team_occipant_guid()
    return skynet.call(self.obj_address, "lua", "get_team_occipant_guid")
end

function monster:get_owners()
    return skynet.call(self.obj_address, "lua", "get_owners")
end

function monster:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    skynet.send(self.obj_address, "lua", "on_damages", damages, caster_obj_id, is_critical, skill_id, imp)
end

function monster:back_monster_damage(hp_modify,sender)
    return skynet.call(self.obj_address, "lua", "back_monster_damage",hp_modify,sender)
end
-- function monster:health_increment(hp_modify, sender, is_critical_hit, imp)
    -- skynet.send(self.obj_address, "lua", "health_increment", hp_modify, sender, is_critical_hit, imp)
-- end

-- function monster:gm_kill_obj(targetId)
    -- return skynet.call(self.obj_address, "lua", "gm_kill_obj",targetId)
-- end

function monster:get_respawn_time() 
    return skynet.call(self.obj_address, "lua", "get_respawn_time")
end

function monster:respawn()
    skynet.call(self.obj_address, "lua", "respawn")
end

function monster:set_patrol_id(id)
    skynet.call(self.obj_address, "lua", "set_patrol_id", id)
end

function monster:get_patrol_id()
    return skynet.call(self.obj_address, "lua", "get_patrol_id")
end

function monster:is_patrol_monster()
    return skynet.call(self.obj_address, "lua", "is_patrol_monster")
end

function monster:set_mp()
end

function monster:set_hp_max(hp_max)
    skynet.send(self.obj_address, "lua", "set_hp_max", hp_max)
end

function monster:set_mind_attack(mind_attack)
    skynet.send(self.obj_address, "lua", "set_mind_attack", mind_attack)
end

function monster:set_attrib_hit(attrib_hit)
    skynet.send(self.obj_address, "lua", "set_attrib_hit", attrib_hit)
end

function monster:set_attrib_miss(attrib_miss)
    skynet.send(self.obj_address, "lua", "set_attrib_miss", attrib_miss)
end

function monster:set_attrib_att_physics(attrib_att_physics)
    skynet.send(self.obj_address, "lua", "set_attrib_att_physics", attrib_att_physics)
end

function monster:set_attrib_def_physics(attrib_def_physics)
    skynet.send(self.obj_address, "lua", "set_attrib_def_physics", attrib_def_physics)
end

function monster:set_attrib_att_magic(attrib_att_magic)
    skynet.send(self.obj_address, "lua", "set_attrib_att_magic", attrib_att_magic)
end

function monster:set_attrib_def_magic(attrib_def_magic)
    skynet.send(self.obj_address, "lua", "set_attrib_def_magic", attrib_def_magic)
end

function monster:set_att_cold(att_cold)
    skynet.send(self.obj_address, "lua", "set_att_cold", att_cold)
end

function monster:set_def_cold(def_cold)
    skynet.send(self.obj_address, "lua", "set_def_cold", def_cold)
end

function monster:set_att_fire(att_fire)
    skynet.send(self.obj_address, "lua", "set_att_fire", att_fire)
end

function monster:set_def_fire(def_fire)
    skynet.send(self.obj_address, "lua", "set_def_fire", def_fire)
end

function monster:set_att_light(att_light)
    skynet.send(self.obj_address, "lua", "set_att_light", att_light)
end

function monster:set_def_light(def_light)
    skynet.send(self.obj_address, "lua", "set_def_light", def_light)
end

function monster:set_att_poison(att_poison)
    skynet.send(self.obj_address, "lua", "set_att_poison", att_poison)
end

function monster:set_def_poison(def_poison)
    skynet.send(self.obj_address, "lua", "set_def_poison", def_poison)
end

function monster:get_attrib(attr)
    return skynet.call(self.obj_address, "lua", "get_attrib", attr)
end

function monster:get_dir()
    return skynet.call(self.obj_address, "lua", "get_dir")
end

function monster:mark_unbreakable_flag()
    skynet.call(self.obj_address, "lua", "mark_unbreakable_flag")
end

function monster:clear_unbreakable_flag()
    skynet.call(self.obj_address, "lua", "clear_unbreakable_flag")
end

function monster:set_temp_camp_id(id)
    skynet.call(self.obj_address, "lua", "set_temp_camp_id", id)
end

function monster:create_new_obj_packet()
    return skynet.call(self.obj_address, "lua", "create_new_obj_packet")
end

function monster:set_create_time(time)
    skynet.send(self.obj_address, "lua", "set_create_time", time)
end

function monster:get_create_time()
    return skynet.call(self.obj_address, "lua", "get_create_time")
end

function monster:on_impact_fade_out(imp)
    skynet.send(self.obj_address, "lua", "on_impact_fade_out", imp)
end

function monster:AIS_SetPatrolID(patrol_id)
    skynet.send(self.obj_address, "lua", "AIS_SetPatrolID", patrol_id)
end

function monster:AIS_SetBaseAIType(...)
    skynet.send(self.obj_address, "lua", "AIS_SetBaseAIType", ...)
end

function monster:AIS_SetReputationID_CodingRefix(reputation_id)
    skynet.send(self.obj_address, "lua", "AIS_SetReputationID_CodingRefix", reputation_id)
end

function monster:AIS_SetMonsterFightWithNpcFlag(flag)
    skynet.send(self.obj_address, "lua", "AIS_SetMonsterFightWithNpcFlag", flag)
end

function monster:set_near_humans(humans)
    skynet.send(self.obj_address, "lua", "set_near_humans", humans)
end

function monster:get_near_humans()
    return skynet.call(self.obj_address, "lua", "get_near_humans")
end

function monster:get_dw_jinjie_effect_details(id)
    return 0
end

function monster:get_interaction_type()
    return skynet.call(self.obj_address, "lua", "get_interaction_type")
end

function monster:get_need_skill()
    return skynet.call(self.obj_address, "lua", "get_need_skill")
end

function monster:get_damage_member()
    return skynet.call(self.obj_address, "lua", "get_damage_member")
end

function monster:get_scene_params(index)
    return skynet.call(self.obj_address, "lua", "get_scene_params",index)
end

function monster:set_scene_params(index,value)
    return skynet.call(self.obj_address, "lua", "set_scene_params",index,value)
end

function monster:set_unconstrained_monster(value)
    return skynet.call(self.obj_address, "lua", "set_unconstrained_monster",value)
end


return monster
