local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impact = require "scene.skill.impact"
local ModifyHpMpRageStrikePointByValue_T = require "scene.skill.impact_logic.std_impact_004"
local base = require "scene.skill.impact_logic.base"
local std_impact_089 = class("std_impact_089", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_089:is_over_timed()
    return true
end

function std_impact_089:is_intervaled()
    return false
end

function std_impact_089:get_activate_odds(imp)
    return imp.params["激发几率"]
end

function std_impact_089:get_reflec_rate(imp)
    return imp.params["伤害反弹率"]
end

function std_impact_089:on_damages(imp, obj, damages, caster_obj_id)
	if damages and damages.damage_rate then
		local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
		if not attacker then
			return
		end
		local odds = self:get_activate_odds(imp)
		local num = math.random(100)
		if num > odds then
			return
		end
		local reflect_rate = self:get_reflec_rate(imp)
		if reflect_rate > 0 then
			local idx = DAMAGE_TYPE_BACK[3]
			table.insert(damages[idx],{rate = reflect_rate})
		end
	end
    -- print("std_impact_089:on_damages", imp, obj, damages, caster_obj_id)
    -- local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
    -- print("attacker =", attacker)
    -- if attacker == nil then
        -- return
    -- end
    -- local odds = self:get_activate_odds(imp)
    -- local num = math.random(100)
    -- print("num =", num, ";odds =", odds)
    -- if num > odds then
        -- return
    -- end
    -- local reflect_rate = self:get_reflec_rate(imp)
    -- print("reflect_rate =", reflect_rate)
    -- if reflect_rate > 0 then
        -- local im = impact.new()
        -- im:clean_up()
        -- local reflect_damage = math.ceil(damages.hp_damage * reflect_rate / 100)
        -- impactenginer:init_impact_from_data(define.SYSTEM_USE_IMPACT_ID.IMP_NOTYPE_DAMAGE, im)
        -- local logic = ModifyHpMpRageStrikePointByValue_T
        -- reflect_damage = -1 * reflect_damage
        -- print("reflect_damage =", reflect_damage)
        -- logic:set_hp_modify(im, reflect_damage)

        -- eventenginer:register_impact_event(attacker, obj, im, 500, imp:get_skill_id())
    -- end
end


return std_impact_089