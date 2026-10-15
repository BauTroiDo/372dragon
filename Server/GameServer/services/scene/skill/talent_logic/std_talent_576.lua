local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_576 = class("std_talent_576", base)
function std_talent_576:is_specific_skill(skill_id)
    return skill_id == 499
end

function std_talent_576:get_reifx_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_576:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_reifx_value(talent, level)
        local template = skillenginer:get_skill_template(skill_id)
        local cool_down_id = template.cool_down_id
        sender:update_cool_down_by_cool_down_id(cool_down_id, value * 1000)
    end
end

return std_talent_576