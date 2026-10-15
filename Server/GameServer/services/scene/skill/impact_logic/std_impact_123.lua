local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local impactenginer = require "impactenginer":getinstance()
local std_impact_123 = class("std_impact_123", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_123:is_over_timed()
    return true
end

function std_impact_123:is_intervaled()
    return false
end

function std_impact_123:get_odds(imp)
    return imp.params["生效几率"]
end

function std_impact_123:get_ignore_rate(imp)
    return imp.params["伤害免疫率"]
end

function std_impact_123:get_target_beaing_rate(imp)
    return imp.params["为目标承受比率"] or 0
end

function std_impact_123:set_target_beaing_rate(imp,value)
    imp.params["为目标承受比率"] = value
end

function std_impact_123:get_target_range_limit(imp)
    return imp.params["目标距离限制"]
end

function std_impact_123:get_fade_out_effct(imp)
    return imp.params["消失时触发效果"]
end

function std_impact_123:cal_dist(p1, p2)
    return math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y))
end

function std_impact_123:on_damages(imp, obj, damages)
	if damages and damages.damage_rate then
		local percent = self:get_ignore_rate(imp)
		if percent > 0 then
			if percent >= 100 then
				damages.flag_immu = true
				return
			end
			damages.imm_dmg_rate = (damages.imm_dmg_rate or 0) + percent
		end
		local idx = DAMAGE_TYPE_BACK[1]
		table.insert(damages[idx],imp)
	end
    -- local hp_damage = damages.hp_damage
    -- local caster_obj_id = imp:get_caster_obj_id()
    -- local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    -- local num = math.random(100)
    -- if num > self:get_odds(imp) then
        -- return
    -- end
    -- if sender == nil then
        -- return
    -- end
    -- if caster_obj_id ~= obj:get_obj_id() then
        -- local range_limit = self:get_target_range_limit(imp)
        -- local my_pos = obj:get_world_pos()
        -- local sender_pos = sender:get_world_pos()
        -- local range = self:cal_dist(my_pos, sender_pos)
        -- if range > range_limit then
            -- return
        -- end
    -- end
    -- local ignore_damage = math.ceil(hp_damage * self:get_ignore_rate(imp) / 100)
    -- if caster_obj_id ~= obj:get_obj_id() then
        -- local rate = self:get_target_beaing_rate(imp)
        -- local bearing = math.ceil(ignore_damage * rate / 100)
		-- ignore_damage = ignore_damage - bearing
        -- sender:health_increment(-1 * bearing, nil, false)
    -- end
    -- damages.hp_damage = damages.hp_damage - ignore_damage
end

function std_impact_123:on_damages_back(imp, obj, damage_value,tarobj,is_critical)
	if damage_value <= 0 then
		return 0
	end
	local selfId = obj:get_obj_id()
    local caster_obj_id = imp:get_caster_obj_id()
	if selfId ~= caster_obj_id then
		local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
		if not sender then
			return 0
		end
		local num = math.random(100)
		if num > self:get_odds(imp) then
			return 0
		end
		local range_limit = self:get_target_range_limit(imp)
		local my_pos = obj:get_world_pos()
		local sender_pos = sender:get_world_pos()
		local range = self:cal_dist(my_pos, sender_pos)
		if range > range_limit then
			return 0
		end
		local ignore_damage = math.ceil(damage_value * self:get_ignore_rate(imp) / 100)
		local rate = self:get_target_beaing_rate(imp)
		local bearing = math.ceil(ignore_damage * rate / 100)
		sender:health_increment(-1 * bearing, tarobj, is_critical)
		sender:show_skill_missed(sender:get_obj_id(),caster_obj_id,imp:get_skill_id(),sender:get_logic_count(),define.MISS_FLAG.FLAG_ABSORB)
		return ignore_damage
	end
	return 0
end

function std_impact_123:on_health_increment(imp,hp_modifys)
	local percent = self:get_ignore_rate(imp)
	if percent > 0 then
		if percent >= 100 then
			hp_modifys.flag_immu = true
			return
		end
		hp_modifys.imm_dmg_rate = hp_modifys.imm_dmg_rate + percent
	end
end

function std_impact_123:on_fade_out(imp, obj)
    if not obj:is_alive() then
        return
    end
    local value = self:get_fade_out_effct(imp)
    impactenginer:send_impact_to_unit(obj, value, obj, 0, imp:is_critical_hit(), self:refix_power_by_rate(imp))
end

return std_impact_123