local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local std_impact_064 = class("std_impact_064", base)

function std_impact_064:is_over_timed()
    return true
end

function std_impact_064:is_intervaled()
    return false
end

function std_impact_064:get_activate_times(imp)
    return imp.params["激发次数"]
end

function std_impact_064:get_is_ignore_defence(imp)
    return imp.params["是否忽略目标防御"] == 1
end

function std_impact_064:set_is_ignore_defence(imp, is)
    imp.params["是否忽略目标防御"] = is
end

function std_impact_064:get_refix_attrib_att_physics(imp, args)
    local value = imp.params["物理攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_064:get_value_of_refix_attrib_att_physics(imp)
    return imp.params["物理攻击+"] or 0
end

function std_impact_064:set_value_of_refix_attrib_att_physics(imp, value)
    imp.params["物理攻击+"] = value
end

function std_impact_064:get_refix_attrib_att_magic(imp, args)
    local value = imp.params["魔法攻击+"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_064:get_value_of_refix_attrib_att_magic(imp)
    return imp.params["魔法攻击+"] or 0
end

function std_impact_064:set_value_of_refix_attrib_att_magic(imp, value)
    imp.params["魔法攻击+"] = value
end

function std_impact_064:get_refix_reduce_def_fire_low_limit(imp, args)
    local value = imp.params["火减抗下限"] or 0
    value = math.floor(value)
    args.point = (args.point or 0) + value
end

function std_impact_064:set_value_of__refix_reduce_def_fire_low_limit(imp, value)
    imp.params["火减抗下限"] = value
end

function std_impact_064:get_refix_attrib_hit(imp, args)
    -- local value = imp.params["命中+"] or 0
    -- value = math.floor(value)
    -- args.point = (args.point or 0) + value
    local rate = imp.params["命中+(%)"] or 0
    rate = math.floor(rate)
    args.rate = (args.rate or 0) + rate
end

function std_impact_064:set_value_of_refix_attrib_hit(imp,value)
    imp.params["命中+(%)"] = value
end

function std_impact_064:get_value_of_refix_attrib_hit(imp)
    return imp.params["命中+(%)"] or 0
end

function std_impact_064:on_hit_target(imp, sender, reciver, skill)
	self:set_value_of_refix_attrib_hit(imp,0)
end

function std_impact_064:refix_skill(imp, obj, skill_info)
    if self:get_is_ignore_defence(imp) then
        skill_info:set_is_ignore_defence(true)
    end
end

return std_impact_064