local class = require "class"
local define = require "define"
local impact = require "scene.skill.impact"
local impactenginer = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_332 = class("std_impact_332", base)

function std_impact_332:is_over_timed()
    return true
end

function std_impact_332:is_intervaled()
    return false
end

function std_impact_332:get_accuracy_rate_up(imp)
    return imp.params["指定技能命中率+"] or 0
end


function std_impact_332:get_specific_skill_id(imp)
    return imp.params["指定技能ID"] or define.INVAILD_ID
end

function std_impact_332:refix_skill(imp, obj, skill_info)
    if self:get_specific_skill_id(imp) == skill_info:get_skill_id() then
        local rate_up = self:get_accuracy_rate_up(imp)
        local accuracy_up_rate = skill_info:get_accuracy_rate_up()
        skill_info:set_accuracy_rate_up(accuracy_up_rate + rate_up)
    end
end

return std_impact_332