-- 白日神殇：重云掩日(823)触发虚弱状态时，有X%概率使目标受到内功伤害增加30%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_958 = class("std_talent_958", base)

function std_talent_958:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 823 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            impactenginer:send_impact_to_unit(reciver, 63088, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

return std_talent_958
