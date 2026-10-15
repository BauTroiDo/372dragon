local class = require "class"
local define = require "define"
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_314 = class("std_impact_314", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_314:is_over_timed()
    return true
end

function std_impact_314:is_intervaled()
    return false
end

function std_impact_314:get_single_target_skill_damage_up(imp)
    return imp.params["单体技能伤害+"] or 0
end

function std_impact_314:get_aoe_skill_damage_up(imp)
    return imp.params["群体技能伤害+"] or 0
end

function std_impact_314:get_single_target_skill_mind_attck_rate_up(imp)
    return imp.params["单体技能会心一击率+"] or 0
end

function std_impact_314:get_aoe_skill_mind_attck_rate_up(imp)
    return imp.params["群体技能会心一击率+"] or 0
end

function std_impact_314:get_add_buff(imp)
	return imp.params["给予状态"] or -1
end

function std_impact_314:set_add_buff(imp, value)
	imp.params["给予状态"] = value
end

function std_impact_314:on_damage_target(imp, sender, reciver, damages, skill_id)
    if skill_id == 371 then
		local buffid = self:get_add_buff(imp)
		if buffid ~= -1 then
			self:set_add_buff(imp, -1)
			impactenginer:send_impact_to_unit(reciver, buffid, sender, 0, false, 0)
		end
	end
	local skill_info = sender and sender:get_skill_info()
	local is_aoe_skill = false
	if skill_info then
		local tl = skill_info:get_targeting_logic()
		is_aoe_skill = (tl == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_SELF 
			or tl == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT 
			or tl == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT_NEW 
			or tl == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_POSITION)
	end
	local up
	if is_aoe_skill then
		up = self:get_aoe_skill_damage_up(imp)
	else
		up = self:get_single_target_skill_damage_up(imp)
	end
	if damages and damages.damage_rate then
		for _,j in ipairs(DAMAGE_TYPE_RATE) do
			damages[j] = damages[j] * (100 + up) / 100
		end
	end
end

function std_impact_314:refix_critical_rate(imp, critical_rate, skill_info)
    if skill_info then
        local targeting_logic = skill_info:get_targeting_logic()
        local is_aoe_skill = (targeting_logic == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_SELF or targeting_logic == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT or targeting_logic == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_POSITION)
        if is_aoe_skill then
            critical_rate = critical_rate + self:get_aoe_skill_mind_attck_rate_up(imp) / 100
        else
            critical_rate = critical_rate + self:get_single_target_skill_mind_attck_rate_up(imp) / 100    
        end
    end
    return critical_rate
end

return std_impact_314