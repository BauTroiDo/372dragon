local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_352 = class("std_impact_352", base)

function std_impact_352:is_over_timed()
    return true
end

function std_impact_352:is_intervaled()
    return true
end

function std_impact_352:get_refix_can_action_1(imp, args)
    args.replace = args.replace or 1
    if args.replace == 1 then
        local value = imp.params["可否使用任何技能（CanAction1标记，-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_352:get_refix_can_action_2(imp, args)
    args.replace = args.replace or 1
    if args.replace == 1 then
        local value = imp.params["可否使用任何技能（CanAction2标记,-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_352:get_refix_can_move(imp, args)
    args.replace = args.replace or 1
    if args.replace == 1 then
        local value = imp.params["可否移动（CanMove标记,-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_352:get_refix_unbreakable(imp, args)
    args.replace = args.replace or 0
    if args.replace == 0 then
        local value = imp.params["无敌否（Unbreakable标记,-1为无效）"]
        if value ~= define.INVAILD_ID then
            args.replace = value
        end
    end
end

function std_impact_352:is_unbreakable_impact(imp)
    local value = imp.params["无敌否（Unbreakable标记,-1为无效）"]
    return value == 1
end

function std_impact_352:get_refix_stealth_level(imp, args)
    args.replace = args.replace or 0
    local value = imp.params["隐身级别修正（0为无效）"]
    if value ~= 0 then
        args.replace = value > args.replace and value or args.replace
    end
end

function std_impact_352:is_stealth_impact(imp)
    local value = imp.params["隐身级别修正（0为无效）"]
    return value ~= 0
end

function std_impact_352:get_refix_detect_level(imp, args)
    args.replace = args.replace or 0
    local value = imp.params["反隐级别修正（0为无效）"]
    if value ~= 0 then
        args.replace = value > args.replace and value or args.replace
    end
end

function std_impact_352:get_refix_model_id(imp, args)
    local value = imp.params["变身ID(-1为无效)"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_352:get_refix_ride_model(imp, args)
    local value = imp.params["骑乘ID(-1为无效)"]
    if value ~= define.INVAILD_ID then
        args.replace = value
    end
end

function std_impact_352:get_refix_speed(imp, args)
    local value = imp.params["移动速度修正%（0为无效）"]
    args.rate = (args.rate or 0) + value
end

function std_impact_352:get_value_of_refix_speed(imp)
    local value = imp.params["移动速度修正%（0为无效）"] or 0
    return value
end

function std_impact_352:set_value_of_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_352:set_refix_speed(imp, value)
    imp.params["移动速度修正%（0为无效）"] = value
end

function std_impact_352:get_refix_reduce_def_fire_low_limit(imp, args)
    local value = imp.params["火减抗下限"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_352:set_value_of__refix_reduce_def_fire_low_limit(imp, value)
    imp.params["火减抗下限"] = value
end

function std_impact_352:on_active(imp, obj)
    if obj:get_obj_type() == "human" then
        obj:send_refresh_attrib()
    end
    if imp:get_stand_flag() == define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_AMITY and self:is_unbreakable_impact(imp) then
        obj:dispel_hostility_impact()
    end
end

function std_impact_352:get_damage_interval_value(imp)
    return imp.params["伤害数值"] or 0
end

function std_impact_352:set_value_of_interval_damage(imp, value)
    imp.params["伤害数值"] = value
end

function std_impact_352:on_interval_over(imp, obj)
    if not obj:is_alive() then
        return
    end
    local value = self:get_damage_interval_value(imp)
    if value == 0 then
        return
    end
    if imp:get_caster_obj_id() == obj:get_obj_id() then
        return
    end
    local caster_obj = obj:get_scene():get_obj_by_id(imp:get_caster_obj_id())
    local damage = -1 * math.abs(value)
    obj:health_increment(damage, caster_obj, false)
end

return std_impact_352