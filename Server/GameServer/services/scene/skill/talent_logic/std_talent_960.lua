-- 偶定花前：凌神式(835)有X%概率使目标定身2秒
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_960 = class("std_talent_960", base)

function std_talent_960:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 835 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            impactenginer:send_impact_to_unit(reciver, 63089, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

return std_talent_960
