local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_689 = class("std_talent_689", base)

function std_talent_689:on_damages(talent, level, damages, obj_me)
    if obj_me:impact_have_impact_of_specific_impact_id(103) then
		local talents = talent.params[level]
		if talents then
			local rate = talents[1] or 0
			if math.random(100) <= rate then
				if damages.rage_damage then
					damages.rage_damage = damages.rage_damage + 8
				else
					damages.rage_damage = 8
				end
			end
		end
	end
end

return std_talent_689