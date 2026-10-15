local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_131 = class("std_talent_131", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_131:is_specific_impact(impact_id)
    return impact_id == 155
end

function std_talent_131:is_specific_skill(skill_id)
    return skill_id == 437
end

function std_talent_131:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end


function std_talent_131:refix_impact(talent, level, imp, sender, reciver, skill_id)
    if self:is_specific_impact(imp:get_impact_id()) then
        if imp:get_logic_id() == 10 then
            local logic = impactenginer:get_logic(imp)
            local key = logic:get_sub_impact_key(1)
            logic:set_sub_impact_by_key(imp, key, 1612)
        end
    end
end

function std_talent_131:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        local tar_imp = reciver:impact_get_first_impact_of_specific_impact_id(155)
        if tar_imp then
            if tar_imp:get_caster_obj_id() == sender:get_obj_id() then
				if damages and damages.damage_rate then
					local recover_hp_rate = self:get_refix_value(talent, level)
					if recover_hp_rate > 0 then
						local idx = DAMAGE_TYPE_BACK[4]
						table.insert(damages[idx],{rate = recover_hp_rate})
						damages.recover_hp_rate_enable = true
					end
				end
                -- local percent = self:get_refix_value(talent, level)
                -- local hp = math.ceil(damages.hp_damage * percent / 100)
                -- sender:health_increment(math.abs(hp), sender, false)
            end
        end
    end
end

return std_talent_131