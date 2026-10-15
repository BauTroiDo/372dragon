local skynet = require "skynet"
local class = require "class"
local define = require "define"
local obj_base = require "scene.obj_agent.base"
local character = class("character", obj_base)

function character:get_guid()
    return skynet.call(self.obj_address, "lua", "get_guid")
end

function character:get_obj_id() 
    return skynet.call(self.obj_address, "lua", "get_obj_id")
end

function character:get_base_attribs()
    return skynet.call(self.obj_address, "lua", "get_base_attribs")
end

function character:get_detail_attribs()
    return skynet.call(self.obj_address, "lua", "get_detail_attribs")
end

function character:get_speed()
    return skynet.call(self.obj_address, "lua", "get_speed")
end

function character:get_data_id()
    return skynet.call(self.obj_address, "lua", "get_data_id")
end

function character:set_name(name)
    skynet.send(self.obj_address, "lua", "set_name", name)
end

function character:set_hp(hp)
    skynet.send(self.obj_address, "lua", "set_hp", hp)
end

function character:set_mp(mp)
    skynet.send(self.obj_address, "lua", "set_mp", mp)
end

function character:set_level(level)
    skynet.send(self.obj_address, "lua", "set_level", level)
end

function character:set_rage(rage)
    skynet.send(self.obj_address, "lua", "set_rage", rage)
end

function character:set_strike_point(point)
    skynet.send(self.obj_address, "lua", "set_strike_point", point)
end

function character:get_strike_point()
    return skynet.call(self.obj_address, "lua", "get_strike_point")
end

function character:set_datura_flower(point)
    skynet.send(self.obj_address, "lua", "set_datura_flower", point)
end

function character:set_temp_camp_id(id)
    skynet.send(self.obj_address, "lua", "set_temp_camp_id", id)
end

function character:get_datura_flower()
    return skynet.call(self.obj_address, "lua", "get_datura_flower")
end

function character:get_mp()
    return skynet.call(self.obj_address, "lua", "get_mp")
end

function character:get_rage()
    return skynet.call(self.obj_address, "lua", "get_rage")
end

function character:get_obj_chuanci()
    return skynet.call(self.obj_address, "lua", "get_obj_chuanci")
end

function character:get_obj_fangchuan()
    return skynet.call(self.obj_address, "lua", "get_obj_fangchuan")
end

function character:get_attack_traits_type()
    return define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI
end

function character:is_moving()
    return skynet.call(self.obj_address, "lua", "is_moving")
end

function character:is_alive_in_deed()
    return skynet.call(self.obj_address, "lua", "is_alive_in_deed")
end

function character:get_reputation()
    return skynet.call(self.obj_address, "lua", "get_reputation")
end

function character:set_reputation(reputation)
    skynet.send(self.obj_address, "lua", "set_reputation", reputation)
end

function character:is_die()
    return skynet.call(self.obj_address, "lua", "is_die")
end

function character:is_can_view(obj)
    return skynet.call(self.obj_address, "lua", "is_can_view", obj)
end

function character:get_stealth_level()
    return skynet.call(self.obj_address, "lua", "get_stealth_level")
end

function character:set_top_monster()
    skynet.send(self.obj_address, "lua", "set_top_monster")
end

function character:empty_top_monster()
    skynet.send(self.obj_address, "lua", "empty_top_monster")
end

function character:set_die_time(timer)
    skynet.send(self.obj_address, "lua", "set_die_time", timer)
end

function character:send_refresh_attrib()

end

function character:get_cool_down_by_cool_down_id(cool_down_id)
    return skynet.call(self.obj_address, "lua", "get_cool_down_by_cool_down_id", cool_down_id)
end

function character:send_cool_down_time()
end

function character:do_move(handle, pos_tar)
    return skynet.call(self.obj_address, "lua", "do_move", handle, pos_tar)
end

function character:do_fly(handle, pos_tar)
    return skynet.call(self.obj_address, "lua", "do_fly", handle, pos_tar)
end

function character:do_idle()
    return skynet.call(self.obj_address, "lua", "do_idle")
end

function character:do_stop()
    return skynet.call(self.obj_address, "lua", "do_stop")
