--[[
    技能基类
    定义了技能系统的核心逻辑，包括技能启动、目标选择、条件检查、资源消耗、效果触发等
    所有具体技能类都应继承此类并重写相关方法
]]

local skynet = require "skynet"
local packet_def = require "game.packet"
local combat_core = require "scene.skill.combat_core"
local condition_delplete_core = require "scene.skill.condition_delplete_core"
local define = require "define"
local class = require "class"

-- 技能基类
local skill = class("skill")

-- 枚举类型定义
local enum_OPERATE_RESULT = define.OPERATE_RESULT
local enum_SYSTEM_USE_SKILL = define.SYSTEM_USE_SKILL
-- 条件与消耗项数量
local CONDITION_AND_DEPLETE_TERM_NUMBER = 3

-- 技能开始时的特殊操作（子类可重写）
-- @return boolean 是否成功
function skill:speical_operation_on_skill_start()
    return true
end

-- 检查是否为被动技能
-- @return boolean 是否为被动技能
function skill:is_passive()
    return false
end

-- 技能被打断时的处理（子类可重写）
-- @return boolean 是否成功处理
function skill:on_interrupt()
    return false
end

-- 技能被取消时的处理
-- @param obj_me 执行者对象
function skill:on_cancel(obj_me)
    local params = obj_me:get_targeting_and_depleting_params()
    params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_SKILL)
    params:set_errparam(params:get_activated_skill())
end

-- 开始释放技能（立即释放类型）
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:start_launching(obj_me)
    return self:action_active_once_handler(obj_me)
end

