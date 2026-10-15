local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_022 = class("std_talent_022", base)
local std_impacts = { 50018, 50019, 50020, 50021, 50022}
function std_talent_022:is_specific_skill(skill_id)
    return skill_id == 360
end

function std_talent_022:get_value(talent, level)
    return std_impacts[level]
end

function std_talent_022:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
        local value = self:get_value(talent, level)
        assert(value)
        skill_info.impacts.effect_once[1] = value
    end
end

return std_talent_022