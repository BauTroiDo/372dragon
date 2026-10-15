-- 白羽流星：破天式(logic_id=96)状态期间受到攻击时，有X‰概率额外召唤1把飞剑
-- 该效果每2秒最多触发1次
-- params[level][1] = 概率(千分比)，Lv1=60 Lv2=105 Lv3=165 Lv4=270 Lv5=435
local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local std_impact_096 = require "scene.skill.impact_logic.std_impact_096"
local std_talent_950 = class("std_talent_950", base)

-- 检查角色身上是否有破天式状态（logic_id == 96）
local function has_potianshi(human)
    local list = human:get_impact_list()
    for i = 1, #list do
        if list[i]:get_logic_id() == 96 then
            return true
        end
    end
    return false
end

function std_talent_950:on_be_hit(talent, level, human, sender, skill)
    -- 必须处于破天式状态才触发
    if not has_potianshi(human) then
        return
    end

    -- 2秒内置CD
    local last = human:get_talent_trigger_time(talent.name)
    local now = os.time()
    if last ~= nil and now - last < 2 then
        skynet.error("[TALENT_950] CD未到，跳过 last=", last, " now=", now)
        return
    end

    -- 概率判断（千分比）
    local params = talent.params[level]
    local chance = params and params[1] or 0
    local n = math.random(1000)
    skynet.error("[TALENT_950] on_be_hit level=", level, " chance=", chance, " roll=", n)
    if n > chance then
        return
    end

    -- 尝试召唤额外飞剑
    local ok = std_impact_096:create_extra_sword(human)
    skynet.error("[TALENT_950] create_extra_sword result=", ok)
    if ok then
        human:set_talent_trigger_time(talent.name)
    end
end

return std_talent_950
