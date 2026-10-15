local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_890 = class("std_talent_890", base)

function std_talent_890:is_specific_skill(skill_id)
    return skill_id == 810
end

function std_talent_890:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_890:on_damage_target(talent, level, id, sender, reciver, damages, skill_id, imp)
    if imp and self:is_specific_skill(skill_id) then
		if imp:is_critical_hit() then
			if math.random(100) <= self:get_refix_value(talent, level) then
				local skill_info = sender:get_skill_info()
				if skill_info.id == skill_id then
					local life_soul_data = skill_info:get_consume_life_soul_data()
					if #life_soul_data > 0 then
						local index = math.random(1,#life_soul_data)
						local impact = life_soul_data[index]
						if impact and impact ~= -1 then
							impactenginer:send_impact_to_unit(sender, impact, sender, 0, false, 0)
						end
					end
				end
			end
		end
	end
end

return std_talent_890