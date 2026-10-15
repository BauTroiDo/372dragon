--[[
    天赋逻辑类：std_talent_026
    用于修正特定技能（ID为291）的状态效果参数
    该天赋会增加技能施加的物理防御修正状态效果的数值
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_026
local std_talent_026 = class("std_talent_026", base)

-- 检查是否为特定技能（ID为291）
-- @param skill_id 技能ID
-- @return boolean 是否为特定技能
function std_talent_026:is_specific_skill(skill_id)
    return skill_id == 291
end

-- 获取修正百分比
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 修正百分比
function std_talent_026:get_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

-- 修正状态效果
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param imp 状态效果对象
function std_talent_026:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    -- 如果是特定技能，则修正状态效果
    if self:is_specific_skill(skill_id) then
        local percent = self:get_value(talent, level)
        -- 如果是物理防御修正状态效果（逻辑ID为11）
        if imp:get_logic_id() == 11 then
            local logic = impactenginer:get_logic(imp)
            if logic then
                -- 获取当前修正值并按百分比增加
                local value = logic:get_value_of_refix_attrib_def_physics(imp)
                value = math.ceil(value * (100 + percent) / 100)
                logic:set_value_of_refix_attrib_def_physics(imp, value)
            end
        end
    end
end

-- 返回std_talent_026类
return std_talent_026