-- 公子无双：拥有蓄气状态时，有X%概率抵御一个控制效果，每个蓄气状态最多生效一次
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_962 = class("std_talent_962", base)

-- 蓄气状态的 mutex_id 集合
local XUQI_MUTEX = { [11]=true, [13]=true, [15]=true, [17]=true, [19]=true, [21]=true, [122]=true }
-- 控制类 mutex_id 集合
local CONTROL_MUTEX = { [11]=true, [13]=true, [15]=true, [17]=true, [19]=true, [21]=true, [122]=true }

function std_talent_962:on_be_skill(talent, level, human, sender, skill_id, behaviortype)
    if behaviortype ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then return end
    -- 检查技能是否施加控制
    local scene = human:get_scene()
    local skillenginer = scene:get_skill_enginer()
    local template = skillenginer:get_skill_template(skill_id)
    if not template then return end
    local level_skills = template.level_skills
    if not level_skills then return end
    local skill_info_id = level_skills[1]
    if not skill_info_id then return end
    local info = skillenginer:get_skill_info(skill_info_id)
    if not info or not info.impacts then return end
    -- 收集技能的所有 impact
    local has_control = false
    local impact_ids = {}
    if info.impacts.effect_once then
        for _, v in pairs(info.impacts.effect_once) do
            if type(v) == "number" and v >= 0 then impact_ids[#impact_ids+1] = v end
        end
    end
    if info.impacts.give_target and info.impacts.give_target.id and info.impacts.give_target.id >= 0 then
        impact_ids[#impact_ids+1] = info.impacts.give_target.id
    end
    for _, data_index in ipairs(impact_ids) do
        local imp_data = impactenginer:get_data_by_data_index(data_index)
        if imp_data and imp_data.mutex_id and CONTROL_MUTEX[imp_data.mutex_id] then
            has_control = true
            break
        end
    end
    if not has_control then return end
    -- 查找自身蓄气状态
    local impacts = human:get_impact_list()
    local xuqi_imp = nil
    for i = #impacts, 1, -1 do
        local imp = impacts[i]
        local logic_id = imp:get_logic_id()
        -- 蓄气状态使用 logic_id=533 的衍生 buff 或 mutex_id 属于蓄气类
        local imp_data = impactenginer:get_data_by_data_index(imp:get_data_index())
        if imp_data and imp_data.mutex_id and XUQI_MUTEX[imp_data.mutex_id] then
            -- 检查该蓄气状态是否已经用过962
            if not imp._962_used then
                xuqi_imp = imp
                break
            end
        end
    end
    if not xuqi_imp then return end
    -- 概率判定
    local params = talent.params[level]
    local chance = params[1] or 0
    if math.random(100) > chance then return end
    -- 免疫成功：标记该蓄气已用过，移除蓄气状态
    xuqi_imp._962_used = true
    human:on_impact_fade_out(xuqi_imp)
    human:remove_impact(xuqi_imp)
    -- 通知 980 减 CD
    human._962_immune_triggered = true
    local r, err = pcall(human.talent_on_be_hit, human, sender, nil)
    if not r then
        skynet.error("[TALENT_962] talent_on_be_hit 回调异常 err=", err)
    end
    human._962_immune_triggered = nil
end

return std_talent_962
