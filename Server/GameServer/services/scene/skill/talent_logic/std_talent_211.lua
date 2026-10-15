local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_211 = class("std_talent_211", base)
local impacts = {
    44288, 44289, 44290, 44291, 44292
}
function std_talent_211:get_skill_config(skill_id)
    local config = self.skills[skill_id]
    return config
end

function std_talent_211:is_specific_skill(skill_id)
    return skill_id == 283
end

function std_talent_211:get_send_impact(level)
    return impacts[level] or define.INVAILD_ID
end

function std_talent_211:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local impact_id = self:get_send_impact(level)
        if impact_id ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
        end
    end
end

return std_talent_211