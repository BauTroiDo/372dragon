-- 常相见：持续性效果，使目标的65级门派技能进入全量冷却
-- 门派对照：0=少林836, 1=明教837, 2=丐帮838, 3=武当839, 4=峨眉840
--           5=星宿841, 6=大理842, 7=天山843, 8=逍遥844
--           10=曼陀845, 11=恶人846, 12=慕容833
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_540 = class("std_impact_540", base)

-- 门派ID → 65级技能ID
local MENPAI_SKILL_65 = {
    [0]  = 836,  -- 少林 易筋锻骨
    [1]  = 837,  -- 明教 纯阳无极
    [2]  = 838,  -- 丐帮 天下无狗
    [3]  = 839,  -- 武当 天外飞仙
    [4]  = 840,  -- 峨眉 九阴神爪
    [5]  = 841,  -- 星宿 化骨绵掌
    [6]  = 842,  -- 大理 少泽剑
    [7]  = 843,  -- 天山 同生共死
    [8]  = 844,  -- 逍遥 鲲跃北溟
    [10] = 845,  -- 曼陀山庄 弦弄花影
    [11] = 846,  -- 恶人谷 判指阴阳
    [12] = 833,  -- 慕容 化气式
}

function std_impact_540:is_over_timed()
    return true  -- 必须返回true匹配配置，使引擎走持续性效果分支
end

function std_impact_540:is_intervaled()
    return false
end

function std_impact_540:on_active(imp, obj)
    skynet.error("[IMP540] on_active ENTER obj=", obj and obj:get_obj_id() or "nil")
    if not obj then return end
    if not obj.get_menpai then return end

    local menpai = obj:get_menpai()
    if menpai == nil then return end

    local skill_id = MENPAI_SKILL_65[menpai]
    if not skill_id then
        skynet.error("[IMP540] no 65-skill for menpai=", menpai)
        return
    end

    local template = skillenginer:get_skill_template(skill_id)
    if not template then return end

    -- 从 SkillData 获取实际冷却时间
    local max_cd = 120000  -- 兜底值
    local data_id = skillenginer:get_skill_info_id_by_level(template, 1)
    if data_id then
        local data = skillenginer:get_skill_info(data_id)
        if data and data.cool_down_time and data.cool_down_time > 0 then
            max_cd = data.cool_down_time
        end
    end

    -- 设置服务端冷却：写入 cool_down_times[skill_id]
    obj:set_cool_down(skill_id, max_cd)
    skynet.error("[IMP540] set_cool_down skill=", skill_id, " cd=", max_cd, " menpai=", menpai)

    -- 覆盖 impact 持续时间，使客户端 debuff 图标倒计时匹配冷却时间
    imp:set_continuance(max_cd)

    -- 回读验证
    local verify_cd = obj.cool_down_times and obj.cool_down_times[tostring(skill_id)] or -999
    local verify_check = obj.is_skill_cool_down and obj:is_skill_cool_down(skill_id)
    skynet.error("[IMP540] VERIFY cd=", verify_cd, " is_skill_cool_down=", tostring(verify_check))

    -- 打断：如果目标正在自动攻击被封印的技能，强制停止
    local ai = obj:get_ai()
    if ai and ai.param_ai_use_skill then
        local current = ai.param_ai_use_skill.auto_use_skill
        if current == skill_id then
            ai.param_ai_use_skill.auto_use_skill = define.INVAILD_ID
            ai.param_ai_use_skill.queued_skill = define.INVAILD_ID
            ai.param_ai_use_skill.auto_shoot_target_obj_id = define.INVAILD_ID
            if ai.change_state then
                ai:change_state("idle")
            end
            skynet.error("[IMP540] interrupted auto-attack skill=", skill_id)
        end
    end

    -- 文字通知
    if obj.notify_tips then
        obj:notify_tips("65级技能被封印，冷却中")
    end
end

function std_impact_540:on_fade_out(imp, obj)
    skynet.error("[IMP540] on_fade_out, debuff expired")
    -- 效果到期时无需额外清理，cool_down_times 自然递减
end

return std_impact_540
