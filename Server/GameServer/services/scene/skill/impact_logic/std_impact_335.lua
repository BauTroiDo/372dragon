local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_335 = class("std_impact_335", base)

function std_impact_335:is_over_timed()
    return true
end

function std_impact_335:is_intervaled()
    return false
end

function std_impact_335:get_inherit_attrib_physic_and_attrib_magics_rate(imp)
    return imp.params["继承内外功攻击比例"]
end

function std_impact_335:get_inherit_attrib_hit_rate(imp)
    return imp.params["继承命中比例"]
end

function std_impact_335:get_inherit_max_hp_rate(imp)
    return imp.params["继承血上限比例"]
end

function std_impact_335:get_refix_attrib_att_physics(imp, args, obj)
    local value = 0
    local owner = obj:get_owner()
    if owner then
        local rate = self:get_inherit_attrib_physic_and_attrib_magics_rate(imp)
        local owner_attrib_att_physics = owner:get_attrib("attrib_att_physics")
        value = math.ceil(owner_attrib_att_physics * (rate / 100))
    end
    args.point = (args.point or 0) + value
end

function std_impact_335:get_refix_attrib_att_magic(imp, args, obj)
    local value = 0
    local owner = obj:get_owner()
    if owner then
        local rate = self:get_inherit_attrib_physic_and_attrib_magics_rate(imp)
        local owner_attrib_att_magic = owner:get_attrib("attrib_att_magic")
        value = math.ceil(owner_attrib_att_magic * (rate / 100))
    end
    args.point = (args.point or 0) + value
end

function std_impact_335:get_refix_attrib_hit(imp, args, obj)
    local value = 0
    local owner = obj:get_owner()
    if owner then
        local rate = self:get_inherit_attrib_hit_rate(imp)
        local owner_attrib_hit = owner:get_attrib("attrib_hit")
        value = math.ceil(owner_attrib_hit * (rate / 100))
    end
    args.point = (args.point or 0) + value
end

function std_impact_335:get_refix_hp_max(imp, args, obj)
    local value = 0
    local owner = obj:get_owner()
    if owner then
        local rate = self:get_inherit_max_hp_rate(imp)
        local owner_max_hp = owner:get_max_hp()
        value = math.ceil(owner_max_hp * (rate / 100))
    end
    args.point = (args.point or 0) + value
end

return std_impact_335