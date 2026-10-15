local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"

-- 乘月返真：持续10秒的防控制BUFF
-- 受到部分控制效果时，减少该效果1秒持续时间（最低2秒）
-- 并有X%概率直接免疫该控制效果（免疫最多生效1次）
local std_impact_537 = class("std_impact_537", base)

-- 持续性效果（有持续时间，10秒）
function std_impact_537:is_over_timed()
    return true
end

-- 获取免疫概率参数（3/6/9/12/15，对应5级）
function std_impact_537:get_immune_odds(imp)
    return imp.params["免疫概率"] or 0
end

-- on_filtrate_impact：拦截控制效果
-- 返回 define.MissFlag_T.FLAG_IMMU 表示完全免疫
-- 返回 false 表示不拦截
function std_impact_537:on_filtrate_impact(imp, obj_me, need_check_imp)
    if not need_check_imp then return false end

    -- 只处理敌对控制效果
    if need_check_imp:get_stand_flag() ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then
        return false
    end

    -- 检查是否属于控制效果集合（collection_id=60）
    local collection_id = 60
    if not impactenginer:is_impact_in_collection(need_check_imp, collection_id) then
        return false
    end

    -- 尝试免疫（最多生效1次）
    if not imp.immune_used then
        local odds = self:get_immune_odds(imp)
        if odds > 0 and math.random(100) <= odds then
            imp.immune_used = true
            return define.MissFlag_T.FLAG_IMMU
        end
    end

    -- 未免疫：减少控制持续时间1秒（最低保留2秒）
    local cur_continuance = need_check_imp:get_continuance()
    local new_continuance = cur_continuance - 1000
    if new_continuance < 2000 then
        new_continuance = 2000
    end
    need_check_imp:set_continuance(new_continuance)

    return false
end

return std_impact_537
