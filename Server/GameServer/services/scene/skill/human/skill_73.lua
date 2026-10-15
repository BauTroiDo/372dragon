-- 凌神式
-- 瞬移到目标身边并造成伤害，化气状态下追加增强伤害
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local murong_common = require "scene.skill.murong_skill_common"
local impactenginer = require "impactenginer":getinstance()
local skill_73 = class("skill_73", base)

skill_73.IMPACT_NUMBER = 17
local TALENT_SKILL_ID = 848
-- 化气增伤百分比
local HUAQI_BONUS_RATE = 50
-- 贴近目标距离
local APPROACH_DISTANCE = 1.5

function skill_73:get_activate_once_impact_by_index(skill_info, index)
    local value = skill_info:get_activate_once_impact_by_index(index)
    if not value and index == 1 then
        local imps = skill_info:get_activate_once_impacts()
        value = imps.self
    end
    return value or define.INVAILD_ID
end

function skill_73:get_attack_impact(skill_info)
    return skill_info:get_attack_impact() or define.INVAILD_ID
end

function skill_73:apply_activate_once_impacts(obj_me, obj_tar, delay_time, is_critical, bonus_rate)
    local skill_info = obj_me:get_skill_info()
    -- 攻击效果（SkillData 参数说明="攻击效果" 对应的 StandardImpact）
    local atk_value = self:get_attack_impact(skill_info)
    if atk_value >= 0 then
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(atk_value, imp)
        -- 凌神式的 StandardImpact 用的是 logic_id=11（属性修正），
        -- 但实际需要 logic_id=3（直接伤害）才能触发 combat_core 的伤害计算。
        -- 运行时强制转换为 3，使 register_impact_event 走伤害计算路径。
        if imp:get_logic_id() == 11 then
            imp:set_logic_id(DI_DamagesByValue_T.ID)
        end
        if bonus_rate > 0 and imp:get_logic_id() == DI_DamagesByValue_T.ID then
            for _, key in ipairs(DAMAGE_TYPE_RATE) do
                imp:add_rate_params(key, bonus_rate)
            end
        end
        self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
    end
    for i = 1, self.IMPACT_NUMBER do
        local value = self:get_activate_once_impact_by_index(skill_info, i)
        if value >= 0 then
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(value, imp)
            if bonus_rate > 0 and imp:get_logic_id() == DI_DamagesByValue_T.ID then
                for _, key in ipairs(DAMAGE_TYPE_RATE) do
                    imp:add_rate_params(key, bonus_rate)
                end
            end
            self:register_impact_event(obj_tar, obj_me, imp, delay_time, is_critical)
        end
    end
end

function skill_73:activate_talent_skill(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    local target_position = params:get_target_position()

    -- 武道版凌神式改为点选地面后瞬移，再由配置的范围效果在落点结算伤害。
    if target_position and target_position.x >= 0 and target_position.y >= 0 then
        obj_me:on_teleport(target_position)
    end

    self:apply_activate_once_impacts(obj_me, obj_me, params:get_delay_time(), false, 0)

    if target_position then
        -- 直接对3米范围内最多3个目标施加60%普攻伤害
        local scene = obj_me:get_scene()
        if scene then
            local operate = {scaner = obj_me, obj = obj_me, x = target_position.x, y = target_position.y,
                             target_logic_by_stand = 1, radious = 3, count = 3}
            for _, target in ipairs(scene:scan(operate)) do
                if target:is_character_obj() then
                    impactenginer:send_impact_to_unit(target, 63001, obj_me, 0, false, 0, params:get_activated_skill()) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
                end
            end
        end
        -- 创建 SpecialObj 2023（爆炸特效，不依赖其主动触发伤害）
        local sword = obj_me:skill_create_obj_specail(target_position, 2023, params:get_activated_skill())
        if sword then
            sword:mark_fade_out_flag()
        end
    end

    self:broadcast_target_list_message(obj_me, {}, {})
    return true
end

function skill_73:activate_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    if skill_info:get_skill_id() == TALENT_SKILL_ID then
        return self:activate_talent_skill(obj_me)
    end
    return base.activate_once(self, obj_me)
end

function skill_73:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local params = obj_me:get_targeting_and_depleting_params()

    -- 原版凌神式仍保持贴近目标后单体伤害的流程。
    if obj_me ~= obj_tar then
        local dst = murong_common.calc_near_target_position(obj_me, obj_tar, APPROACH_DISTANCE)
        if dst and dst.x >= 0 and dst.y >= 0 then
            obj_me:on_teleport(dst)
        end
    end

    local has_huaqi = murong_common.has_huaqi_state(obj_me)
    local bonus_rate = has_huaqi and HUAQI_BONUS_RATE or 0
    self:apply_activate_once_impacts(obj_me, obj_tar, params:get_delay_time(), is_critical, bonus_rate)

    if has_huaqi then
        murong_common.remove_huaqi_state(obj_me)
    end
end


return skill_73
