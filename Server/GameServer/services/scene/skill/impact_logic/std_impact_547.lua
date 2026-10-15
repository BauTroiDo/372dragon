-- 灵兽共鸣：根据珍兽的兽魂融魂装备属性为主人提供属性增幅
-- 施加在主人身上，激活时读取融魂珍兽的魂装备数据，按 pet_soul_attr_effect 逻辑计算属性值后乘增幅率
-- 融魂珍兽通过主人的 soul_melting_pet_guid 属性获取（不一定是施法珍兽）
-- 施法珍兽（caster）用于 calc_amplify_rate（觉醒等级、兽灵等级、成长率、资质）
-- 通过标准 get_refix_xxx 钩子在属性计算时注入，消失时自动清零
local class         = require "class"
local skynet        = require "skynet"
local define        = require "define"
local base          = require "scene.skill.impact_logic.base"
local configenginer = require "configenginer":getinstance()

local std_impact_547 = class("std_impact_547", base)

--------------------------------------------------------------
-- 增幅参数常量（方便后续调参）
--------------------------------------------------------------
-- 基础增幅率（按开悟等级 1-5 对应，index = kw_level）
local BASE_RATE_BY_KW_LEVEL = { 0.05, 0.10, 0.15, 0.20, 0.25 }
-- 兽灵等级因子：前四槽最低等级 * 此系数
local ELF_LEVEL_FACTOR      = 0.005
-- 成长率因子：growth_rate（浮点，如 1.0~3.0）* 此系数
local GROW_RATE_FACTOR      = 0.02
-- 资质因子：最高 perception 值 * 此系数（perception 通常 100~4000）
local APTITUDE_FACTOR       = 0.0001
-- 资质来源字段列表
local PERCEPTION_KEYS = { "str_perception", "spr_perception", "con_perception", "int_perception", "dex_perception" }

--------------------------------------------------------------
-- 融魂属性 type → imp.params 存储键名
-- 对应 define.PET_SOUL_MELTING_ATTR_2_IA 的 type 编号
--------------------------------------------------------------
local SOUL_PARAM_KEY = {
    [0]  = "soul_hp_max",           -- IATTRIBUTE_POINT_MAXHP
    [1]  = "soul_str",              -- IATTRIBUTE_STR
    [2]  = "soul_spr",              -- IATTRIBUTE_SPR
    [3]  = "soul_con",              -- IATTRIBUTE_CON
    [4]  = "soul_int",              -- IATTRIBUTE_INT
    [5]  = "soul_dex",              -- IATTRIBUTE_DEX
    [6]  = "soul_att_p_m",          -- IATTRIBUTE_POINT_ATTACK_P_ATTACK_M（内外功同步）
    [7]  = "soul_attrib_hit",       -- IATTRIBUTE_HIT
    [8]  = "soul_attrib_miss",      -- IATTRIBUTE_MISS
    [9]  = "soul_mind_attack",      -- IATTRIBUTE_2ATTACK_RATE（会心）
    [10] = "soul_mind_defend",      -- IATTRIBUTE_LUK（会心防御）
    [11] = "soul_def_cold",         -- IATTRIBUTE_COLD_RESIST
    [12] = "soul_def_fire",         -- IATTRIBUTE_FIRE_RESIST
    [13] = "soul_def_light",        -- IATTRIBUTE_LIGHT_RESIST
    [14] = "soul_def_poison",       -- IATTRIBUTE_POISON_RESIST
    [15] = "soul_jian_su_resist",   -- IATTRIBUTE_POINT_JIAN_SU_RESIST（减速免疫）
    [16] = "soul_dian_xue_resist",  -- IATTRIBUTE_POINT_DIAN_XUE_RESIST（封穴免疫）
    [17] = "soul_ma_bi_resist",     -- IATTRIBUTE_POINT_MA_BI_RESIST（麻痹免疫）
    [18] = "soul_san_gong_resist",  -- IATTRIBUTE_POINT_SAN_GONG_RESIST（散功免疫）
    [19] = "soul_feng_yin_resist",  -- IATTRIBUTE_POINT_FENG_YIN_RESIST（封印免疫）
    [20] = "soul_shi_ming_resist",  -- IATTRIBUTE_POINT_SHI_MING_RESIST（失明免疫）
    [21] = "soul_reduce_damage",    -- IATTRIBUTE_POINT_REDUCE_DAMAGE（通过 item_value 读取）
    [22] = "soul_add_damage",       -- IATTRIBUTE_POINT_ADD_DAMAGE（通过 item_value 读取）
}

