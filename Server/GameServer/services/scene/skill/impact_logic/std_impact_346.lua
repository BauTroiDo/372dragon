local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_346 = class("std_impact_346", base)

function std_impact_346:is_over_timed()
    return true
end

function std_impact_346:is_intervaled()
    return false
end

function std_impact_346:get_refix_mind_defend(imp, args)
    local value = imp.params["会心防御修正%（0为无效）"] or 0
    value = math.floor(value)
    args.rate = (args.rate or 0) + value
end

return std_impact_346