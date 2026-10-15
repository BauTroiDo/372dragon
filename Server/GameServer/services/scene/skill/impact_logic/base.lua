local class = require "class"
local actionenginer = require "actionenginer":getinstance()
local packet_def = require "game.packet"
local base = class("base")

function base:ctor()

end

function base:is_intervaled()
    return false
end

function base:is_stealth_impact()
    return false
end

function base:mark_modified_attr_dirty(imp, obj)
    local meta = getmetatable(self)
    for key in pairs(meta) do
        local f = self[key]
        if type(f) == "function" then
            local attr = string.match(key, "get_refix_(.+)")
            if attr then
                obj:mark_attrib_refix_dirty(attr)
            end
        end
    end
end

function base:get_refix(imp, key, args, obj)
    local fn = string.format("get_refix_%s", key)
    local f = self[fn]
    if f then
        return f(self, imp, args, obj)
    end
end

function base:on_impact_get_combat_result()

end

function base:on_be_heal()

end

function base:on_active()

end

function base:refix_skill()

end

function base:refix_skill_launch_rate()

end

function base:on_use_skill_success_fully()

end

function base:on_be_critical_hit()

end

function base:on_critical_hit_target()

end

function base:on_hit_target()

end

function base:on_damages()

end

function base:on_damage_target()

end

function base:on_fade_out()

end

function base:refix_impact()

end

function base:on_die()

end

function base:on_logic_move()

end

function base:on_filtrate_impact()

end

function base:refix_critical_rate(imp, critical_rate)
    return critical_rate
end

function base:refix_power_by_rate(imp)
    return false
end

function base:refix_skill_power_by_rate()
    return false
end

function base:special_heart_beat_check()
    return true
end

function base:on_interval_over()

end

function base:on_call_up_pet_success()

end

function base:interval_calc(imp, obj, delta_time)
    local elapsed = imp:get_interval_elpased()
    local continuance = imp:get_continuance()
    if delta_time > continuance and 0 <= continuance then
        delta_time = continuance
    end
    elapsed = elapsed + delta_time
    local interval = imp:get_interval()
    if interval > 0 then
        while (elapsed >= interval)
        do
            self:on_interval_over(imp, obj)
            elapsed = elapsed - interval
        end
        imp:set_interval_elpased(elapsed)
    end
end

function base:continuance_cal(imp, obj, delta_time)
    local continuance = imp:get_continuance()
    local elapsed = imp:get_continuance_elapsed()
    if imp:get_is_over_timed() then
        if continuance == -1 then
            return
        end
        if elapsed <= continuance then
            elapsed = elapsed + delta_time
        end
        --print("elapsed =", elapsed, ";continuance =", continuance)
        if elapsed > continuance then
            obj:on_impact_fade_out(imp)
            obj:remove_impact(imp)
        else
            imp:set_continuance_elapsed(elapsed)
        end
    end
end

function base:critical_refix(imp)

end

function base:continuance_refix(imp)

end

function base:refix_miss_rate()
    return 0
end

function base:target_refix_accuracy_rate()
    return 0
end

function base:on_skill_miss()

end

function base:forbidden_this_skill()
    return false
end

function base:is_support_still_on(imp, obj)
    local caster_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_id)
    if sender == nil then
        return false
    end
    if not sender:is_character_obj() then
        return false
    end
    if not sender:is_alive() then
        return false
    end
    if not actionenginer:is_channel(sender) then
        return false
    end
    return true
end

function base:reduce_continuance(imp,obj_me, reduce_time)
    self:continuance_cal(imp, obj_me, reduce_time)
end

