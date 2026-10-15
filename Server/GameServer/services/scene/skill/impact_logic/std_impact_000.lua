local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_000 = class("std_impact_000", base)

function std_impact_000:is_over_timed()
    return false
end

function std_impact_000:is_intervaled()
    return false
end

function std_impact_000:on_active()
end

return std_impact_000