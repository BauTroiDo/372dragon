local class = require "class"
local define = require "define"
local skynet = require "skynet"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_708 = class("std_talent_708", base)


function std_talent_708:is_specific_skill(skill_id)
    return skill_id == 325
end

function std_talent_708:get_refix_p(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_708:on_hit_target(talent, level, sender, reciver, skill_id)
    if self:is_specific_skill(skill_id) then
		local imp = reciver:impact_get_first_impact_of_specific_impact_id(35)
		if imp and imp:get_logic_id() == 15 then
			local p = self:get_refix_p(talent, level)
			local n = math.random(100)
			if n <= p then
				local caster_id = imp:get_caster_obj_id()
				local scene = reciver:get_scene()
				local caster = scene and scene:get_obj_by_id(caster_id)
				reciver:on_impact_fade_out(imp)
				reciver:remove_impact(imp)
				impactenginer:send_impact_to_unit(reciver, imp:get_data_index(), caster, 0, false, 0)
			end
		end
	end
end

function std_talent_708:refix_impact(talent, level, imp, sender, reciver)
	if imp:get_impact_id() == 35 and imp:get_logic_id() == 15 then
		imp:set_continuance_elapsed(0)
	end
end

return std_talent_708