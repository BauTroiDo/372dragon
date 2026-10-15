--[[
    天赋逻辑类：std_talent_062
    用于在特定技能（ID为313）暴击时，有一定概率刷新目标技能（ID为335）的冷却时间
    该天赋可以减少目标技能的冷却时间
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_062
local std_talent_062 = class("std_talent_062", base)

-- 检查是否为特定技能（ID为313）
-- @param skill_id 技能ID
-- @return boolean 是否为特定技能
function std_talent_062:is_specific_skill(skill_id)
    return skill_id == 313
end

-- 获取目标技能ID
-- @return number 目标技能ID
function std_talent_062:get_target_skill_id()
    return 335
end

-- 获取触发概率
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 触发概率（0-100）
function std_talent_062:get_trigger_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 暴击目标时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param human 玩家对象
-- @param obj_tar 目标对象
-- @param skill_id 技能ID
function std_talent_062:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    -- 调试输出已屏蔽
    -- print("0 std_talent_062:on_critical_hit_target")
    -- 如果是特定技能，则检查是否刷新冷却
    if self:is_specific_skill(skill_id) then
        local percent = self:get_trigger_percent(talent, level)
        local n = math.random(100)
        -- 如果随机数小于等于概率，则刷新目标技能冷却
        if n <= percent then
            local cool_down_id = skillenginer:get_skill_template(self:get_target_skill_id(),"cool_down_id")
            -- local cool_down_id = template.cool_down_id
            local cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
            -- 调试输出已屏蔽
            -- print("1 std_talent_062:on_critical_hit_target cool_down_time =", cool_down_time, ";cool_down_id =", cool_down_id)
            -- 更新冷却时间为10秒（10000毫秒）
            human:update_cool_down_by_cool_down_id(cool_down_id, 10000)
            cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
            -- 调试输出已屏蔽
            -- print("2 std_talent_062:on_critical_hit_target cool_down_time =", cool_down_time, ";cool_down_id =", cool_down_id)
        end
    end
end

-- 返回std_talent_062类
return std_talent_062