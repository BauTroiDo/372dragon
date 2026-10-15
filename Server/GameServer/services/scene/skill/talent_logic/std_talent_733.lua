local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_733 = class("std_talent_733", base)
local impacts = {
	51813,
	51814,
	51815,
	51816,
	51817,
}

-- function std_talent_733:get_talent_value(talent, level)
    -- local params = talent.params[level]
    -- return params[1] or 0,params[2] or 0
-- end

function std_talent_733:refix_impact(talent, level, imp, sender, reciver)
	local buffid = imp:get_data_index()
	if buffid >= 923 and buffid <= 934 then
		if imp:get_skill_id() == 349 then
			local impact = impacts[level] or -1
			if impact ~= -1 then
				local logic = impactenginer:get_logic(imp)
				if logic then
					logic:set_add_buff(imp,impact)
				end
			end
		end
	end
end

return std_talent_733