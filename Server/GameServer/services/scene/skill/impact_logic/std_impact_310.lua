local class = require "class"
local define = require "define"
local base = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()
local impactenginer  = require "impactenginer":getinstance()
local eventenginer = require "eventenginer":getinstance()
local skillenginer = require "skillenginer":getinstance()
local impact = require "scene.skill.impact"
local std_impact_310 = class("std_impact_310", base)

function std_impact_310:is_over_timed()
    return false
end

function std_impact_310:is_intervaled()
    return false
end

function std_impact_310:get_min_dis(imp)
    return imp.params["最小距离"]
end

function std_impact_310:get_max_dis(imp)
    return imp.params["最大距离"]
end

function std_impact_310:get_xinfa_order(imp)
    return imp.params["心法位置"]
end

function std_impact_310:get_skill_order(imp)
    return imp.params["技能位置"]
end

function std_impact_310:get_give_self_impact_1(imp)
    return imp.params["给自己的子效果1"]
end

function std_impact_310:get_give_self_impact_2(imp)
    return imp.params["给自己的子效果2"]
end

function std_impact_310:get_odds(imp)
    return imp.params["命中目标时的激发几率"]
end

function std_impact_310:on_hit_target(imp, sender, reciver, skill)
    if skill == 0 then
        return 
    end
    if sender:get_obj_type() ~= "human" then
        return
    end
    local need_skill_order = self:get_skill_order(imp)
    local need_xinfa_order = self:get_xinfa_order(imp)
    local skill_order = skillenginer:get_skill_order(skill)
    local xinfa_order = skillenginer:get_skill_xinfa_order(skill)
    if need_skill_order ~= skill_order or xinfa_order ~= need_xinfa_order then
        return
    end
    local odd = self:get_odds(imp)
    local num = math.random(100)
    if num > odd then
        return
    end
    local min_dis = self:get_min_dis(imp)
    local max_dis = self:get_max_dis(imp)
    local sender_obj_pos = sender:get_world_pos()
    local reciver_obj_pos = reciver:get_world_pos()
    local vx = sender_obj_pos.x - reciver_obj_pos.x
    local vy = sender_obj_pos.y - reciver_obj_pos.y
    local dist = math.sqrt(vx * vx + vy * vy)
    dist = math.floor(dist)
    if dist < min_dis or dist > max_dis then
        return
    end
    if self:get_give_self_impact_1(imp) ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(sender, self:get_give_self_impact_1(imp), sender, 100, false, 0)
    end
    if self:get_give_self_impact_2(imp) ~= define.INVAILD_ID then
        impactenginer:send_impact_to_unit(sender, self:get_give_self_impact_2(imp), sender, 100, false, 0)
    end
end

return std_impact_310