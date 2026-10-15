--[[
    天赋逻辑类：std_talent_003
    用于修改特定技能（ID为351）的自身状态效果参数
    该天赋会增加技能对自身施加的状态效果的参数值
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_003
local std_talent_003 = class("std_talent_003", base)

-- 检查是否为特定技能（ID为351）
-- @param skill_info 技能信息
-- @return boolean 是否为特定技能
function std_talent_003:is_specific_skill(skill_info)
    return skill_info.id == 351
end

-- 获取天赋修正值
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 修正值
function std_talent_003:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 修正技能信息
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param skill_info 技能信息
function std_talent_003:refix_skill_info(talent, level, skill_info)
    -- 如果是特定技能，则修正自身状态效果参数
    if self:is_specific_skill(skill_info) then
        local value = self:get_refix_value(talent, level)
        local p = skill_info:get_give_self_impact().p
        skill_info:set_give_self_impact_p(p + value)
    end
end

-- 返回std_talent_003类
return std_talent_003