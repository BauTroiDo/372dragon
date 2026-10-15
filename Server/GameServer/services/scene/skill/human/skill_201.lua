local class = require "class"
local define = require "define"
local configenginer = require "configenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local impact = require "scene.skill.impact"
local base = require "scene.skill.base"
local skill_201 = class("skill_201", base)

function skill_201:get_impact_by_key(skill_info, key)
    local descriptor = skill_info:get_descriptor()
    return descriptor[key] or define.INVAILD_ID
end

function skill_201:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local otype = obj_tar:get_obj_type()
    local o_key = "(人宠)"
    if otype == "monster" then
        o_key = "(怪)"
    end
    local exclude = math.random(4)
    local key = string.format("效果%d%s", exclude, o_key)
    local value = self:get_impact_by_key(skill_info, key)
    if value ~= define.INVAILD_ID then
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_tar, obj_me, imp, params:get_delay_time(), is_critical)
    end
end

return skill_201