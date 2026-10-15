local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_035 = class("std_impact_035", base)

function std_impact_035:is_over_timed()
    return true
end

function std_impact_035:is_intervaled()
    return false
end

function std_impact_035:get_refix_is_fear(imp, args)
    args.replace = 1
end

function std_impact_035:on_active(imp, obj)
    if not obj:is_alive() then
        return
    end
    obj:get_ai():change_state("terror")
end

function std_impact_035:on_fade_out(imp, obj)
    if not obj:is_alive() then
        return
    end
    if obj:get_obj_type() == "human" then
        obj:get_ai():change_state("idle")
    else
        obj:get_ai():change_state("combat")
    end
end

return std_impact_035