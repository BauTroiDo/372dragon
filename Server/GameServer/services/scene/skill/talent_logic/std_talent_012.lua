local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_012 = class("std_talent_012", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE

function std_talent_012:is_aoe_skill(skill_id)
    local template = skillenginer:get_skill_template(skill_id)
    local target_mode = template.targeting_logic
    return target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_SELF or
    target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT or
    target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_UNIT_NEW or
    target_mode == define.ENUM_TARGET_LOGIC.TARGET_AE_AROUND_POSITION
end

function std_talent_012:on_damage_target(talent, level, id, _, target, damages, skill_id)
    skill_id = skill_id or define.INVAILD_ID
    if skill_id == define.INVAILD_ID then
        return
    end
    if self:is_aoe_skill(skill_id) then
		if damages and damages.damage_rate then
			for _,j in ipairs(DAMAGE_TYPE_RATE) do
				damages[j] = damages[j] + 10
			end
		end
        -- damages.hp_damage = 0
        -- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- damages[i] = math.floor((damages[i] or 0) * 1.1)
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

function std_talent_012:refix_impact(talent, level, imp)
    local data_index = imp:get_data_index()
    if data_index >= 971 and data_index <= 982 then
        local logic = impactenginer:get_logic(imp)
        if logic then
            local value = logic:get_value_of_refix_attrib_hit(imp)
            logic:set_value_of_refix_attrib_hit(imp, value * 2)
        end
    end
end

return std_talent_012