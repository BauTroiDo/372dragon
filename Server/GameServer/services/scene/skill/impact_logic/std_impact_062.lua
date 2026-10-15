local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_062 = class("std_impact_062", base)

function std_impact_062:is_over_timed()
    return true
end

function std_impact_062:is_intervaled()
    return false
end

function std_impact_062:get_refix_can_ignore_disturb(imp, args)
    local value = (imp.params["是否忽略干扰"] or 0)
    args.replace = value
end
return std_impact_062