--[[
    天赋逻辑类：std_talent_082（注意：类名为std_talent_074）
    用于修改特定技能（ID为374）产生的状态效果（ID为132）的速度值
    将速度值改为负值，即减速效果
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_074（注意：文件名为std_talent_082.lua）
local std_talent_074 = class("std_talent_074", base)

-- 检查是否为需要修改状态效果的技能（ID为374）
-- @param skill_info 技能信息
-- @return boolean 是否为指定技能
function std_talent_074:is_refix_impact_skill(skill_info)
    return skill_info.id == 374
end

-- 获取状态效果修改值
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 修改值
function std_talent_074:get_refix_impact_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

-- 修改状态效果
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param imp 状态效果对象
function std_talent_074:refix_impact(talent, level, imp)
    -- 如果状态效果ID为132，则修改其速度值为负值（减速）
    if imp:get_impact_id() == 132 then
        local value = self:get_refix_impact_value(talent, level)
        value = -1 * math.abs(value)
        local logic = impactenginer:get_logic(imp)
        if logic and logic.set_refix_speed then
            logic:set_refix_speed(imp, value)
        end
    end
end

-- 返回std_talent_074类
return std_talent_074