local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_071 = class("std_talent_071", base)
local skills = {
    [371] = 373,
    [281] = 283,
    [311] = 313,
}
function std_talent_071:is_specific_skill(skill_id)
    return skills[skill_id] ~= nil
end

function std_talent_071:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_071:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            local target_skill_id = skills[skill_id]
            local template = skillenginer:get_skill_template(target_skill_id)
            sender:update_cool_down_time(template.cool_down_id, 2000)
        end
    end
end

return std_talent_071