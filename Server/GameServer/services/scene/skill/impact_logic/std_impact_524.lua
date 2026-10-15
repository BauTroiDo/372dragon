local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.impact_logic.base"
local std_impact_524 = class("std_impact_524", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_impact_524:is_over_timed()
    return true
end

function std_impact_524:is_intervaled()
    return false
end

-- function std_impact_524:get_single_target_skill_damage_up(imp)
    -- return imp.params["单体技能伤害+"] or 0
-- end

-- function std_impact_524:get_aoe_skill_damage_up(imp)
    -- return imp.params["群体技能伤害+"] or 0
-- end

function std_impact_524:get_single_target_skill_mind_attck_rate_up(imp)
    return imp.params["单体技能会心一击率+"] or 0
end

function std_impact_524:get_skill_collection_id(imp)
    return imp.params["技能集合ID"] or -1
end

function std_impact_524:get_menpai_id(imp)
    return imp.params["门派ID"] or -1
end

-- function std_impact_524:get_aoe_skill_mind_attck_rate_up(imp)
    -- return imp.params["群体技能会心一击率+"] or 0
-- end

-- function std_impact_524:get_aoe_skill_mind_attck_rate_up(imp)
    -- return imp.params["群体技能会心一击率+"] or 0
-- end

-- function std_impact_524:get_add_buff(imp)
	-- return imp.params["给予状态"] or -1
-- end

-- function std_impact_524:set_add_buff(imp, value)
	-- imp.params["给予状态"] = value
-- end
function std_impact_524:refix_critical_rate(imp, critical_rate, skill_info, obj)
    if skill_info then
		if obj:get_menpai() == self:get_menpai_id(imp) then
			local collection_id = self:get_skill_collection_id(imp)
			if collection_id ~= -1 then
				if skillenginer:is_skill_in_collection(skill_info.id, collection_id) then
					critical_rate = critical_rate + self:get_single_target_skill_mind_attck_rate_up(imp) / 100
					obj:on_impact_fade_out(imp)
					obj:remove_impact(imp)
				end
				return critical_rate
			end
		end
    end
	obj:on_impact_fade_out(imp)
	obj:remove_impact(imp)
    return critical_rate
end

return std_impact_524