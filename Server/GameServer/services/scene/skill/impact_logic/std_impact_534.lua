-- 心剑交融专用状态（继承 std_impact_060）
-- 在 060 所有功能基础上，增加：被攻击时概率触发借力状态
-- 借力概率受武道 931（山雨欲来加成）和 968（低血量加成）影响
-- 借力触发时检查天赋 930（静水深流）减少借力返施冷却
-- 借力触发时检查天赋 969（吞花卧酒）已有借力时额外叠加增伤buff
-- 借力触发时检查天赋 913（借力打力）对攻击者反伤
-- 借力未触发时检查天赋 909（君子剑）概率恢复血量
local class = require "class"
local impactenginer = require "impactenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local skillenginer  = require "skillenginer":getinstance()
local std_impact_060 = require "scene.skill.impact_logic.std_impact_060"
local std_impact_534 = class("std_impact_534", std_impact_060)

-- 获取天赋等级和配置参数的通用辅助
local function get_talent_params(obj, talent_id)
    if not obj.get_talent then return nil end
    local talent = obj:get_talent()
    if not talent or not talent.study then return nil end
    for _, t in ipairs(talent.study) do
        if t.id == talent_id then
            local sect_desc = configenginer:get_config("sect_desc")
            if not sect_desc then return nil end
            local cfg = sect_desc[talent_id]
            if cfg and cfg.params then
                local lv = t.level == 0 and 1 or t.level
                return cfg.params[lv], lv
            end
            return nil
        end
    end
    return nil
end

-- 借力触发后，检查天赋930（静水深流）减少借力返施(829)冷却
local function apply_talent_930(obj)
    local params, lv = get_talent_params(obj, 930)
    if not params then
        -- 调试输出已屏蔽
        -- print("[930] apply_talent_930: no params, talent not learned or cfg missing")
        return
    end
    local reduce_sec = params[1] or 0
    -- 调试输出已屏蔽
    -- print("[930] apply_talent_930: lv=", lv, " reduce_sec=", reduce_sec)
    if reduce_sec > 0 then
        local reduce_ms = reduce_sec * 1000
        local template = skillenginer:get_skill_template(829)
        if not template then
            -- 调试输出已屏蔽
            -- print("[930] apply_talent_930: skill 829 template not found!")
            return
        end
        local cd_id = template.cool_down_id
        local cur_cd = obj:get_cool_down_by_cool_down_id(cd_id)
        -- 调试输出已屏蔽
        -- print("[930] apply_talent_930: cool_down_id=", cd_id, " cur_cd=", cur_cd, " reduce_ms=", reduce_ms)
        if cur_cd and cur_cd > 0 then
            obj:update_cool_down_by_cool_down_id(cd_id, reduce_ms)
            -- 调试输出已屏蔽
            -- print("[930] apply_talent_930: cooldown reduced, new_cd=", obj:get_cool_down_by_cool_down_id(cd_id))
        else
            -- 调试输出已屏蔽
            -- print("[930] apply_talent_930: skill 829 not on cooldown (cur_cd=", cur_cd, "), no effect")
        end
    end
end

-- 天赋969（吞花卧酒）的增伤buff映射表（按等级）
local TALENT_969_IMPACTS = {19155, 19156, 19157, 19158, 19159}

-- 借力触发后，若已有借力状态，检查天赋969（吞花卧酒）叠加增伤buff
local function apply_talent_969(obj)
    local params, lv = get_talent_params(obj, 969)
    if not params then return end
    local impact_id = TALENT_969_IMPACTS[lv]
    if impact_id then
        -- 保存当前542叠层，供新impact的on_active继承；无则清空（新周期从1开始）
        local saved
        for _, imp in ipairs(obj:get_impact_list() or {}) do
            if imp:get_logic_id() == 542 then
                saved = imp._stack_count
                break
            end
        end
        obj._saved_542_stack = saved
        impactenginer:send_impact_to_unit(obj, impact_id, obj, 0, false, 0)
    end
