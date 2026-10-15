local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local combat_core = require "scene.skill.combat_core"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local skill_699 = class("skill_699", base)
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function skill_699:ctor()
end

-- function skill_699:get_give_self_impact(skill_info)
    -- local impacts = skill_info:get_activate_once_impacts()
    -- return impacts.self or define.INVAILD_ID
-- end

-- function skill_699:get_give_target_impact(skill_info)
    -- local impacts = skill_info:get_activate_once_impacts()
    -- return impacts.target or define.INVAILD_ID
-- end

function skill_699:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
	local skill_id = skill_info:get_skill_id()
	if skill_id == 4435 then
		obj_me:set_shenbind_status(0)
	end
end

return skill_699