--------------------------------------------------------------
-- 融魂附体效果参数键名（对应 PET_SOUL_BASE_ATTR_2_IA）
-- IATTRIBUTE → imp.params 存储键名
--------------------------------------------------------------
local MELTING_PARAM_KEY = {
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_ATTACK]                  = "mp_cold_attack",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_ATTACK]                = "mp_poison_attack",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_ATTACK]                 = "mp_light_attack",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_ATTACK]                  = "mp_fire_attack",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST]    = "mp_reduce_cold_resist",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST]  = "mp_reduce_poison_resist",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST]   = "mp_reduce_light_resist",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST]    = "mp_reduce_fire_resist",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POINT_MAXHP]                  = "mp_hp_max",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_HIT]                          = "mp_hit",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_MISS]                         = "mp_miss",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_2ATTACK_RATE]                 = "mp_mind_attack",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LUK]                          = "mp_mind_defend",
}

-- IATTRIBUTE → get_refix 钩子属性名（对应 human_attrib.lua 中的属性定义）
local MELTING_REFIX_HOOKS = {
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_COLD_ATTACK]                  = "att_cold",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_POISON_ATTACK]                = "att_poison",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_LIGHT_ATTACK]                 = "att_light",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_FIRE_ATTACK]                  = "att_fire",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_COLD_RESIST]    = "reduce_def_cold",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_POISON_RESIST]  = "reduce_def_poison",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_LIGHT_RESIST]   = "reduce_def_light",
    [define.ITEM_ATTRIBUTE.IATTRIBUTE_REDUCE_TARGET_FIRE_RESIST]    = "reduce_def_fire",
    -- hp_max / attrib_hit / attrib_miss / mind_attack / mind_defend 钩子已存在，在各自函数中合并处理
}

--------------------------------------------------------------
-- 持续型，不需要周期
--------------------------------------------------------------
function std_impact_547:is_over_timed()
    return true
end

function std_impact_547:is_intervaled()
    return false
end

--------------------------------------------------------------
-- 辅助：计算增幅率（基于施法珍兽）
-- 三个因子：前四兽灵最低等级、珍兽成长率、最高资质
-- 返回 amplify_rate（如 0.35 = 35%）
--------------------------------------------------------------
local function calc_amplify_rate(detail)
    local elf_slots = detail:get_elf_slots() or {}

    -- 1. 前四槽最低等级
    local min_elf_level = math.huge
    local has_valid_slot = false
    for i = 1, 4 do
        local slot = elf_slots[i]
        if slot and slot.activated == 1 and slot.level and slot.level > 0 then
            if slot.level < min_elf_level then
                min_elf_level = slot.level
            end
            has_valid_slot = true
        end
    end
    if not has_valid_slot then min_elf_level = 0 end

    -- 2. 开悟等级决定基础增幅（kw_level = 已激活槽数）
    local kw_level = detail:get_kw_level() or 0
    local base_rate = BASE_RATE_BY_KW_LEVEL[kw_level] or 0

    -- 3. 成长率因子
    local grow_rate = detail:get_growth_rate() or 0

    -- 4. 最高资质因子
    local max_aptitude = detail:get_max_perception_in_collection(PERCEPTION_KEYS) or 0

    local amplify_rate = base_rate
                       + min_elf_level * ELF_LEVEL_FACTOR
                       + grow_rate     * GROW_RATE_FACTOR
                       + max_aptitude  * APTITUDE_FACTOR

    skynet.error(string.format(
        "[IMPACT_547] 增幅率计算: kw_level=%d base=%.2f min_elf_lv=%d grow=%.3f max_apt=%d amplify=%.4f(%.2f%%)",
        kw_level, base_rate, min_elf_level, grow_rate, max_aptitude, amplify_rate, amplify_rate * 100))

    return amplify_rate
end