end

function character:do_jump()
    skynet.call(self.obj_address, "lua", "do_jump")
end

function character:do_use_ability()
    skynet.send(self.obj_address, "lua", "do_use_ability")
end

function character:do_use_item(bag_index, target_obj_id, target_pos, target_pet_guid, target_item_bag_index)
    return skynet.call(self.obj_address, "lua", "do_use_item", bag_index, target_obj_id, target_pos, target_pet_guid, target_item_bag_index)
end

function character:do_activite_monster(skill_id, target_obj_id, target_pos)
    return skynet.call(self.obj_address, "lua", "do_activite_monster",skill_id, target_obj_id, target_pos)
end

function character:activate_item()

end

function character:get_skill_level()
    return skynet.call(self.obj_address, "lua", "get_skill_level")
end

function character:do_use_skill(skill_id, id_tar, pos_tar, dir_tar, guid_tar, script_arg_1, script_arg_2, script_arg_3)
    return skynet.call(self.obj_address, "lua", "do_use_skill",skill_id, id_tar, pos_tar, dir_tar, guid_tar, script_arg_1, script_arg_2, script_arg_3)
end

function character:get_skill_info()
    return skynet.call(self.obj_address, "lua", "get_skill_info")
end

function character:get_targeting_and_depleting_params()
    return skynet.call(self.obj_address, "lua", "get_targeting_and_depleting_params")
end

function character:is_alive()
    return skynet.call(self.obj_address, "lua", "is_alive")
end

function character:get_skill_template(skill_id)
    return skynet.call(self.obj_address, "lua", "get_skill_template", skill_id)
end

function character:can_use_this_skill_in_this_status(skill_id)
    return skynet.call(self.obj_address, "lua", "can_use_this_skill_in_this_status", skill_id)
end

function character:impact_forbidden_this_skill()
    return false
end

function character:is_skill_cool_down(skill_id)
    return skynet.call(self.obj_address, "lua", "is_skill_cool_down", skill_id)
end

function character:is_cool_downed(id)
    return skynet.call(self.obj_address, "lua", "is_cool_downed", id)
end

function character:have_skill(skill_id)
    return true
end

function character:refix_skill(skill_info)
    return skynet.call(self.obj_address, "lua", "refix_skill", skill_info)
end

function character:talent_refix_skill_info()

end

function character:impact_refix_skill(skill_info)
    skynet.send(self.obj_address, "lua", "impact_refix_skill", skill_info)
end

function character:on_use_skill_success_fully(skill_info)
    skynet.send(self.obj_address, "lua", "on_use_skill_success_fully", skill_info)
end

function character:is_enemy(other)
    return skynet.call(self.obj_address, "lua", "is_enemy", other)
end

function character:is_party(other)

end

function character:is_friend(other)
    return skynet.call(self.obj_address, "lua", "is_friend", other)
end

function character:is_teammate()
    return false
end

function character:is_active_obj()
    return true
end

function character:get_character_logic()
    return skynet.call(self.obj_address, "lua", "get_character_logic")
end

function character:set_character_logic(logic)
    skynet.send(self.obj_address, "lua", "set_character_logic", logic)
end

function character:is_character_logic_use_skill()
    return skynet.call(self.obj_address, "lua", "is_character_logic_use_skill")
end

function character:stop_character_logic(...)
    skynet.send(self.obj_address, "lua", "stop_character_logic", ...)
end

function character:can_view_me(obj)
    return skynet.call(self.obj_address, "lua", "can_view_me", obj)
end

function character:get_action_time()
    return skynet.call(self.obj_address, "lua", "get_action_time")
end

function character:set_action_time(action_time)
    skynet.send(self.obj_address, "lua", "set_action_time", action_time)
end

function character:get_hit()
    return skynet.call(self.obj_address, "lua", "get_hit")
end

function character:get_miss()
    return skynet.call(self.obj_address, "lua", "get_miss")
end

function character:get_action_params()
    return skynet.call(self.obj_address, "lua", "get_action_params")
end

function character:get_attack_cool_down_time()
    return skynet.call(self.obj_address, "lua", "get_attack_cool_down_time")
