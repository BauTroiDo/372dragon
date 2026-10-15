local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_476 = class("std_talent_476", base)
function std_talent_476:is_specific_skill(skill_id)
    return skill_id == 342
end

function std_talent_476:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_476:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local last_time = human:get_talent_trigger_time(talent.name)
        local now = os.time()
        if last_time == nil or now - last_time > 60 then
            human:set_talent_trigger_time(talent.name)
            local odd = self:get_odd(talent, level)
            local num = math.random(100)
            if num <= odd then
                local template = skillenginer:get_skill_template(skill_id)
                local cool_down_id = template.cool_down_id
                human:set_cool_down(cool_down_id, 0)
            end
        end
    end
end

return std_talent_476