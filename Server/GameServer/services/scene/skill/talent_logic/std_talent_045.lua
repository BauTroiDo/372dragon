--[[
    天赋逻辑类：std_talent_045
    用于在激活天赋时给玩家添加一个技能（ID为3293）
    在移除天赋时删除该技能
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_045
local std_talent_045 = class("std_talent_045", base)

-- 添加的技能ID
local skill_id = 3293

-- 天赋激活时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param human 玩家对象
function std_talent_045:on_active(talent, level, human)
    -- 如果玩家没有该技能，则添加并发送技能列表
    if not human:have_skill(skill_id) then
        human:add_skill(skill_id)
        human:send_skill_list()
    end
end

-- 天赋移除时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param human 玩家对象
function std_talent_045:on_remove(talent, level, human)
    -- 如果玩家有该技能，则删除
    if human:have_skill(skill_id) then
        human:del_skill(skill_id)
    end
end

-- 返回std_talent_045类
return std_talent_045