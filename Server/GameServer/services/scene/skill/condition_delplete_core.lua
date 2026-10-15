--[[
    技能条件与消耗核心模块
    负责处理技能释放前的条件检查和资源消耗逻辑
    包括：法力值、怒气值、生命值、连击点等资源的检查与消耗
    以及各种特殊条件的判断（如目标等级、状态效果、配偶关系等）
]]

local class = require "class"
local define = require "define"

-- 主模块类
local condition_delplete_core = class("condition_delplete_core")

-- 基类：条件与消耗逻辑的抽象基类
local ConDepLogic_T = class("ConDepLogic_T")

-- 按固定值消耗法力值
local CD_ManaByValue_T = class("CD_ManaByValue_T", ConDepLogic_T)

-- 按百分比消耗法力值
local CD_ManaByRate_T = class("CD_ManaByRate_T", ConDepLogic_T)

-- 按百分比消耗怒气值
local CD_RageByRate_T = class("CD_RageByRate_T", ConDepLogic_T)

-- 按段数消耗连击点
local CD_StrikePointBySegment_T = class("CD_StrikePointBySegment_T", ConDepLogic_T)

-- 消耗所有怒气值
local D_AllRage_T = class("D_AllRage_T", ConDepLogic_T)

-- 条件：目标等级必须小于指定值
local C_TargetLevelMustLessThanByValues_T = class("C_TargetLevelMustLessThanByValues_T", ConDepLogic_T)

-- 条件：单位必须拥有指定状态效果
local C_UnitHaveImpact_T = class("C_UnitHaveImpact_T", ConDepLogic_T)

-- 条件：单位生命值必须低于指定百分比
local C_UnitHpLessThanByRate_T = class("C_UnitHpLessThanByRate_T", ConDepLogic_T)

-- 条件：目标必须拥有指定状态效果
local C_TargetMustHaveImpact_T = class("C_TargetMustHaveImpact_T", ConDepLogic_T)

-- 消耗：取消指定状态效果
local D_CancelSpecialImpact_T = class("D_CancelSpecialImpact_T", ConDepLogic_T)

-- 条件：目标必须是自己的配偶
local C_TargetMustBeMySpouse_T = class("C_TargetMustBeMySpouse_T", ConDepLogic_T)

-- 按百分比消耗生命值
local CD_HpByRate_T = class("CD_HpByRate_T", ConDepLogic_T)

-- 条件：生命值必须达到指定百分比
local C_HpByRate_T = class("C_HpByRate_T", ConDepLogic_T)

-- 按固定值消耗曼陀罗花
local CD_FlowerByValue_T = class("CD_FlowerByValue_T", ConDepLogic_T)

-- 按固定值消耗生命值
local CD_HPByValue_T = class("CD_HPByValue_T", ConDepLogic_T)

-- 条件：单位不能拥有指定状态效果
local C_UnitNotHaveImpact_T = class("C_UnitNotHaveImpact_T", ConDepLogic_T)

-- 设置基类的ID为无效ID
ConDepLogic_T.ID = define.ConditionAndDepleteID.CD_INVALID

-- 基类条件检查方法（默认返回true）
-- @param obj_me 执行者对象
-- @param data 条件数据
-- @return boolean 是否满足条件
function ConDepLogic_T:ConditionCheck()
    return true
end

-- 基类消耗方法（默认返回true）
-- @param obj_me 执行者对象
-- @param data 消耗数据
-- @return boolean 消耗是否成功
function ConDepLogic_T:Deplete()
    return true
end

-- 设置条件ID：单位不能拥有指定状态效果
C_UnitNotHaveImpact_T.ID = define.ConditionAndDepleteID.C_TARGET_MUST_NOT_HAVE_IMPACT

