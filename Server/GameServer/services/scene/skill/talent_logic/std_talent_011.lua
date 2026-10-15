local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_011 = class("std_talent_011", base)
function std_talent_011:is_specific_skill(skill_id)
    return skill_id == 347
end

function std_talent_011:get_value(talent, level, segment)
    local params = talent.params[level]
    return params[3] or 0
end

function std_talent_011:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local segment = 3
        local value = self:get_value(talent, level, segment) * 1000
        do
            local tar_skill_id = 351
            local template = skillenginer:get_skill_template(tar_skill_id)
            local cool_down_id = template.cool_down_id
            sender:update_cool_down_by_cool_down_id(cool_down_id, value)
        end
        do
            local tar_skill_id = 364
            local template = skillenginer:get_skill_template(tar_skill_id)
            local cool_down_id = template.cool_down_id
            sender:update_cool_down_by_cool_down_id(cool_down_id, value)
        end
    end
end

return std_talent_011