local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_110 = class("std_talent_110", base)
local data_indexs = { 50046, 50047, 50048, 50049, 50050 }
function std_talent_110:is_specific_skill(skill_id)
    return skill_id == 421
end

function std_talent_110:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_110:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local data_index = data_indexs[level]
        impactenginer:send_impact_to_unit(reciver, data_index, reciver, 0, false, 0)
    end
end

return std_talent_110