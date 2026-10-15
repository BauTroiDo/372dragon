-- 寂海生澜：释放门派控制技能或破天式飞剑命中目标后
-- 使自身造成的伤害提高X%，持续10秒
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_938 = class("std_talent_938", base)
local impacts = {19127, 19128, 19115, 19116, 19117}

-- 慕容控制技能集合：破天式(834)、凌神式(835)、行意步移(813)、剑锁江山(827)
local CONTROL_SKILLS = { [813]=true, [827]=true, [834]=true, [835]=true }

function std_talent_938:on_hit_target(talent, level, sender, reciver, skill_id)
    if CONTROL_SKILLS[skill_id] then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(sender, impact_id, sender, 0, false, 0)
        end
    end
end

return std_talent_938
