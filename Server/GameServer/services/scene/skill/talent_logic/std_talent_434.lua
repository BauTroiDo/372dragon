local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_434 = class("std_talent_434", base)
function std_talent_434:is_specific_skill(template)
    return template.id == 288
end

function std_talent_434:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_434:on_get_skill_template(talent, level, obj_me, template)
    if self:is_specific_skill(template) then
        template.disable_by_flag_1 = false
        template.disable_by_flag_2 = false
    end
end

return std_talent_434