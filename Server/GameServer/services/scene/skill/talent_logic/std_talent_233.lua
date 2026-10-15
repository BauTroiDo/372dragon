local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_224 = class("std_talent_224", base)
local data_indexs = { 44312, 44313, 44314, 44315, 44316}
function std_talent_224:is_specific_skill(skill_id)
    return skill_id == 313
end

function std_talent_224:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_224:get_impact(level)
    return data_indexs[level] or define.INVAILD_ID
end

function std_talent_224:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= value then
            local data_index = self:get_impact(level)
            if data_index ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_224