local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_070 = class("std_talent_070", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_070:is_tianma_feipu_skill(skill_id)
    return skill_id == 377
end

function std_talent_070:get_damage_add_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_070:on_damage_target(talent, level, id, _, target, damages, skill_id)
    if self:is_tianma_feipu_skill(skill_id) then
        local percent = self:get_damage_add_percent(talent, level)
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + percent
			end
		end
        -- local hp_damage = 0
        -- for i = 0, 6 do
            -- damages[i] = math.floor(damages[i] * ( 100 + percent) / 100)
            -- hp_damage = hp_damage + damages[i]
        -- end
        -- hp_damage = math.floor(hp_damage)
        -- hp_damage = hp_damage < 1 and 1 or hp_damage
        -- damages.hp_damage = hp_damage
    end
end

return std_talent_070