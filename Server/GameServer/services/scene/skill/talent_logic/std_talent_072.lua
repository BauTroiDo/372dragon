local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_072 = class("std_talent_072", base)
local specific_skill_id = 394

function std_talent_072:get_continuance_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_072:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if skill_id == specific_skill_id then
        local value = self:get_continuance_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            value = value * 1000
            logic:continuance_refix(imp, value)
        end
    end
end

return std_talent_072