--------------------------------------------------------------
-- 辅助：复用 pet_soul_attr_effect 的计算逻辑，计算单个 attr 的 iv 值
-- 返回 iv（整数），无效类型返回 nil
--------------------------------------------------------------
local function calc_soul_attr_iv(pet_detail, attr)
    local t = attr.type
    if t == define.INVAILD_ID then return nil end

    local value = attr.value
    local cof = define.PET_SOUL_MELTING_COF[t]
    local collection = define.PET_SOUL_MELTING_INFLUENCE_PERCEPTION[t]
    if not cof or not collection then return nil end

    local growth_rate = pet_detail:get_growth_rate() * 1000
    local perception = pet_detail:get_max_perception_in_collection(collection)
    local growth_rate_arg = (growth_rate * growth_rate / 64000000.0) + 0.0099999998

    -- type 15-20：控制免疫抗性（减速/封穴/麻痹/散功/封印/失明），与 human_attrib 同公式
    if t == 15 or t == 16 or t == 17 or t == 18 or t == 19 or t == 20 then
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        iv = iv * 11.58
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)

    elseif t == 11 or t == 12 or t == 13 or t == 14 then
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        iv = iv * 11.58
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)

    elseif t == 21 or t == 22 then
        local v = value / 100
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (v * growth_rate_arg) * 15.0
        iv = iv * 11.58
        if (v * 18) <= iv then iv = v * 18 end
        iv = math.floor(iv)
        return (iv < 1) and 1 or iv

    elseif t == 0 then
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        iv = iv * 15.27699669966997
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)

    elseif t == 1 or t == 2 or t == 3 or t == 4 or t == 5
        or t == 6 or t == 7 or t == 8 then
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        iv = iv * 11.19
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)

    elseif t == 9 then
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        iv = iv * 7.63
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)

    elseif t == 10 then
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        iv = iv * 4.23
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)

    else
        local iv = (((perception + 2000) * (perception + 2000) * cof) + 0.0099999998) * (value * growth_rate_arg)
        if iv > value * 1.2 then iv = value * 1.2 end
        return math.floor(iv)
    end
end

--------------------------------------------------------------
-- 辅助：处理单个 PetSoulSkill.txt 附体效果（melting_impacts），增幅后写入 imp.params
-- skill_id: PetSoulSkill.txt 的技能 ID
-- level: soul_level+1（决定读取哪一级数值）
-- impact_id: 1 或 2（melting_impacts 的索引）
-- amplify_rate: 已计算好的增幅率
--------------------------------------------------------------
local function apply_melting_impact_one(imp, skill_id, level, impact_id, amplify_rate)
    local pet_soul_skill = configenginer:get_config("pet_soul_skill")
    if not pet_soul_skill or not pet_soul_skill[skill_id] then return end

    local skill_conf = pet_soul_skill[skill_id]
    local melting = skill_conf.melting_impacts and skill_conf.melting_impacts[impact_id]
    if not melting then return end

    local desc = melting.desc
    local values = melting.values
    if not desc or desc == define.INVAILD_ID or not values then return end

    local raw_iv = values[level]
    if not raw_iv or raw_iv <= 0 then return end

    local ia = define.PET_SOUL_BASE_ATTR_2_IA[desc]
    if not ia then return end

    -- 穷奇特殊处理，跳过
    if ia == define.ITEM_ATTRIBUTE.IATTRIBUTE_QIONGQI_MELTING_IMPACT then return end

    local param_key = MELTING_PARAM_KEY[ia]
    if not param_key then return end

    local multiplier = 1 + amplify_rate
    local amplified = math.floor(raw_iv * multiplier)
    imp.params[param_key] = (imp.params[param_key] or 0) + amplified

    skynet.error(string.format("[IMPACT_547] 附体效果%d: %s ia=%d 原始=%d 增幅后=%d (×%.4f)",
        impact_id, tostring(desc), ia, raw_iv, amplified, multiplier))
end

