-- 化气式
-- 释放时判断目标门派，使用对应门派的65级绝学对目标释放
-- 门派0-8,10-11: 使用目标门派绝学
-- 门派9(无门派)/12(慕容): 从0-8,10-11随机一个门派绝学
-- 释放后给自己挂化气状态
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local c_skill_info = require "skillinfo"
local murong_common = require "scene.skill.murong_skill_common"
local skill_751 = class("skill_751", base)

local MURONG_MENPAI = 12
local WUMENPAI = 9
local VALID_FACTIONS = {0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11}
local IMPACT_NUMBER = 17
-- 65级绝学在level_skills中的最大索引（13-16为80级数据）
local LEVEL_65_MAX = 12

-- 门派绝学模板 → 逻辑模块ID映射
-- SkillData中这些技能的logic_id为0(基础逻辑)，实际逻辑ID在SkillTemplate原始数据中
local FACTION_LOGIC_IDS = {
    [836] = 707,  -- 少林 易筋锻骨
    [837] = 708,  -- 明教 纯阳无极
    [838] = 709,  -- 丐帮 天下无狗
    [839] = 710,  -- 武当 天外飞仙
    [840] = 711,  -- 峨眉 九阴神爪
    [841] = 712,  -- 星宿 化骨绵掌
    [842] = 713,  -- 大理 少泽剑
    [843] = 714,  -- 天山 同生共死
    [844] = 715,  -- 逍遥 鲲跃北溟
    [845] = 798,  -- 曼陀山庄 弦弄花影
    [846] = 810,  -- 恶人谷 判指阴阳
}

function skill_751:get_faction_skill_id(skill_info, menpai)
    local key = string.format("门派%d技能ID", menpai)
    return skill_info:get_descriptor_value(key) or -1
end