end

function character:set_action_logic(logic)
    skynet.send(self.obj_address, "lua", "set_action_logic", logic)
end

function character:get_action_logic()
    return skynet.call(self.obj_address, "lua", "get_action_logic")
end

function character:set_logic_count(logic_count)
    skynet.send(self.obj_address, "lua", "set_logic_count", logic_count)
end

function character:set_cool_down(id, cool_down_time)
    skynet.send(self.obj_address, "lua", "set_cool_down", id, cool_down_time)
end

function character:get_cool_down(id)
   return skynet.call(self.obj_address, "lua", "get_cool_down", id)
end

function character:get_cool_downs()
    return skynet.call(self.obj_address, "lua", "get_cool_downs")
end

function character:set_dir(dir)
    skynet.send(self.obj_address, "lua", "set_dir", dir)
end

function character:get_dir()
    return skynet.call(self.obj_address, "lua", "get_dir")
end

function character:on_action_start()
    skynet.send(self.obj_address, "lua", "on_action_start")
end

function character:on_critical_hit_target(skill_id, obj_tar)
    skynet.send(self.obj_address, "lua", "on_critical_hit_target", skill_id, obj_tar)
end

function character:talent_on_critical_hit_target(skill_id, obj_tar)
end

function character:on_be_critical_hit(skill_id, sender)
    skynet.send(self.obj_address, "lua", "on_be_critical_hit", skill_id, sender)
end

function character:talent_on_be_critical_hit(skill_id, sender)

end

function character:get_auto_repeat_cool_down()
    return skynet.call(self.obj_address, "lua", "get_auto_repeat_cool_down")
end

function character:set_auto_repeat_cool_down(cooldown)
    skynet.send(self.obj_address, "lua", "set_auto_repeat_cool_down", cooldown)
end

function character:get_attack_physics()
    return skynet.call(self.obj_address, "lua", "get_attack_physics")
end

function character:get_attack_magic()
    return skynet.call(self.obj_address, "lua", "get_attack_magic")
end

function character:get_attack_cold()
    return skynet.call(self.obj_address, "lua", "get_attack_cold")
end

function character:get_attack_fire()
    return skynet.call(self.obj_address, "lua", "get_attack_fire")
end

function character:get_attack_light()
    return skynet.call(self.obj_address, "lua", "get_attack_light")
end

function character:get_attack_posion()
    return skynet.call(self.obj_address, "lua", "get_attack_posion")
end

function character:get_defence_physics()
    return skynet.call(self.obj_address, "lua", "get_defence_physics")
end

function character:get_defence_magic()
    return skynet.call(self.obj_address, "lua", "get_defence_magic")
end

function character:get_defence_cold()
    return skynet.call(self.obj_address, "lua", "get_defence_cold")
end

function character:get_defence_fire()
    return skynet.call(self.obj_address, "lua", "get_defence_fire")
end

function character:get_defence_light()
    return skynet.call(self.obj_address, "lua", "get_defence_light")
end

function character:get_defence_posion()
    return skynet.call(self.obj_address, "lua", "get_defence_posion")
end

function character:get_reduce_def_cold()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_cold")
end

function character:get_reduce_def_fire()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_fire")
end

function character:get_reduce_def_light()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_light")
end

function character:get_reduce_def_posion()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_posion")
end

function character:get_reduce_def_cold_low_limit()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_cold_low_limit")
end

function character:get_reduce_def_fire_low_limit()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_fire_low_limit")
end

function character:get_reduce_def_light_low_limit()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_light_low_limit")
end

function character:get_reduce_def_posion_low_limit()
    return skynet.call(self.obj_address, "lua", "get_reduce_def_posion_low_limit")
end

function character:get_logic_count()
    return skynet.call(self.obj_address, "lua", "get_logic_count")
end

function character:get_level()
    return skynet.call(self.obj_address, "lua", "get_level")
end

function character:is_unbreakable()
    return skynet.call(self.obj_address, "lua", "is_unbreakable")
end

function character:get_mind_attack()
    return skynet.call(self.obj_address, "lua", "get_mind_attack")
end

