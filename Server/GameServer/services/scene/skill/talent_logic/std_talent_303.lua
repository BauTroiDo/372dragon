local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_303 = class("std_talent_303", base)
function std_talent_303:is_specific_impact(impact_data_index)
    return impact_data_index >= 1733 and impact_data_index <= 1744
end

function std_talent_303:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_303:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = self:get_refix_value(talent, level)
            local reduce_attrib_hit = logic:get_value_of_refix_attrib_hit(imp)
            local reduce_attrib_miss = math.ceil(reduce_attrib_hit * value / 100)
            local base_reduce_attrib_miss = logic:get_value_of_refix_attrib_miss(imp)
            base_reduce_attrib_miss = base_reduce_attrib_miss + reduce_attrib_miss
            logic:set_value_of_refix_attrib_miss(imp, base_reduce_attrib_miss)
        end
    end
end

return std_talent_303