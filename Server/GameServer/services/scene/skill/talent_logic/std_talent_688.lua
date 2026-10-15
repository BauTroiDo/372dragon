local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_688 = class("std_talent_688", base)
local impacts = {
    51625, 51626, 51627, 51628, 51629
}

function std_talent_688:is_specific_skill(skill_id)
    return skill_id == 305
end

function std_talent_688:get_give_impact(level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_688:refix_impact(talent, level, imp, sender, reciver)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local impact = self:get_give_impact(level)
        if impact ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
        end
    end
end

return std_talent_688