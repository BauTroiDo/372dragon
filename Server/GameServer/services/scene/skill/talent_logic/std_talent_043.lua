--[[
    天赋逻辑类：std_talent_043
    用于修正特定状态效果（ID为106）的持续时间
    该天赋会增加状态效果的持续时间
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_043
local std_talent_043 = class("std_talent_043", base)
 
-- 检查是否为特定状态效果（ID为106）
-- @param impact_id 状态效果ID
-- @return boolean 是否为特定状态效果
function std_talent_043:is_specific_impact(impact_id)
    return impact_id == 106
end

-- 获取状态效果持续时间的修正值
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 持续时间修正值（秒）
function std_talent_043:get_refix_impact_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

-- 修正状态效果
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param imp 状态效果对象
function std_talent_043:refix_impact(talent, level, imp)
    local impact_id = imp:get_impact_id()
    -- 如果是特定状态效果，则增加持续时间
    if self:is_specific_impact(impact_id) then
        local value = self:get_refix_impact_value(talent, level)
        local contianuce = imp:get_continuance()
        -- 持续时间单位为毫秒，所以需要乘以1000
        imp:set_continuance(contianuce + value * 1000)
    end
end

-- 返回std_talent_043类
return std_talent_043