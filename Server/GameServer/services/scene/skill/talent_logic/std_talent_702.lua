local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_702 = class("std_talent_702", base)
function std_talent_702:is_specific_skill(skill_id)
    return skill_id == 282
end

function std_talent_702:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_702:refix_skill_info(talent, level, skill_info, sender)
    if self:is_specific_skill(skill_info.id) then
		skill_info:set_radious(15)
		skill_info.impacts.effect_once[2] = -1
    end
end

function std_talent_702:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local percent = self:get_refix_value(talent, level)
		local n = math.random(100)
		if n <= percent then
			local target_position = sender:get_world_pos()
			reciver:on_teleport(target_position)
			impactenginer:send_impact_to_unit(reciver, 63066, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		end
	end
end



return std_talent_702