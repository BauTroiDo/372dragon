local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local std_impact_301 = class("std_impact_301", base)

function std_impact_301:is_over_timed()
    return true
end

function std_impact_301:is_intervaled()
    return false
end

function std_impact_301:get_refix_skill_group(imp)
    return imp.params["技能组ID"]
end

function std_impact_301:get_add_skill_launch_rate(imp)
    return imp.params["技能组ID"]
end

function std_impact_301:refix_skill_launch_rate(imp, args)
    local skill_id = args.id
    if skill_id == define.INVAILD_ID then
        return
    end
    local template = skillenginer:get_skill_template(skill_id)
    if template == nil then
        return
    end
    if template.group_id ~= self:get_refix_skill_group(imp) then
        return
    end
    local add_rate = self:get_add_skill_launch_rate(imp)
    args.value = args.value * (100 + add_rate) / 100
end

return std_impact_301