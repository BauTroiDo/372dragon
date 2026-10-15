local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_666 = class("std_talent_666", base)
function std_talent_666:is_specific_skill(skill_id)
    return skill_id == 796
end

function std_talent_666:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_666:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_refix_value(talent, level)
        local num = math.random(100)
        if num <= odd then
            local target_skill_id = 797
            local cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
            sender:update_cool_down_by_cool_down_id(cool_down_id, 1 * 1000)
			target_skill_id = 791
            cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
            sender:update_cool_down_by_cool_down_id(cool_down_id, 1 * 1000)
			target_skill_id = 795
            cool_down_id = skillenginer:get_skill_template(target_skill_id,"cool_down_id")
            sender:update_cool_down_by_cool_down_id(cool_down_id, 1 * 1000)
        end
    end
end

return std_talent_666