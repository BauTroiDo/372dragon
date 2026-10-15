local define = require "define"
local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_433 = class("std_talent_433", base)
local impacts = {
    45890, 45891, 45892, 45893, 45894
}
function std_talent_433:is_specific_skill(skill_id)
    return skill_id == 282
end

function std_talent_433:get_give_impact(talent, level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_433:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local impact = self:get_give_impact(talent, level)
        if impact ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact, sender, 0, false, 0)
        end
    end
end
return std_talent_433