-- 白刃托身：借力返施(829)命中目标后，有X%概率给目标一个效果
-- 使目标下次受到自身借力返施的伤害提高35%，命中后消失，持续15秒
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_974 = class("std_talent_974", base)

function std_talent_974:on_hit_target(talent, level, sender, reciver, skill_id)
    if skill_id == 829 then
        local params = talent.params[level]
        local chance = params[1] or 0
        local n = math.random(100)
        if n <= chance then
            impactenginer:send_impact_to_unit(reciver, 63101, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

return std_talent_974
