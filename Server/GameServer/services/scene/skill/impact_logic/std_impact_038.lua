local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_038 = class("std_impact_038", base)

function std_impact_038:is_over_timed()
    return true
end

function std_impact_038:is_intervaled()
    return false
end

function std_impact_038:get_refix_pet_exp_multiple(imp, args)
    local value = imp.params["经验倍数(不设默认双倍)"] or 2
    args.point = (args.point or 0) + value
end

return std_impact_038