-- 开始蓄力技能
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:start_charging(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local maxtime = skill_info:get_charge_time()
    local ret = true
    -- print("skill:start_charging maxtime =", maxtime)
    -- 如果蓄力时间<=0，则立即释放
    if maxtime <= 0 then
        ret = self:action_active_once_handler(obj_me)
    else
        -- 注册蓄力动作
        ret = obj_me:get_scene():get_action_enginer():register_charge_action_for_skill(obj_me, skill_info:get_skill_id(), maxtime)
    end
    if ret then
        params:set_errcode(enum_OPERATE_RESULT.OR_OK)
    end
    return ret
end

-- 开始引导技能
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:start_channeling(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local maxtime = skill_info:get_channel_time()
    if maxtime <= 0 then
        skynet.logw("skill logic start_channeling: zero channel time found!!")
        return false
    end
    local ret = true
    -- 如果不忽略条件检查，则执行消耗过程
    if not params:get_ignore_condition_check_flag() then
        ret = self:deplete_process(obj_me)
    end
    -- print("skill:start_channeling ret =", ret)
    if ret then
        obj_me:on_use_skill_success_fully(skill_info)
        -- 注册引导动作
        if obj_me:get_scene():get_action_enginer():register_channel_action_for_skill(obj_me, skill_info:get_skill_id(), maxtime, skill_info:get_charges_or_interval()) then
            if not params:get_ignore_cool_down_write_flag() then
                self:cooldown_process(obj_me)
            end
            params:set_errcode(enum_OPERATE_RESULT.OR_OK)
            self:activate_once(obj_me)
            return true
        end
    end
    return false
end

-- 检查目标是否符合技能要求
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @param skill_info 技能信息
-- @return boolean 目标是否符合要求
function skill:is_wantd_target(obj_me, obj_tar, skill_info)
    -- CYS-MOUNT-FLIGHT
    if not require('cys_mount_flight').skill_allowed(obj_me,obj_tar,skill_info:get_skill_id()) then return false end
    -- 检查目标类型
    local otype = skill_info:get_target_check_by_obj_type()
    if otype == 0 then
        -- 必须是人类
        if obj_tar:get_obj_type() ~= "human" then
            return false
        end
    elseif otype == 1 then
        -- 必须是宠物
        if obj_tar:get_obj_type() ~= "pet" then
            return false
        end
    elseif otype == 2 then
        -- 必须是怪物
        if obj_tar:get_obj_type() ~= "monster" then
            return false
        end
    end

    -- 检查阵营关系
    local stand_type = skill_info:get_target_logic_by_stand()
    if stand_type == 0 then
        -- 不能是敌人
        if obj_tar:is_enemy(obj_me) and obj_me:is_enemy(obj_tar) then
            return false
        else
            -- 检查是否仅限队友
            local is_party_only = skill_info:is_party_only()
            if is_party_only then
                if not obj_me:is_party(obj_tar) then
                    return false
                end
            end
        end
    elseif stand_type == 1 then
        -- 不能是友方
        if obj_tar:is_friend(obj_me) and obj_me:is_friend(obj_tar) then
            return false
        end
    end

    -- 检查目标状态
    local must_in_special_state = skill_info:get_target_must_in_special_state()
    if must_in_special_state == 0 then
        -- 目标必须存活
        if not obj_tar:is_alive() then
            return false
        end
    elseif must_in_special_state == 1 then
        -- 目标必须死亡
        if obj_tar:is_dead() then
            return false
        end
    end

    -- 检查特殊目标要求
    return self:is_special_target_wanted(obj_me, obj_tar, skill_info)
end

-- 按百分比修正消耗
-- @param skill_info 技能信息
-- @param rate 修正百分比
function skill:refix_deplete_by_rate(skill_info, rate)
    if self:can_be_refix() then
        skill_info:set_deplete_refix_by_rate(rate)
    end
end

-- 按百分比修正威力
-- @param skill_info 技能信息
-- @param rate 修正百分比
function skill:refix_power_by_rate(skill_info, rate)
    if self:can_be_refix() then
        skill_info:set_power_refix_by_rate(rate)
    end
end

-- 检查是否可以修正
-- @return boolean 是否可以修正
function skill:can_be_refix()
    return false
end

-- 检查条件是否满足
-- @param obj_me 执行者对象
-- @return boolean 条件是否满足
function skill:is_condition_satisfied(obj_me)
    return self:common_condition_check(obj_me) and self:specific_condition_check(obj_me)
end

-- 取消技能效果（子类可重写）
function skill:cancel_skill_effect()

end

-- 立即释放技能的处理函数
-- @param obj_me 执行者对象
function skill:action_active_once_handler(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 检查条件是否满足
    if not self:is_condition_satisfied(obj_me) then
        return false
    end
    local ret = true
    -- 如果不忽略条件检查，则执行消耗过程
    if not params:get_ignore_condition_check_flag() then
        ret = self:deplete_process(obj_me)
    end
    if ret then
        -- 计算动作时间
        local actiontime = self:calculate_action_time(obj_me)
        -- 调试输出已屏蔽
        -- print("actiontime =", actiontime)
        -- 注册立即动作
        if not obj_me:get_scene():get_action_enginer():register_instant_action_for_skill(obj_me, skill_info:get_skill_id(), actiontime) then
            return false
        end
        obj_me:set_action_time(actiontime)
        -- 处理冷却
        if not params:get_ignore_cool_down_write_flag() then
            self:cooldown_process(obj_me)
        end
        -- 获取激活次数
        local active_times = skill_info:get_charges_or_interval()
        if active_times <= 0 then
            active_times = 1
        end
        -- 设置延迟时间
        local delaytime = skill_info:get_delay_time() == 0 and define.MIN_DELAY_TIME or skill_info:get_delay_time()
        params:set_delay_time(delaytime)
        -- 多次激活技能
        for i = 1, active_times do
            self:activate_once(obj_me)
        end
        obj_me:on_use_skill_success_fully(skill_info)
        self:on_use_skill_success_fully(obj_me)
        return true
    end
end

-- 每次tick激活技能的处理函数（用于引导技能）
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:action_active_each_tick_handler(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    if self:target_check_for_each_tick(obj_me) then
        params:set_delay_time(skill_info:get_delay_time())
        self:activate_each_tick(obj_me)
        return true
    end
    return false
end

-- 获取技能信息描述符值（子类可重写）
function skill:get_skill_info_descriptor_vlue_by_Index()

end

-- 设置技能信息描述符值（子类可重写）
function skill:set_skill_info_descriptor_vlue_by_Index()

end
-- 计算目标列表
-- @param obj_me 执行者对象
-- @return table 目标对象列表
function skill:calculate_target_list(obj_me)
    local skill_info = obj_me:get_skill_info()
    local cy_targets=require("cy_four_combat.release").target_list(self,obj_me,skill_info)
    if cy_targets then return cy_targets end
    local params = obj_me:get_targeting_and_depleting_params()
    local target_mode = skill_info:get_targeting_logic()
    local ret = false
    local objs = {}
	--skynet.logi("target_mode = ",target_mode)
    -- 根据目标模式选择目标
    if target_mode == define.ENUM_TARGET_LOGIC.TARGET_SELF then
        -- 目标是自己
        table.insert(objs, obj_me)
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_MY_PET then
        -- 目标是自己的宠物
        table.insert(objs, obj_me:get_pet())
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_MY_SHADOW_GUARD then
        -- 目标是自己的影卫
        table.insert(objs, obj_me:get_my_shadow_guard())
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_MY_MASTER then
        -- 目标是自己的主人
        table.insert(objs, obj_me:get_my_master())
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_SELF then
        -- 目标是周围单位
        local pos = obj_me:get_world_pos()
        objs = self:scan_unit_for_target(obj_me, pos.x, pos.y)
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT
	or target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT_NEW then
        -- 目标是指定单位周围
        local obj_tar = obj_me:get_specific_obj_in_same_scene_by_id(params:get_target_obj())
        local pos = obj_tar:get_world_pos()
        objs = self:scan_unit_for_target(obj_me, pos.x, pos.y)
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_POSITION then
        -- 目标是指定位置周围
        local pos = params:get_target_position()
        objs = self:scan_unit_for_target(obj_me, pos.x, pos.y)
    elseif target_mode == define.ENUM_TARGET_LOGIC.TARGET_SPECIFIC_UNIT then
        -- 目标是指定单位
        local obj_tar = obj_me:get_specific_obj_in_same_scene_by_id(params:get_target_obj())
        table.insert(objs, obj_tar)
    end
    return objs
end

-- 激活技能一次（立即释放）
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:activate_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local targets = self:calculate_target_list(obj_me)
    local target_count = #targets
    local hit_flag_list = {}
    if skill_info:get_skill_id() == 834 then
        -- skynet.error("[DEBUG_834] activate_once called, targets count=", target_count)
    end
    if target_count == 0 then
    else
		local skill_id = skill_info:get_skill_id()
		local delay_time = skill_info:get_delay_time()
        -- 检查每个目标是否命中
        for i, o in ipairs(targets) do
            local hit_result = self:hit_this_target(obj_me, o)
            if skill_info:get_skill_id() == 834 then
                -- skynet.error("[DEBUG_834] hit_this_target for target[", i, "] result=", tostring(hit_result))
            end
            if hit_result then
                hit_flag_list[i] = true
            else
				target_count = target_count - 1
                hit_flag_list[i] = false
            end
            -- 注册被技能事件
            self:register_be_skill_event(o, obj_me, skill_id, delay_time)
        end
		target_count = target_count < 1 and 1 or target_count
        params:set_target_count(target_count)
        -- 对命中的目标施加效果
        for i, o in ipairs(targets) do
            if hit_flag_list[i] then
                local critical_hit = self:critical_hit_this_target(obj_me, o)
                --skynet.logi("skill:activate_once skill_id =", skill_info:get_skill_id())
                if skill_info:get_skill_id() == 834 then
                    -- skynet.error("[DEBUG_834] effect_on_unit_once called for target[", i, "]")
                end
                self:effect_on_unit_once(obj_me, o, critical_hit)
            end
        end
    end
    -- 广播目标列表消息
    self:broadcast_target_list_message(obj_me, targets, hit_flag_list)
    return true
end

-- 每次tick激活技能（用于引导技能）
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:activate_each_tick(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local targets = self:calculate_target_list(obj_me)
    local target_count = #targets
    local hit_flag_list = {}
    if target_count == 0 then

    else
		local skill_id = skill_info:get_skill_id()
		local delay_time = skill_info:get_delay_time()
        -- 检查每个目标是否命中
        for i, o in ipairs(targets) do
            if self:hit_this_target(obj_me, o) then
                hit_flag_list[i] = true
            else
				target_count = target_count - 1
                hit_flag_list[i] = false
            end
            -- 注册被技能事件
            self:register_be_skill_event(o, obj_me, skill_id, delay_time)
        end
		target_count = target_count < 1 and 1 or target_count
        params:set_target_count(target_count)
        -- 对命中的目标施加效果
        for i, o in ipairs(targets) do
            if hit_flag_list[i] then
                local critical_hit = self:critical_hit_this_target(obj_me, o)
                local r, err = pcall(self.effect_on_unit_each_tick, self, obj_me, o, critical_hit)
                if not r then
                    print("skill:activate_each_tick error =", err)
                end
            end
        end
    end
    -- 广播目标列表消息
    self:broadcast_target_list_message(obj_me, targets, hit_flag_list)
    return true
end

-- 对单位施加效果（每次tick，子类可重写）
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @param critical_hit 是否暴击
-- @return boolean 是否成功
function skill:effect_on_unit_each_tick()
    return true
end

-- 对单位施加效果（一次，子类可重写）
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @param critical_hit 是否暴击
-- @return boolean 是否成功
function skill:effect_on_unit_once(obj_me, obj_tar, is_critical)
    -- 暗器护体保底逻辑：当 skill_642 的 class override 未生效时（require失败回退到base），在此直接处理
    if obj_me and type(obj_me) == "table" and obj_me.get_skill_info then
        local _ok_si, _si = pcall(obj_me.get_skill_info, obj_me)
        if _ok_si and _si then
            local _ok_sid, _sid = pcall(_si.get_skill_id, _si)
            if _ok_sid and (_sid == 274 or _sid == 275 or _sid == 276) then
                -- 技能ID到暗器aq_skill索引的映射
                local _anqi_index_map = {[274]=1, [275]=2, [276]=3}
                local _index = _anqi_index_map[_sid]

                -- 获取暗器装备的洗练Impact ID
                local _container = obj_me:get_equip_container()
                if not _container then
                    return true
                end
                local _anqi = _container:get_item(define.HUMAN_EQUIP.HEQUIP_ANQI)
                if not _anqi then
                    return true
                end
                local _aq_data = _anqi:get_equip_data()
                if not _aq_data then
                    return true
                end
                local _impact_id = _aq_data:get_aq_skill(_index)

                if not _impact_id or _impact_id == define.INVAILD_ID or _impact_id <= 0 then
                    return true
                end

                -- 初始化Impact
                local _impact = require "scene.skill.impact"
                local _scene = obj_me:get_scene()
                local _impeng = _scene:get_impact_enginer()
                local _imp = _impact.new()
                _imp:clean_up()
                local _init_ok = _impeng:init_impact_from_data(_impact_id, _imp)

                if not _init_ok then
                    return true
                end

                -- 注册buff到自身
                local _params = obj_me:get_targeting_and_depleting_params()
                local _delay = _params:get_delay_time()
                self:register_impact_event(obj_me, obj_me, _imp, _delay, is_critical)
                return true
            end
        end
    end
    return true
end

-- 技能成功使用后的处理（子类可重写）
-- @param obj_me 执行者对象
-- @return boolean 是否成功
function skill:on_use_skill_success_fully()
    return true
end

-- 检查是否为角色对象
-- @param t 对象类型
-- @return boolean 是否为角色对象
function skill:is_character_obj(t)
    return t == "monster" or t == "pet" or t == "human"
end

function skill:target_check_for_each_tick(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    if skill_info:get_select_type() ~= 1 then
        return true
    end
    local obj_tar = self:get_target_obj(obj_me)
    if obj_tar then
        if self:is_character_obj(obj_tar:get_obj_type()) then
            local must_in_special_state = skill_info:get_target_must_in_special_state()
            if must_in_special_state == 0 then
                if not obj_tar:is_alive() then
                    params:set_errcode(enum_OPERATE_RESULT.OR_TARGET_DIE)
                    params:set_errparam(0)
                    return false
                end
            elseif must_in_special_state == 1 then
                if obj_tar:is_alive_in_deed() then
                    params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                    return false
                end
            end
            if self:is_out_of_range_to_obj(obj_me, obj_tar) then
                params:set_errcode(enum_OPERATE_RESULT.OR_OUT_RANGE)
                return false
            end
            return true
        end
    end
end

function skill:target_check_for_activate_once(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local select_type = skill_info:get_select_type()
    -- 调试输出已屏蔽
    -- print("skill_info.get_select_type =", select_type)
    if select_type ~= define.ENUM_SELECT_TYPE.SELECT_TYPE_CHARACTER then
        if select_type == define.ENUM_SELECT_TYPE.SELECT_TYPE_POS then
            local pos = params:get_target_position()
            if self:is_out_of_range_to_pos(obj_me, pos) then
                return false
            end
        end
        return true
    else
        local obj_tar = self:get_target_obj(obj_me)
        if obj_tar then
            if self:is_character_obj(obj_tar:get_obj_type()) then
                --[[if not obj_tar:can_view_me(obj_me) then
                    params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                    params:set_errparam(0)
                    -- 调试输出已屏蔽
                    -- print("target can not view me")
                    return false
                end]]
                local otype = skill_info:get_target_check_by_obj_type()
                if otype == 0 then
                    if obj_tar:get_obj_type() ~= "human" then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target not human")
                        return false
                    end
                elseif otype == 1 then
                    if obj_tar:get_obj_type() ~= "pet" then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target not pet")
                        return false
                    end
                elseif otype == 2 then
                    if obj_tar:get_obj_type() ~= "monster" then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target not monster")
                        return false
                    end
                end
                local stand_type = skill_info:get_target_logic_by_stand()
                if stand_type == 0 then
                    if obj_tar:is_enemy(obj_me) and obj_me:is_enemy(obj_tar) then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target is enemy")
                        return false
                    end
                elseif stand_type == 1 then
                    if obj_tar:is_friend(obj_me) and obj_me:is_friend(obj_tar) then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target is friend")
                        return false
                    end
                end
                local must_in_special_state = skill_info:get_target_must_in_special_state()
                if must_in_special_state == 0 then
                    if not obj_tar:is_alive() then
                        params:set_errcode(enum_OPERATE_RESULT.OR_TARGET_DIE)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target not alive")
                        return false
                    end
                elseif must_in_special_state == 1 then
                    if obj_tar:is_alive_in_deed() then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        -- 调试输出已屏蔽
                        -- print("target not deed")
                        return false
                    end
                end
                local party_only = skill_info:is_party_only()
                if party_only then
                    if not obj_tar:is_party(obj_me) and not obj_me:is_party(obj_tar) then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target no party")
                        return false
                    end
                end
                if self:is_out_of_range_to_obj(obj_me, obj_tar) then
		-- skynet.logi("target_check_for_activate_once 111")
                    params:set_errcode(enum_OPERATE_RESULT.OR_OUT_RANGE)
                    params:set_errparam(0)
                    -- 调试输出已屏蔽
                    -- print("target out of range")
                    return false
                end
                local target_level = skill_info:get_target_level()
                if target_level ~= -1 then
                    if target_level > obj_tar:get_level() then
                        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
                        params:set_errparam(0)
                        -- 调试输出已屏蔽
                        -- print("target level too bigger")
                        return false
                    end
                end
                return true
            end
        end
        -- 调试输出已屏蔽
        -- print("target is nil")
        return false
    end
    return false
end

function skill:deplete_process(obj_me)
    return self:common_deplete(obj_me) and self:specific_deplete(obj_me)
end

function skill:common_condition_check(obj_me)
    local skill_info = obj_me:get_skill_info()
    if not require("cy_four_combat.jue_cast_guard").recheck(obj_me, skill_info) then return false end
    for i = 1, define.CONDITION_AND_DEPLETE_TERM_NUMBER do
        local term = skill_info.condition_and_deplete[i]
        if term then
            if not condition_delplete_core:condition_check(obj_me, term) then
                return false
            end
        end
    end
    if not self:target_check_for_activate_once(obj_me) then
        return false
    end
    return true
end

function skill:specific_condition_check()
    return true
end

function skill:common_deplete(obj_me)
    local skill_info = obj_me:get_skill_info()
    for i = 1, CONDITION_AND_DEPLETE_TERM_NUMBER do
        local term = skill_info.condition_and_deplete[i]
        if term then
            if not condition_delplete_core:deplete(obj_me, term) then
                return false
            end
        end
    end
    return true
end

function skill:specific_deplete()
    return true
end

function skill:is_special_target_wanted()
    return true
end

function skill:cancel_skill_effect()
    return false
end

function skill:get_target_obj(obj)
    local skill_info = obj:get_skill_info()
    local params = obj:get_targeting_and_depleting_params()

    local target_id = params:get_target_obj()
    -- print("get_target_obj target id =", target_id)
    local obj_tar = obj:get_specific_obj_in_same_scene_by_id(target_id)
    if obj_tar == nil then
        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
        return
    end
    if not obj_tar:is_active_obj() then
        params:set_errcode(enum_OPERATE_RESULT.OR_INVALID_TARGET)
        return 
    end
    return obj_tar
end

-- 检查目标是否超出范围
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @return boolean 是否超出范围
function skill:is_out_of_range_to_obj(obj_me, obj_tar)
    -- 宠物不检查距离
    if obj_me:get_obj_type() == "pet" then
        return false
    end
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 计算可接受的距离误差
    local acceptable_distance_error
    -- CYS-ATKRANGE: ban goc chon theo NGUOI DANH (SkillLogic.cpp:546 `rMe.GetObjType()`),
    -- khong phai theo muc tieu; va KHONG co phep `* 2` nao. So cua CY 3.71 CHUA DO (muc 8b).
    if obj_me:get_obj_type() == "human" then
        acceptable_distance_error = define.AcceptableDistanceError_NS.ADE_FOR_HUMAN / 4
    else
        acceptable_distance_error = define.AcceptableDistanceError_NS.ADE_FOR_NPC / 4
    end
    -- 如果目标正在移动，增加误差
    if obj_tar:get_character_logic() == define.ENUM_CHARACTER_LOGIC.CHARACTER_LOGIC_MOVE then
        acceptable_distance_error = acceptable_distance_error + 0.5
    end
    local min = skill_info:get_optimal_range_min()
    local max = skill_info:get_optimal_range_max()
	
	-- 获取技能进阶效果（增加攻击范围）
	local skill_id = skill_info:get_skill_id()
	local effect_value,feature_rate = 0,0
	local skillenginer = obj_me:get_scene():get_skill_enginer()
	if skillenginer:is_skill_in_collection(skill_id,121) then
		effect_value,feature_rate = obj_me:get_dw_jinjie_effect_details(15)
		if effect_value > 0 then
			effect_value = effect_value / feature_rate
		end
	end
    min = min - acceptable_distance_error
    max = max + acceptable_distance_error + effect_value
    min = min > 0 and min * min or 0
    max = max > 0 and max * max or 0
    local pos_me = obj_me:get_world_pos()
    local pos_tar = obj_tar:get_world_pos()
    local dist2targetsq = self:distance_sq(pos_me, pos_tar)
    if dist2targetsq < min then
        params:set_errcode(enum_OPERATE_RESULT.OR_OUT_RANGE)
        params:set_errparam(dist2targetsq - min)
        return true
    end
    if dist2targetsq > max then
        params:set_errcode(enum_OPERATE_RESULT.OR_OUT_RANGE)
        params:set_errparam(dist2targetsq - max)
        return true
    end
    params:set_errcode(enum_OPERATE_RESULT.OR_OK)
    return false
end

-- 检查位置是否超出范围
-- @param obj_me 执行者对象
-- @param pos_tar 目标位置
-- @return boolean 是否超出范围
function skill:is_out_of_range_to_pos(obj_me, pos_tar)
    -- 宠物不检查距离
    if obj_me:get_obj_type() == "pet" then
        return false
    end
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local min = skill_info:get_optimal_range_min()
    local max = skill_info:get_optimal_range_max()
    min = min > 0 and min * min or 0
    max = max > 0 and max * max or 0
    local pos_me = obj_me:get_world_pos()
    local dist2targetsq = self:distance_sq(pos_me, pos_tar)
    if dist2targetsq < min then
		-- skynet.logi("is_out_of_range_to_pos 111")
        params:set_errcode(enum_OPERATE_RESULT.OR_OUT_RANGE)
        params:set_errparam(dist2targetsq - min)
        return true
    end
    if dist2targetsq > max then
		-- skynet.logi("is_out_of_range_to_pos 222")
        params:set_errcode(enum_OPERATE_RESULT.OR_OUT_RANGE)
        params:set_errparam(dist2targetsq - max)
        return true
    end
    params:set_errcode(enum_OPERATE_RESULT.OR_OK)
    return false
end

-- 设置冷却时间
-- @param obj 执行者对象
-- @param id 冷却ID
-- @param cool_down_time 冷却时间
function skill:set_cool_down(obj, id, cool_down_time)
    obj:set_cool_down(id, cool_down_time)
end

-- 设置自动重复冷却时间
-- @param obj 执行者对象
-- @param cool_down_time 冷却时间
function skill:set_auto_repeat_cool_down(obj, cool_down_time)
    local auto_repeat_cool_down_time = obj:get_auto_repeat_cool_down()
    -- 调试输出已屏蔽
    -- print("skill:set_auto_repeat_cool_down obj =", obj:get_obj_id(), ";cool_down_time =", cool_down_time, ";auto_repeat_cool_down_time =", auto_repeat_cool_down_time)
    cool_down_time = cool_down_time + auto_repeat_cool_down_time
    obj:set_auto_repeat_cool_down(cool_down_time)
end

-- 扫描目标单位
-- @param obj_me 执行者对象
-- @param x 中心X坐标
-- @param y 中心Y坐标
-- @return table 目标单位列表
function skill:scan_unit_for_target(obj_me, x, y)
    local skill_info = obj_me:get_skill_info()
    --local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local operate = {}
    operate.skill_info = skill_info
    operate.obj = obj_me
    operate.scene = scene
    operate.radious = skill_info:get_radious()
    operate.x = x
    operate.y = y
    operate.target_logic_by_stand = skill_info:get_target_logic_by_stand()
    operate.target_check_by_obj_type = skill_info:get_target_check_by_obj_type()
    operate.target_must_be_teammate = skill_info:get_target_must_be_teammate()
    operate.count = skill_info:get_target_count()
    return scene:scan(operate)
end

-- 检查是否命中目标
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @return boolean 是否命中
function skill:hit_this_target(obj_me, obj_tar)
    -- CYS-MOUNT-FLIGHT
    if not require('cys_mount_flight').skill_allowed(obj_me,obj_tar,obj_me:get_skill_info():get_skill_id()) then return false end
	-- skynet.logi("hit_this_target")
    local skill_info = obj_me:get_skill_info()
    local _dbg_sid = skill_info:get_skill_id()
    -- skynet.error("[DBG_COMBAT] hit_this_target: skill=", _dbg_sid, " acc_cfg=", skill_info:get_accuracy(), " attacker=", obj_me:get_obj_id(), " target=", obj_tar:get_obj_id())
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local _sid = skill_info:get_skill_id()
    if _sid == 834 then
        -- skynet.error("[DEBUG_834] hit_this_target entered, is_friend=", tostring(obj_me:is_friend(obj_tar)))
    end
    -- 友方必定命中
    if obj_me:is_friend(obj_tar) then
        return true
    end
    -- 检查命中率
    if not self:is_hit(obj_me, obj_tar, skill_info:get_accuracy()) then
        if _sid == 834 then
            -- skynet.error("[DEBUG_834] is_hit=false, register_skill_miss_event called")
        end
        scene:get_event_enginer():register_skill_miss_event(obj_me, obj_tar, _sid, skill_info:get_delay_time())
        return false
    end
    if _sid == 834 then
        -- skynet.error("[DEBUG_834] is_hit=true, register_skill_hit_event called, skill_id=", _sid)
    elseif _sid ~= 812 then
        -- [DEBUG_834] 记录所有非普攻命中事件，观察飞剑命中时是否会走这里
        -- skynet.error("[DEBUG_834] register_skill_hit_event (non-812), skill_id=", _sid)
    end
    scene:get_event_enginer():register_skill_hit_event(obj_me, obj_tar, _sid, skill_info:get_delay_time())
    return true
end

-- 检查是否暴击目标
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @return boolean 是否暴击
function skill:critical_hit_this_target(obj_me, obj_tar)
    -- 友方不会暴击
    if obj_me:is_friend(obj_tar) then
        return false
    end
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 检查暴击率
    if self:is_critical_hit(obj_me, obj_tar, skill_info:get_critical_rate(), skill_info) then
        obj_me:on_critical_hit_target(skill_info:get_skill_id(), obj_tar)
        obj_tar:on_be_critical_hit(skill_info:get_skill_id(), obj_me)
        return true
    end
    return false
end

-- 检查目标是否存活
-- @param obj_tar 目标对象
-- @return boolean 是否存活
function skill:is_target_alive(obj_tar)
    return obj_tar:is_alive()
end

-- 计算两点间距离的平方
-- @param p1 点1 {x, y}
-- @param p2 点2 {x, y}
-- @return number 距离的平方
function skill:distance_sq(p1, p2)
    local dx = p2.x - p1.x
    local dy = p2.y - p1.y
    return dx * dx + dy * dy
end

-- 检查是否命中
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @param accuracy 命中率
-- @return boolean 是否命中
function skill:is_hit(obj_me, obj_tar, accuracy)
    local combat = combat_core.new()
    if accuracy == -1 then
        -- 计算命中率
        accuracy = combat:calculate_hit_rate(obj_me:get_hit(), obj_tar:get_miss())
        local refix_miss_rate = obj_tar:refix_miss_rate()
        local target_refix_accuracy_rate = obj_tar:target_refix_accuracy_rate(obj_me)
        local skill_info = obj_me:get_skill_info()
        local skill_accuracy_rate_up = skill_info:get_accuracy_rate_up()
        accuracy = accuracy + (target_refix_accuracy_rate / 100) + (skill_accuracy_rate_up / 100) - (refix_miss_rate / 100)
    else
        -- CYS-PVP percentage: table and fixed buff rates are 0..100; -1 uses derived ratio.
        accuracy = accuracy / 100
    end
    -- skynet.error("[DBG_COMBAT] is_hit: accuracy=", accuracy, " me_hit=", obj_me:get_hit(), " tar_miss=", obj_tar:get_miss())
    local rand = math.random(100)
    return combat:is_hit(accuracy, rand)
end
-- @param obj_me 执行者对象
-- @param obj_tar 目标对象
-- @param critical_rate 暴击率
-- @param skill_info 技能信息
-- @return boolean 是否暴击
function skill:is_critical_hit(obj_me, obj_tar, critical_rate, skill_info)
    local combat = combat_core.new()
    if critical_rate == -1 then
        -- 计算暴击率
        local mind_attack = obj_me:get_mind_attack()
        local mind_defend = require("cy_four_combat.release").dark_wound(obj_me,obj_tar,obj_tar:get_mind_defend())
        critical_rate = combat:calculate_critical_rate(mind_attack, mind_defend)
        critical_rate = obj_me:impact_refix_critical_rate(critical_rate, skill_info)
        critical_rate = critical_rate + skill_info:get_mind_attack_rate_up()
        -- print("is_critical_hit critical_rate =", critical_rate)
    else
        -- CYS-PVP percentage: table and fixed buff rates are 0..100; -1 uses derived ratio.
        critical_rate = critical_rate / 100
    end
    local rand = math.random(100)
    return combat:is_critical_hit(critical_rate, rand)
end

-- 按攻击速度修正动作时间
-- @param play_action_time 动作时间
-- @param attack_rate 攻击速度
-- @return number 修正后的动作时间
function skill:refix_play_action_time_with_attack_rate(play_action_time, attack_rate)
    return play_action_time * attack_rate / 100
end

-- 按攻击速度修正冷却时间
-- @param cool_down_time 冷却时间
-- @param attack_rate 攻击速度
-- @return number 修正后的冷却时间
function skill:refix_cool_down_time_with_attack_rate(cool_down_time, attack_rate)
    return cool_down_time * attack_rate / 100
end

-- 注册状态效果事件
-- @param reciver 接收者对象
-- @param sender 发送者对象
-- @param imp 状态效果对象
-- @param delaytime 延迟时间
-- @param critical_flag 是否暴击
-- @return boolean 是否成功
function skill:register_impact_event(reciver, sender, imp, delaytime, critical_flag)
    local skill_info = sender:get_skill_info()
    local params = sender:get_targeting_and_depleting_params()

    imp:set_skill_id(skill_info:get_skill_id())
    imp:set_skill_level(skill_info:get_skill_level())

    if critical_flag then
        imp:mark_critical_hit_flag()
    end
    local scene = reciver:get_scene()
    local eventenginer = scene:get_event_enginer()
    if imp:get_logic_id() == 3 then
        local co = combat_core.new()
		co:get_result_impact(sender, reciver, imp)
    end
    return eventenginer:register_impact_event(reciver, sender, imp, delaytime, imp:get_skill_id())
end

-- 注册技能未命中事件
-- @param reciver 接收者对象
-- @param sender 发送者对象
-- @param skill_id 技能ID
-- @param delaytime 延迟时间
-- @return boolean 是否成功
function skill:register_skill_miss_event(reciver, sender, skill_id, delaytime)
    local scene = reciver:get_scene()
    return scene:get_event_enginer():register_skill_miss_event(reciver, sender, skill_id, delaytime)
end

-- 注册被技能事件
-- @param reciver 接收者对象
-- @param sender 发送者对象
-- @param skill_id 技能ID
-- @param delaytime 延迟时间
-- @return boolean 是否成功
function skill:register_be_skill_event(reciver, sender, skill_id, delaytime)
    local skillenginer = sender:get_scene():get_skill_enginer()
    local template = skillenginer:get_skill_template(skill_id)
    -- 确定行为类型
    local behaviortype
    if template.stand_flag > 0 then
        behaviortype = define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_AMITY
    elseif template.stand_flag < 0 then
        behaviortype = define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY
    else
        behaviortype = define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_NEUTRALITY
    end
    return reciver:get_scene():get_event_enginer():register_be_skill_event(reciver, sender, skill_id, behaviortype, delaytime)
end

-- 广播目标列表消息
-- @param obj_me 执行者对象
-- @param obj_tars 目标对象列表
-- @param hitflags 命中标志列表
function skill:broadcast_target_list_message(obj_me, obj_tars, hitflags)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local ret = packet_def.GCTargetListAndHitFlags.new()
    ret.m_objID = obj_me:get_obj_id()
    ret.logic_count = obj_me:get_logic_count()
    ret.data_type = ret.enum_type.UNIT_USE_SKILL
    ret.skill_or_special_obj_id = skill_info:get_skill_id()
    ret.target_pos = params:get_target_position()
    ret.target_list = {}
    -- 收集命中的目标
    for i, flag in ipairs(hitflags) do
        if flag ~= nil then
            local obj = obj_tars[i]
            table.insert(ret.target_list, obj:get_obj_id())
        end
    end
    ret.size = #(ret.target_list)
    local scene = obj_me:get_scene()
    -- 异步化broadcast，避免在技能执行链中跨C-call边界yield导致协程崩溃
    skynet.fork(function()
        local ok, err = pcall(scene.broadcast, scene, obj_me, ret, true)
        if not ok then
            skynet.loge("skill:broadcast_target_list_message error =", err)
        end
    end)
end

-- 计算动作时间
-- @param obj_me 执行者对象
-- @return number 动作时间
function skill:calculate_action_time(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local action_time = skill_info:get_play_action_time()
    -- 如果是近战攻击且是怪物，使用怪物的攻击动画时间
    if enum_SYSTEM_USE_SKILL.MELEE_ATTACK == params:get_activated_skill() then
        if obj_me:get_obj_type() == "monster" then
            action_time = obj_me:get_attack_anim_time()
        end
    end
    return action_time
end

-- 处理冷却时间
-- @param obj_me 执行者对象
function skill:cooldown_process(obj_me)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local play_action_time = skill_info:get_play_action_time()
    local cool_down = skill_info:get_cool_down_time()
    local delay = skill_info:get_delay_time()
    -- 如果是近战攻击且是怪物，使用怪物的攻击冷却时间
    if enum_SYSTEM_USE_SKILL.MELEE_ATTACK == params:get_activated_skill() then
        if obj_me:get_obj_type() == "monster" then
            play_action_time = obj_me:get_attack_anim_time()
            cool_down = obj_me:get_attack_cool_down_time()
        end
    end
    -- 修正冷却时间
    cool_down = obj_me:refix_skill_cool_down_time(skill_info, cool_down)
    -- 冷却时间不能小于动作时间
    if cool_down < play_action_time then
        cool_down = play_action_time
    end
    -- 检查是否为自动射击技能
    local is_auto_shot_skill = skill_info:is_auto_shot_skill()
    -- 调试输出已屏蔽
    -- print("is_auto_shot_skill =", is_auto_shot_skill, ";cool_down =", cool_down)
    if is_auto_shot_skill then
        self:set_auto_repeat_cool_down(obj_me, cool_down)
    else
        self:set_cool_down(obj_me, skill_info:get_cool_down_id(), cool_down)
    end
end

-- 注册激活对象事件
-- @param obj 对象
-- @param sender 发送者对象
-- @param delaytime 延迟时间
-- @param skill_id 技能ID
-- @return boolean 是否成功
function skill:register_active_obj(obj, sender, delaytime, skill_id)
    local scene = sender:get_scene()
    local eventenginer = scene:get_event_enginer()
    return eventenginer:register_active_special_obj_event(obj:get_obj_id(), sender, delaytime, skill_id)
end

-- 获取技能逻辑（子类可重写）
function skill:skill_get_logic()

end

-- 返回skill类
return skill
