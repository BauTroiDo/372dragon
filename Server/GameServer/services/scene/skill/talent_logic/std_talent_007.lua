--[[
    天赋逻辑类：std_talent_007
    用于在特定技能（ID为341）命中目标时，有一定概率增加连击点
    该天赋会增加技能命中时获得连击点的概率
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_007
local std_talent_007 = class("std_talent_007", base)

-- 检查是否为特定技能（ID为341）
-- @param skill_id 技能ID
-- @return boolean 是否为特定技能
function std_talent_007:is_specific_skill(skill_id)
    return skill_id == 341
end

-- 获取增加连击点的概率
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 概率值（0-100）
function std_talent_007:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 命中目标时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param sender 发送者对象
-- @param reciver 接收者对象
-- @param skill_id 技能ID
function std_talent_007:on_hit_target(talent, level, sender, reciver, skill_id)
    -- 如果是特定技能，则检查是否增加连击点
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        -- 如果随机数小于等于概率，则增加连击点
        if num <= odd then
            sender:strike_point_increment(1, sender)
        end
    end
end

-- 返回std_talent_007类
return std_talent_007