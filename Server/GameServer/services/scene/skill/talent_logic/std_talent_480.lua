local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local base = require "scene.skill.talent_logic.base"
local std_talent_480 = class("std_talent_480", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_480:is_specific_skill(skill_id)
    return skill_id == 365
end

function std_talent_480:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_480:on_skill_miss(talent, level, sender, reciver, skill_id)
    local impact = reciver:impact_get_first_impact_of_specific_impact_id(585)
    if impact then
        local logic = impactenginer:get_logic(impact)
        if logic then
            local count = logic:get_skill_miss_count(impact)
            count = count + 1
            logic:set_skill_miss_count(impact, count)
        end
    end
end

function std_talent_480:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local impact = sender:impact_get_first_impact_of_specific_impact_id(585)
        if impact then
            local logic = impactenginer:get_logic(impact)
            if logic then
                local count = logic:get_skill_miss_count(impact)
                if count >= 8 then
                    local odd = self:get_refix_value(talent, level)
                    local n = math.random(1, 100)
                    if n <= odd then
                        local percent = 100
						if damages and damages.damage_rate then
							for _,j in ipairs(DAMAGE_TYPE_RATE) do
								damages[j] = damages[j] * (100 + percent) / 100
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
        end
    end
end


return std_talent_480