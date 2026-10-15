local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skynet = require "skynet"
local configenginer = require "configenginer":getinstance()

local skill_5100 = class("skill_5100", base)

-- 兽灵技能怒意三阶 Impact ID 映射表
-- key   = PetElfSkill ID (1-66)
-- value = {[1]=lv1_impact, [2]=lv2_impact, [3]=lv3_impact, [4]=lv4_impact}
-- Impact ID 来源：PetElfSkill.txt 中 ints[35..38]
-- -1 表示该等级无三阶效果
-- 初版仅预埋框架，运行时优先从配表动态读取，映射表作为回退
local ELF_FURY3_OVERRIDE = {
    -- 预留：如需手动覆盖特定技能的三阶效果，在此填写
    -- 示例：[20] = {50633, 50634, 50635, 50636},
}

-- 获取兽灵技能在当前等级对应的怒意三阶 Impact ID
-- 优先查 ELF_FURY3_OVERRIDE 手动覆盖表，否则从配表 ints[35..38] 动态读取
-- slot_level: 兽灵槽等级 (1-4+), skill_id: PetElfSkill ID
local function get_fury3_impact_id(skill_id, slot_level)
    -- 手动覆盖表优先
    local override = ELF_FURY3_OVERRIDE[skill_id]
    if override then
        local idx = math.min(slot_level, 4)
        local imp_id = override[idx]
        if imp_id and imp_id > 0 then
            return imp_id
        end
        return define.INVAILD_ID
    end

    -- 从配表动态读取 ints[35..38]
    local elf_skill_cfg = configenginer:get_config("pet_elf_skill")
    if not elf_skill_cfg then return define.INVAILD_ID end

    local cfg = elf_skill_cfg[skill_id]
    if not cfg or not cfg.ints then return define.INVAILD_ID end

    local ints = cfg.ints
    -- ints[35..38] 为怒意三阶 Impact ID（对应等级1/2/3/4）
    local idx = math.min(slot_level, 4)
    local col = 34 + idx   -- slot_level=1 → ints[35], 4 → ints[38]
    local imp_id = ints[col]
    if imp_id and imp_id > 0 then
        return imp_id
    end
    return define.INVAILD_ID
end

-- 获取珍兽自身buff Impact ID（索引1: 49947）
function skill_5100:get_pet_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[1] or define.INVAILD_ID
end

-- 获取玩家属性增幅buff Impact ID（索引2: 49950）
function skill_5100:get_owner_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[2] or define.INVAILD_ID
end

-- 前置条件检查（在冷却/动画之前拦截）
function skill_5100:specific_condition_check(obj_me)
    -- 检查出战珍兽是否存在
    local pet = obj_me:get_current_pet()
    skynet.error(string.format("[skill_5100:check] pet=%s", tostring(pet)))
    if not pet then
        obj_me:notify_tips("#{ZSCZ_241217_01}")
        skynet.error("[skill_5100:check] 无出战珍兽，拦截技能")
        return false
    end

    -- 获取珍兽 detail
    local pet_guid = obj_me:get_current_pet_guid()
    local detail = nil
    if pet_guid and not pet_guid:is_null() then
        local container = obj_me:get_pet_bag_container()
        if container then
            detail = container:get_pet_by_guid(pet_guid)
        end
    end
    skynet.error(string.format("[skill_5100:check] pet_guid=%s detail=%s", tostring(pet_guid), tostring(detail)))

    -- 检查觉醒等级 >= 5
    local kw_level_raw = detail and detail:get_kw_level()
    local kw_level = kw_level_raw or 0
    skynet.error(string.format("[skill_5100:check] kw_level_raw=%s (type=%s) kw_level=%s",
        tostring(kw_level_raw), type(kw_level_raw), tostring(kw_level)))
    if kw_level < 5 then
        obj_me:notify_tips("#{ZSCZ_241217_21}")
        skynet.error(string.format("[skill_5100:check] 觉醒等级不足，kw_level=%s < 5，拦截技能", tostring(kw_level)))
        return false
    end

    -- 检查前4个兽灵槽是否全部已缔约
    local elf_slots = detail:get_elf_slots()
    skynet.error(string.format("[skill_5100:check] elf_slots=%s", tostring(elf_slots)))
    for i = 1, 4 do
        local slot = elf_slots and elf_slots[i]
        skynet.error(string.format("[skill_5100:check] elf_slot[%d] slot=%s activated=%s",
            i, tostring(slot), tostring(slot and slot.activated)))
        if not slot or slot.activated ~= 1 then
            obj_me:notify_tips("#{ZSCZ_241217_16}")
            skynet.error(string.format("[skill_5100:check] 兽灵槽[%d]未缔约，拦截技能", i))
            return false
        end
    end

    -- 检查怒意值 >= 400
    local rage = pet:get_rage() or 0
    skynet.error(string.format("[skill_5100:check] rage=%s", tostring(rage)))
    if rage < 400 then  -- [audit 2026-09-03] khoi phuc dieu kien 400 (dong test bo quen)
        obj_me:notify_tips("#{ZSCZ_241217_02}")
        skynet.error(string.format("[skill_5100:check] 怒意不足，rage=%s < 400，拦截技能", tostring(rage)))
        return false
    end

    -- 检查珍兽寿命 > 5000
    local life = detail and detail:get_life() or 0
    skynet.error(string.format("[skill_5100:check] life=%s", tostring(life)))
    if life <= 5000 then
        obj_me:notify_tips("#{ZSCZ_241217_05}")
        skynet.error(string.format("[skill_5100:check] 珍兽寿命不足，life=%s <= 5000，拦截技能", tostring(life)))
        return false
    end

    skynet.error("[skill_5100:check] 所有前置条件通过")
    return true
