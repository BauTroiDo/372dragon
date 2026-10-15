local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local std_impact_302 = class("std_impact_302", base)

function std_impact_302:is_over_timed()
    return true
end

function std_impact_302:is_intervaled()
    return false
end

function std_impact_302:get_trigger_skill_group(imp)
    return imp.params["技能组ID"]
end

function std_impact_302:get_add_odds(imp)
    return imp.params["增加生效几率"] or 0
end

function std_impact_302:refix_impact(imp, obj_me, need_refix_imp)
    local skill_id = need_refix_imp:get_skill_id()
    if skill_id == define.INVAILD_ID then
        return
    end
    local template = skillenginer:get_skill_template(skill_id)
    if template == nil then
        return
    end
    if template.group_id ~= self:get_trigger_skill_group(imp) then
        return
    end
    local add_odds = self:get_add_odds(imp)
    local logic = impactenginer:get_logic(need_refix_imp)
    local odds = logic:get_activate_odds(need_refix_imp)
    odds = odds + add_odds
    logic:set_activate_odds(need_refix_imp, odds)
end

return std_impact_302