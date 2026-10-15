-- 山河不复：剑锁江山(技能827)会心时，触发散功的几率提升至X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_939 = class("std_talent_939", base)
local SANGONG_IMPACT_ID = 63016  -- 散功效果ID -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

function std_talent_939:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id ~= 827 then return end
    local params = talent.params[level]
    local chance = params[1] or 0
    if math.random(100) <= chance then
        impactenginer:send_impact_to_unit(reciver, SANGONG_IMPACT_ID, sender, 0, false, 0)
    end
end

return std_talent_939
