-- 无量剑：心剑交融状态下，破天式(834)飞剑命中目标时
-- 若自身没有借力状态，则有50%概率使自己获得借力状态
-- 并减少借力返施(829)X秒的冷却时间
local class = require "class"
local skynet = require "skynet"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_953 = class("std_talent_953", base)

-- 借力状态 impact ID（StandardImpact ID=19001, logic_id=532）
local BORROW_IMPACT_ID = 69001 -- CS3c: dời khỏi 19001
-- 借力状态 logic_id=532（用于检测自身是否已有借力）
local BORROW_LOGIC_ID = 532
-- 心剑交融 logic_id=60(基础版) 或 534(扩展版)
local XINJIAN_LOGIC_ID_1 = 60
local XINJIAN_LOGIC_ID_2 = 534

function std_talent_953:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    skynet.error("[TALENT_953] on_damage_target called, skill_id=", skill_id, " level=", level)
    if skill_id ~= 834 then
        return
    end

    -- 检查自身是否有心剑交融状态，以及是否已有借力状态
    local impacts = sender:get_impact_list()
    local has_xinjian = false
    local has_borrow = false
    for i = 1, #impacts do
        local lid = impacts[i]:get_logic_id()
        if lid == XINJIAN_LOGIC_ID_1 or lid == XINJIAN_LOGIC_ID_2 then
            has_xinjian = true
        end
        if lid == BORROW_LOGIC_ID then
            has_borrow = true
        end
    end

    skynet.error("[TALENT_953] has_xinjian=", has_xinjian, " has_borrow=", has_borrow)
    if not has_xinjian then return end
    if has_borrow then return end

    -- 50%概率触发
    local rand = math.random(100)
    skynet.error("[TALENT_953] rand=", rand, " (need <=50 to trigger)")
    if rand > 50 then return end

    -- 施加借力状态（impact ID=19001）
    impactenginer:send_impact_to_unit(sender, BORROW_IMPACT_ID, sender, 0, false, 0)
    skynet.error("[TALENT_953] applied borrow impact ", BORROW_IMPACT_ID, " to sender")

    -- 减少借力返施(829)冷却时间
    local params = talent.params[level]
    local reduce_sec = params[1] or 0
    local reduce_ms = reduce_sec * 1000
    skynet.error("[TALENT_953] reduce_sec=", reduce_sec, " reduce_ms=", reduce_ms)
    if reduce_ms > 0 then
        local template = skillenginer:get_skill_template(829)
        if not template then
            skynet.error("[TALENT_953] skill 829 template not found!")
            return
        end
        local cd_id = template.cool_down_id
        local cur_cd = sender:get_cool_down_by_cool_down_id(cd_id)
        skynet.error("[TALENT_953] skill829 cool_down_id=", cd_id, " cur_cd=", cur_cd)
        if cur_cd and cur_cd > 0 then
            sender:update_cool_down_by_cool_down_id(cd_id, reduce_ms)
            skynet.error("[TALENT_953] cooldown reduced by ", reduce_ms, "ms")
        else
            skynet.error("[TALENT_953] skill 829 not on cooldown, skip reduce")
        end
    end
end

return std_talent_953
