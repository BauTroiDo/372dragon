--[[
    状态效果（Impact）类
    用于管理游戏中的各种状态效果，包括Buff、Debuff等
    包含状态效果的持续时间、间隔、互斥关系、参数等属性
]]

local class = require "class"

-- 状态效果类
local impact = class("impact")

-- 状态效果标志位枚举
impact.enum_IDX = {
    IDX_FADE_OUT = "IDX_FADE_OUT",           -- 淡出标志（状态即将消失）
    IDX_CRITICAL = "IDX_CRITICAL",           -- 暴击标志
    IDX_CREATE_BY_PLAYER = "IDX_CREATE_BY_PLAYER"  -- 由玩家创建的标志
}

-- 构造函数：初始化状态效果对象
function impact:ctor()
    self.sn = nil                    -- 序列号
    self.data_index = nil            -- 数据索引
    self.impact_id = nil             -- 状态效果ID
    self.skill_id = nil              -- 技能ID
    self.is_over_timed = false       -- 是否超时
    self.caster_obj_id = nil         -- 施法者对象ID
    self.caster_unique_id = nil      -- 施法者唯一ID
    self.logic_id = nil              -- 逻辑ID
    self.caster_logic_count = 0      -- 施法者逻辑计数
    self.continuance = 0             -- 持续时间（毫秒）
    self.continuance_elapsed = 0     -- 已持续的时间（毫秒）
    self.interval_elapsed = 0        -- 间隔已过时间（毫秒）
    self.interval = 0                -- 间隔时间（毫秒）
    self.mutex_id = 0                -- 互斥组ID
    self.mutex_priority = 0          -- 互斥优先级
    self.flags = {}                  -- 标志位集合
    self.params = {}                 -- 参数集合
    self.transport_dest = {}         -- 传送目标位置
    self.use_skill_success_fully_count = 0  -- 成功使用技能次数
    self.hit_target_count = 0        -- 命中目标次数
    self.can_be_cancled = false      -- 是否可被取消
    self.skill_segment = 0           -- 技能段数
    -- self.features = {}            -- 特性（已注释）
end

-- 清理状态效果对象，重置所有属性
function impact:clean_up()
    require("cy_four_combat.state_cache")[self] = nil   -- skill-logic guard
    self._cy_four_native = nil
    self._cy_four_formation_attr = nil
    self.sn = nil
    self.data_index = nil
    self.impact_id = nil
    self.skill_id = nil
    self.caster_obj_id = nil
    self.caster_unique_id = nil
    self.caster_logic_count = 0
    self.continuance = 0
    self.continuance_elapsed = 0
    self.interval_elapsed = 0
    self.interval = 0
    self.mutex_id = 0
    self.mutex_priority = 0
    self.flags = {}
    self.params = {}
    self.transport_dest = {}
    self.use_skill_success_fully_count = 0
    self.hit_target_count = 0
    self.logic_count = 0
    self.can_be_cancled = false
    self.skill_segment = 0
    -- self.features = {}
end

-- 从数据表初始化状态效果
-- @param data 数据表，包含状态效果的各种属性
function impact:init_from_data(data)
    -- 计算剩余持续时间（总持续时间 - 已持续时间）
    data.continuance = (data.continuance or 0) - (data.continuance_elapsed or 0)
    data.continuance_elapsed = 0
    -- 遍历数据表，将属性复制到当前对象
    for key, value in pairs(data) do
        -- 清理params中的空键
        if key == "params" and type(value) == "table" then
            for k in pairs(value) do
                if k == "" then
                    value[k] = nil
                end
            end
        end
        self[key] = value
    end
end



-- 获取序列号
-- @return 序列号
function impact:get_sn()
    return self.sn
end

-- 设置序列号
-- @param sn 序列号
function impact:set_sn(sn)
    self.sn = sn
end

-- 设置逻辑ID
-- @param logic_id 逻辑ID
function impact:set_logic_id(logic_id)
    self.logic_id = logic_id
end

-- 获取逻辑ID
-- @return 逻辑ID
function impact:get_logic_id()
    return self.logic_id
end

-- 添加百分比参数（默认值为100）
-- @param key 参数键
-- @param value 要添加的值
function impact:add_rate_params(key,value)
	self.params[key] = (self.params[key] or 100) + value
