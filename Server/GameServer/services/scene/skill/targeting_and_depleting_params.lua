--[[
    技能目标选择与消耗参数类
    用于存储技能释放过程中的各种参数，包括目标信息、消耗资源、错误码等
    在技能释放前进行条件检查和资源消耗时使用
]]

local class = require "class"
local define = require "define"
local pet_guid = require "pet_guid"

-- 技能目标选择与消耗参数类
local targeting_and_depleting_params = class("targeting_and_depleting_params")

-- 构造函数：初始化参数对象
function targeting_and_depleting_params:ctor()
    self:reset()
    self.target_position = {x = -1, y = -1}
end

-- 重置所有参数为默认值
function targeting_and_depleting_params:reset()
    self.delay_time = 0                      -- 延迟时间
    self.error_code = 0                      -- 错误码
    self.errparam = 0                        -- 错误参数
    self.ignore_condition_check_flag = false -- 是否忽略条件检查标志
    self.target_count = 0                     -- 目标数量
    self.active_time = 0                      -- 激活时间
    self.target_obj_id = define.INVAILD_ID    -- 目标对象ID
    self.skill_id = define.INVAILD_ID         -- 技能ID
    self.skill_level = 1                      -- 技能等级
    self.target_dir = -1                      -- 目标方向
    self.target_guid = define.INVAILD_ID      -- 目标GUID
    self.ignore_cool_down_write_flag = false -- 是否跳过冷却写入
    self.depleted_strike_point = 1            -- 已消耗的连击点
    self.target_bag_index = define.INVAILD_ID -- 目标背包索引
    self.deplted_item_guid = nil             -- 已消耗物品的GUID
    self.activated_skill = define.INVAILD_ID  -- 激活的技能ID
    self.activated_script = define.INVAILD_ID -- 激活的脚本ID
    self.script_arg_1 = define.INVAILD_ID     -- 脚本参数1
    self.script_arg_2 = define.INVAILD_ID     -- 脚本参数2
	
    -- 已消耗物品的背包索引和物品索引
    self.bag_index_of_deplted_item = define.INVAILD_ID
    self.item_index_of_deplted_item = define.INVAILD_ID
    self.bag_index_of_deplted_item_uicall = define.INVAILD_ID
    self.item_index_of_deplted_item_uicall = define.INVAILD_ID
	
    -- 目标宠物GUID和天赋ID集合
    self.target_pet_guid = pet_guid.new()
	self.talent_id = {}
end

-- 设置已消耗物品的物品索引
-- @param index 物品索引
function targeting_and_depleting_params:set_item_index_of_deplted_item(index)
    self.item_index_of_deplted_item = index
end

-- 获取已消耗物品的物品索引
-- @return 物品索引
function targeting_and_depleting_params:get_item_index_of_deplted_item()
    return self.item_index_of_deplted_item
end

-- 设置已消耗物品的物品索引（UI调用）
-- @param index 物品索引
function targeting_and_depleting_params:set_item_index_of_deplted_item_uicall(index)
    self.item_index_of_deplted_item_uicall = index
end

-- 获取已消耗物品的物品索引（UI调用）
-- @return 物品索引
function targeting_and_depleting_params:get_item_index_of_deplted_item_uicall()
    return self.item_index_of_deplted_item_uicall
end

-- 设置已消耗物品的背包索引
-- @param index 背包索引
function targeting_and_depleting_params:set_bag_index_of_deplted_item(index)
    self.bag_index_of_deplted_item = index
end

-- 获取已消耗物品的背包索引
-- @return 背包索引
function targeting_and_depleting_params:get_bag_index_of_deplted_item()
    return self.bag_index_of_deplted_item
end

-- 设置已消耗物品的背包索引（UI调用）
-- @param index 背包索引
function targeting_and_depleting_params:set_bag_index_of_deplted_item_uicall(index)
    self.bag_index_of_deplted_item_uicall = index
end

-- 获取已消耗物品的背包索引（UI调用）
-- @return 背包索引
function targeting_and_depleting_params:get_bag_index_of_deplted_item_uicall()
    return self.bag_index_of_deplted_item_uicall
end

-- 设置错误码
-- @param code 错误码
function targeting_and_depleting_params:set_errcode(code)
    self.error_code = code
end

-- 设置错误参数
-- @param errparam 错误参数
function targeting_and_depleting_params:set_errparam(errparam)
    self.errparam = errparam
end

-- 设置是否忽略条件检查标志
-- @param flag 是否忽略条件检查
function targeting_and_depleting_params:set_ignore_condition_check_flag(flag)
    self.ignore_condition_check_flag = flag
end

-- 获取是否忽略条件检查标志
-- @return 是否忽略条件检查
function targeting_and_depleting_params:get_ignore_condition_check_flag()
    return self.ignore_condition_check_flag
end

function targeting_and_depleting_params:set_ignore_cool_down_write_flag(flag)
    self.ignore_cool_down_write_flag = flag
end

function targeting_and_depleting_params:get_ignore_cool_down_write_flag()
    return self.ignore_cool_down_write_flag
end

-- 设置延迟时间
-- @param time 延迟时间
function targeting_and_depleting_params:set_delay_time(time)
    self.delay_time = time
end

-- 获取延迟时间
-- @return 延迟时间
function targeting_and_depleting_params:get_delay_time()
    return self.delay_time
end

-- 设置目标数量
-- @param count 目标数量
function targeting_and_depleting_params:set_target_count(count)
    self.target_count = count
end

-- 获取目标数量
-- @return 目标数量，默认返回0
function targeting_and_depleting_params:get_target_count()
    return self.target_count or 0
end

-- 获取目标位置
-- @return 目标位置表 {x, y}
function targeting_and_depleting_params:get_target_position()
    return self.target_position
