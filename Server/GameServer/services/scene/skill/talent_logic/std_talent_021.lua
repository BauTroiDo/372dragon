local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_021 = class("std_talent_021", base)
local specific_skill_id = 365
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_021:is_specific_skill(skill_id)
    return skill_id == specific_skill_id
end

function std_talent_021:get_up_damage_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 100
end

function std_talent_021:get_up_target_count(talent, level)
    local params = talent.params[level]
    return params[2] or 6
end

function std_talent_021:on_damage_target(talent, level, id, human, target, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local up_to_percent = self:get_up_damage_percent(talent, level) - 100
        -- local percent = self:get_refix_value(talent, level)
		if up_to_percent > 0 then
			if damages and damages.damage_rate then
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] + up_to_percent
				end
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * up_to_percent / 100)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

function std_talent_021:refix_impact(talent, level, imp)
    local skill_id = imp:get_skill_id()
    if self:is_specific_skill(skill_id) then
        local up_to_count = self:get_up_target_count(talent, level)
        local logic = impactenginer:get_logic(imp)
        -- Guard missing API and keep imp as first arg for std_impact_086.
        if logic and logic.set_affect_target_count then
            logic:set_affect_target_count(imp, up_to_count)
        end
    end
end

return std_talent_021