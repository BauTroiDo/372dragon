local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_473 = class("std_talent_473", base)
function std_talent_473:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_473:on_skill_miss(talent, level, sender, reciver, skill_id)
    local odd = self:get_value(talent, level)
    local n = math.random(1, 100)
    if n <= odd then
        local target_skill_id = 364
        local template = skillenginer:get_skill_template(target_skill_id)
        local cool_down_id = template.cool_down_id
        reciver:update_cool_down_by_cool_down_id(cool_down_id, 2 * 1000)
    end
end

return std_talent_473