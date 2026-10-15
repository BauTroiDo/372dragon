local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_265 = class("std_talent_265", base)
function std_talent_265:is_specific_skill(skill_id)
    return skill_id == 381
end

function std_talent_265:get_reifx_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_265:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_reifx_value(talent, level)
        local n = math.random(1, 100)
        if n <= value then
            local target_skill_id = 373
            local template = skillenginer:get_skill_template(target_skill_id)
            local cool_down_id = template.cool_down_id
            sender:update_cool_down_by_cool_down_id(cool_down_id, 5 * 1000)
        end
    end
end

return std_talent_265