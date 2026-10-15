local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_008 = class("std_impact_008", base)

function std_impact_008:is_over_timed()
    return false
end

function std_impact_008:is_intervaled()
    return false
end

function std_impact_008:get_target_me_flag(imp)
    return imp.params["攻击还是回避；0：回避，1：攻击。"] == 1
end
function std_impact_008:on_active(imp, obj)
    local caster_id = imp:get_caster_obj_id()
    if obj:get_obj_type() == "monster" and obj:is_alive() then
        if self:get_target_me_flag(imp) then
            obj:get_ai():add_primary_enemy(caster_id)
        else
            obj:get_ai():change_primary_enemy(caster_id)
        end
    end
end

return std_impact_008