end

-- 添加点数参数（默认值为0）
-- @param key 参数键
-- @param value 要添加的值
function impact:add_point_params(key,value)
	self.params[key] = (self.params[key] or 0) + value
end

-- 获取特性值
-- @return 特性值
function impact:get_features()
    return self.features_value
end

-- 设置特性值
-- @param value 特性值
function impact:set_features(value)
	self.features_value = value
end

-- 获取数据索引
-- @return 数据索引，默认返回-1
function impact:get_data_index()
    return self.data_index or -1
end

-- 设置数据索引
-- @param data_index 数据索引
function impact:set_data_index(data_index)
    self.data_index = data_index
end

-- 获取状态效果ID
-- @return 状态效果ID
function impact:get_impact_id()
    return self.impact_id
end

-- 设置状态效果ID
-- @param impact_id 状态效果ID
function impact:set_impact_id(impact_id)
    self.impact_id = impact_id
end

-- 获取类ID
-- @return 类ID
function impact:get_class_id()
    return self.class_id
end

-- 设置类ID
-- @param class_id 类ID
function impact:set_class_id(class_id)
    self.class_id = class_id
end

-- 获取技能ID
-- @return 技能ID
function impact:get_skill_id()
    return self.skill_id
end

-- 设置技能ID
-- @param skill_id 技能ID
function impact:set_skill_id(skill_id)
    self.skill_id = skill_id
end

-- 获取技能等级
-- @return 技能等级，默认返回1
function impact:get_skill_level()
    return self.skill_level or 1
end

-- 设置技能等级
-- @param skill_level 技能等级
function impact:set_skill_level(skill_level)
    self.skill_level = skill_level
end

-- 设置是否超时
-- @param is 是否超时
function impact:set_is_over_timed(is)
    self.is_over_timed = is
end

-- 获取是否超时
-- @return 是否超时
function impact:get_is_over_timed()
    return self.is_over_timed
end

-- 获取施法者对象ID
-- @return 施法者对象ID
function impact:get_caster_obj_id()
    return self.caster_obj_id
end

-- 设置施法者对象ID
-- @param caster_obj_id 施法者对象ID
function impact:set_caster_obj_id(caster_obj_id)
    self.caster_obj_id = caster_obj_id
end

-- 获取施法者逻辑计数
-- @return 施法者逻辑计数
function impact:get_caster_logic_count()
    return self.caster_logic_count
end

-- 设置施法者逻辑计数
-- @param caster_logic_count 施法者逻辑计数
function impact:set_caster_logic_count(caster_logic_count)
    self.caster_logic_count = caster_logic_count
end

-- 获取持续时间
-- @return 持续时间（毫秒）
function impact:get_continuance()
    return self.continuance
end

-- 设置持续时间
-- @param continuance 持续时间（毫秒）
function impact:set_continuance(continuance)
    self.continuance = continuance
end

-- 获取已持续的时间
-- @return 已持续的时间（毫秒）
function impact:get_continuance_elapsed()
    return self.continuance_elapsed
end

-- 设置已持续的时间
-- @param continuance_elapsed 已持续的时间（毫秒）
function impact:set_continuance_elapsed(continuance_elapsed)
    self.continuance_elapsed = continuance_elapsed
end

-- 获取间隔已过时间
-- @return 间隔已过时间（毫秒）
function impact:get_interval_elapsed()
    return self.interval_elapsed
end

-- 设置间隔已过时间
-- @param interval_elapsed 间隔已过时间（毫秒）
function impact:set_interval_elapsed(interval_elapsed)
    self.interval_elapsed = interval_elapsed
end

-- 检查是否由玩家创建
-- @return 是否由玩家创建
function impact:is_create_by_player()
    return self.flags[self.enum_IDX.IDX_CREATE_BY_PLAYER] == 1
end

-- 标记为由玩家创建
function impact:mark_create_by_player_flag()
    self.flags[self.enum_IDX.IDX_CREATE_BY_PLAYER] = 1
end

-- 清除由玩家创建的标记
function impact:clear_create_by_player_flag()
    self.flags[self.enum_IDX.IDX_CREATE_BY_PLAYER] = 0
