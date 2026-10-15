local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_486 = class("std_talent_486", base)
function std_talent_486:is_specific_impact(data_index)
    return data_index >= 1222 and data_index <= 1233
end

function std_talent_486:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_486:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local value = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            logic:set_rate_of_refix_attrib_def_magic(imp, -1 * value)
        end
    end
end

return std_talent_486