end

-- 检查攻击者(sender)身上是否有心剑交融破绽状态（logic_id=11 且 skill_id=828）
local function sender_has_blemish(sender)
    if not sender then return false end
    local list = sender:get_impact_list()
    if not list then return false end
    for i = 1, #list do
        local imp = list[i]
        if imp:get_logic_id() == 11 and imp:get_skill_id() == 828 then
            return true
        end
    end
    return false
end

-- 借力未触发时，检查天赋909（君子剑）20%概率恢复伤害X%血量
-- 触发条件：攻击者(sender)身上有心剑交融破绽状态
local function apply_talent_909(obj, sender, damage_taken)
    local params = get_talent_params(obj, 909)
    if not params then return end
    -- 检查攻击者是否拥有破绽状态
    if not sender_has_blemish(sender) then return end
    -- 20%概率
    if math.random(100) > 20 then return end
    local percent = params[1] or 0
    if percent <= 0 then return end
    local heal = math.ceil(damage_taken * percent / 100)
    if heal > 0 then
        obj:health_increment(heal, obj)
    end
end

-- 借力触发后，检查天赋913（借力打力）对攻击者造成伤害X%反伤
local function apply_talent_913(obj, sender, damage_taken)
    local params = get_talent_params(obj, 913)
    if not params then return end
    local percent = params[1] or 0
    if percent <= 0 then return end
    local reflect = math.ceil(damage_taken * percent / 100)
    if reflect > 0 and sender and sender ~= obj then
        sender:health_increment(-reflect, obj)
    end
end

-- 记录受击前HP快照（on_damages 在 on_be_hit 之前同步执行）
-- 供 on_be_hit 中天赋909/913计算实际伤害使用
function std_impact_534:on_damages(imp, obj, damages, caster_obj_id, is_critical, skill_id, imp2)
    obj._534_hp_before_hit = obj:get_hp()
end

function std_impact_534:on_be_hit(imp, obj, sender, skill)
    if not sender then return end
    if not sender:is_alive() then return end
    if not obj:is_enemy(sender) then return end

    local rate = self:calc_borrow_rate(imp, obj)
    if rate <= 0 then return end

    local buff_id = imp.params["借力效果ID"] or -1
    if buff_id < 0 then return end

    -- 计算本次受到的伤害（on_damages 先于 on_be_hit 执行，HP已被扣减）
    local damage_taken = 0
    if obj._534_hp_before_hit then
        damage_taken = obj._534_hp_before_hit - obj:get_hp()
        if damage_taken < 0 then damage_taken = 0 end
        obj._534_hp_before_hit = nil
    end

    -- 检查是否已有借力状态(logic_id=532)，供天赋969判断
    local already_has_borrow = false
    local impact_list = obj:get_impact_list()
    if impact_list then
        for i = 1, #impact_list do
            if impact_list[i]:get_logic_id() == 532 then
                already_has_borrow = true
                break
            end
        end
    end

    local rand = math.random(100)
    if rand <= rate then
        -- === 借力触发 ===
        impactenginer:send_impact_to_unit(obj, buff_id, obj, 0, false, 0)
        -- 天赋930: 静水深流 - 触发借力时减少借力返施冷却
        apply_talent_930(obj)
        -- 天赋969: 吞花卧酒 - 已有借力状态时再次触发，叠加增伤buff
        if already_has_borrow then
            apply_talent_969(obj)
        end
        -- 天赋913: 借力打力 - 触发借力时对攻击者造成反伤
        if damage_taken > 0 then
            apply_talent_913(obj, sender, damage_taken)
        end
    else
        -- === 借力未触发 ===
        -- 天赋909: 君子剑 - 攻击者有破绽状态时20%概率恢复伤害X%的血量
        if damage_taken > 0 then
            apply_talent_909(obj, sender, damage_taken)
        end
    end
end

return std_impact_534