-- 检查单位是否不拥有指定状态效果
-- @param obj_me 执行者对象
-- @param data 条件数据，params[1]为状态效果集合ID
-- @return boolean 是否满足条件
function C_UnitNotHaveImpact_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local collection = data.params[1]
    -- 如果单位拥有指定集合中的状态效果，则条件不满足
    if obj_me:impact_have_impact_in_specific_collection(collection) then
        params:set_errcode(define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_UnitNotHaveImpact_T:Deplete()
    return true
end

-- 设置条件ID：目标必须拥有指定状态效果
C_TargetMustHaveImpact_T.ID = define.ConditionAndDepleteID.C_TARGET_MUST_HAVE_IMPACT

-- 检查目标是否拥有指定状态效果
-- @param obj_me 执行者对象
-- @param data 条件数据，params[1]为状态效果集合ID
-- @return boolean 是否满足条件
function C_TargetMustHaveImpact_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local collection = data.params[1]
    -- 获取目标对象
    local tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    if tar == nil then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- 检查目标是否拥有指定集合中的状态效果
    if not tar:impact_have_impact_in_specific_collection(collection) then
        params:set_errcode(define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_TargetMustHaveImpact_T:Deplete()
    return true
end


-- 设置条件ID：单位生命值必须低于指定百分比
C_UnitHpLessThanByRate_T.ID = define.ConditionAndDepleteID.C_UNIT_HP_MUST_LESS_THAN_BY_RATE

-- 检查单位生命值是否低于指定百分比
-- @param obj_me 执行者对象
-- @param data 条件数据，params[1]为百分比（0-100）
-- @return boolean 是否满足条件
function C_UnitHpLessThanByRate_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local rate = data.params[1]
    -- 计算生命值阈值
    local hp = obj_me:get_max_hp()
    hp = math.floor(hp * rate / 100)
    -- 检查当前生命值是否低于阈值
    if obj_me:get_hp() > hp then
        params:set_errcode(define.OPERATE_RESULT.OR_TOO_MUCH_HP)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_UnitHpLessThanByRate_T:Deplete()
    return true
end

-- 设置条件ID：目标等级必须小于指定值
C_TargetLevelMustLessThanByValues_T.ID = define.ConditionAndDepleteID.C_TARGET_LEVEL_MUST_LESS_THAN_BY_VALUE

-- 检查目标等级是否小于指定值
-- @param obj_me 执行者对象
-- @param data 条件数据，params[1]为等级上限
-- @return boolean 是否满足条件
function C_TargetLevelMustLessThanByValues_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local level = data.params[1]
    -- 获取目标对象
    local tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    if tar == nil then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- 调试输出已屏蔽
    -- print("tar:get_level() =", tar:get_level(), "level =", level)
    -- 检查目标等级是否超过限制
    if tar:get_level() > level then
        params:set_errcode(define.OPERATE_RESULT.OR_NO_LEVEL)
        return false
    end
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_TargetLevelMustLessThanByValues_T:Deplete()
    return true
end

-- 设置条件ID：单位必须拥有指定状态效果
C_UnitHaveImpact_T.ID = define.ConditionAndDepleteID.C_UNIT_MUST_HAVE_IMPACT

-- 检查单位是否拥有指定状态效果
-- @param obj_me 执行者对象
-- @param data 条件数据，params[1]为状态效果集合ID
-- @return boolean 是否满足条件
function C_UnitHaveImpact_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local collection = data.params[1]
    -- 检查单位是否拥有指定集合中的状态效果
    if not obj_me:impact_have_impact_in_specific_collection(collection) then
        params:set_errcode(define.OPERATE_RESULT.OR_U_CANNT_DO_THIS_RIGHT_NOW)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_UnitHaveImpact_T:Deplete()
    return true
end

-- 设置消耗ID：按固定值消耗法力值
CD_ManaByValue_T.ID = define.ConditionAndDepleteID.CD_MANA_BY_VALUE

-- 检查法力值是否足够
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要消耗的法力值
-- @return boolean 是否满足条件
function CD_ManaByValue_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗法力值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local need = data.params[1]
    local mana = obj_me:get_mp()
    need = need < 0 and 0 or need
    -- 检查法力值是否足够
    if mana < need then
        params:set_errcode(define.OPERATE_RESULT.OR_LACK_MANA)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗法力值
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要消耗的法力值
-- @return boolean 消耗是否成功
function CD_ManaByValue_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗法力值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local need = data.params[1]
    need = need < 0 and 0 or need
    -- 扣除法力值
    obj_me:mana_increment(-need, obj_me)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置消耗ID：按百分比消耗法力值
CD_ManaByRate_T.ID = define.ConditionAndDepleteID.CD_MANA_BY_RATE

-- 检查法力值是否足够（按百分比计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比（0-100）
-- @return boolean 是否满足条件
function CD_ManaByRate_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗法力值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local rate = data.params[1]
    local mana = obj_me:get_max_mp()
    -- 计算需要消耗的法力值
    local need = math.floor(mana * rate / 100)
    need = need < 0 and 0 or need
    -- 检查法力值是否足够
    if obj_me:get_mp() < need then
        params:set_errcode(define.OPERATE_RESULT.OR_LACK_MANA)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗法力值（按百分比计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比（0-100）
-- @return boolean 消耗是否成功
function CD_ManaByRate_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗法力值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local rate = data.params[1]
    local mana = obj_me:get_max_mp()
    -- 计算需要消耗的法力值
    local need = math.floor(mana * rate / 100)
    need = need < 0 and 0 or need
    -- 扣除法力值
    obj_me:mana_increment(-need, obj_me)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置消耗ID：按百分比消耗怒气值
CD_RageByRate_T.ID = define.ConditionAndDepleteID.CD_RAGE_BY_RATE

-- 检查怒气值是否足够（按百分比计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比（0-100）
-- @return boolean 是否满足条件
function CD_RageByRate_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗怒气值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local rate = data.params[1]
    local rage = obj_me:get_max_rage()
    -- 计算需要消耗的怒气值
    local need = math.floor(rage * rate / 100)
    need = need < 0 and 0 or need
    -- 检查怒气值是否足够
    if obj_me:get_rage() < need then
        params:set_errcode(define.OPERATE_RESULT.OR_NOT_ENOUGH_RAGE)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗怒气值（按百分比计算或全部消耗）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比，params[2]为消耗模式（0=按百分比，1=全部消耗）
-- @return boolean 消耗是否成功
function CD_RageByRate_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗怒气值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local rate = data.params[1]
    local rage = obj_me:get_max_rage()
    local need
    -- 根据参数2决定消耗模式
    if data.params[2] == 0 then
        -- 按百分比消耗
        need = math.floor(rage * rate / 100)
    else
        -- 消耗全部怒气值
        need = obj_me:get_rage()
    end
    need = need < 0 and 0 or need
    -- 扣除怒气值
    obj_me:rage_increment(-need, obj_me)
    params:set_deplete_rage(need)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置消耗ID：按段数消耗连击点
CD_StrikePointBySegment_T.ID = define.ConditionAndDepleteID.CD_STRIKE_POINT_BY_SEGMENT

-- 检查连击点是否足够（按段数计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要的段数
-- @return boolean 是否满足条件
function CD_StrikePointBySegment_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗连击点
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local segment = data.params[1]
    -- 检查连击点是否足够（每段包含STRIKE_POINT_SEGMENT_SIZE个点）
    if obj_me:get_strike_point() < segment * define.STRIKE_POINT_SEGMENT_SIZE then
        params:set_errcode(define.OPERATE_RESULT.OR_NOT_ENOUGH_STRIKE_POINT)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗连击点（按段数计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据
-- @return boolean 消耗是否成功
function CD_StrikePointBySegment_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗连击点
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    -- 计算当前连击点段数
    local segment = obj_me:get_strike_point() / define.STRIKE_POINT_SEGMENT_SIZE
    local point = segment * define.STRIKE_POINT_SEGMENT_SIZE
    -- 扣除连击点
    obj_me:strike_point_increment(-point, obj_me)
    -- 触发连击点消耗事件
    obj_me:on_deplete_strike_points()
    params:set_deplete_strike_point(point)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置消耗ID：消耗所有怒气值
D_AllRage_T.ID = define.ConditionAndDepleteID.D_ALL_RAGE

-- 条件检查（总是返回true）
-- @param obj_me 执行者对象
-- @param data 消耗数据
-- @return boolean 总是返回true
function D_AllRage_T:ConditionCheck(obj_me, data)
    return true
end

-- 消耗所有怒气值（按百分比计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比（0-100）
-- @return boolean 消耗是否成功
function D_AllRage_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗怒气值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local rate = data.params[1]
    local rage = obj_me:get_max_rage()
    -- 计算需要消耗的怒气值
    rage = math.floor(rage * rate / 100)
    -- 扣除怒气值
    obj_me:rage_increment(-rage)
    params:set_deplete_rage(rage)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置条件ID：目标必须是自己的配偶
C_TargetMustBeMySpouse_T.ID = define.ConditionAndDepleteID.C_TARGET_MUST_BE_MY_SPOUSE

-- 检查目标是否是自己的配偶
-- @param obj_me 执行者对象
-- @param data 条件数据
-- @return boolean 是否满足条件
function C_TargetMustBeMySpouse_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 执行者必须是人类
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- 获取目标对象
    local tar = obj_me:get_scene():get_obj_by_id(params:get_target_obj())
    if tar == nil then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- 目标也必须是人类
    if tar:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    -- 检查双方是否为配偶关系
    if not obj_me:is_my_spouse(tar) or not tar:is_my_spouse(obj_me) then
        params:set_errcode(define.OPERATE_RESULT.OR_INVALID_TARGET)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_TargetMustBeMySpouse_T:Deplete()
    return true
end

-- 设置消耗ID：取消指定状态效果
D_CancelSpecialImpact_T.ID = define.ConditionAndDepleteID.D_CANCEL_SPECIFIC_IMPACT

-- 条件检查（总是返回true）
-- @return boolean 总是返回true
function D_CancelSpecialImpact_T:ConditionCheck()
    return true
end

-- 取消指定状态效果
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为状态效果集合ID
-- @return boolean 消耗是否成功
function D_CancelSpecialImpact_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local collection = data.params[1]
    -- 取消指定集合中的所有状态效果
    obj_me:impact_cancel_impact_in_specific_collection(collection)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置消耗ID：按百分比消耗生命值
CD_HpByRate_T.ID = define.ConditionAndDepleteID.CD_HP_BY_RATE

-- 检查生命值是否足够（按百分比计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比（0-100）
-- @return boolean 是否满足条件
function CD_HpByRate_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local rate = data.params[1]
    -- 计算需要消耗的生命值
    local hp = obj_me:get_max_hp()
    hp = math.floor(hp * rate / 100)
    -- 检查生命值是否足够
    if obj_me:get_hp() < hp then
        params:set_errcode(define.OPERATE_RESULT.OR_NOT_ENOUGH_HP)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗生命值（按百分比计算）
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为消耗百分比（0-100）
-- @return boolean 消耗是否成功
function CD_HpByRate_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗生命值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local rate = data.params[1]
    -- 计算需要消耗的生命值
    local hp = obj_me:get_max_hp()
    hp = math.floor(hp * rate / 100)
    -- 扣除生命值
    obj_me:health_increment(-hp, obj_me)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置条件ID：生命值必须达到指定百分比
C_HpByRate_T.ID = define.ConditionAndDepleteID.C_HP_BY_RATE

-- 检查生命值是否达到指定百分比
-- @param obj_me 执行者对象
-- @param data 条件数据，params[1]为百分比（0-100）
-- @return boolean 是否满足条件
function C_HpByRate_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local rate = data.params[1]
    -- 计算生命值阈值
    local hp = obj_me:get_max_hp()
    hp = math.floor(hp * rate / 100)
    -- 检查当前生命值是否达到阈值
    if obj_me:get_hp() < hp then
        params:set_errcode(define.OPERATE_RESULT.OR_NOT_ENOUGH_HP)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗方法（此条件不涉及消耗）
function C_HpByRate_T:Deplete()
    return true
end


-- 设置消耗ID：按固定值消耗曼陀罗花
CD_FlowerByValue_T.ID = define.ConditionAndDepleteID.CD_FLOWER_BY_VALUE

-- 检查曼陀罗花是否足够
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要消耗的曼陀罗花数量
-- @return boolean 是否满足条件
function CD_FlowerByValue_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗曼陀罗花
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local need = data.params[1]
    local flower = obj_me:get_datura_flower()
    need = need < 0 and 0 or need
    -- 检查曼陀罗花是否足够
    if flower < need then
        params:set_errcode(define.OPERATE_RESULT.OR_LACK_MANA)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗曼陀罗花
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要消耗的曼陀罗花数量
-- @return boolean 消耗是否成功
function CD_FlowerByValue_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗曼陀罗花
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local need = data.params[1]
    need = need < 0 and 0 or need
    -- 扣除曼陀罗花
    obj_me:datura_flower_increment(-need, obj_me)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 设置消耗ID：按固定值消耗生命值
CD_HPByValue_T.ID = define.ConditionAndDepleteID.CD_HP_BY_VALUE

-- 检查生命值是否足够
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要消耗的生命值
-- @return boolean 是否满足条件
function CD_HPByValue_T:ConditionCheck(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗生命值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local need = data.params[1]
    local hp = obj_me:get_hp()
    need = need < 0 and 0 or need
    -- 检查生命值是否足够
    if hp < need then
        params:set_errcode(define.OPERATE_RESULT.OR_ERROR)
        return false
    end
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 消耗生命值
-- @param obj_me 执行者对象
-- @param data 消耗数据，params[1]为需要消耗的生命值
-- @return boolean 消耗是否成功
function CD_HPByValue_T:Deplete(obj_me, data)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    -- 非人类角色不消耗生命值
    if obj_me:get_obj_type() ~= "human" then
        params:set_errcode(define.OPERATE_RESULT.OR_OK)
        return true
    end
    local need = data.params[1]
    need = need < 0 and 0 or need
    -- 扣除生命值
    obj_me:health_increment(-need, obj_me)
    params:set_errcode(define.OPERATE_RESULT.OR_OK)
    return true
end

-- 执行条件检查
-- @param obj_me 执行者对象
-- @param data 条件数据，包含type字段指定条件类型
-- @return boolean 是否满足条件
function condition_delplete_core:condition_check(obj_me, data)
    local handled, result = require("cy_four_combat.resources").dispatch("condition_check", obj_me, data)
    if handled then return result end
    local type = data.type
    -- menpai-fix: CDCore_T native — kiểu không có trong switch → đạt/không tiêu hao (trước: assert làm sập chiêu)
    local logic = self.logics[type] or self.cy_default_logic
    assert(logic, type)
    -- 调试输出已屏蔽
    -- print("condition_delplete_core:condition_check type =", type)
    return logic:ConditionCheck(obj_me, data)
end

-- 执行资源消耗
-- @param obj_me 执行者对象
-- @param data 消耗数据，包含type字段指定消耗类型
-- @return boolean 消耗是否成功
function condition_delplete_core:deplete(obj_me, data)
    local handled, result = require("cy_four_combat.resources").dispatch("deplete", obj_me, data)
    if handled then return result end
    local type = data.type
    -- menpai-fix: CDCore_T native — kiểu không có trong switch → đạt/không tiêu hao (trước: assert làm sập chiêu)
    local logic = self.logics[type] or self.cy_default_logic
    assert(logic, type)
    return logic:Deplete(obj_me, data)
end

-- 条件与消耗逻辑映射表
condition_delplete_core.logics = {}
-- 注册所有条件与消耗逻辑类
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_INVALID]                            = ConDepLogic_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_UNIT_MUST_HAVE_IMPACT]               = C_UnitHaveImpact_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_UNIT_HP_MUST_LESS_THAN_BY_RATE]      = C_UnitHpLessThanByRate_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_TARGET_LEVEL_MUST_LESS_THAN_BY_VALUE]= C_TargetLevelMustLessThanByValues_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_TARGET_MUST_HAVE_IMPACT]             = C_TargetMustHaveImpact_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_MANA_BY_VALUE]                      = CD_ManaByValue_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_MANA_BY_RATE]                       = CD_ManaByRate_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_STRIKE_POINT_BY_SEGMENT]            = CD_StrikePointBySegment_T
condition_delplete_core.logics[define.ConditionAndDepleteID.D_ALL_RAGE]                            = D_AllRage_T
condition_delplete_core.logics[define.ConditionAndDepleteID.D_CANCEL_SPECIFIC_IMPACT]              = D_CancelSpecialImpact_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_TARGET_MUST_BE_MY_SPOUSE]            = C_TargetMustBeMySpouse_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_HP_BY_RATE]                         = CD_HpByRate_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_HP_BY_RATE]                          = C_HpByRate_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_FLOWER_BY_VALUE]                    = CD_FlowerByValue_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_RAGE_BY_RATE]                       = CD_RageByRate_T
condition_delplete_core.logics[define.ConditionAndDepleteID.CD_HP_BY_VALUE]                        = CD_HPByValue_T
condition_delplete_core.logics[define.ConditionAndDepleteID.C_UNIT_MUST_NOT_HAVE_IMPACT]           = C_UnitNotHaveImpact_T

-- menpai-fix: logic điều kiện/tiêu hao CY 16–21 theo mã tlbb15 (16 = 消耗能量 桃花岛, không còn là C_UNIT_MUST_NOT_HAVE_IMPACT; 18 mới là "bản thân không có impact thuộc tập")
require("scene.skill.condition_cy").install(condition_delplete_core)

-- skill-logic-4 (17/09/2026): điều kiện 0/2 và 驱散 9 tra THÊM tập ID của CY (configs/IDCollections.txt là bản GL/HJS, khác nghĩa ở 128/376/388/389/499).
pcall(function() require("cy_collection_bridge").install(condition_delplete_core) end)

-- 返回模块
return condition_delplete_core