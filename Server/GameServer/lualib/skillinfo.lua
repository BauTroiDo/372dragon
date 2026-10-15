local class = require "class"
local define = require "define"
local skill_info = class("skill_info")

function skill_info:ctor(...)
    local template, data, level,effect_value = ...
    self.id = template.id
    self._cy_four_data_id = data.id
    self.level = level
    self.accuracy = template.accuracy
    self.critical_rate = template.critical_rate

    self.cool_down_time = data.cool_down_time
    self.cool_down_id = template.cool_down_id
    self.charge_time = data.charge_time
    self.channel_time = data.channel_time
    self.use_need_learnd = template.use_need_learnd

    self.menpai = template.menpai
    self.skill_classs = template.skill_class
    self.target_must_in_special_state = template.target_must_in_special_state
    self.select_type = template.select_type

    self.stand_flag = template.stand_flag
    self.party_only = template.party_only
    self.radious = template.radious
    self.target_count = template.target_count
    self.target_check_by_obj_type = template.target_check_by_obj_type
    self.target_logic_by_stand = template.target_logic_by_stand
    self.target_must_be_teammate = template.target_must_be_teammate
    self.charges_or_interval = template.charges_or_interval
    self.auto_shot_skill_flag = template.auto_shot_skill_flag
    self.delay_time = template.delay_time

    self.condition_and_deplete = table.clone(data.condition_and_deplete)

    self.target_level = data.target_level
    self.optimal_range_min = template.optimal_range_min
	self.optimal_range_max = template.optimal_range_max

    self.play_action_time = template.play_action_time

    self.percentage_of_distraction = template.percentage_of_distraction
    self.chance_of_interference = template.chance_of_interference
    self.percentage_of_disturbance_time_floats = template.percentage_of_disturbance_time_floats

    self.logic_id = data.logic_id
    self.skill_type = template.skill_type
    self.need_weapon_flag = template.need_weapon_flag
    self.targeting_logic = template.targeting_logic
    -- self.is_shenbing_skill = template.is_shenbing_skill
	
    self.descriptor = table.clone(data.descriptor)
    self.effect_damage = table.clone(data.effect_damage)

    self.impacts = table.clone(data.impacts)
    self.cy_raw_params = data.cy_raw_params -- server-impact (chỉ đọc)
    self.is_ignore_defence = false

    self.power_refix_by_rate = 0
    self.power_refix_by_value = 0

    self.time_refix_by_rate = 0
    self.time_refix_by_value = 0
    self.mind_attack = -1
	
end

function skill_info:get_accuracy()
    return self.accuracy
end

function skill_info:set_accuracy(accuracy)
    self.accuracy = accuracy
end

function skill_info:get_skill_id()
    return self.id
end

function skill_info:get_skill_level()
    return self.level
end

function skill_info:get_critical_rate()
    return self.critical_rate
end

function skill_info:set_critical_rate(rate)
    self.critical_rate = rate
end

function skill_info:get_cool_down_time()
    return self.cool_down_time
end

function skill_info:set_cool_down_time(cool_down_time)
    self.cool_down_time = cool_down_time
end

function skill_info:get_cool_down_id()
    return self.cool_down_id
end

function skill_info:get_charge_time()
    return self.charge_time
end

function skill_info:set_charge_time(charge_time)
    self.charge_time = charge_time
end

function skill_info:get_channel_time()
    return self.channel_time
end

function skill_info:set_channel_time(channel_time)
    self.channel_time = channel_time
end

function skill_info:get_menpai()
    return self.menpai
end

function skill_info:get_skill_classs()
    return self.skill_classs
end

function skill_info:get_target_must_in_special_state()
    return self.target_must_in_special_state
end

function skill_info:get_select_type()
    return self.select_type
end

function skill_info:get_stand_flag()
    return self.stand_flag
end

function skill_info:is_party_only()
    return self.party_only
end

function skill_info:get_radious()
    return self.radious
end

function skill_info:set_radious(radious)
    self.radious = radious
end

function skill_info:get_target_count()
    return self.target_count
end

function skill_info:set_target_count(target_count)
    self.target_count = target_count
end

function skill_info:get_target_check_by_obj_type()
    return self.target_check_by_obj_type
end

function skill_info:get_target_logic_by_stand()
    return self.target_logic_by_stand
end

function skill_info:get_target_must_be_teammate()
    return self.target_must_be_teammate
end

function skill_info:get_charges_or_interval()
    return self.charges_or_interval
end

function skill_info:get_delay_time()
    return self.delay_time
end

function skill_info:get_target_level()
    return self.target_level
end

function skill_info:get_optimal_range_min()
    return self.optimal_range_min
end

function skill_info:set_optimal_range_max(max)
    self.optimal_range_max = max
end

function skill_info:get_optimal_range_max()
    return self.optimal_range_max
end

function skill_info:get_play_action_time()
    return self.play_action_time
end

