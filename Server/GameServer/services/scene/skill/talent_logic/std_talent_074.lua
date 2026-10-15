local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_074 = class("std_talent_074", base)

function std_talent_074:is_refix_impact_skill(skill_id)
    return skill_id == 382
end

function std_talent_074:get_refix_impact_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_074:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_refix_impact_skill(skill_id) then
        local value = self:get_refix_impact_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:add_odds(imp, value)
        end
    end
end

return std_talent_074