local class = require "class"
-- local define = require "define"
-- local skillenginer = require "skillenginer":getinstance()
-- local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_713 = class("std_talent_713", base)
-- local impacts = {
    -- 51648, 51649, 51650, 51651, 51652
-- }


-- function std_talent_713:is_specific_skill(skill_id)
    -- return skill_id == 325
-- end

-- function std_talent_713:get_talent_value(talent,level)
    -- local params = talent.params[level]
    -- return params[1] or 0
-- end

-- function std_talent_713:refix_impact(talent, level, imp, sender, reciver)
	-- if imp:get_impact_id() == 116 then
		-- local value = self:get_talent_value(talent,level)
		-- if value > 0 then
			-- local logic = impactenginer:get_logic(imp)
			-- if logic then
				-- logic:set_cool_down_value(imp, value)
			-- end
		-- end
	-- end
-- end

return std_talent_713