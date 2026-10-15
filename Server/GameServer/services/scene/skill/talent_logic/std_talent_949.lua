-- 锁清风：破天式(834)飞剑额外造成30%减速，持续时间X秒
-- 同时目标无法使用除轻功外的位移技能
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_949 = class("std_talent_949", base)
local impacts = {19165, 19166, 19167, 19168, 19169}
local EXTRA_IMPACT = 63005  -- 禁止移动 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

function std_talent_949:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 834 then
        local impact_id = impacts[level]
        if impact_id then
            impactenginer:send_impact_to_unit(reciver, impact_id, sender, 0, false, 0)
            impactenginer:send_impact_to_unit(reciver, EXTRA_IMPACT, sender, 0, false, 0)
        end
    end
end

return std_talent_949
