local class = require "class"
local define = require "define"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_225 = class("std_talent_225", base)
local data_indexs = {44306, 44307, 44308, 44309, 44310}
function std_talent_225:is_specific_skill(skill_id)
    return skill_id == 311
end

function std_talent_225:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_225:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local value = 5--self:get_refix_value(talent, level)
        local n = math.random(1, 100)
        if n <= value then
            local data_index = data_indexs[level] or define.INVAILD_ID
            if data_index ~= define.INVAILD_ID then
                impactenginer:send_impact_to_unit(reciver, data_index, sender, 0, false, 0)
            end
        end
    end
end

return std_talent_225