function character:get_mind_defend()
    return skynet.call(self.obj_address, "lua", "get_mind_defend")
end

function character:register_impact(imp)
    skynet.send(self.obj_address, "lua", "register_impact", imp)
end

function character:remove_impact(imp)
    skynet.send(self.obj_address, "lua", "remove_impact", imp)
end

function character:set_impact_sn_seed(count)
    skynet.send(self.obj_address, "lua", "set_impact_sn_seed", count)
end

function character:add_impact_sns_seed()
    skynet.send(self.obj_address, "lua", "add_impact_sns_seed")
end

function character:on_impact_get_combat_result()

end

function character:unregister_impact_by_sn(sn)
    skynet.send(self.obj_address, "lua", "unregister_impact_by_sn", sn)
end

function character:on_impact_fade_out(imp)
    skynet.send(self.obj_address, "lua", "on_impact_fade_out", imp)
end

function character:imp_on_impact_fade_out(imp)

end

function character:talent_on_impact_fade_out(imp)

end

function character:on_be_skill(sender, skill_id, behaviortype)
    skynet.send(self.obj_address, "lua", "on_be_skill", sender, skill_id, behaviortype)
end

function character:on_new_obj_enter_view(obj)
    skynet.send(self.obj_address, "lua", "on_new_obj_enter_view", obj)
end

function character:on_obj_leave_view(obj)
    skynet.send(self.obj_address, "lua", "on_obj_leave_view", obj)
end

function character:on_be_hit(sender, skill)
    skynet.send(self.obj_address, "lua", "on_be_hit", sender, skill)
end

function character:talent_on_be_hit()

end

function character:impact_on_use_skill_success_fully(skill_info)
    skynet.send(self.obj_address, "lua", "impact_on_use_skill_success_fully", skill_info)
end

function character:talent_on_use_skill_success_fully(skill_info)
end

function character:impact_refix_skill_launch_rate(args)
    skynet.send(self.obj_address, "lua", "impact_refix_skill_launch_rate", args)
end

function character:on_hit_target(reciver, skill)
    self:impact_on_hit_target(reciver, skill)
end

function character:on_skill_miss(sender, skill_id)

end

function character:on_skill_miss_target(reciver, skill_id)

end

function character:is_stealth_immu(imp)
    return skynet.call(self.obj_address, "lua", "is_stealth_immu", imp)
end

function character:impact_on_damage_target(damages, target, skill_id)
    skynet.send(self.obj_address, "lua", "impact_on_damage_target", damages, target, skill_id)
end

function character:on_damage_target(target, damages, skill_id)
    self:impact_on_damage_target(damages, target, skill_id)
end

function character:on_damages(damages, caster_obj_id, is_critical, skill_id, imp)
    skynet.send(self.obj_address, "lua", "on_damages", damages, caster_obj_id, is_critical, skill_id, imp)
end

function character:on_teleport(world_pos)
    skynet.send(self.obj_address, "lua", "on_teleport", world_pos)
end

function character:get_hp()
    return skynet.call(self.obj_address, "lua", "get_hp")
end

function character:get_mp()
    return skynet.call(self.obj_address, "lua", "get_mp")
end

function character:get_max_hp()
    return skynet.call(self.obj_address, "lua", "get_max_hp")
end

function character:get_max_mp()
    return skynet.call(self.obj_address, "lua", "get_max_mp")
end

function character:get_max_rage()
    return skynet.call(self.obj_address, "lua", "get_max_rage")
end

function character:refix_impact(imp, reciver)
    skynet.send(self.obj_address, "lua", "refix_impact", imp, reciver)
end

function character:impact_refix_imp(imp)
    skynet.send(self.obj_address, "lua", "impact_refix_imp", imp)
end

function character:on_relive()

end

function character:on_filtrate_impact(imp)
    return skynet.call(self.obj_address, "lua", "on_filtrate_impact", imp)
end

function character:direct_move_to(tar)
    self:do_move(-1, { tar })
end

function character:fly_to(tar)
    self:do_fly(-1, { tar })
end

function character:set_locked_target(obj_id)
    skynet.send(self.obj_address, "lua", "set_locked_target", obj_id)
