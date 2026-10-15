local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_658 = class("std_talent_658", base)

function std_talent_658:is_specific_skill(skill_id)
    return skill_id == 788
end


function std_talent_658:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_658:on_critical_hit_target(talent, level, human, obj_tar, skill_id)
    if self:is_specific_skill(skill_id) then
        local odd = self:get_refix_value(talent, level)
        local num = math.random(100)
        if num <= odd then
			impactenginer:send_impact_to_unit(reciver, 63063, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
        end
    end
end

return std_talent_658

