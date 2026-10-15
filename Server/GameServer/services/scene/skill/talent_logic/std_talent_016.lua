local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_014 = class("std_talent_014", base)
function std_talent_014:is_specific_skill(skill_id)
    return skill_id == 361
end

function std_talent_014:get_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_014:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
        local value = self:get_value(talent, level)
        assert(value)
        skill_info:set_radious(value)
    end
end

return std_talent_014