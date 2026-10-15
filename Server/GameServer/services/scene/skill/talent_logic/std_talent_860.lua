-- [FIX] 天赋860（落英生花）：欺烟困雨(impact 521)期间，落英剑会心时概率 5/10/15/20/25% 在目标位置生成桃花阵effect
-- 钩子: on_critical_hit_target
-- 检查 reciver 身上是否有 impact 521（欺烟困雨），按参数概率对目标施加桃花阵effect（impact 521）
-- SectInfo第862行: talent_id=860, sect=8(逍遥), impact_id=521
-- SectDesc第862行: 参数 5/10/15/20/25
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_860 = class("std_talent_860", base)

local QIYAN_IMPACT_ID = 521  -- 欺烟困雨 impact

function std_talent_860:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- [FIX] 会心命中时：若目标身上有欺烟困雨(impact 521)，按概率发送桃花阵effect(impact 521)到目标
function std_talent_860:on_critical_hit_target(talent, level, sender, reciver, skill_id)
    if not reciver then return end
    if reciver:impact_have_impact_of_specific_impact_id(QIYAN_IMPACT_ID) then
        local odd = self:get_odd(talent, level)
        if math.random(100) <= odd then
            impactenginer:send_impact_to_unit(reciver, QIYAN_IMPACT_ID, sender, 0, false, 0)
        end
    end
end

return std_talent_860
