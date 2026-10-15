local class = require "class"
local define = require "define"
local base = require "scene.skill.base"
local impact = require "scene.skill.impact"
local skynet = require "skynet"
local configenginer = require "configenginer":getinstance()
local skill_734 = class("skill_734", base)

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

-- 获取珍兽自身buff Impact ID (索引1: 49947)
function skill_734:get_self_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[1] or define.INVAILD_ID
end

-- 获取主人属性增幅buff Impact ID (索引2: 49950)
function skill_734:get_owner_impact(skill_info)
    local impacts = skill_info:get_activate_once_impacts()
    return impacts[2] or define.INVAILD_ID
end

-- 怒意灼心 (SkillData ID 31875, logic_id 734)
-- Impact 49947 施加给珍兽自身，Impact 49950 施加给珍兽主人
function skill_734:effect_on_unit_once(obj_me, obj_tar, is_critical)
    local skill_info = obj_me:get_skill_info()
    local params = obj_me:get_targeting_and_depleting_params()
    local scene = obj_me:get_scene()
    local impactenginer = scene:get_impact_enginer()

    -- ======== 前置条件检查 ========
    local owner = obj_me:get_owner()

    -- 检查冷却时间
    local cd_id = skill_info:get_cool_down_id()
    if cd_id and not obj_me:is_cool_downed(cd_id) then
        if owner then owner:notify_tips("#{ZSCZ_241217_14}") end
        return
    end

    -- 检查怒意值 >= 400
    local rage = obj_me:get_rage() or 0
    if rage < 400 then
        if owner then owner:notify_tips("#{ZSCZ_241217_02}") end
        return
    end

    -- 获取珍兽 detail，后续多个检查共用
    local detail = obj_me:get_detail()

    -- 检查珍兽寿命 > 5000
    local life = detail and detail:get_life() or 0
    if life <= 5000 then
        if owner then owner:notify_tips("#{ZSCZ_241217_05}") end
        return
    end

    -- 检查觉醒等级 >= 5
    local kw_level = detail and detail:get_kw_level() or 0
    if kw_level < 5 then
        if owner then owner:notify_tips("#{ZSCZ_241217_21}") end
        return
    end

    -- 检查前4个兽灵槽是否全部已缔约
    local elf_slots = detail:get_elf_slots()
    for i = 1, 4 do
        local slot = elf_slots and elf_slots[i]
        if not slot or slot.activated ~= 1 then
            if owner then owner:notify_tips("#{ZSCZ_241217_16}") end
            return
        end
    end
    -- ======== 前置条件检查结束 ========

    -- 施加 Impact 49947 给珍兽自身
    local self_impact_id = self:get_self_impact(skill_info)
    if self_impact_id ~= define.INVAILD_ID then
        print("skill_734:effect_on_unit_once self impact obj_id =", obj_me:get_obj_id(), ";logic_id =", self_impact_id)
        local imp = impact.new()
        imp:clean_up()
        impactenginer:init_impact_from_data(self_impact_id, imp)
        self:register_impact_event(obj_me, obj_me, imp, params:get_delay_time(), is_critical)
    end

    -- 施加 Impact 49950 给珍兽主人（owner 已在前置检查中获取）
    local owner_impact_id = self:get_owner_impact(skill_info)
    if owner_impact_id ~= define.INVAILD_ID then
        if owner then
            print("skill_734:effect_on_unit_once owner impact obj_id =", obj_me:get_obj_id(), ";logic_id =", owner_impact_id)
            local imp = impact.new()
            imp:clean_up()
            impactenginer:init_impact_from_data(owner_impact_id, imp)
            self:register_impact_event(owner, obj_me, imp, params:get_delay_time(), is_critical)
        end
    end

    -- 从前四个兽灵中随机一个技能的怒意三阶效果释放给主人
    self:release_elf_fury_stage3(obj_me, params, impactenginer, is_critical)
end

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

-- 从前4个兽灵槽中随机一个已激活且有技能的槽位，
-- 查找其怒意三阶 Impact ID 并施加给珍兽主人
function skill_734:release_elf_fury_stage3(obj_me, params, impactenginer, is_critical)
    local owner = obj_me:get_owner()
    if not owner then return end

    local detail = obj_me:get_detail()
    if not detail then return end

    local elf_slots = detail:get_elf_slots()
    if not elf_slots then return end

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
        skynet.error(string.format("[skill_734] release_elf_fury_stage3: pet=%s 无可用兽灵槽",
            tostring(obj_me:get_name())))
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
        "[skill_734] release_elf_fury_stage3: pet=%s slot[%d] skill_id=%d level=%d skill_name=%s",
        tostring(obj_me:get_name()), chosen.index, skill_id, level, skill_name))

    -- 等级分层检查
    if level < 5 then
        -- 兽灵等级不足5级，效果不生效
        owner:notify_tips(string.format("随机到的%s技能兽灵等级不足5级，效果不生效！", skill_name))
        skynet.error(string.format(
            "[skill_734] release_elf_fury_stage3: 兽灵技能 %s(等级%d) 不足5级，效果不生效",
            skill_name, level))
        return
    end

    local impact_id = get_fury3_impact_id(skill_id, level)

    if impact_id == define.INVAILD_ID then
        -- 珍兽没有对应技能（配表无三阶效果）
        owner:notify_tips(string.format("随机到的%s技能珍兽没有对应技能，效果不生效！", skill_name))
        skynet.error(string.format(
            "[skill_734] release_elf_fury_stage3: 兽灵技能 %s(等级%d) 无怒意三阶效果配置",
            skill_name, level))
        return
    end

    if level >= 10 then
        -- 高阶效果生效
        owner:notify_tips(string.format("随机到的%s技能兽灵等级为10级，该技能高阶效果生效！", skill_name))
        skynet.error(string.format(
            "[skill_734] release_elf_fury_stage3: 兽灵技能 %s 等级%d >=10，高阶效果生效 impact_id=%d",
            skill_name, level, impact_id))
    else
        -- level 5~9，初阶效果生效
        owner:notify_tips(string.format("随机到的%s技能兽灵等级为5至9级，该技能初阶效果生效！", skill_name))
        skynet.error(string.format(
            "[skill_734] release_elf_fury_stage3: 兽灵技能 %s 等级%d 5~9，初阶效果生效 impact_id=%d",
            skill_name, level, impact_id))
    end

    local imp = impact.new()
    imp:clean_up()
    impactenginer:init_impact_from_data(impact_id, imp)
    self:register_impact_event(owner, obj_me, imp, params:get_delay_time(), is_critical)
end

return skill_734
