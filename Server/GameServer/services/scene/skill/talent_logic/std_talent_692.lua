local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_692 = class("std_talent_692", base)
function std_talent_692:is_specific_skill(skill_info)
    return skill_info.id == 289
end

function std_talent_692:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_692:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info) then
        local value = self:get_refix_value(talent, level)
		if math.random(100) <= value then
            impactenginer:send_impact_to_unit(sender, 63065, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		end
    end
end

return std_talent_692