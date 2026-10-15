local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_344 = class("std_impact_344", base)

function std_impact_344:is_over_timed()
    return true
end

function std_impact_344:is_intervaled()
    return false
end

function std_impact_344:get_refix_mind_attack(imp, args)
    local value = imp.params["降低会心百分比"] or 0
    value = math.floor(value)
    args.rate = (args.rate or 0) - value
end


return std_impact_344