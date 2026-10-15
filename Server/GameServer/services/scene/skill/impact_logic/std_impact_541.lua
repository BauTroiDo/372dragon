-- 妄生颠倒：持续10秒的BUFF状态
-- 受到伤害时，若自身没有借力状态，则心剑交融必定触发借力效果
-- 且有25%概率减少借力返施(829)的冷却时间（减少量由params["CD减少量"]决定）
local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_541 = class("std_impact_541", base)

-- 借力状态 logic_id=532
local BORROW_LOGIC_ID = 532
-- 心剑交融 logic_id=60 或 534
local XINJIAN_LOGIC_ID_1 = 60
local XINJIAN_LOGIC_ID_2 = 534

function std_impact_541:is_over_timed()
    return true
end

function std_impact_541:is_intervaled()
    return false
end

function std_impact_541:get_cd_reduce_ms(imp)
    return imp.params["CD减少量"] or 0
end

function std_impact_541:get_trigger_rate(imp)
    return imp.params["触发概率"] or 25
end

-- 被攻击时触发
function std_impact_541:on_be_hit(imp, obj, sender, skill)
    if not sender then return end
    if not sender:is_alive() then return end
    -- 仅敌对来源触发
    if not obj:is_enemy(sender) then return end

    -- 遍历自身的impacts，查找心剑交融和借力状态
    local impacts = obj:get_impact_list()
    local has_xinjian = false
    local has_borrow = false
    local borrow_buff_id = -1

    for i = 1, #impacts do
        local cur_imp = impacts[i]
        local lid = cur_imp:get_logic_id()
        if lid == XINJIAN_LOGIC_ID_1 or lid == XINJIAN_LOGIC_ID_2 then
            has_xinjian = true
            borrow_buff_id = cur_imp.params["借力效果ID"] or -1
        end
        if lid == BORROW_LOGIC_ID then
            has_borrow = true
        end
    end

    -- 有心剑交融但没有借力状态：必定触发借力
    if has_xinjian and not has_borrow and borrow_buff_id > 0 then
        impactenginer:send_impact_to_unit(obj, borrow_buff_id, obj, 0, false, 0)
    end

    -- 25%概率减少借力返施(829)冷却
    local rate = self:get_trigger_rate(imp)
    if math.random(100) <= rate then
        local reduce_ms = self:get_cd_reduce_ms(imp)
        if reduce_ms > 0 then
            local template = skillenginer:get_skill_template(829)
            if template then
                obj:update_cool_down_by_cool_down_id(template.cool_down_id, reduce_ms)
            end
        end
    end
end

return std_impact_541
