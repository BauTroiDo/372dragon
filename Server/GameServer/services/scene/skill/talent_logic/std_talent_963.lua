-- 日月任我攀：星河虹吸(832)对玩家释放时增强效果
-- 定身效果提升到X秒，无法被门派常规技能驱散
-- 对目标释放虹吸之线，超过10米断裂并散功3秒
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_963 = class("std_talent_963", base)
local impacts = {19176, 19177, 19178, 19179, 19180}
local TETHER_IMPACT = 63090  -- 虹吸之线 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
local SPECIFIC_SKILL_ID = 832

function std_talent_963:on_use_skill_success_fully(talent, level, skill_info, human)
    if skill_info:get_skill_id() ~= SPECIFIC_SKILL_ID then
        return
    end

    local params = human:get_targeting_and_depleting_params()
    if not params then
        return
    end

    local target_obj_id = params:get_target_obj()
    if not target_obj_id then
        return
    end

    local scene = human:get_scene()
    if not scene then
        return
    end

    local reciver = scene:get_obj_by_id(target_obj_id)
    if not reciver or reciver:get_obj_type() ~= "human" then
        return
    end

    local impact_id = impacts[level]
    if not impact_id then
        return
    end

    -- 增强定身发送给目标
    impactenginer:send_impact_to_unit(reciver, impact_id, human, 0, false, 0)
    -- 虹吸之线发送给目标，由 tether logic 检测距离并在断裂时散功
    impactenginer:send_impact_to_unit(reciver, TETHER_IMPACT, human, 0, false, 0)
end

return std_talent_963
