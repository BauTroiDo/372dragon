local class = require "class"
local base = require "scene.skill.impact_logic.base"
local std_impact_353 = class("std_impact_353", base)

function std_impact_353:is_over_timed()
    return true
end

function std_impact_353:is_intervaled()
    return false
end

function std_impact_353:get_refix_att_cold(imp, args, obj)
    local value = imp.params["冰系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_353:get_refix_att_fire(imp, args, obj)
    local value = imp.params["火系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_353:get_refix_att_light(imp, args, obj)
    local value = imp.params["电系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_353:get_refix_att_poison(imp, args, obj)
    local value = imp.params["毒系攻击修正"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_353:get_rate(imp)
    return imp.params["随机属性+(%)"] or 0
end

function std_impact_353:check_attr(imp, obj)
    if imp.params["当前属性"] then
        return
    end
    local keys = {"冰系攻击修正", "火系攻击修正", "电系攻击修正", "毒系攻击修正"}
    local e_keys = { "att_cold", "att_fire", "att_light", "att_poison"}
    local n = math.random(1, #keys)
    local key = keys[n]
    local e_key = e_keys[n]
    local value = obj:get_attrib(e_key) or 0
    value = math.ceil(value * (self:get_rate(imp)) / 100)
    imp.params[key] = value
    imp.params["当前属性"] = e_key
end

return std_impact_353