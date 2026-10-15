local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_448 = class("std_talent_448", base)
local data_indexs = { 45920, 45921, 45922, 45923, 45924}
function std_talent_448:is_specific_impact(impact_id)
    return impact_id == 581
end

function std_talent_448:refix_impact(talent, level, imp, sender, reciver)
    if self:is_specific_impact(imp:get_impact_id()) then
        local data_index = data_indexs[level] or define.INVAILD_ID
        if data_index ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
        end
    end
end

return std_talent_448