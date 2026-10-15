local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_221 = class("std_talent_221", base)
local data_indexs = { 44300, 44301, 44302, 44303, 44304}
function std_talent_221:is_specific_skill(skill_id)
    return skill_id == 313
end

function std_talent_221:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_221:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = 15--self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= value then
            local data_index = data_indexs[level] or define.INVAILD_ID
            if data_index ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(sender, data_index, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_221