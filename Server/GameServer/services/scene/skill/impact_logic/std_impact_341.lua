local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_341 = class("std_impact_341", base)

function std_impact_341:is_over_timed()
    return true
end

function std_impact_341:is_intervaled()
    return false
end

function std_impact_341:get_impact_id(imp)
    return imp.params["致命一击获得效果"] or define.INVAILD_ID
end

function std_impact_341:on_be_critical_hit(imp, obj_me)
    local value = self:get_impact_id(imp)
    if value ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(obj_me, value, obj_me, 0, false, 0)
        obj_me:on_impact_fade_out(imp)
        obj_me:remove_impact(imp)
    end
end

return std_impact_341