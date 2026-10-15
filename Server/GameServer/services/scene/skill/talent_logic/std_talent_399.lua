local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_397 = class("std_talent_397", base)
function std_talent_397:is_specific_skill(skill_id)
    return skill_id == 764
end

function std_talent_397:get_odd(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_397:on_use_skill_success_fully(talent, level, skill_info, human)
    local skill_id = skill_info:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local odd = self:get_odd(talent, level)
        local num = math.random(100)
        if num <= odd then
            local data_index = 63050 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
            impactenginer:send_impact_to_unit(human, data_index, human, 0, false, 0)
        end
    end
end

return std_talent_397