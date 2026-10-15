--[[
    天赋逻辑类：std_talent_061
    用于修正特定状态效果（ID为115）的物理攻击和物理防御属性修正值
    该天赋会增加状态效果提供的物理攻击和物理防御数值
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_061
local std_talent_061 = class("std_talent_061", base)
 
-- 检查是否为特定状态效果（ID为115）
-- @param impact_id 状态效果ID
-- @return boolean 是否为特定状态效果
function std_talent_061:is_specific_impact(impact_id)
    return impact_id== 115
end

-- 获取修正百分比
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 修正百分比
function std_talent_061:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 修正状态效果
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param imp 状态效果对象
function std_talent_061:refix_impact(talent, level, imp)
    -- 如果是特定状态效果，则修正属性值
    if self:is_specific_impact(imp:get_impact_id()) then
        local percent = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        -- 如果是属性修正类型状态效果（逻辑ID为11）
        if imp:get_logic_id() == 11 then
            -- 修正物理攻击
            do
                local value = logic:get_value_of_refix_attrib_att_physics(imp)
                value = math.ceil(value * (100 + percent)/ 100)
                logic:set_value_of_refix_attrib_att_physics(imp, value)
            end
            -- 修正物理防御
            do
                local value = logic:get_value_of_refix_attrib_def_physics(imp)
                value = math.ceil(value * (100 + percent)/ 100)
                logic:set_value_of_refix_attrib_def_physics(imp, value)
            end
        end
    end
end

-- 返回std_talent_061类
return std_talent_061