end

function character:on_lock_target()

end

function character:get_locked_target()
    return skynet.call(self.obj_address, "lua", "get_locked_target")
end

function character:soul_separated_kill_blindness(targeobj)
    skynet.send(self.obj_address, "lua", "soul_separated_kill_blindness", targeobj)
end

-- [FIX] 901 向死而生代理函数
function character:toward_death_kill_heal(targeobj)
    skynet.send(self.obj_address, "lua", "toward_death_kill_heal", targeobj)
end

function character:health_increment(hp_modify, sender, is_critical_hit, imp)
    skynet.send(self.obj_address, "lua", "health_increment", hp_modify, sender, is_critical_hit, imp)
end

-- function character:health_increment_damages(hp_modify,recover_hp_count,sender,imp,skill_id)
    -- skynet.send(self.obj_address, "lua", "health_increment_damages", hp_modify,recover_hp_count,sender,imp,skill_id)
-- end
-- function character:rage_increment_damages(rage_modify,rage_modify_count)
    -- skynet.send(self.obj_address, "lua", "rage_increment_damages", rage_modify,rage_modify_count)
-- end
-- function character:mana_increment_damages(mp_modify,mp_modify_count,sender,imp)
    -- skynet.send(self.obj_address, "lua", "mana_increment_damages", mp_modify,mp_modify_count,sender,imp)
-- end

function character:gm_kill_obj(targetId)
    skynet.send(self.obj_address, "lua", "gm_kill_obj", targetId)
end


function character:mana_increment(mp_modify, sender, is_critical, imp)
    skynet.send(self.obj_address, "lua", "mana_increment", mp_modify, sender, is_critical, imp)
end

function character:rage_increment(rage_modify)
    skynet.send(self.obj_address, "lua", "rage_increment", rage_modify)
end

function character:strike_point_increment(strike_point_modify, sender)
    skynet.send(self.obj_address, "lua", "strike_point_increment", strike_point_modify, sender)
end

function character:datura_flower_increment(datura_flower_modify, sender)
    skynet.send(self.obj_address, "lua", "strike_point_increment", datura_flower_modify, sender)
end

function character:on_heal_target(skill_id, hp_modify, healed_obj_id)
    skynet.send(self.obj_address, "lua", "on_heal_target", skill_id, hp_modify, healed_obj_id)
end

function character:set_relive_info(is_skill_relive, relive_info)
    skynet.send(self.obj_address, "lua", "set_relive_info", is_skill_relive, relive_info)
end

function character:clear_skill_relive_info()
    skynet.send(self.obj_address, "lua", "clear_skill_relive_info")
end

function character:get_relive_info(is_skill_relive)
    return skynet.call(self.obj_address, "lua", "get_relive_info", is_skill_relive)
end

function character:can_action_flag_1()
    return skynet.call(self.obj_address, "lua", "")
end

function character:can_action_flag_2()
    return skynet.call(self.obj_address, "lua", "can_action_flag_2")
end

function character:get_camp_id()
    return skynet.call(self.obj_address, "lua", "get_camp_id")
end

function character:is_enemy_camp(other)
    return skynet.call(self.obj_address, "lua", "is_enemy_camp", other)
end

function character:calc_relation_type(otype_1, otype_2, camp_1, camp_2)
    return skynet.call(self.obj_address, "lua", "calc_relation_type", otype_1, otype_2, camp_1, camp_2)
end

function character:mark_attrib_refix_dirty(key)
    skynet.send(self.obj_address, "lua", "mark_attrib_refix_dirty", key)
end

function character:impact_get_first_impact_of_specific_class_id(id)
    return skynet.call(self.obj_address, "lua", "impact_get_first_impact_of_specific_class_id", id)
end

function character:impact_have_impact_of_specific_impact_id(id)
    return self:impact_get_first_impact_of_specific_impact_id(id) ~= nil
end

function character:impact_get_first_impact_in_specific_collection(id)
    return skynet.call(self.obj_address, "lua", "impact_get_first_impact_in_specific_collection", id)
end

function character:impact_have_impact_in_specific_collection(id)
    return self:impact_get_first_impact_in_specific_collection(id) ~= nil
