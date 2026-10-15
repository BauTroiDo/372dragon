local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_050 = class("std_talent_050", base)
local impacts = { 50034, 50035, 50036, 50037, 50038}
function std_talent_050:is_specific_skill(skill_id)
    return skill_id == 327
end

function std_talent_050:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_050:refix_skill_info(talent, level, skill_info)
    if self:is_specific_skill(skill_info.id) then
        skill_info:set_logic_id(1)
        skill_info:set_radious(5)
        skill_info:set_target_count(5)
        skill_info:set_activate_once_impacts_target(impacts[level])
    end
end

return std_talent_050