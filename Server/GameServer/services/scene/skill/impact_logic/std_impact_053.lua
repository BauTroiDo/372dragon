local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_053 = class("std_impact_053", base)

function std_impact_053:is_over_timed()
    return false
end

function std_impact_053:is_intervaled()
    return false
end

function std_impact_053:on_active(imp, obj)
    local cool_downs = obj:get_cool_downs()
    for id in pairs(cool_downs) do
        obj:set_cool_down(id, 0)
    end
end

return std_impact_053