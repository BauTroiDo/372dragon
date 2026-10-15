local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_056 = class("std_impact_056", base)

function std_impact_056:is_over_timed()
    return true
end

function std_impact_056:is_intervaled()
    return false
end

function std_impact_056:get_refix_attrib_att_physics(imp, args)
    local value = imp.params["物攻"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_attrib_def_physics(imp, args)
    local value = imp.params["物防"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_attrib_att_magic(imp, args)
    local value = imp.params["魔攻"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_attrib_def_magic(imp, args)
    local value = imp.params["魔防"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_attrib_hit(imp, args)
    local value = imp.params["命中+"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_attrib_miss(imp, args)
    local value = imp.params["闪避+"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_attrib_hit(imp, args)
    local value = imp.params["命中+"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_mind_attack(imp, args)
    local value = imp.params["会心攻击+"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_mind_defend(imp, args)
    local value = imp.params["会心防御+"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_056:get_refix_hp_max(imp, args)
    local value = imp.params["生命最大"]
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

return std_impact_056