--------------------------------------------------------------
-- 辅助：从融魂珍兽的魂装备读取属性，乘以增幅率后写入 imp.params
-- caster_detail：施法珍兽 detail（用于增幅率计算）
-- soul_pet_detail：融魂珍兽 detail（用于读取魂装备属性值和资质）
-- 返回 amplify_rate 供外部展示
--------------------------------------------------------------
local function calc_soul_melting_bonus(imp, caster_detail, soul_pet_detail)
    -- 获取魂装备
    local soul = soul_pet_detail:get_equip_container():get_item(define.PET_EQUIP.PEQUIP_SOUL)
    if not soul then
        skynet.error("[IMPACT_547] calc_soul_melting_bonus: 融魂珍兽无魂装备")
        return 0
    end

    local equip_data = soul:get_pet_equip_data()
    if not equip_data then
        skynet.error("[IMPACT_547] calc_soul_melting_bonus: 魂装备无 equip_data")
        return 0
    end

    -- soul_level+1 决定读取多少层属性（与 pet_soul_melting_extra_effect 一致）
    local level = (equip_data:get_pet_soul_level() or 0) + 1
    local pet_soul_attr = equip_data:get_pet_soul_attr()
    if not pet_soul_attr then
        skynet.error("[IMPACT_547] calc_soul_melting_bonus: 魂装备无 pet_soul_attr")
        return 0
    end

    -- 计算增幅率（基于施法珍兽）
    local amplify_rate = calc_amplify_rate(caster_detail)
    local multiplier   = 1 + amplify_rate

    -- ===== 处理融魂附体效果（PetSoulSkill.txt）=====
    local soul_level = (equip_data:get_pet_soul_level() or 0) + 1
    local base = soul:get_pet_soul_base()
    if base and base.skill then
        skynet.error(string.format("[IMPACT_547] 处理附体效果 skill_id=%s soul_level=%d",
            tostring(base.skill), soul_level))
        apply_melting_impact_one(imp, base.skill, soul_level, 1, amplify_rate)
        apply_melting_impact_one(imp, base.skill, soul_level, 2, amplify_rate)
        apply_melting_impact_one(imp, base.skill, soul_level, 3, amplify_rate)
    else
        skynet.error("[IMPACT_547] 无附体效果: soul:get_pet_soul_base() 为空或无 skill 字段")
    end

    -- 先累加原始融魂属性 iv（多层叠加）
    local raw_sum = {}  -- param_key -> 原始合计
    for i = 1, level do
        local attr = pet_soul_attr[i]
        if attr then
            local iv = calc_soul_attr_iv(soul_pet_detail, attr)
            if iv and iv > 0 then
                local t = attr.type
                local param_key = SOUL_PARAM_KEY[t]
                if param_key then
                    raw_sum[param_key] = (raw_sum[param_key] or 0) + iv
                end
            end
        end
    end

    -- 应用增幅率
    for param_key, raw_val in pairs(raw_sum) do
        local amplified = math.floor(raw_val * multiplier)
        imp.params[param_key] = amplified
        skynet.error(string.format(
            "[IMPACT_547] %s 原始iv=%d 增幅后=%d (×%.4f)",
            param_key, raw_val, amplified, multiplier))
    end

    return amplify_rate
end

--------------------------------------------------------------
-- 激活：读取融魂珍兽魂装备数据，填充 imp.params 属性加成
--------------------------------------------------------------
function std_impact_547:on_active(imp, obj_owner)
    if not obj_owner then return end
    if obj_owner:get_obj_type() ~= "human" then return end

    -- 通过施法者 obj_id 找到施法珍兽（用于增幅率）
    local caster_obj_id = imp:get_caster_obj_id()
    local scene = obj_owner:get_scene()
    if not scene then return end

    local caster_pet = scene:get_obj_by_id(caster_obj_id)
    if not caster_pet or caster_pet:get_obj_type() ~= "pet" then
        skynet.error("[IMPACT_547] on_active: caster is not a pet, id=", caster_obj_id)
        return
    end

    local caster_detail = caster_pet:get_detail()
    if not caster_detail then
        -- 场景pet的get_detail()可能返回nil，走标准路径
        local owner = caster_pet:get_owner()
        if owner then
            local pet_guid = owner:get_current_pet_guid()
            if pet_guid and not pet_guid:is_null() then
                local container = owner:get_pet_bag_container()
                if container then
                    caster_detail = container:get_pet_by_guid(pet_guid)
                end
            end
        end
    end
    if not caster_detail then
        skynet.error("[IMPACT_547] on_active: 施法珍兽无 detail (标准路径也失败)")
        return
    end

    -- 通过主人的 soul_melting_pet_guid 找到融魂珍兽（不一定与施法珍兽相同）
    local soul_melting_pet_guid = obj_owner:get_attrib("soul_melting_pet_guid")
    if not soul_melting_pet_guid or soul_melting_pet_guid:is_null() then
        skynet.error("[IMPACT_547] on_active: 主人无融魂珍兽 (soul_melting_pet_guid 为空)")
        return
    end

    local pet_bag = obj_owner:get_pet_bag_container()
    if not pet_bag then
        skynet.error("[IMPACT_547] on_active: 主人无珍兽背包容器")
        return
    end

    local soul_pet_detail = pet_bag:get_pet_by_guid(soul_melting_pet_guid)
    if not soul_pet_detail then
        skynet.error("[IMPACT_547] on_active: 未找到融魂珍兽 guid=", tostring(soul_melting_pet_guid))
        return
    end

    -- 清零所有融魂参数，防止重复叠加
    for _, param_key in pairs(SOUL_PARAM_KEY) do
        imp.params[param_key] = 0
    end
    for _, param_key in pairs(MELTING_PARAM_KEY) do
        imp.params[param_key] = 0
    end

    -- 计算并写入融魂属性加成（含增幅率）
    local amplify_rate = calc_soul_melting_bonus(imp, caster_detail, soul_pet_detail)

    -- 标记属性脏位，让引擎在下次属性计算时调用 get_refix_xxx 钩子
    self:mark_modified_attr_dirty(imp, obj_owner)
    -- 刷新主人属性显示
    obj_owner:send_refresh_attrib()

    -- 发送增幅提示给主人
    local tip_msg = string.format("兽魂融魂共鸣激活，当前增幅率 %.1f%%", amplify_rate * 100)
    if obj_owner.notify_tips then
        obj_owner:notify_tips(tip_msg)
    end

    skynet.error(string.format("[IMPACT_547] on_active: owner=%s caster_pet=%s soul_pet=<fusion> 融魂增幅已施加 amplify=%.2f%%",
        tostring(obj_owner:get_name()), tostring(caster_pet:get_name()), amplify_rate * 100))
