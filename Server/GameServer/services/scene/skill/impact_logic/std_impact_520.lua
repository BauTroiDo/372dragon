local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_520 = class("std_impact_520", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_impact_520:is_over_timed()
    return true
end

function std_impact_520:is_intervaled()
    return false
end

function std_impact_520:get_absorb_rate(imp)
    return imp.params["伤害吸收率"] or 0
end

function std_impact_520:get_shield_hp(imp)
    return imp.params["护盾生命值"] or 0
end

function std_impact_520:set_shield_hp(imp, hp)
    imp.params["护盾生命值"] = hp
end

-- function std_impact_520:on_active(imp, obj)

-- end
function std_impact_520:on_damages(imp, obj, damages, caster_obj_id)
    local shield_hp = self:get_shield_hp(imp)
	if shield_hp > 0 then
		if damages and damages.damage_rate then
			local idx = DAMAGE_TYPE_BACK[1]
			table.insert(damages[idx],imp)
		end
	else
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
	end
end

function std_impact_520:on_damages_back(imp, obj, damage_value)
	if damage_value <= 0 then
		return 0
	end
    local shield_hp = self:get_shield_hp(imp)
    local absorb_rate = self:get_absorb_rate(imp)
    local absorb_damage = math.floor(damage_value * absorb_rate / 100)
    absorb_damage = absorb_damage > shield_hp and shield_hp or absorb_damage
    shield_hp = shield_hp - absorb_damage
    if shield_hp > 0 then
        self:set_shield_hp(imp, shield_hp)
    else
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
    local caster_obj_id = imp:get_caster_obj_id()
	obj:show_skill_missed(obj:get_obj_id(),caster_obj_id,imp:get_skill_id(),obj:get_logic_count(),define.MISS_FLAG.FLAG_ABSORB)
	return absorb_damage
end

function std_impact_520:on_filtrate_impact(imp, obj_me, need_check_imp)
    local collection_id = 60
    if impactenginer:is_impact_in_collection(need_check_imp, collection_id) then
        return define.MissFlag_T.FLAG_IMMU
    end
    return false
end



return std_impact_520