end

function character:impact_cancel_impact_in_specific_collection(id)
    skynet.send(self.obj_address, "lua", "impact_cancel_impact_in_specific_collection", id)
end

function character:impact_have_impact_in_specific_collection(id)
    return skynet.call(self.obj_address, "lua", "impact_have_impact_in_specific_collection", id)
end

function character:impact_cancel_impact_in_specific_impact_id(id)
    skynet.send(self.obj_address, "lua", "impact_cancel_impact_in_specific_impact_id", id)
end

function character:impact_cancel_impact_in_specific_data_index(data_index)
    skynet.send(self.obj_address, "lua", "impact_cancel_impact_in_specific_data_index", data_index)
end

function character:on_deplete_strike_points(point)

end

function character:set_title(title)
    skynet.send(self.obj_address, "lua", "set_title", title)
end

function character:is_can_relive()
    return skynet.call(self.obj_address, "lua", "is_can_relive")
end

function character:get_can_relive()
    return skynet.call(self.obj_address, "lua", "get_can_relive")
end

function character:skill_create_obj_specail(world_pos, trap_data_index)
    return skynet.call(self.obj_address, "lua", "skill_create_obj_specail", world_pos, trap_data_index)
end

function character:skill_charge(to,skillid)
    skynet.send(self.obj_address, "lua", "skill_charge", to, skillid)
end

function character:skill_exec_from_script(skill_id, id_tar, x, z, dir, pass_check)
    skynet.send(self.obj_address, "lua", "skill_exec_from_script", skill_id, id_tar, x, z, dir, pass_check)
end

function character:refix_skill_cool_down_time(skill_info, cool_down_time)
    return cool_down_time
end

function character:refix_miss_rate()
    return skynet.call(self.obj_address, "lua", "refix_miss_rate")
end

function character:target_refix_accuracy_rate(obj_tar)
    return skynet.call(self.obj_address, "lua", "target_refix_accuracy_rate", obj_tar)
end

function character:impact_refix_miss_rate()
    return skynet.call(self.obj_address, "lua", "impact_refix_miss_rate")
end

function character:impact_target_refix_accuracy_rate(obj_tar)
    return skynet.call(self.obj_address, "lua", "impact_target_refix_accuracy_rate", obj_tar)
end

function character:ais_is_can_skill(skill)
    return skynet.call(self.obj_address, "lua", "ais_is_can_skill", skill)
end

function character:ais_to_skill(skill)
    return skynet.call(self.obj_address, "lua", "ais_to_skill", skill)
end

function character:ais_call_other_monster_by_group()
    skynet.send(self.obj_address, "lua", "ais_call_other_monster_by_group")
end

function character:ais_rand()
    return math.random(1, 100) - 1
end

function character:GetAIScriptTimes(id)
    return skynet.call(self.obj_address, "lua", "GetAIScriptTimes", id)
end

function character:SetAIScriptTimes(id, times)
    skynet.send(self.obj_address, "lua", "SetAIScriptTimes", id, times)
end

function character:show_skill_missed(selfId,targetid,skill_id,ogic_count,flag)
    return skynet.call(self.obj_address, "lua", "show_skill_missed",selfId,targetid,skill_id,ogic_count,flag)
end

function character:show_buff_effect(selfId,targetid,skill_id,ogic_count,flag)
    return skynet.call(self.obj_address, "lua", "show_buff_effect",selfId,targetid,skill_id,ogic_count,flag)
end

-- function character:get_is_stealth_flag()
    -- skynet.send(self.obj_address, "lua", "get_is_stealth_flag")
-- end

-- function character:set_is_stealth_flag()
    -- skynet.send(self.obj_address, "lua", "set_is_stealth_flag")
-- end


function character:aiscript_call(fn, ...)
    local f = self[fn]
    assert(f, fn)
    local r, err = pcall(f, self, ...)
    if not r then
        print("character:aiscript_call r =", r, ";error =", err)
    end
    --print("aiscript_call func =", fn, ";args =", ...,  ";result =", err)
    return err
end

function character:get_obj_type()
    return "character"
end

return character
