local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_716 = class("std_talent_716", base)
function std_talent_716:is_specific_skill(skill_id)
    return skill_id == 312
end

function std_talent_716:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_716:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local percent = self:get_refix_value(talent, level)
		local n = math.random(100)
		if n <= percent then
			impactenginer:send_impact_to_unit(reciver, 63068, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		end
	end
end



return std_talent_716