function skill_751:get_random_faction_skills(skill_info)
    local list = {}
    for _, mp in ipairs(VALID_FACTIONS) do
        local tid = self:get_faction_skill_id(skill_info, mp)
        if tid > 0 then
            list[#list + 1] = tid
        end
    end
    return list
end

-- 确定门派绝学模板ID
function skill_751:determine_faction_skill(skill_info, obj_tar)
    local target_menpai = -1
    if obj_tar and obj_tar.get_menpai then
        target_menpai = obj_tar:get_menpai() or -1
    end

    local faction_template_id = -1
    if target_menpai >= 0 and target_menpai <= 8 then
        faction_template_id = self:get_faction_skill_id(skill_info, target_menpai)
    elseif target_menpai >= 10 and target_menpai <= 15 then -- CS3b: số CY, SkillData CY có tham số mọi phái
        faction_template_id = self:get_faction_skill_id(skill_info, target_menpai)
    end

    -- 无门派(9)/慕容(12)/无效 → 随机选
    if faction_template_id <= 0 then
        local all = self:get_random_faction_skills(skill_info)
        if #all > 0 then
            faction_template_id = all[math.random(#all)]
        end
    end
    return faction_template_id
end

-- 创建门派绝学的skill_info
function skill_751:create_faction_skill_info(skillenginer, faction_template_id, params)
    local template = skillenginer:get_skill_template(faction_template_id)
    if not template then
        return nil
    end
    local level = params:get_skill_level()
    if not level or level <= 0 then level = 1 end
    if level > LEVEL_65_MAX then level = LEVEL_65_MAX end

    local level_skills = template.level_skills
    if not level_skills then return nil end
    local faction_data_id = level_skills[level] or level_skills[1]
    if not faction_data_id then return nil end

    local faction_data = skillenginer:get_skill_info(faction_data_id)
    if not faction_data then return nil end
    return c_skill_info.new(template, faction_data, level)
end

-- 重写action_active_once_handler：在注册动作前确定门派绝学，用门派ID注册
function skill_751:action_active_once_handler(obj_me)
    local original_skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local skillenginer = scene:get_skill_enginer()

    -- 条件检查/消耗/动作时间（使用化气式）
    if not self:is_condition_satisfied(obj_me) then
        return false
    end
    local ret = true
    if not params:get_ignore_condition_check_flag() then
        ret = self:deplete_process(obj_me)
    end
    if not ret then return end
    local actiontime = self:calculate_action_time(obj_me)

    -- 确定门派绝学
    local target_id = params:get_target_obj()
    local obj_tar = nil
    if target_id then
        obj_tar = obj_me:get_specific_obj_in_same_scene_by_id(target_id)
    end
    local faction_template_id = self:determine_faction_skill(original_skill_info, obj_tar)

    local faction_skill_info = nil
    if faction_template_id > 0 then
        faction_skill_info = self:create_faction_skill_info(skillenginer, faction_template_id, params)
    end

    -- 替换为门派绝学（broadcast_unit_start_instant_action读obj:get_skill_info()）
    if faction_skill_info then
        obj_me.skill_info = faction_skill_info
    end

    -- 注册动作（GCCharSkill_Send此时发送的是门派绝学ID）
    local action_skill_id = faction_skill_info and faction_skill_info:get_skill_id() or original_skill_info:get_skill_id()
    if not scene:get_action_enginer():register_instant_action_for_skill(obj_me, action_skill_id, actiontime) then
        obj_me.skill_info = original_skill_info
        return false
    end
    obj_me:set_action_time(actiontime)

    -- 冷却（恢复化气式处理冷却，冷却归化气式管）
    obj_me.skill_info = original_skill_info
    self:cooldown_process(obj_me)

    -- 再次替换为门派绝学（activate_once和broadcast都用门派ID）
    if faction_skill_info then
        obj_me.skill_info = faction_skill_info
    end

    -- 激活次数和延迟从化气式取
    local active_times = original_skill_info:get_charges_or_interval()
    if active_times <= 0 then active_times = 1 end
    local delaytime = original_skill_info:get_delay_time() == 0 and define.MIN_DELAY_TIME or original_skill_info:get_delay_time()
    params:set_delay_time(delaytime)

    for i = 1, active_times do
        local r, err = pcall(self.activate_once, self, obj_me)
        if not r then
            skynet.loge("skill_751:action_active_once_handler error =", err)
        end
    end

    -- 恢复原始skill_info
    obj_me.skill_info = original_skill_info
    obj_me:on_use_skill_success_fully(original_skill_info)
    self:on_use_skill_success_fully(obj_me)

    -- 挂化气状态
    murong_common.apply_huaqi_buff(obj_me, original_skill_info:get_skill_id())
end

-- 重写activate_once：skill_info已是门派绝学，走标准流程
function skill_751:activate_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer_inst = scene:get_impact_enginer()

    local targets = self:calculate_target_list(obj_me)
    local target_count = #targets
    local hit_flag_list = {}

    if target_count == 0 then
        self:broadcast_target_list_message(obj_me, targets, hit_flag_list)
        return true
    end

    local skill_id = skill_info:get_skill_id()
    local delay_time = params:get_delay_time()

    for i, o in ipairs(targets) do
        if self:hit_this_target(obj_me, o) then
            hit_flag_list[i] = true
        else
            target_count = target_count - 1
            hit_flag_list[i] = false
        end
        self:register_be_skill_event(o, obj_me, skill_id, delay_time)
        scene:get_event_enginer():register_skill_hit_event(obj_me, o, skill_id, delay_time)
    end
    target_count = target_count < 1 and 1 or target_count
    params:set_target_count(target_count)

    -- 施加门派绝学效果（数据驱动，不调用门派逻辑避免自增益打到敌人）
    for i, o in ipairs(targets) do
        if hit_flag_list[i] then
            local critical_hit = self:critical_hit_this_target(obj_me, o)
            self:apply_faction_impacts(obj_me, o, skill_info, impactenginer_inst, delay_time, critical_hit)
        end
    end

    -- 化气式是自释放技能，targets中只有自身
    -- 额外用真正的目标注册一次skill_hit_event，让天赋（如970常相见）能拿到真正的目标
    local real_target_id = params:get_target_obj()
    if real_target_id then
        local real_target = obj_me:get_specific_obj_in_same_scene_by_id(real_target_id)
        if real_target and real_target ~= obj_me then
            scene:get_event_enginer():register_skill_hit_event(obj_me, real_target, skill_id, delay_time)
        end
    end

    -- 广播（skill_id = 门派绝学ID）
    self:broadcast_target_list_message(obj_me, targets, hit_flag_list)
    return true
end

-- 施加门派绝学数据定义的impacts
function skill_751:apply_faction_impacts(obj_me, obj_tar, faction_si, impactenginer_inst, delay_time, is_critical)
    for i = 1, IMPACT_NUMBER do
        local value = faction_si:get_activate_once_impact_by_index(i)
        if value and value >= 0 then
            local imp = impact.new()
            imp:clean_up()
            impactenginer_inst:init_impact_from_data(value, imp)
            self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
        end
    end
    local atk = faction_si:get_attack_impact()
    if atk and atk >= 0 then
        local imp = impact.new()
        imp:clean_up()
        impactenginer_inst:init_impact_from_data(atk, imp)
        self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
    end
    local gt = faction_si:get_give_target_impact()
    if gt and gt.id and gt.id >= 0 then
        local imp = impact.new()
        imp:clean_up()
        impactenginer_inst:init_impact_from_data(gt.id, imp)
        self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
    end
end

return skill_751
