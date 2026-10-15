local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_543 = class("std_talent_543", base)
function std_talent_543:is_specific_impact(data_index)
    return data_index >= 2156 and data_index <= 2167
end

function std_talent_543:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_543:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_data_index()) then
        local data_indexs = { 46051, 46052, 46053, 46054, 46055}
        local data_index = data_indexs[level] or define.INVAILD_ID
        if data_index ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(sender, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_543