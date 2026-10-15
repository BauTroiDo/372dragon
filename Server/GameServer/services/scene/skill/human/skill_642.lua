local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"

local skill_642 = class("skill_642", base)

-- 技能276用aq_skill索引3（暗器修炼等级>=90解锁）
local skill_id_2_index = {
    [274] = 1,
    [275] = 2,
    [276] = 3,
}

-- 获取暗器洗练出的Impact ID
-- 返回 aq_skill[index]，即洗练后存储的具体Impact ID
function skill_642:get_impact_id_from_anqi(obj_me, index)
    local container = obj_me:get_equip_container()
    if not container then
        return define.INVAILD_ID
    end
    local anqi = container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if not anqi then
        return define.INVAILD_ID
    end
    local aq_data = anqi:get_equip_data()
    if not aq_data then
        return define.INVAILD_ID
    end
    local impact_id = aq_data:get_aq_skill(index)
    return impact_id or define.INVAILD_ID
end

-- 前置条件检查：需要装备暗器且已洗练出对应技能
function skill_642:specific_condition_check(obj_me)
    local skillinfo = obj_me:get_skill_info()
    local skill_id = skillinfo:get_skill_id()

    local index = skill_id_2_index[skill_id]
    if not index then
        return false
    end

    local container = obj_me:get_equip_container()
    local anqi = container and container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
    if not anqi then
        obj_me:notify_tips("使用暗器技能需要装备暗器！")
        return false
    end

    local aq_data = anqi:get_equip_data()
    local aq_skill_val = aq_data and aq_data:get_aq_skill(index)

    if not aq_skill_val or aq_skill_val == 0 then
        obj_me:notify_tips("未领悟暗器对应技能！（需暗器修炼等级>=90）")
        return false
    end

    return true
end

-- 对目标施加buff效果（一次性）
function skill_642:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skillinfo = obj_me:get_skill_info()
    local skill_id = skillinfo:get_skill_id()
    local params = obj_me:get_targeting_and_depleting_params()
    local index = skill_id_2_index[skill_id]

    if not index then
        return
    end

    -- 获取洗练出的Impact ID（aq_skill[index] 直接存储的就是按等级查表后的Impact ID）
    local impact_id = self:get_impact_id_from_anqi(obj_me, index)

    if not impact_id or impact_id == define.INVAILD_ID or impact_id <= 0 then
        obj_me:notify_tips("暗器护体：未能获取有效的护体效果！")
        return
    end

    -- 初始化Impact并注册到目标（自身）
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()

    local imp = impact.new()
    imp:clean_up()
    local ok = impactenginer:init_impact_from_data(impact_id, imp)

    if not ok then
        obj_me:notify_tips("暗器护体：效果初始化失败！")
        return
    end

    local delay_time = params:get_delay_time()

    -- 注册buff到目标（TARGET_SELF，obj_tar == obj_me）
    self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
end

return skill_642
