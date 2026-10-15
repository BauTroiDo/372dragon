local class = require "class"
local define = require "define"
local skillenginer = require "skillenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local base = require "scene.skill.talent_logic.base"
local std_talent_076 = class("std_talent_076", base)
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK

function std_talent_076:is_liangyi_jian_skill(skill_id)
    return skill_id == 373
end

function std_talent_076:get_absorb_percent(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_076:on_damage_target(talent, level, id, human, target, damages, skill_id)
    if self:is_liangyi_jian_skill(skill_id) then
        if damages and damages.damage_rate then
            local percent = self:get_absorb_percent(talent, level)
            if percent > 0 then
                -- 插入回血标记，需设 recover_hp_rate_enable=true 绕过全局开关
                local key = DAMAGE_TYPE_BACK[4]  -- "recover_hp_rate"
                table.insert(damages[key], {rate = percent})
                damages.recover_hp_rate_enable = true
                -- 插入回气标记（recover_mp_rate 无全局开关，直接插入即生效）
                key = DAMAGE_TYPE_BACK[5]  -- "recover_mp_rate"
                table.insert(damages[key], {rate = percent})
            end
        end
    end
end

return std_talent_076