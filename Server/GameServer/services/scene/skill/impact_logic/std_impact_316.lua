local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.impact_logic.base"
local std_impact_316 = class("std_impact_316", base)
local DAMAGE_TYPE_POINT = DI_DamagesByValue_T.enum_DAMAGE_TYPE_POINT
function std_impact_316:is_over_timed()
    return true
end

function std_impact_316:is_intervaled()
    return false
end

function std_impact_316:get_hp_max_damage_rate(imp)
    return imp.params["附加生命值百分比伤害"] or 0
end

function std_impact_316:set_hp_max_damage_rate(imp, rate)
    imp.params["附加生命值百分比伤害"] = rate
end

function std_impact_316:get_take_effect_count(imp)
    return imp.params["需要伤害次数"] or 0
end

function std_impact_316:set_take_effect_count(imp, count)
    imp.params["需要伤害次数"] = count
end

function std_impact_316:get_collection_id(imp)
    return imp.params["技能集合ID"]
end

function std_impact_316:get_refix_key_value(imp,key)
    return imp.params[key] or 0
end

function std_impact_316:set_refix_key_value(imp,key,value)
    imp.params[key] = value
end


function std_impact_316:on_damages(imp, reciver, damages, caster_obj_id, is_critical, skill_id)
    local collection_id = self:get_collection_id(imp)
    local in_collection = skillenginer:is_skill_in_collection(skill_id, collection_id)
    if in_collection then
        local count = self:get_take_effect_count(imp)
        count = count - 1
        if count <= 0 then
            local sender = reciver:get_scene():get_obj_by_id(caster_obj_id)
            if sender then
                local hp_max = sender:get_max_hp()
                local percent = self:get_hp_max_damage_rate(imp)
                local damage = hp_max * percent / 100
				local reduce_damage = self:get_refix_key_value(imp,"reduce_damage")
				if reduce_damage > 0 then
					reduce_damage = 100 - reduce_damage
					damage = damage * reduce_damage / 100
				end
				if damages and damages.mp_damage then
					local idx = DAMAGE_TYPE_POINT[7]
					damages[idx] = damages[idx] + damage
				end
                -- damages.hp_damage = damages.hp_damage + damage
                reciver:on_impact_fade_out(imp)
                reciver:remove_impact(imp)
				if damage > 0 then
					-- local mind_attack = sender:get_mind_attack()
					local position = reciver:get_world_pos()
					local radious = 5
					local operate = {
						obj = sender,
						x = position.x, y = position.y,
						radious = radious, target_logic_by_stand = 1,
						check_can_view = true
					}
					local nearbys = sender:get_scene():scan(operate)
					local newhp_modify
					local hitcount = 0
					local targetId = reciver:get_obj_id()
					for _, nb in ipairs(nearbys) do
						if nb:is_character_obj(nb) then
						   if sender:is_enemy(nb) and nb:is_alive() and nb:get_obj_id() ~= targetId then
								newhp_modify = damage
								-- local mind_defend = nb:get_mind_defend()
								-- mind_defend = mind_defend == 0 and 1 or mind_defend
								-- local critical_rate = mind_attack / (mind_defend * 20)
								-- local rand = math.random(100)
								local is_critical = false
								-- if rand <= critical_rate * 100 then
									-- is_critical = true
									-- newhp_modify = wk_bj * 2
								-- end
								nb:health_increment(newhp_modify,obj_me,is_critical)
								hitcount = hitcount + 1
								if hitcount >= 4 then
									break
								end
						   end
						end
					end
				end
            end
        else
            self:set_take_effect_count(imp, count)
        end
    end
end

return std_impact_316