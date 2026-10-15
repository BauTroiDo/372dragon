-- [FIX] 天赋772（妙德回天）：处于绝剑式(impact 412)期间，血量从高于50%降至50%以下时自动释放回天术
-- on_be_hit 中检查自身挂有 impact 412，且上一次hp>50%、本次hp<=50%，CD 30/25/20/15/10 秒
-- SectInfo第774行: skill_type=366, impact_id=412
-- SectDesc第774行: 参数 30/25/20/15/10（递减CD，单位秒）
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_772 = class("std_talent_772", base)

local WATCH_IMPACT_ID = 412  -- 绝剑式
local HEAL_SKILL_IMPACT_ID = 411  -- 回天术effect
local HP_THRESHOLD = 0.5  -- 50%血量触发线

function std_talent_772:get_cd(talent, level)
    local params = talent.params[level]
    return params and params[1] or 30
end

-- [FIX] on_be_hit: 有绝剑式buff时，血量穿越50%触发回天术，受CD限制
function std_talent_772:on_be_hit(talent, level, human, sender, skill)
    -- 检查自身是否处于绝剑式状态（impact 412）
    if not human:impact_have_impact_of_specific_impact_id(WATCH_IMPACT_ID) then
        return
    end
    -- 当前血量比例
    local max_hp = human:get_max_hp()
    if not max_hp or max_hp <= 0 then
        return
    end
    local cur_hp = human:get_hp()
    local hp_ratio = cur_hp / max_hp
    -- 只在血量<=50%时触发
    if hp_ratio > HP_THRESHOLD then
        return
    end
    -- CD 检查：上次触发时间
    local last = human:get_talent_trigger_time(talent.name)
    local now = os.time()
    local cd = self:get_cd(talent, level)
    if last ~= nil and now - last < cd then
        return
    end
    -- 记录触发时间并发送回天术effect给自身
    human:set_talent_trigger_time(talent.name)
    impactenginer:send_impact_to_unit(human, HEAL_SKILL_IMPACT_ID, human, 0, false, 0)
end

return std_talent_772
