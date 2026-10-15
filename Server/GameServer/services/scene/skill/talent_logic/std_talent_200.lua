local class = require "class"
local define = require "define"
-- local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_200 = class("std_talent_200", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_RATE = DI_DamagesByValue_T.enum_DAMAGE_TYPE_RATE
local enum_refix_types = {
    [281] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY,
    [311] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY,
    [341] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY,
    [371] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
    [401] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
    [431] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
    [461] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
    [491] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY,
    [521] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
    [760] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
    [788] = DI_DamagesByValue_T.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC,
}
function std_talent_200:get_refix_type(skill_id)
    return enum_refix_types[skill_id]
end

function std_talent_200:get_refix_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_200:on_damage_target(talent, level, id, sender, _, damages, skill_id)
    local refix_type = self:get_refix_type(skill_id)
    if refix_type then
		refix_type = refix_type + 1
        local percent = self:get_refix_percent(talent, level)
		if damages and damages.damage_rate then
			local idx = DAMAGE_TYPE_RATE[refix_type]
			if idx then
				damages[idx] = damages[idx] + percent
			end
		end
        -- damages.hp_damage = 0
        -- for i = damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY, damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT do
            -- if i == refix_type then
                -- damages[i] = math.floor((damages[i] or 0) * (100 + percent) / 100)
            -- end
            -- damages.hp_damage = (damages.hp_damage or 0) + damages[i]
        -- end
    end
end

return std_talent_200