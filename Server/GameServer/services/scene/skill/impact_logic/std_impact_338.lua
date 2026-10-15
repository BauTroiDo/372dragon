local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_338 = class("std_impact_338", base)

function std_impact_338:is_over_timed()
    return true
end

function std_impact_338:is_intervaled()
    return false
end

function std_impact_338:get_die_give_owner_imp(imp)
    return imp.params["死亡时给主人效果"] or define.INVAILD_ID
end

function std_impact_338:on_die(imp, obj)
    if obj:get_obj_type() == "pet" then
        local value = self:get_die_give_owner_imp(imp)
        if value ~= define.INVAILD_ID then
            local owner = obj:get_owner()
            if owner then
                local impactenginer  = require "impactenginer":getinstance()
                impactenginer:send_impact_to_unit(owner, value, obj, 0, false)
            end
        end
    end
end

return std_impact_338