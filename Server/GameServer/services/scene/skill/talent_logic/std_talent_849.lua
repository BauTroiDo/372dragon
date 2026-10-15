local class = require "class"
local skillenginer = require "skillenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_849 = class("std_talent_849", base)

function std_talent_849:is_specific_skill(skill_id)
    return skill_id == 541
end

function std_talent_849:get_odds(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_849:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		if math.random(100) <= self:get_odds(talent, level) then
            local cool_down_id = skillenginer:get_skill_template(541, "cool_down_id")
            if cool_down_id then
                local cool_down_time = sender:get_cool_down_by_cool_down_id(cool_down_id)
                sender:update_cool_down_by_cool_down_id(cool_down_id, cool_down_time)
            end
        end
    end
end



return std_talent_849