end

--------------------------------------------------------------
-- HP 上限修正（点数）
--------------------------------------------------------------
function std_impact_547:get_refix_hp_max(imp, args)
    local point = (imp.params["soul_hp_max"] or 0) + (imp.params["mp_hp_max"] or 0)
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_hp_max: +%d (融魂出战=%d 附体=%d)",
            math.floor(point), imp.params["soul_hp_max"] or 0, imp.params["mp_hp_max"] or 0))
    end
end

--------------------------------------------------------------
-- 五维修正
--------------------------------------------------------------
function std_impact_547:get_refix_str(imp, args)
    local v = imp.params["soul_str"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_str: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_spr(imp, args)
    local v = imp.params["soul_spr"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_spr: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_con(imp, args)
    local v = imp.params["soul_con"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_con: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_int(imp, args)
    local v = imp.params["soul_int"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_int: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_dex(imp, args)
    local v = imp.params["soul_dex"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_dex: +%d (融魂增幅)", math.floor(v)))
    end
end

--------------------------------------------------------------
-- 内外功攻击修正（type 6 → IATTRIBUTE_POINT_ATTACK_P_ATTACK_M，同时加内功外功）
--------------------------------------------------------------
function std_impact_547:get_refix_attrib_att_physics(imp, args)
    local point = imp.params["soul_att_p_m"] or 0
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_attrib_att_physics: +%d (融魂增幅)", math.floor(point)))
    end
end

function std_impact_547:get_refix_attrib_att_magic(imp, args)
    local point = imp.params["soul_att_p_m"] or 0
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_attrib_att_magic: +%d (融魂增幅)", math.floor(point)))
    end
end

--------------------------------------------------------------
-- 命中修正
--------------------------------------------------------------
function std_impact_547:get_refix_attrib_hit(imp, args)
    local point = (imp.params["soul_attrib_hit"] or 0) + (imp.params["mp_hit"] or 0)
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_attrib_hit: +%d (融魂出战=%d 附体=%d)",
            math.floor(point), imp.params["soul_attrib_hit"] or 0, imp.params["mp_hit"] or 0))
    end
end

--------------------------------------------------------------
-- 闪避修正
--------------------------------------------------------------
function std_impact_547:get_refix_attrib_miss(imp, args)
    local point = (imp.params["soul_attrib_miss"] or 0) + (imp.params["mp_miss"] or 0)
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_attrib_miss: +%d (融魂出战=%d 附体=%d)",
            math.floor(point), imp.params["soul_attrib_miss"] or 0, imp.params["mp_miss"] or 0))
    end
end

--------------------------------------------------------------
-- 会心一击率修正
--------------------------------------------------------------
function std_impact_547:get_refix_mind_attack(imp, args)
    local point = (imp.params["soul_mind_attack"] or 0) + (imp.params["mp_mind_attack"] or 0)
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_mind_attack: +%d (融魂出战=%d 附体=%d)",
            math.floor(point), imp.params["soul_mind_attack"] or 0, imp.params["mp_mind_attack"] or 0))
    end
