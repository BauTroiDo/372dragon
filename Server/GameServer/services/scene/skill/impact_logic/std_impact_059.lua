local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_059 = class("std_impact_059", base)

function std_impact_059:is_over_timed()
    return true
end

function std_impact_059:is_intervaled()
    return false
end

function std_impact_059:get_refix_rage_regenerate(imp, obj, attrib, key)
end

function std_impact_059:get_refix_def_cold(imp, args)
    local value = imp.params["冰抗性修正"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_059:get_refix_def_fire(imp, args)
    local value = imp.params["火抗性修正"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_059:get_refix_def_light(imp, args)
    local value = imp.params["电抗性修正"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_059:get_refix_def_poison(imp, args)
    local value = imp.params["毒抗性修正"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_059:get_refix_hp_max(imp, args)
    local value = imp.params["最大生命修正"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

return std_impact_059