end

-- 检查是否正在淡出（即将消失）
-- @return 是否正在淡出
function impact:is_fade_out()
    return self.flags[self.enum_IDX.IDX_FADE_OUT] == 1
end

-- 标记为淡出状态
function impact:mark_fade_out_flag()
    self.flags[self.enum_IDX.IDX_FADE_OUT] = 1
end

-- 清除淡出标记
function impact:clear_fade_out_flag()
    self.flags[self.enum_IDX.IDX_FADE_OUT] = 0
end

-- 检查是否为暴击
-- @return 是否为暴击
function impact:is_critical_hit()
    return self.flags[self.enum_IDX.IDX_CRITICAL] == 1
end

-- 标记为暴击
function impact:mark_critical_hit_flag()
    self.flags[self.enum_IDX.IDX_CRITICAL] = 1
end

-- 清除暴击标记
function impact:clear_critical_hit_flag()
    self.flags[self.enum_IDX.IDX_CRITICAL] = 0
end

-- 根据索引获取参数
-- @param idx 参数索引
-- @return 参数值
function impact:get_param_by_index(idx)
    return self.params[idx]
end

-- 根据索引设置参数
-- @param idx 参数索引
-- @param value 参数值
function impact:set_param_by_index(idx, value)
    self.params[idx] = value
end

-- 设置参数集合
-- @param params 参数表
function impact:set_params(params)
    self.params = params
end

-- 设置施法者唯一ID
-- @param unique_id 唯一ID
function impact:set_caster_unique_id(unique_id)
    self.caster_unique_id = unique_id
end

-- 获取施法者唯一ID
-- @return 施法者唯一ID
function impact:get_caster_unique_id()
    return self.caster_unique_id
end

-- 获取传送目标位置
-- @return 传送目标位置
function impact:get_transport_dest()
    return self.transport_dest
end

-- 获取互斥组ID
-- @return 互斥组ID
function impact:get_mutex_id()
    return self.mutex_id
end

-- 设置互斥组ID
-- @param mutex_id 互斥组ID
function impact:set_mutex_id(mutex_id)
    self.mutex_id = mutex_id
end

-- 获取互斥优先级
-- @return 互斥优先级
function impact:get_mutex_priority()
    return self.mutex_priority
end

-- 设置互斥优先级
-- @param mutex_priority 互斥优先级
function impact:set_mutex_priority(mutex_priority)
    self.mutex_priority = mutex_priority
end

-- 检查是否可被取消
-- @return 是否可被取消，默认返回true
function impact:is_can_be_cancled()
    if self.can_be_cancled == nil then
        return true
    end
    return self.can_be_cancled
end

-- 设置是否可被取消
-- @param can 是否可被取消
function impact:set_can_be_cancled(can)
    self.can_be_cancled = can
end

-- 检查是否在离线时继续计数
-- @return 是否在离线时继续计数
function impact:is_counter_when_offline()
    return self.counter_when_offline
end

-- 设置是否在离线时继续计数
-- @param is 是否在离线时继续计数
function impact:set_counter_when_offline(is)
    self.counter_when_offline = is
end

-- 检查是否需要吟唱支持
-- @return 是否需要吟唱支持
function impact:is_need_channel_support()
    return self.need_channel_support
end

-- 设置是否需要吟唱支持
-- @param need 是否需要吟唱支持
function impact:set_need_channel_support(need)
    self.need_channel_support = need
end

-- 检查是否需要装备支持
-- @return 是否需要装备支持
function impact:is_need_equip_support()
    return self.need_equip_support
end

-- 设置是否需要装备支持
-- @param need 是否需要装备支持
function impact:set_need_equip_support(need)
    self.need_equip_support = need
end

-- 检查是否在尸体上保留
-- @return 是否在尸体上保留
function impact:is_remain_on_corpse()
    return self.remain_on_corpse
end

-- 设置是否在尸体上保留
-- @param remain 是否在尸体上保留
function impact:set_remain_on_corpse(remain)
    self.remain_on_corpse = remain
end

-- 设置间隔时间
-- @param interval 间隔时间（毫秒）
function impact:set_interval(interval)
    self.interval = interval
end

