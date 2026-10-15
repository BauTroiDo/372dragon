--[[
    天赋逻辑类：std_talent_060
    用于修正特定状态效果（ID为109）的伤害类型
    该天赋会将部分冰系伤害转化为火系伤害
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_060
local std_talent_060 = class("std_talent_060", base)
 
-- 检查是否为特定状态效果（ID为109）
-- @param impact_id 状态效果ID
-- @return boolean 是否为特定状态效果
function std_talent_060:is_specific_impact(impact_id)
    return impact_id== 109
end

-- 获取转化百分比
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 转化百分比
function std_talent_060:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 修正状态效果
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param imp 状态效果对象
function std_talent_060:refix_impact(talent, level, imp)
    -- 如果是特定状态效果，则转化伤害类型
    if self:is_specific_impact(imp:get_impact_id()) then
        local value = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        -- 如果是伤害类型状态效果
        if imp:get_logic_id() == DI_DamagesByValue_T then
            -- 获取冰系伤害并计算转化量
            local damage_cold = logic:get_damage_cold(imp)
            local cold = math.floor(damage_cold * (value / 100))
            -- 减少冰系伤害，增加火系伤害
            logic:set_damage_cold(damage_cold - cold)
            local damage_fire = logic:get_damage_fire(imp)
            logic:set_damage_fire(damage_fire + cold)
        end
    end
end

-- 返回std_talent_060类
return std_talent_060