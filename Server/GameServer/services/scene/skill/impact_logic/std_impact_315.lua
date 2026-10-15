local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_315 = class("std_impact_315", base)

function std_impact_315:is_over_timed()
    return true
end

function std_impact_315:is_intervaled()
    return false
end

function std_impact_315:get_value_of_refix_miss_rate(imp)
    return imp.params["闪避率+"] or 0
end

function std_impact_315:get_take_effect_count(imp)
    return imp.params["生效次数"] or 0
end

function std_impact_315:set_take_effect_count(imp, count)
    imp.params["生效次数"] = count
end

function std_impact_315:refix_miss_rate(imp, obj_me)
    return self:get_value_of_refix_miss_rate(imp)
end

function std_impact_315:on_skill_miss(imp, obj_me)
    if not obj_me then return end
    local count = self:get_take_effect_count(imp)
    count = count - 1
    self:set_take_effect_count(imp, count)
    if count <= 0 then
        if obj_me.on_impact_fade_out then
            obj_me:on_impact_fade_out(imp)
        end
        if obj_me.remove_impact then
            obj_me:remove_impact(imp)
        end
    end
end

return std_impact_315