local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_535 = class("std_talent_535", base)
function std_talent_535:is_specific_skill(skill_id)
    return skill_id == 451
end

function std_talent_535:get_target_skill_id(skill_id)
    return 768
end

function std_talent_535:get_trigger_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_535:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    if self:is_specific_skill(skill_id) then
        local percent = self:get_trigger_percent(talent, level)
        local n = math.random(100)
        if n <= percent then
            local target_skill_id = 454
            local template = skillenginer:get_skill_template(target_skill_id)
            local cool_down_id = template.cool_down_id
            local cool_down_time = human:get_cool_down_by_cool_down_id(cool_down_id)
            human:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
        end
    end
end

return std_talent_535