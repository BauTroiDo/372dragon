local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_198 = class("std_talent_198", base)
local impact_data_indexs = {
    50066, 50067, 50068, 50069, 50070
}
function std_talent_198:is_specific_impact(impact_id)
    return impact_id == 195
end

function std_talent_198:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_198:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local data_index = impact_data_indexs[level]
        impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
    end
end

return std_talent_198