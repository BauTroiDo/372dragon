local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_327 = class("std_impact_327", base)

function std_impact_327:is_over_timed()
    return true
end

function std_impact_327:is_intervaled()
    return false
end

function std_impact_327:get_refix_reduce_def_cold_low_limit(imp, args)
    local value = imp.params["减冰抗下限+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_327:get_refix_reduce_def_fire_low_limit(imp, args)
    local value = imp.params["减火抗下限+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_327:get_refix_reduce_def_light_low_limit(imp, args)
    local value = imp.params["减玄抗下限+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_327:get_refix_reduce_def_poison_low_limit(imp, args)
    local value = imp.params["减毒抗下限+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_327:on_active(_, obj)
    if obj:get_obj_type() == "human" then
        obj:send_refresh_attrib()
    end
end

return std_impact_327