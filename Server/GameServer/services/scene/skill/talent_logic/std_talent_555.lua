local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_555 = class("std_talent_555", base)
local data_indexs = { 46028, 46029, 46030, 46031, 46032 }
function std_talent_555:is_specific_skill(skill_id)
    return skill_id == 481
end

function std_talent_555:get_send_impact(level)
    local impact_id = data_indexs[level] or define.INVAILD_ID
    return impact_id
end

function std_talent_555:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_555:on_critical_hit_target(talent_config, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local impact_id = self:get_send_impact(level)
        if impact_id ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
        end
    end
end

return std_talent_555