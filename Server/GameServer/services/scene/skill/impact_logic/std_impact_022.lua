local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local ModifyHpMpRageStrikePointByValue_T = require "scene.skill.impact_logic.std_impact_004"
local combat_core = require "scene.skill.combat_core"
local base = require "scene.skill.impact_logic.base"
local std_impact_022 = class("std_impact_022", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_022:is_over_timed()
    return true
end

function std_impact_022:is_intervaled()
    return false
end

function std_impact_022:get_activate_odds(imp)
    return imp.params["生效几率"]
end

function std_impact_022:set_activate_odds(imp, odds)
    imp.params["生效几率"] = odds
end

function std_impact_022:get_damage_count(imp)
    return imp.params["反击次数"]
end

function std_impact_022:get_reflec_rate(imp)
    return imp.params["伤害反弹率"]
end

-- function std_impact_022:get_reflec_rate(imp)
    -- return imp.params["伤害反弹率"]
-- end

function std_impact_022:get_absorb_rate(imp)
    return imp.params["吸血效率"]
end

function std_impact_022:on_damages(imp, obj, damages, caster_obj_id)
    local attacker = obj:get_scene():get_obj_by_id(caster_obj_id)
    if attacker == nil then
        return
    end
    local odds = self:get_activate_odds(imp)
    local num = math.random(100)
    if num > odds then
        return
    end
	if damages and damages.damage_rate then
		local idx = DAMAGE_TYPE_BACK[3]
		local damage_count = self:get_damage_count(imp)
		local reflec_rate = self:get_reflec_rate(imp)
		for i = 1, damage_count do
			table.insert(damages[idx],{rate = reflec_rate})
		end
		local recover_hp_rate = self:get_absorb_rate(imp)
		if recover_hp_rate > 0 then
			idx = DAMAGE_TYPE_BACK[4]
			table.insert(damages[idx],{rate = recover_hp_rate})
			damages.recover_hp_rate_enable = true
		end
    end
    -- local reflect_rate = self:get_reflec_rate(imp)
    -- if reflect_rate > 0 then
        -- for i = 1, damage_count do
            -- local im = impact.new()
            -- im:clean_up()
            -- local reflect_damage = math.ceil(damages.hp_damage * reflect_rate / 100)
            -- impactenginer:init_impact_from_data(define.SYSTEM_USE_IMPACT_ID.IMP_NOTYPE_DAMAGE, im)
            -- local logic = ModifyHpMpRageStrikePointByValue_T
            -- logic:set_hp_modify(im, -1 * reflect_damage)
            -- eventenginer:register_impact_event(attacker, obj, im, 500, define.INVAILD_ID)
        -- end
    -- end
end
-- function std_impact_022:on_damage_target(imp, obj, _, damages)
    -- local odd = self:get_activate_odds(imp)
    -- local num = math.random(100)
    -- if num > odd then
        -- return
    -- end
    -- local rate = self:get_absorb_rate(imp)
	-- damages.recover_hp_damage = (damages.recover_hp_damage or 0) + rate
    -- -- local absorb_hp = math.ceil(damages.hp_damage * rate / 100)
    -- -- obj:health_increment(absorb_hp, obj,false)
-- end

return std_impact_022