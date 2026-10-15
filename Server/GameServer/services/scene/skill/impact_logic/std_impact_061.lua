local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_061 = class("std_impact_061", base)

function std_impact_061:is_over_timed()
    return true
end

function std_impact_061:is_intervaled()
    return false
end

function std_impact_061:get_refix_skill_accuracy(imp)
    return imp.params["命中率"]
end

function std_impact_061:get_refix_skill_mind_attack(imp)
    return imp.params["会心率"]
end

function std_impact_061:get_affect_skill_collection_id(imp)
    return imp.params["影响的技能集合ID"]
end

function std_impact_061:get_refix_charge_time_rate(imp)
    return imp.params["聚气时间百分修正"]
end

function std_impact_061:refix_skill(imp, obj, skill_info)
    local accuracy_refix = self:get_refix_skill_accuracy(imp)
    if accuracy_refix > 0 then
        skill_info:set_accuracy(accuracy_refix)
    end
    local mind_attck_refix = self:get_refix_skill_mind_attack(imp)
    if mind_attck_refix > 0 then
        skill_info:set_critical_rate(mind_attck_refix)
    end
    local collection_id = self:get_affect_skill_collection_id(imp)
    local in_collection = true
    if collection_id ~= define.INVAILD_ID then
        in_collection = skillenginer:is_skill_in_collection(skill_info:get_skill_id(), collection_id)
    end
    if in_collection then
        local channel_time = skill_info:get_charge_time()
        local rate = self:get_refix_charge_time_rate(imp)
        channel_time = math.floor(channel_time * (100 + rate) / 100)
        skill_info:set_charge_time(channel_time)
    end
end

return std_impact_061