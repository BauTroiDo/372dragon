-- 待时而动：彼行我释(技能825)释放后，恢复自身X%的血量
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_941 = class("std_talent_941", base)
local impacts = {19118, 19119, 19120, 19129, 19130}

function std_talent_941:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 825 then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        end
    end
end

return std_talent_941