function base:heart_beat(imp, obj_me, delta_time)
    local continue = true
    local is = imp:is_need_channel_support()
    --print("is_need_channel_support =", is)
    if is then
        is = self:is_support_still_on(imp, obj_me)
        if not is then
            continue = false
        end
    end
    if not obj_me:is_alive() then
        if not imp:is_remain_on_corpse() then
            continue = false
        end
    end
    if not self:special_heart_beat_check(imp, obj_me) then
        continue = false
    end
    if continue then
        if imp:get_is_over_timed() then
            if self:is_intervaled() then
                self:interval_calc(imp, obj_me, delta_time)
            end
            self:continuance_cal(imp, obj_me, delta_time)
        end
    else
        obj_me:on_impact_fade_out(imp)
        obj_me:remove_impact(imp)
    end
end

function base:register_active_obj(obj, sender, delaytime, skill_id)
    local scene = sender:get_scene()
    local eventenginer = scene:get_event_enginer()
    return eventenginer:register_active_special_obj_event(obj:get_obj_id(), sender, delaytime, skill_id)
end
function base:on_health_increment(imp,hp_modifys)

end
function base:on_damages_back(imp, obj, damage_value,tarobj,is_critical)

end
function base:on_die_check()

end
function base:get_refix_key_value()
	return 0
end
function base:set_refix_key_value()

end
function base:get_attack_phy()
    return 0
end

function base:set_attack_phy()

end

function base:get_attack_magic()
    return 0
end

function base:set_attack_magic()
end

function base:get_attack_cold()
    return 0
end

function base:set_attack_cold()
end

function base:get_attack_fire()
    return 0
end

function base:set_attack_fire()
end

function base:get_attack_light()
    return 0
end

function base:set_attack_light()
end

function base:get_attack_posion()
    return 0
end

function base:set_attack_posion()
end

function base:get_attack_direct()
    return 0
end

function base:set_attack_direct()
end


function base:get_damage_phy()
    return 0
end

function base:set_damage_phy()
end

function base:get_damage_magic()
    return 0
end

function base:set_damage_magic()
end

function base:get_damage_cold()
    return 0
end

function base:set_damage_cold()
end

function base:get_damage_fire()
    return 0
end

function base:set_damage_fire()
end

function base:get_damage_light()
    return 0
end

function base:set_damage_light()
end

function base:get_damage_posion()
    return 0
end

function base:set_damage_posion()
end

function base:get_damage_direct()
    return 0
end

function base:set_damage_direct()
end





function base:set_trigger_index()
end

function base:get_trigger_index()
    return 0
end

function base:get_value_of_damage_up()
    return 0
end

function base:set_value_of_damage_up()
end
function base:set_ignore_rate()
end
function base:set_refix_damage_percent()
end
function base:set_calculate_total_damage_taken()
end
function base:reset_calculate_total_damage_taken()
end

function base:broadcast_skill_hit_message(obj_me,hits,skill_id,target_pos)
    local ret = packet_def.GCTargetListAndHitFlags.new()
    ret.m_objID = obj_me:get_obj_id()
    ret.logic_count = obj_me:get_logic_count()
    ret.data_type = ret.enum_type.UNIT_USE_SKILL
    ret.skill_or_special_obj_id = skill_id
    ret.target_pos = target_pos
    ret.target_list = hits
    ret.size = #(ret.target_list)
    local scene = obj_me:get_scene()
    scene:broadcast(obj_me, ret, true)
end


function base:change_shenbing(obj_me,imp)
	local live_time = imp.params["live_time"] or 0
	if live_time > 0 then
		live_time = live_time * 1000
		imp.params["live_time"] = nil
		imp:set_continuance(live_time)
	end
	local Visual = imp.params["Visual"] or 0
	if Visual > 0 then
		obj_me:set_game_flag_key("sb_visual",Visual)
		obj_me:get_scene():broad_char_equioment(obj,define.HUMAN_EQUIP.HEQUIP_WEAPON)
	end
end
function base:empty_shenbing(obj_me)
	obj_me:set_game_flag_key("sb_visual",0)
	obj_me:get_scene():broad_char_equioment(obj,define.HUMAN_EQUIP.HEQUIP_WEAPON)
end

function base:on_be_hit()
end

function base:on_be_skill()
end

return base
