local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_011 = class("std_impact_011", base)

function std_impact_011:is_over_timed()
    return true
end

function std_impact_011:is_intervaled()
    return false
end

function std_impact_011:get_refix_attrib_att_physics(imp, args)
    local value = imp.params["物理攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["物理攻击百分比+"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_011:get_value_of_refix_attrib_att_physics(imp)
    return imp.params["物理攻击+"] or 0
end

function std_impact_011:set_value_of_refix_attrib_att_physics(imp, value)
    imp.params["物理攻击+"] = value
end

function std_impact_011:get_refix_attrib_def_physics(imp, args)
    local value = imp.params["物理防御+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    value = imp.params["物理防御百分比+"] or 0
    args.rate = (args.rate or 0) + value
end

function std_impact_011:get_value_of_refix_attrib_def_physics(imp)
    return imp.params["物理防御+"] or 0
end

function std_impact_011:set_value_of_refix_attrib_def_physics(imp, value)
    imp.params["物理防御+"] = value
end

function std_impact_011:set_rate_of_refix_attrib_def_physics(imp, rate)
    imp.params["物理防御百分比+"] = rate
end

function std_impact_011:get_refix_attrib_att_magic(imp, args)
    local value = imp.params["魔法攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["魔法攻击百分比+"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_011:get_value_of_refix_attrib_att_magic(imp)
    return imp.params["魔法攻击+"] or 0
end

function std_impact_011:set_value_of_refix_attrib_att_magic(imp, value)
    imp.params["魔法攻击+"] = value
end

function std_impact_011:get_refix_attrib_def_magic(imp, args)
    local value = imp.params["魔法防御+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
    local rate = imp.params["魔法防御+%"] or imp.params["魔法防御百分比+"]  or 0
    args.rate = (args.rate or 0) + rate
end

function std_impact_011:get_value_of_refix_attrib_def_magic(imp)
    return imp.params["魔法防御+"] or 0
end

function std_impact_011:set_value_of_refix_attrib_def_magic(imp, value)
    imp.params["魔法防御+"] = value
end

function std_impact_011:set_rate_of_refix_attrib_def_magic(imp, rate)
    imp.params["魔法防御+%"] = rate
end

function std_impact_011:get_refix_att_cold(imp, args)
    local value = imp.params["冰系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value

    local rate = imp.params["冰系攻击修正%"] or 0
    rate = math.floor(rate)
    args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
end

function std_impact_011:get_refix_def_cold(imp, args)
    local value = imp.params["冰系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_refix_def_cold(imp)
    return imp.params["冰系抗性修正"] or 0
end

function std_impact_011:set_value_of_refix_def_cold(imp, value)
    imp.params["冰系抗性修正"] = value
end

function std_impact_011:get_refix_att_fire(imp, args)
    local value = imp.params["火系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value

    local rate = imp.params["火系攻击修正%"] or 0
    rate = math.floor(rate)
    args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
end

function std_impact_011:get_value_of_refix_att_fire(imp)
    return imp.params["火系攻击修正"] or 0
end

function std_impact_011:set_value_of_refix_att_fire(imp, value)
    imp.params["火系攻击修正"] = value
end

function std_impact_011:get_refix_def_fire(imp, args)
    local value = imp.params["火系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_refix_def_fire(imp)
    return imp.params["火系抗性修正"] or 0
end

function std_impact_011:set_value_of_refix_def_fire(imp, value)
    imp.params["火系抗性修正"] = value
end

function std_impact_011:get_refix_att_light(imp, args)
    local value = imp.params["电系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value

    local rate = imp.params["电系攻击修正%"] or 0
    rate = math.floor(rate)
    args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
end

function std_impact_011:get_refix_def_light(imp, args)
    local value = imp.params["电系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_refix_def_light(imp)
    return imp.params["电系抗性修正"] or 0
end

function std_impact_011:set_value_of_refix_def_light(imp, value)
    imp.params["电系抗性修正"] = value
end

function std_impact_011:get_refix_att_poison(imp, args)
    local value = imp.params["毒系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value

    local rate = imp.params["毒系攻击修正%"] or 0
    rate = math.floor(rate)
    args.item_point_refix_rate = (args.item_point_refix_rate or 0) + rate
end

function std_impact_011:get_refix_def_poison(imp, args)
    local value = imp.params["毒系抗性修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_refix_def_poison(imp)
    return imp.params["毒系抗性修正"] or 0
end

function std_impact_011:set_value_of_refix_def_poison(imp, value)
    imp.params["毒系抗性修正"] = value
end
function std_impact_011:get_increase_max_health(imp)
    return imp.params["MAX_HP修正"] or 0
end

function std_impact_011:set_adjust_max_health_ratio(imp,addvalue)
    local value = self:get_increase_max_health(imp)
	if value > 0 then
		addvalue = addvalue + 100
		value = math.ceil(value * addvalue / 100)
		imp.params["MAX_HP修正"] = value
	end
end

function std_impact_011:get_refix_hp_max(imp, args)
    local value = self:get_increase_max_health(imp)
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_refix_mp_max(imp, args)
    -- [2026-09-17] CYS: 40 dong logic 11 khong co o "MAX_MP修正" -> nil. Moi ham khac trong file
    -- deu `or 0`; thieu o day lam math.floor(nil) nem loi moi lan refresh thuoc tinh (vd impact
    -- 55181 银钩走蝎 keo dai ~28 phut -> hong ca phien va ca lan dang nhap sau).
    local value = imp.params["MAX_MP修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_refix_mind_defend(imp, args)
    local value = imp.params["会心防御修正%(0为无效)"] or 0
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
	value = imp.params["会心防御+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:set_value_of_refix_mind_defend(imp, rate)
    imp.params["会心防御修正%(0为无效)"] = rate
end

function std_impact_011:set_refix_mind_defend(imp, value)
    imp.params["会心防御+"] = value
end

function std_impact_011:get_refix_reduce_def_cold(imp, args)
    local value = imp.params["减少对方冰抗"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_reduce_def_cold(imp)
    return imp.params["减少对方冰抗"] or 0
end

function std_impact_011:set_value_of_reduce_def_cold(imp, value)
    imp.params["减少对方冰抗"] = value
end

function std_impact_011:get_refix_reduce_def_fire(imp, args)
    local value = imp.params["减少对方火抗"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_reduce_def_fire(imp)
    return imp.params["减少对方火抗"] or 0
end

function std_impact_011:set_value_of_reduce_def_fire(imp, value)
    imp.params["减少对方火抗"] = value
end

function std_impact_011:get_refix_reduce_def_light(imp, args)
    local value = imp.params["减少对方玄抗"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_reduce_def_light(imp)
    return imp.params["减少对方玄抗"] or 0
end

function std_impact_011:set_value_of_reduce_def_light(imp, value)
    imp.params["减少对方玄抗"] = value
end

function std_impact_011:get_refix_reduce_def_poison(imp, args)
    local value = imp.params["减少对方毒抗"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:get_value_of_reduce_def_poison(imp)
    return imp.params["减少对方毒抗"] or 0
end

function std_impact_011:set_value_of_reduce_def_poison(imp, value)
    imp.params["减少对方毒抗"] = value
end

function std_impact_011:get_refix_mind_attack(imp, args, obj)
    local value = imp.params["会心攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_011:continuance_refix(imp, value)
    local continuance = imp:get_continuance()
    continuance = continuance + value
    imp:set_continuance(continuance)
end

return std_impact_011