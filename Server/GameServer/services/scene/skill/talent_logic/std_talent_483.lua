local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_483 = class("std_talent_483", base)
function std_talent_483:is_specific_impact(data_index)
    return data_index >= 7728 and data_index <= 7739
end

function std_talent_483:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_483:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local value = self:get_refix_value(talent, level)
        local logic = impactenginer:get_logic(imp)
        if logic then
            local modify = logic:get_value_of_refix_spr(imp)
            modify = math.ceil(modify * (100 + value) / 100)
            logic:set_value_of_refix_int(imp, modify)
        end
    end
end

return std_talent_483