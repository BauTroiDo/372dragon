local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_542 = class("std_talent_542", base)
function std_talent_542:is_specific_skill(skill_id)
    return skill_id == 462
end

function std_talent_542:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_542:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local data_indexs = { 45990, 45991, 45992, 45993, 45994}
        local data_index = data_indexs[level]
        if data_index ~= define.INVAILD_ID then
            impactenginer:send_impact_to_unit(human, data_index, human, 0, false, 0)
        end
    end
end

return std_talent_542