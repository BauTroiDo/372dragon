local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_422 = class("std_talent_422", base)

function std_talent_422:is_specific_impact(impact_id)
    return impact_id == 3831
end

function std_talent_422:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_422:refix_impact(talent, level, imp, obj)
    if self:is_specific_impact(imp:get_impact_id()) then
        local caster_obj_id = imp:get_caster_obj_id()
        local scene = obj:get_scene()
        local caster_obj = scene:get_obj_by_id(caster_obj_id)
        if caster_obj then
            local max_hp = caster_obj:get_max_hp()
            local value = self:get_refix_value(talent, level)
            local recover_hp = math.ceil(max_hp * value / 100)
            caster_obj:health_increment(recover_hp, caster_obj, false)
        end
    end
end

return std_talent_422