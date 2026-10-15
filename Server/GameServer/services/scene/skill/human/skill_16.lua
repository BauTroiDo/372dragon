local class = require "class"
local define = require "define"
local impactenginer  = require "impactenginer":getinstance()
local impact = require "scene.skill.impact"
local base = require "scene.skill.base"
local skill_16 = class("skill_16", base)

function skill_16:ctor()

end

function skill_16:get_transfer_impact(skill)
    local descriptor = skill:get_descriptor()
    return descriptor["回城术的效果"] or define.INVAILD_ID
end

function skill_16:effect_on_unit_once(obj_me)
    local ski = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local value = self:get_transfer_impact(ski)
    if value ~= define.INVAILD_ID then
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(value, imp)
        self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), false)
    end
end

return skill_16