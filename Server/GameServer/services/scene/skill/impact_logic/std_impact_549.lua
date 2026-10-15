local skynet = require "skynet"
local class = require "class"
local base = require "scene.skill.impact_logic.base"
local define = require "define"
local damage_impact_logic = require "scene.skill.impact_logic.std_impact_003"

-- std_impact_549: 通用百分比攻击伤害
-- 读取施法者全部攻击属性（外功/内功/冰/火/玄/毒），直接按各自百分比缩放（不经战斗公式）
-- 各伤害类型独立读取自己的配置参数：
--   "普通攻击伤害百分比" → 物理攻击伤害缩放率 rate_phy
--   "魔法攻击伤害百分比" → 魔法攻击伤害缩放率 rate_magic
--   "冰系伤害百分比" / "火系伤害百分比" / "电系伤害百分比" / "毒系伤害百分比" → 各自独立
local std_impact_549 = class("std_impact_549", base)

function std_impact_549:is_over_timed()
    return false
end

function std_impact_549:is_intervaled()
    return false
end

function std_impact_549:on_active(imp, obj)
    if not imp or not obj or not obj:is_alive() then
        return
    end

    local targetid = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(targetid)
    if not sender then
        skynet.logi("[IMPACT_549] sender not found, targetid=", targetid)
        return
    end

    -- 从 StandardImpact 配表参数读取各伤害类型百分比（各自独立，互不影响）
    local rate_phy    = imp.params["普通攻击伤害百分比"] or 0
    local rate_magic  = imp.params["魔法攻击伤害百分比"] or 0
    local rate_cold   = imp.params["冰系伤害百分比"] or 0
    local rate_fire   = imp.params["火系伤害百分比"] or 0
    local rate_light  = imp.params["电系伤害百分比"] or 0
    local rate_poison = imp.params["毒系伤害百分比"] or 0

    -- 如果所有百分比都为0，无伤害可造成，直接返回
    if rate_phy <= 0 and rate_magic <= 0 and rate_cold <= 0
       and rate_fire <= 0 and rate_light <= 0 and rate_poison <= 0 then
        return
    end

    -- 直接从施法者读取各攻击属性，按百分比缩放（不经 combat_core 战斗公式）
    local skill_id = imp:get_skill_id()
    local is_critical_hit = imp:is_critical_hit()

    -- 各类伤害 = 施法者对应攻击属性 × 百分比 / 100（百分比为0时伤害为0）
    local dmg_phy    = rate_phy > 0    and math.floor(sender:get_attack_physics() * rate_phy / 100)    or 0
    local dmg_magic  = rate_magic > 0  and math.floor(sender:get_attack_magic()   * rate_magic / 100)  or 0
    local dmg_cold   = rate_cold > 0   and math.floor(sender:get_attack_cold()    * rate_cold / 100)   or 0
    local dmg_fire   = rate_fire > 0   and math.floor(sender:get_attack_fire()    * rate_fire / 100)   or 0
    local dmg_light  = rate_light > 0  and math.floor(sender:get_attack_light()   * rate_light / 100)  or 0
    local dmg_poison = rate_poison > 0 and math.floor(sender:get_attack_posion()  * rate_poison / 100) or 0
    local dmg_direct = 0


    -- 检查是否有实际伤害，至少一个类型>0才投递
    local has_damage = (dmg_phy > 0 or dmg_magic > 0 or dmg_cold > 0
                        or dmg_fire > 0 or dmg_light > 0 or dmg_poison > 0 or dmg_direct > 0)
    if not has_damage then
        return
    end

    local damages = {hp_damage = 1}

    -- 穿刺伤害：使用所有非零百分比中的最大值进行缩放
    if skill_id and skill_id ~= -1 and define.CHUANCI_SKILL[skill_id] then
        local chuanci = obj:get_chuanci_damage(sender, is_critical_hit)
        if chuanci > 0 then
            local max_rate = math.max(rate_phy, rate_magic, rate_cold, rate_fire, rate_light, rate_poison)
            if max_rate > 0 then
                damages.chuanci = math.floor(chuanci * max_rate / 100)
            end
        end
    end

    -- 写入各类伤害
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_PHY]     = dmg_phy
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_MAGIC]   = dmg_magic
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_COLD]    = dmg_cold
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_FIRE]    = dmg_fire
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_LIGHT]   = dmg_light
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_POISON]  = dmg_poison
    damages[damage_impact_logic.enum_DAMAGE_TYPE.IDX_DAMAGE_DIRECHT] = dmg_direct

    -- rate 设为 100（百分比缩放已在上方完成，不再二次缩放）
    for _, j in ipairs(damage_impact_logic.enum_DAMAGE_TYPE_RATE) do
        damages[j] = 100
    end
    for _, j in ipairs(damage_impact_logic.enum_DAMAGE_TYPE_POINT) do
        damages[j] = imp.params[j] or 0
    end
    for _, j in ipairs(damage_impact_logic.enum_DAMAGE_TYPE_BACK) do
        damages[j] = {}
    end

    obj:on_damages(damages, targetid, is_critical_hit, skill_id, imp)
end

return std_impact_549
