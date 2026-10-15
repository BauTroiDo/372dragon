-- 来去如风：使用探营取将(技能817)后，自身获得30%加速，持续X秒
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_955 = class("std_talent_955", base)
local impacts = {19131, 19132, 19133, 19134, 19135}

function std_talent_955:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 817 then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        end
    end
end

return std_talent_955
