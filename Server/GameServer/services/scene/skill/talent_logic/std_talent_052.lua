local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_052 = class("std_talent_052", base)
local data_indexs = { 50039, 50040, 50041, 50042, 50043 }
function std_talent_052:is_specific_skill(skill_id)
    return skill_id == 311
end

function std_talent_052:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_052:on_skill_miss_target(talent, level, obj_me, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local data_index = data_indexs[level]
        impactenginer:send_impact_to_unit(obj_me, data_index, obj_me, 0, false, 0)
    end
end

return std_talent_052