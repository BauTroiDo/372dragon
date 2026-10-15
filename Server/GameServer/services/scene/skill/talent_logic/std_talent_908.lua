-- 怒剑随心：受到会心攻击时，心剑交融触发借力的几率提高至X%
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_908 = class("std_talent_908", base)

-- 心剑交融 logic_id=60(基础版) 或 534(扩展版)
local XINJIAN_LOGIC_ID_1 = 60
local XINJIAN_LOGIC_ID_2 = 534

function std_talent_908:on_be_critical_hit(talent, level, human, sender, skill_id)
    -- 遍历自身impacts，查找心剑交融状态
    local impacts = human:get_impact_list()
    local borrow_buff_id = -1
    for i = 1, #impacts do
        local imp = impacts[i]
        local lid = imp:get_logic_id()
        if lid == XINJIAN_LOGIC_ID_1 or lid == XINJIAN_LOGIC_ID_2 then
            local bid = imp.params["借力效果ID"] or -1
            if bid > 0 then
                borrow_buff_id = bid
            end
        end
    end
    if borrow_buff_id < 0 then return end
    local params = talent.params[level]
    local rate = params[1] or 0
    if math.random(100) <= rate then
        impactenginer:send_impact_to_unit(human, borrow_buff_id, human, 0, false, 0)
    end
end

return std_talent_908
