--[[
    天赋逻辑类：std_talent_078
    当使用范围攻击（AE）技能成功时，给自身添加一个状态效果
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_078
local std_talent_078 = class("std_talent_078", base)

-- 触发的状态效果ID
local impact_id = 63020 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

-- 技能使用成功完全触发
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param skill_info 技能信息
-- @param human 角色对象
function std_talent_078:on_use_skill_success_fully(talent, level, skill_info, human)
    -- 获取技能的目标模式
    local target_mode = skill_info:get_targeting_logic()
    -- 如果是范围攻击（AE）类型的技能，则给自身添加状态效果
    if target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_SELF or
        target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT or
        target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT_NEW or
        target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_POSITION then
            impactenginer:send_impact_to_unit(human, impact_id, human, 0, false, 0)
        end
end

-- 返回std_talent_078类
return std_talent_078