--[[
    天赋逻辑类：std_talent_005
    用于在特定技能（ID为343）命中目标时，有一定概率给目标施加状态效果
    该天赋会增加技能命中时施加状态效果的概率
]]

local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"

-- 天赋逻辑类：std_talent_005
local std_talent_005 = class("std_talent_005", base)

-- 施加的状态效果ID
local give_impact_id = 63018 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

-- 检查是否为特定技能（ID为343）
-- @param skill_id 技能ID
-- @return boolean 是否为特定技能
function std_talent_005:is_specific_skill(skill_id)
    return skill_id == 343
end

-- 获取施加状态效果的概率
-- @param talent 天赋信息
-- @param level 天赋等级
-- @return number 概率值（0-100）
function std_talent_005:get_give_impact_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

-- 命中目标时的处理
-- @param talent 天赋信息
-- @param level 天赋等级
-- @param sender 发送者对象
-- @param reciver 接收者对象
-- @param skill_id 技能ID
function std_talent_005:on_hit_target(talent, level, sender, reciver, skill_id)
    -- 如果是特定技能，则检查是否施加状态效果
    if self:is_specific_skill(skill_id) then
        local odd = self:get_give_impact_odd(talent, level)
        local num = math.random(100)
        -- 如果随机数小于等于概率，则施加状态效果
        if num <= odd then
            impactenginer:send_impact_to_unit(reciver, give_impact_id, sender, 0, false, 0)
        end
    end
end

-- 返回std_talent_005类
return std_talent_005