end

-- 怒意灼心（人物技能版，skill_id=5100）
-- obj_me = 玩家，对出战珍兽施加49947，对自己施加49950
-- 注意：此处所有前置条件已由 specific_condition_check 保证通过
function skill_5100:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()

    -- 重新获取出战珍兽和 detail（函数间不共享局部变量）
    local pet = obj_me:get_current_pet()
    local pet_guid = obj_me:get_current_pet_guid()
    local detail = nil
    if pet_guid and not pet_guid:is_null() then
        local container = obj_me:get_pet_bag_container()
        if container then
            detail = container:get_pet_by_guid(pet_guid)
        end
    end

    skynet.error("[skill_5100] 所有检查通过，开始施加Impact")
    local delay_time = params:get_delay_time()

    -- 施加 Impact 49947 给出战珍兽（珍兽自损增强）
    local pet_impact_id = self:get_pet_impact(skill_info)
    if pet_impact_id ~= define.INVAILD_ID then
        skynet.error(string.format("[skill_5100] 施加珍兽buff impact_id=%d -> pet=%s",
            pet_impact_id, tostring(pet:get_name())))
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(pet_impact_id, imp)
        self:register_impact_event(pet, obj_me, imp, delay_time, is_critical)
    end

    -- 怒意灼心释放后10秒内怒意不衰减
    if pet then
        pet._rage_nyzx_immune_ms = 10000
        skynet.error("[skill_5100] 设置怒意灼心免衰减 10s")
    end

    -- 施加 Impact 49950 给玩家自身（属性增幅，以珍兽为caster）
    -- 注意：register_impact_event 内部会用 sender:get_skill_info()，
    -- 而珍兽此时无主动施放技能上下文，故手动走底层调用路径：
    -- sender=obj_me（玩家，有 skill_info），再通过 eventenginer 覆盖 caster_obj_id 前
    -- 用珍兽替代 sender，确保 caster_obj_id 指向珍兽
    local owner_impact_id = self:get_owner_impact(skill_info)
    if owner_impact_id ~= define.INVAILD_ID then
        skynet.error(string.format("[skill_5100] 施加玩家buff impact_id=%d -> owner=%s",
            owner_impact_id, tostring(obj_me:get_name())))
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(owner_impact_id, imp)
        imp:set_skill_id(skill_info:get_skill_id())
        imp:set_skill_level(skill_info:get_skill_level())
        if is_critical then
            imp:mark_critical_hit_flag()
        end
        local eventenginer = scene:get_event_enginer()
        -- 传入 pet 作为 sender，让 eventenginer 把珍兽 obj_id 设为 caster_obj_id
        -- std_impact_547.on_active 通过 imp:get_caster_obj_id() 查找施法珍兽
        eventenginer:register_impact_event(obj_me, pet, imp, delay_time, imp:get_skill_id())
    end

    -- 从前四个兽灵中随机一个技能的怒意三阶效果释放给主人
    self:release_elf_fury_stage3(pet, detail, obj_me, scene, params, is_critical)
end