function skill_info:get_logic_id()
    return self.logic_id
end

function skill_info:set_logic_id(id)
    self.logic_id = id
end

function skill_info:get_skill_type()
    return self.skill_type
end

function skill_info:get_need_weapon_flag()
    return self.need_weapon_flag
end

function skill_info:is_auto_shot_skill()
    return self.auto_shot_skill_flag
end

function skill_info:get_targeting_logic()
    return self.targeting_logic
end

function skill_info:get_activate_once_impact_by_index(idx)
    local impact_effect_once = self.impacts.effect_once
    return impact_effect_once[idx]
end

function skill_info:set_activate_once_impact_by_index(idx, impact)
    self.impacts.effect_once[idx] = impact
end

function skill_info:get_activate_each_tick_impact_by_index(idx)
    local impact_effect_each_tick = self.impacts.effect_each_tick
    return impact_effect_each_tick[idx]
end

function skill_info:get_activate_once_effect_damages()
    return self.effect_damage
end

function skill_info:get_activate_once_impacts()
    return self.impacts.effect_once
end

function skill_info:set_activate_once_impacts_target(target)
    self.impacts.effect_once.target = target
end

function skill_info:get_attack_impact()
    return self.impacts.attack
end

function skill_info:get_give_self_impact()
	return self.impacts.give_self
end

function skill_info:set_give_self_impact_p(p)
    self.impacts.give_self.p = p
end

function skill_info:get_give_self_impact_index(index)
	return self.impacts.give_self[index] or define.INVAILD_ID
end

function skill_info:get_give_target_impact()
    return self.impacts.give_target
end

function skill_info:set_give_target_impact_p(p)
    self.impacts.give_target.p = p
end

function skill_info:set_give_target_impact_id(id)
    self.impacts.give_target.id = id
end

function skill_info:set_give_target_impact_index(index)
	return self.impacts.give_target[index] or define.INVAILD_ID
end

function skill_info:get_instant_transport_impact()
    return self.impacts.instant_transport
end

function skill_info:get_descriptor()
    return self.descriptor
end

function skill_info:get_descriptor_value(key)
    return self.descriptor[key]
end

function skill_info:set_is_ignore_defence(is)
    self.is_ignore_defence = is
end

function skill_info:get_is_ignore_defence()
    return self.is_ignore_defence
end

function skill_info:set_deplete_refix_by_value(value)
    self.deplete_refix_by_value = value
end

function skill_info:get_use_need_learnd()
    return self.use_need_learnd
end

function skill_info:get_power_refix_by_rate()
    return self.power_refix_by_rate
end

function skill_info:set_power_refix_by_rate(rate)
    self.power_refix_by_rate = rate
end

function skill_info:get_power_refix_by_value()
    return self.power_refix_by_value
end

function skill_info:set_power_refix_by_value(value)
    self.power_refix_by_value = value
end

function skill_info:get_time_refix_by_rate()
    return self.power_refix_by_rate
end

function skill_info:set_time_refix_by_rate(rate)
    self.time_refix_by_rate = rate
end

function skill_info:get_time_refix_by_value()
    return self.time_refix_by_value
end

function skill_info:set_time_refix_by_value(value)
    self.time_refix_by_value = value
end

function skill_info:set_accuracy_rate_up(rate_up)
    self.accuracy_rate_up = rate_up
end

function skill_info:get_accuracy_rate_up()
    return self.accuracy_rate_up or 0
end

function skill_info:set_mind_attack_rate_up(rate_up)
    self.mind_attack_rate_up = rate_up
end

function skill_info:get_mind_attack_rate_up()
    return self.mind_attack_rate_up or 0
end

function skill_info:get_chance_of_interference()
    return self.chance_of_interference or 0
end

function skill_info:get_percentage_of_distraction()
    return self.percentage_of_distraction or 0
end

function skill_info:get_percentage_of_disturbance_time_floats()
    return self.percentage_of_disturbance_time_floats or 0
end

function skill_info:get_condition_and_deplete()
    return self.condition_and_deplete
end

function skill_info:set_target_impact_miss()
    self.target_impact_miss = true
end

function skill_info:get_target_impact_miss()
    return self.target_impact_miss
end

function skill_info:get_consume_life_soul_data()
    return self.life_soul_data or {}
end

function skill_info:set_consume_life_soul_data(id,data)
    self.life_soul_data = self.life_soul_data or {}
	for _,impact in ipairs(data) do
		table.insert(self.life_soul_data,impact)
	end
end

function skill_info:get_consume_life_soul_count()
    return self.life_soul_count or 0
end

function skill_info:set_consume_life_soul_count(value)
    self.life_soul_count = value
end

function skill_info:get_deplete_by_type(deplete_type)
    for i = 1, define.CONDITION_AND_DEPLETE_TERM_NUMBER do
        local term = self.condition_and_deplete[i]
        if term then
            if term.type == deplete_type then
                return term
            end
        end
    end
end

return skill_info