-- 弱柳凭风：心剑交融状态下，柳拂衣(812)攻击非玩家目标时，有X%概率触发借力效果
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_911 = class("std_talent_911", base)

-- 借力状态 logic_id=532
local BORROW_LOGIC_ID = 532
-- 心剑交融 logic_id=60(基础版) 或 534(扩展版)
local XINJIAN_LOGIC_ID_1 = 60
local XINJIAN_LOGIC_ID_2 = 534

function std_talent_911:on_hit_target(talent, level, human, target, skill_id)
    if skill_id ~= 812 then return end
    -- 目标必须是非玩家
    if target:get_obj_type() == "human" then return end
    -- 遍历自身impacts，查找心剑交融和借力状态
    local impacts = human:get_impact_list()
    local has_borrow = false
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
        if lid == BORROW_LOGIC_ID then
            has_borrow = true
        end
    end
    if borrow_buff_id < 0 then return end
    -- 已有借力状态则不再施加
    if has_borrow then return end
    local params = talent.params[level]
    local rate = params[1] or 0
    if math.random(100) <= rate then
        impactenginer:send_impact_to_unit(human, borrow_buff_id, human, 0, false, 0)
    end
end

return std_talent_911
