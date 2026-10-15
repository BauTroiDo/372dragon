-- 抱剑同酣：星河虹吸(832)额外召唤飞剑环绕目标
-- 每2秒对周围5米范围最多3个目标造成30%普攻伤害，有X%概率麻痹1秒
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_964 = class("std_talent_964", base)
local impacts = {19101, 19102, 19103, 19104, 19105}

function std_talent_964:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 832 then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        end
    end
end

return std_talent_964
