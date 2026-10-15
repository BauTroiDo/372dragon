-- 妄生颠倒：使用星河虹吸(832)后自身获得一个状态
-- 受到伤害时，若自身没有借力状态，则心剑交融必定触发借力效果
-- 且有25%概率减少借力返施X秒冷却时间，持续10秒
local skynet        = require "skynet"
local class         = require "class"
local impactenginer = require "impactenginer":getinstance()
local base          = require "scene.skill.talent_logic.base"
local std_talent_973 = class("std_talent_973", base)

-- 各等级对应的impact ID（CD减少量：1/2/3/4/5秒）
local IMPACT_IDS = {63100, 63099, 63098, 63097, 63096} -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

function std_talent_973:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() == 832 then
        local impact_id = IMPACT_IDS[level]
        if impact_id then
            skynet.error("[TALENT_973] delivering impact_id=", impact_id, " level=", level)
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        else
            skynet.error("[TALENT_973] no impact_id for level=", level)
        end
    end
end

return std_talent_973