-- 从前4个兽灵槽中随机一个已激活且有技能的槽位，
-- 查找其怒意三阶 Impact ID 并施加给珍兽主人
-- pet: 出战珍兽, detail: 珍兽detail, owner: 玩家
function skill_5100:release_elf_fury_stage3(pet, detail, owner, scene, params, is_critical)
    if not owner then return end
    if not detail then return end

    local elf_slots = detail:get_elf_slots()
    if not elf_slots then return end

    local impactenginer = scene:get_impact_enginer()

    -- 收集前4个已激活且有技能的兽灵槽
    local candidates = {}
    for i = 1, 4 do
        local slot = elf_slots[i]
        if slot and slot.activated == 1 and slot.skill and slot.skill > 0 then
            table.insert(candidates, {
                index    = i,
                skill_id = slot.skill,
                level    = slot.level or 1,
            })
        end
    end

    if #candidates == 0 then
        skynet.error(string.format("[skill_5100] release_elf_fury_stage3: pet=%s 无可用兽灵槽",
            tostring(pet and pet:get_name() or "nil")))
        return
    end

    -- 随机选一个候选槽
    local chosen = candidates[math.random(#candidates)]
    local skill_id = chosen.skill_id
    local level    = chosen.level

    -- 从 pet_elf_skill 配表获取技能名称
    local elf_skill_cfg = configenginer:get_config("pet_elf_skill")
    local skill_name = "未知技能"
    if elf_skill_cfg and elf_skill_cfg[skill_id] then
        local sname = elf_skill_cfg[skill_id].name
        if sname and sname ~= "" then
            skill_name = sname
        end
    end

    skynet.error(string.format(
        "[skill_5100] release_elf_fury_stage3: pet=%s slot[%d] skill_id=%d level=%d skill_name=%s",
        tostring(pet and pet:get_name() or "nil"), chosen.index, skill_id, level, skill_name))

    -- 等级分层检查
    if level < 5 then
        -- 兽灵等级不足5级，效果不生效
        owner:notify_tips(string.format("随机到的%s技能兽灵等级不足5级，效果不生效！", skill_name))
        skynet.error(string.format(
            "[skill_5100] release_elf_fury_stage3: 兽灵技能 %s(等级%d) 不足5级，效果不生效",
            skill_name, level))
        return
    end

    local impact_id = get_fury3_impact_id(skill_id, level)

    if impact_id == define.INVAILD_ID then
        -- 没有对应技能（配表无三阶效果）
        owner:notify_tips(string.format("随机到的%s技能珍兽没有对应技能，效果不生效！", skill_name))
        skynet.error(string.format(
            "[skill_5100] release_elf_fury_stage3: 兽灵技能 %s(等级%d) 无怒意三阶效果配置",
            skill_name, level))
        return
    end

    if level >= 10 then
        -- 高阶效果生效
        owner:notify_tips(string.format("随机到的%s技能兽灵等级为10级，该技能高阶效果生效！", skill_name))
        skynet.error(string.format(
            "[skill_5100] release_elf_fury_stage3: 兽灵技能 %s 等级%d >=10，高阶效果生效 impact_id=%d",
            skill_name, level, impact_id))
    else
        -- level 5~9，初阶效果生效
        owner:notify_tips(string.format("随机到的%s技能兽灵等级为5至9级，该技能初阶效果生效！", skill_name))
        skynet.error(string.format(
            "[skill_5100] release_elf_fury_stage3: 兽灵技能 %s 等级%d 5~9，初阶效果生效 impact_id=%d",
            skill_name, level, impact_id))
    end

    local imp = impact.new()
    imp:clean_up()
    impactenginer:init_impact_from_data(impact_id, imp)
    -- 珍兽（pet）无主动施放技能上下文，register_impact_event 内部会调用 sender:get_skill_info()
    -- 会导致 nil 崩溃，故直接走底层 eventenginer 调用路径（与施加 Impact 49950 的处理方式一致）
    local owner_skill_info = owner:get_skill_info()
    if owner_skill_info then
        imp:set_skill_id(owner_skill_info:get_skill_id())
        imp:set_skill_level(owner_skill_info:get_skill_level())
    end
    if is_critical then
        imp:mark_critical_hit_flag()
    end
    local eventenginer = scene:get_event_enginer()
    eventenginer:register_impact_event(owner, pet, imp, params:get_delay_time(), imp:get_skill_id())
end

return skill_5100
