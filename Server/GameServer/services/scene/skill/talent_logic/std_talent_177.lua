local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_177 = class("std_talent_177", base)
function std_talent_177:is_specific_skill_hit(skill_id)
    return skill_id == 521
end

function std_talent_177:is_specific_skill_use(skill_id)
    return skill_id == 524
end

function std_talent_177:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill_hit(skill_id) then
        local odd = 10
        local num = math.random(100)
        if num <= odd then
            impactenginer:send_impact_to_unit(sender, 63029, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

function std_talent_177:on_use_skill_success_fully(talent, level, skill_info, human)
    if self:is_specific_skill_use(skill_info.id) then
        local data_index = 63030 -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        impactenginer:send_impact_to_unit(human, data_index, human, 0, false, 0)
    end
end


return std_talent_177