-- 获取间隔时间
-- @return 间隔时间（毫秒）
function impact:get_interval()
    return self.interval
end

-- 获取间隔已过时间（拼写错误的方法名，保留兼容性）
-- @return 间隔已过时间（毫秒）
function impact:get_interval_elpased()
    return self.interval_elapsed
end

-- 设置间隔已过时间（拼写错误的方法名，保留兼容性）
-- @param elapsed 间隔已过时间（毫秒）
function impact:set_interval_elpased(elapsed)
    self.interval_elapsed = elapsed
end

-- 设置激活次数
-- @param times 激活次数
function impact:set_activate_times(times)
    self.activate_times = times
end

-- 获取激活次数
-- @return 激活次数
function impact:get_activate_times()
    return self.activate_times
end

-- 检查是否可被驱散
-- @return 是否可被驱散
function impact:is_can_be_dispeled()
    return self.can_be_dispeled
end

-- 设置是否可被驱散
-- @param can 是否可被驱散
function impact:set_can_be_dispeled(can)
    self.can_be_dispeled = can
end

-- 检查是否在单位受到伤害时淡出
-- @return 是否在单位受到伤害时淡出
function impact:is_fade_out_when_unit_on_damage()
    return self.fade_out_when_unit_on_damage
end

-- 设置是否在单位受到伤害时淡出
-- @param is 是否在单位受到伤害时淡出
function impact:set_fade_out_when_unit_on_damage(is)
    self.fade_out_when_unit_on_damage = is
end

-- 检查是否在单位移动时淡出
-- @return 是否在单位移动时淡出
function impact:is_fade_out_when_unit_on_move()
    return self.fade_out_when_unit_on_move
end

-- 设置是否在单位移动时淡出
-- @param is 是否在单位移动时淡出
function impact:set_fade_out_when_unit_on_move(is)
    self.fade_out_when_unit_on_move = is
end

-- 检查是否在单位开始行动时淡出
-- @return 是否在单位开始行动时淡出
function impact:is_fade_out_when_unit_on_action_start()
    return self.fade_out_when_unit_on_action_start
end

-- 设置是否在单位开始行动时淡出
-- @param is 是否在单位开始行动时淡出
function impact:set_fade_out_when_unit_on_action_start(is)
    self.fade_out_when_unit_on_action_start = is
end

-- 检查是否在单位离线时淡出
-- @return 是否在单位离线时淡出
function impact:is_fade_out_when_unit_offline()
    return self.fade_out_when_unit_offline
end

-- 设置是否在单位离线时淡出
-- @param is 是否在单位离线时淡出
function impact:set_fade_out_when_unit_offline(is)
    self.fade_out_when_unit_offline = is
end

-- 设置成功使用技能次数
-- @param count 成功使用技能次数
function impact:set_use_skill_success_fully_count(count)
    self.use_skill_success_fully_count = count
end

-- 获取成功使用技能次数
-- @return 成功使用技能次数
function impact:get_use_skill_success_fully_count()
    return self.use_skill_success_fully_count
end

-- 设置命中目标次数
-- @param count 命中目标次数
function impact:set_hit_target_count(count)
    self.hit_target_count = count
end

-- 获取命中目标次数
-- @return 命中目标次数
function impact:get_hit_target_count()
    return self.hit_target_count
end

-- 获取站立标志
-- @return 站立标志
function impact:get_stand_flag()
    return self.stand_flag
end

-- 设置站立标志
-- @param flag 站立标志
function impact:set_stand_flag(flag)
    self.stand_flag = flag
end

-- 设置技能段数
-- @param segment 技能段数
function impact:set_skill_segment(segment)
    self.skill_segment = segment
end

-- 获取技能段数
-- @return 技能段数
function impact:get_skill_segment()
    return self.skill_segment
end

-- 获取是否已输出
-- @return 是否已输出
function impact:get_is_out()
    return self.is_out
end

-- 设置为已输出状态
function impact:set_is_out()
    self.is_out = true
end

-- 获取重楼腰带标志
-- @return 重楼腰带标志
function impact:get_chonglou_sash()
    return self.chonglou_sash
end

-- 设置重楼腰带标志
function impact:set_chonglou_sash()
    self.chonglou_sash = true
end

-- 返回impact类
return impact