end

--------------------------------------------------------------
-- 会心防御修正（悟性/LUK）
--------------------------------------------------------------
function std_impact_547:get_refix_mind_defend(imp, args)
    local point = (imp.params["soul_mind_defend"] or 0) + (imp.params["mp_mind_defend"] or 0)
    if point ~= 0 then
        args.point = (args.point or 0) + math.floor(point)
        skynet.error(string.format("[IMPACT_547] get_refix_mind_defend: +%d (融魂出战=%d 附体=%d)",
            math.floor(point), imp.params["soul_mind_defend"] or 0, imp.params["mp_mind_defend"] or 0))
    end
end

--------------------------------------------------------------
-- 四系抗性修正
--------------------------------------------------------------
function std_impact_547:get_refix_def_cold(imp, args)
    local v = imp.params["soul_def_cold"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_def_cold: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_def_fire(imp, args)
    local v = imp.params["soul_def_fire"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_def_fire: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_def_light(imp, args)
    local v = imp.params["soul_def_light"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_def_light: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_def_poison(imp, args)
    local v = imp.params["soul_def_poison"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_def_poison: +%d (融魂增幅)", math.floor(v)))
    end
end

--------------------------------------------------------------
-- 增减伤修正（type 21/22）
-- IATTRIBUTE_POINT_REDUCE_DAMAGE / IATTRIBUTE_POINT_ADD_DAMAGE
-- 这两个属性通过 item_value() 直接读取，框架会自动调用 get_refix_reduce_damage/get_refix_add_damage
-- 目前引擎走 item_value 路径，但保留钩子以便扩展
--------------------------------------------------------------
function std_impact_547:get_refix_reduce_damage(imp, args)
    local v = imp.params["soul_reduce_damage"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_reduce_damage: +%d (融魂增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_add_damage(imp, args)
    local v = imp.params["soul_add_damage"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_add_damage: +%d (融魂增幅)", math.floor(v)))
    end
end

--------------------------------------------------------------
-- 消失：清零所有融魂加成参数，刷新主人属性
--------------------------------------------------------------
function std_impact_547:on_fade_out(imp, obj_owner)
    for _, param_key in pairs(SOUL_PARAM_KEY) do
        imp.params[param_key] = 0
    end
    for _, param_key in pairs(MELTING_PARAM_KEY) do
        imp.params[param_key] = 0
    end

    if obj_owner and obj_owner:get_obj_type() == "human" then
        self:mark_modified_attr_dirty(imp, obj_owner)
        obj_owner:send_refresh_attrib()
        skynet.error(string.format("[IMPACT_547] on_fade_out: owner=%s 融魂增幅已解除",
            tostring(obj_owner:get_name())))
    end
end

--------------------------------------------------------------
-- 四系攻击修正（附体效果专属）
--------------------------------------------------------------
function std_impact_547:get_refix_att_cold(imp, args)
    local v = imp.params["mp_cold_attack"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_att_cold: +%d (融魂附体增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_att_fire(imp, args)
    local v = imp.params["mp_fire_attack"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_att_fire: +%d (融魂附体增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_att_light(imp, args)
    local v = imp.params["mp_light_attack"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_att_light: +%d (融魂附体增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_att_poison(imp, args)
    local v = imp.params["mp_poison_attack"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_att_poison: +%d (融魂附体增幅)", math.floor(v)))
    end
end

--------------------------------------------------------------
-- 四系减抗修正（附体效果专属）
--------------------------------------------------------------
function std_impact_547:get_refix_reduce_def_cold(imp, args)
    local v = imp.params["mp_reduce_cold_resist"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_reduce_def_cold: +%d (融魂附体增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_reduce_def_fire(imp, args)
    local v = imp.params["mp_reduce_fire_resist"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_reduce_def_fire: +%d (融魂附体增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_reduce_def_light(imp, args)
    local v = imp.params["mp_reduce_light_resist"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_reduce_def_light: +%d (融魂附体增幅)", math.floor(v)))
    end
end

function std_impact_547:get_refix_reduce_def_poison(imp, args)
    local v = imp.params["mp_reduce_poison_resist"] or 0
    if v ~= 0 then
        args.point = (args.point or 0) + math.floor(v)
        skynet.error(string.format("[IMPACT_547] get_refix_reduce_def_poison: +%d (融魂附体增幅)", math.floor(v)))
    end
end

return std_impact_547
