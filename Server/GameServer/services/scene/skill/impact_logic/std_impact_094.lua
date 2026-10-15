local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_094 = class("std_impact_094", base)

function std_impact_094:is_over_timed()
    return true
end

function std_impact_094:is_intervaled()
    return false
end

function std_impact_094:get_refix_reduce_def_cold(imp, args)
    local value = imp.params["减少对方冰抗"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_094:get_refix_reduce_def_fire(imp, args)
    local value = imp.params["减少对方火抗"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_094:get_refix_reduce_def_light(imp, args)
    local value = imp.params["减少对方玄抗"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_094:get_refix_reduce_def_poison(imp, args)
    local value = imp.params["减少对方毒抗"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

return std_impact_094