end

-- 获取目标对象ID
-- @return 目标对象ID
function targeting_and_depleting_params:get_target_obj()
    return self.target_obj_id
end

-- 获取激活的技能ID（返回skill_id）
-- @return 技能ID
function targeting_and_depleting_params:get_activated_skill()
    return self.skill_id
end

-- 设置激活的技能ID（设置skill_id）
-- @param skill_id 技能ID
function targeting_and_depleting_params:set_activated_skill(skill_id)
    self.skill_id = skill_id
end

-- 设置技能等级
-- @param level 技能等级
function targeting_and_depleting_params:set_skill_level(level)
    self.skill_level = level
end

-- 获取技能等级
-- @return 技能等级
function targeting_and_depleting_params:get_skill_level()
    return self.skill_level
end

-- 设置目标对象ID
-- @param obj_id 目标对象ID
function targeting_and_depleting_params:set_target_obj(obj_id)
    self.target_obj_id = obj_id
end

-- 设置目标位置
-- @param pos_tar 目标位置表 {x, y}
function targeting_and_depleting_params:set_target_position(pos_tar)
    if pos_tar.x ~= 0 and pos_tar.y ~= 0 then
        self.target_position = {}
        self.target_position.x = pos_tar.x
        self.target_position.y = pos_tar.y
    end
end

-- 设置目标方向
-- @param dir 目标方向
function targeting_and_depleting_params:set_target_dir(dir)
    self.target_dir = dir
end

-- 获取目标方向
-- @return 目标方向
function targeting_and_depleting_params:get_target_dir()
    return self.target_dir
end

-- 设置目标GUID
-- @param guid 目标GUID
function targeting_and_depleting_params:set_target_guid(guid)
    self.target_guid = guid
end

-- 获取错误码
-- @return 错误码
function targeting_and_depleting_params:get_errorcode()
    return self.error_code
end

-- 获取已消耗的连击点
-- @return 已消耗的连击点
function targeting_and_depleting_params:get_depleted_strike_point()
    return self.depleted_strike_point
end

-- 设置目标背包索引
-- @param index 背包索引
function targeting_and_depleting_params:set_target_bag_index(index)
    self.target_bag_index = index
end

-- 获取目标背包索引
-- @return 背包索引
function targeting_and_depleting_params:get_target_bag_index()
    return self.target_bag_index
end

-- 设置目标宠物GUID
-- @param guid 宠物GUID
function targeting_and_depleting_params:set_target_pet_guid(guid)
    self.target_pet_guid = guid
end

-- 获取目标宠物GUID
-- @return 宠物GUID
function targeting_and_depleting_params:get_target_pet_guid()
    return self.target_pet_guid
end

-- 设置已消耗物品的GUID
-- @param guid 物品GUID
function targeting_and_depleting_params:set_deplted_item_guid(guid)
    self.deplted_item_guid = guid
end

-- 获取已消耗物品的GUID
-- @return 物品GUID
function targeting_and_depleting_params:get_deplted_item_guid()
    return self.deplted_item_guid
end

-- 设置激活的脚本ID
-- @param script 脚本ID
function targeting_and_depleting_params:set_activated_script(script)
    self.activated_script = script
end

-- 获取激活的脚本ID
-- @return 脚本ID
function targeting_and_depleting_params:get_activated_script()
    return self.activated_script
end

-- 设置激活的技能ID（设置activated_skill）
-- @param skill 技能ID
function targeting_and_depleting_params:set_activated_skill(skill)
    self.activated_skill = skill
end

-- 获取激活的技能ID（返回activated_skill）
-- @return 技能ID
function targeting_and_depleting_params:get_activated_skill()
    return self.activated_skill
end

-- 设置脚本参数1
-- @param arg1 脚本参数1
function targeting_and_depleting_params:set_script_arg_1(arg1)
    self.script_arg_1 = arg1
end

-- 获取脚本参数1
-- @return 脚本参数1
function targeting_and_depleting_params:get_script_arg_1()
    return self.script_arg_1
end

-- 设置脚本参数2
-- @param arg2 脚本参数2
function targeting_and_depleting_params:set_script_arg_2(arg2)
    self.script_arg_2 = arg2
end

-- 获取脚本参数2
-- @return 脚本参数2
function targeting_and_depleting_params:get_script_arg_2()
    return self.script_arg_2
end

-- 设置脚本参数3
-- @param arg3 脚本参数3
function targeting_and_depleting_params:set_script_arg_3(arg3)
    self.script_arg_3 = arg3
end

-- 获取脚本参数3
-- @return 脚本参数3
function targeting_and_depleting_params:get_script_arg_3()
    return self.script_arg_3
end

-- 设置消耗的怒气值
-- @param rage 怒气值
function targeting_and_depleting_params:set_deplete_rage(rage)
    self.deplete_rage = rage
end

-- 设置消耗的连击点
-- @param point 连击点
function targeting_and_depleting_params:set_deplete_strike_point(point)
    self.depleted_strike_point = point
end

-- 设置激活时间
-- @param active_time 激活时间
function targeting_and_depleting_params:set_active_time(active_time)
    self.active_time = active_time
end

-- 获取激活时间
-- @return 激活时间
function targeting_and_depleting_params:get_active_time()
    return self.active_time
end

-- 获取天赋ID
-- @param id 天赋ID
-- @return 是否拥有该天赋
function targeting_and_depleting_params:get_talent_id(id)
    return self.talent_id[id]
end

-- 设置天赋ID
-- @param id 天赋ID
function targeting_and_depleting_params:set_talent_id(id)
    self.talent_id[id] = true
end

-- 返回targeting_and_depleting_params类
return targeting_and_depleting_params
