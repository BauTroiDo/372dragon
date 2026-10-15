-- 畏少年：气定六合(813)使目标获得状态，对自身造成的伤害减少X%，持续10秒
-- 影响目标减少为5个
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_967 = class("std_talent_967", base)
local impacts = {19143, 19144, 19145, 19146, 19147}

function std_talent_967:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 813 then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
        end
    end
end

return std_talent_967
