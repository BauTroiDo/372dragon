local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_788 = class("std_talent_788", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_788:is_specific_skill(skill_id)
    return skill_id == 432
end

function std_talent_788:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_788:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
		local rate = self:get_refix_value(talent, level)
		if math.random(100) <= rate then
			impactenginer:send_impact_to_unit(reciver, 63074, sender, 0, false, 0) -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)
		end
	end
end

return std_talent_788