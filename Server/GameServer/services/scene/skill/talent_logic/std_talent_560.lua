local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_560 = class("std_talent_560", base)

function std_talent_560:is_specific_skill(skill_id)
    return skill_id == 461
end

function std_talent_560:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_560:refix_skill_info(talent, level, skill_info, human)
    if self:is_specific_skill(skill_info:get_skill_id()) then
        local params = human:get_targeting_and_depleting_params()
        local target_obj_id = params:get_target_obj()
        local target = human:get_scene():get_obj_by_id(target_obj_id)
        if target and target:get_obj_type() == "human" then
            if self:is_fit_condition(human, target) then
                local rate_up = skill_info:get_mind_attack_rate_up()
                local value = self:get_refix_value(talent, level)
                rate_up = rate_up + (value / 100)
                skill_info:set_mind_attack_rate_up(rate_up)
            end
        end
    end
end

function std_talent_560:is_fit_condition(sender, reciver)
    local sender_total = 0
    local reciver_total = 0
    do
        sender_total = sender_total + sender:get_attrib("att_cold")
        sender_total = sender_total + sender:get_attrib("att_fire")
        sender_total = sender_total + sender:get_attrib("att_light")
        sender_total = sender_total + sender:get_attrib("att_poison")
    end
    do
        reciver_total = reciver_total + reciver:get_attrib("att_cold")
        reciver_total = reciver_total + reciver:get_attrib("att_fire")
        reciver_total = reciver_total + reciver:get_attrib("att_light")
        reciver_total = reciver_total + reciver:get_attrib("att_poison")
    end
    return sender_total / reciver_total >= 1.5
end

return std_talent_560