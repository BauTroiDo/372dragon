local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_404 = class("std_talent_404", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_404:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1]
end

function std_talent_404:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if skill_id == 763 then
        if sender:impact_have_impact_of_specific_impact_id(4953) then
            local percent = self:get_refix_value(talent, level)
			if damages and damages.damage_rate then
				for _,j in ipairs(DAMAGE_TYPE_RATE) do
					damages[j] = damages[j] + percent
				end
			end
			-- damages.hp_damage = 0
            -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
                -- damages[i] = math.floor((damages[i] or 0) * (100 + percent) / 100)
                -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
            -- end
        end
    end
end

return std_talent_404