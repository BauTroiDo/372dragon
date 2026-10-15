local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_326 = class("std_impact_326", base)

function std_impact_326:is_over_timed()
    return true
end

function std_impact_326:is_intervaled()
    return false
end

function std_impact_326:get_refix_can_action_1(imp, args)
    local value = imp.params["可否使用任何技能（CanAction1标记，-1为无效）"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_can_action_2(imp, args)
    local value = imp.params["可否使用任何技能（CanAction2标记,-1为无效）"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_can_move(imp, args)
    local value = imp.params["可否移动（CanMove标记,-1为无效）"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_unbreakable(imp, args)
    local value = imp.params["无敌否（Unbreakable标记,-1为无效）"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_stealth_level(imp, args)
    local value = imp.params["隐身级别修正（0为无效）"]
    if value ~= 0 then
        args.replace = value
    end
end

function std_impact_326:is_stealth_impact(imp)
    local value = imp.params["隐身级别修正（0为无效）"]
    return value ~= 0
end

function std_impact_326:get_refix_detect_level(imp, args)
    local value = imp.params["反隐级别修正（0为无效）"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_model_id(imp, args)
    local value = imp.params["变身ID(-1为无效)"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_ride_model(imp, args)
    local value = imp.params["骑乘ID(-1为无效)"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_326:get_refix_speed(imp, args)
    local value = imp.params["移动速度修正%（0为无效）"]
    args.rate = (args.rate or 0) + value
end

function std_impact_326:get_value_of_refix_speed(imp)
    local value = imp.params["移动速度修正%（0为无效）"] or 0
    return value
end

function std_impact_326:set_value_of_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_326:set_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_326:on_active(_, obj)
    if obj:get_obj_type() == "human" then
        obj:send_refresh_attrib()
    end
end

function std_impact_326:on_fade_out(imp, obj_me)
    impactenginer:send_impact_to_unit(obj_me, 63003, obj_me, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
end

return std_impact_326