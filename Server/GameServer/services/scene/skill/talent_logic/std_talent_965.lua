-- 有情剑：使用横剑疆场(技能815)后，自身恢复该次伤害X%的血量
-- 对非玩家目标使用时，恢复的血量降低
-- on_damage_target 回调以 skill_id=815 触发，812是普攻共享子技能不参与匹配
local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.talent_logic.base"
local DI_DamagesByValue_T = require "scene.skill.impact_logic.std_impact_003"
local DAMAGE_TYPE_BACK = DI_DamagesByValue_T.enum_DAMAGE_TYPE_BACK
local std_talent_965 = class("std_talent_965", base)

-- 横剑疆场主技能ID，on_damage_target 回调时以815触发
local HUJIAN_SKILLS = { [815] = true }

function std_talent_965:is_specific_skill(skill_id)
    return HUJIAN_SKILLS[skill_id] == true
end

function std_talent_965:get_refix_value(talent, level)
    local params = talent.params[level]
    return params[1] or 0
end

function std_talent_965:on_damage_target(talent, level, id, sender, reciver, damages, skill_id)
    if self:is_specific_skill(skill_id) then
        if damages and damages.damage_rate then
            local recover_hp_rate = self:get_refix_value(talent, level)
            if recover_hp_rate > 0 then
                -- 对非玩家目标（怪物等）恢复量降低为30%
                if reciver and reciver:get_obj_type() ~= "human" then
                    recover_hp_rate = math.ceil(recover_hp_rate * 30 / 100)
                end
                if recover_hp_rate > 0 then
                    -- 插入回血标记，并通过 recover_hp_rate_enable=true 绕过全局开关
                    local idx = DAMAGE_TYPE_BACK[4]
                    table.insert(damages[idx], {rate = recover_hp_rate})
                    damages.recover_hp_rate_enable = true
                end
            end
        end
    end
end

return std_talent_965
