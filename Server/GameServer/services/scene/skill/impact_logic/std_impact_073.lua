local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_073 = class("std_impact_073", base)

function std_impact_073:is_over_timed()
    return true
end

function std_impact_073:is_intervaled()
    return false
end

function std_impact_073:get_refix_speed(imp, args, obj)
    local value = 0
    if obj:get_obj_type() == "human" and obj:get_ride_model() ~= define.INVAILD_ID then
        value = 20
    end
    args.rate = (args.rate or 0) + value
end

function std_impact_073:on_active(_, obj)
    if obj:get_obj_type() == "human" then
        obj:send_refresh_attrib()
    end
end

return std_impact_073