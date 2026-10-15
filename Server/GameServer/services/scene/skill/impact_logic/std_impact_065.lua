local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_064 = class("std_impact_064", base)

function std_impact_064:is_over_timed()
    return true
end

function std_impact_064:is_intervaled()
    return false
end

function std_impact_064:get_odds(imp)
    return imp.params["激发几率"]
end

function std_impact_064:get_strike_point_modify(imp)
    return imp.params["单次获得的连击点数目"]
end

function std_impact_064:get_refix_strike_point_max(imp, args)
    local value = imp.params["连击点上限修正"]
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_064:on_critical_hit_target(imp, obj)
    local odd = self:get_odds(imp)
    local num = math.random(100)
    if num > odd then
        return
    end
    local strike_point_modify = self:get_strike_point_modify(imp)
    obj:strike_point_increment(strike_point_modify, obj)
end

return std_impact_064