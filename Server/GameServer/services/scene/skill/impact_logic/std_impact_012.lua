local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_012 = class("std_impact_012", base)

function std_impact_012:is_over_timed()
    return true
end

function std_impact_012:is_intervaled()
    return false
end

function std_impact_012:get_refix_attrib_att_physics(imp, args)
    local value = imp.params["物理攻击修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_value_of_refix_attrib_att_physics(imp)
    return imp.params["物理攻击修正率"] or 0
end

function std_impact_012:set_value_of_refix_attrib_att_physics(imp, value)
    imp.params["物理攻击修正率"] = value
end

function std_impact_012:get_refix_attrib_def_physics(imp, args)
    local value = imp.params["物理防御修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_value_of_refix_attrib_def_physics(imp)
    return imp.params["物理防御修正率"] or 0
end

function std_impact_012:set_value_of_refix_attrib_def_physics(imp, value)
    imp.params["物理防御修正率"] = value
end

function std_impact_012:get_refix_attrib_att_magic(imp, args)
    local value = imp.params["魔法攻击修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_value_of_refix_attrib_att_magic(imp)
    return imp.params["魔法攻击修正率"] or 0
end

function std_impact_012:set_value_of_refix_attrib_att_magic(imp, value)
    imp.params["魔法攻击修正率"] = value
end

function std_impact_012:get_refix_attrib_def_magic(imp, args)
    local value = imp.params["魔法防御修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_value_of_refix_attrib_def_magic(imp)
    return imp.params["魔法防御修正率"] or 0
end

function std_impact_012:set_value_of_refix_attrib_def_magic(imp, value)
    imp.params["魔法防御修正率"] = value
end

function std_impact_012:get_refix_att_cold(imp, args)
    local value = imp.params["冰系攻击修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_def_cold(imp, args)
    local value = imp.params["冰系抗性修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end


function std_impact_012:get_refix_att_fire(imp, args)
    local value = imp.params["火系攻击修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_def_fire(imp, args)
    local value = imp.params["火系抗性修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_att_light(imp, args)
    local value = imp.params["电系攻击修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_def_light(imp, args)
    local value = imp.params["电系抗性修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_att_poison(imp, args)
    local value = imp.params["毒系攻击修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_def_poison(imp, args)
    local value = imp.params["毒系抗性修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_refix_hp_max(imp, args)
    local value = imp.params["MAX_HP修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:get_value_of_refix_hp_max(imp)
    return imp.params["MAX_HP修正率"] or 0
end

function std_impact_012:set_value_of_refix_hp_max(imp, value)
    imp.params["MAX_HP修正率"] = value
end

function std_impact_012:get_refix_mp_max(imp, args)
    local value = imp.params["MAX_MP修正率"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_012:set_refix_mp_max(imp, value)
    imp.params["MAX_MP修正率"] = (imp.params["MAX_MP修正率"] or 0) + value
end

return std_impact_012