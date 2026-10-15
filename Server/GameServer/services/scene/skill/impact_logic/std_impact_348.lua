local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_348 = class("std_impact_348", base)

function std_impact_348:is_over_timed()
    return true
end

function std_impact_348:is_intervaled()
    return false
end

function std_impact_348:get_refix_mind_attack(imp, args)
    local value = imp.params["会心攻击率+"] or 0
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

function std_impact_348:get_refix_attrib_hit(imp, args, obj)
    local value = imp.params["命中率+"] or 0
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end


return std_impact_348