-- 归一剑：破天式结束后创建飞剑陷阱 SpecialObj（持续监听型）
-- 在破天式（skill_id=834）释放时由天赋投递到施法者身上
-- 持续监听施法者身上的破天式飞剑状态（logic_id=96），实时缓存飞剑数量
-- 当检测到破天式状态消失后，以最后记录的飞剑数量创建 SpecialObj ID=2022（飞剑陷阱）
-- 陷阱持续 3 秒后在目标位置爆炸，伤害 = 飞剑数 × 伤害百分比% 内功攻击
-- 伤害由 trap.lua 的 effect_on_char 通过 _potianshi_rate 和 _custom_descriptor 投递
local skynet        = require "skynet"
local class         = require "class"
local define        = require "define"
local base          = require "scene.skill.impact_logic.base"

local std_impact_543 = class("std_impact_543", base)

-- 破天式飞剑状态的 logic_id
local POTIANSHI_LOGIC_ID  = 96

-- 归一剑飞剑陷阱的 SpecialObjData ID
local GUIYIJIAN_TRAP_DATA_ID = 2022

-- 每个技能等级对应的爆炸伤害 impact data_index（StandardImpact.txt，logic_id=3）
local DAMAGE_IMPACT_IDS = {63010, 63009, 63008, 63007, 63006} -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

-- 每个技能等级对应的减速 impact data_index（StandardImpact.txt，logic_id=14，移动速度-30%，持续3秒）
local SLOW_IMPACT_IDS = {63015, 63014, 63013, 63012, 63011} -- server-impact: ID impact GL → dải riêng (xem lualib/cys_gl_impact_remap.lua)

-- 持续型状态：在角色身上挂住，直到主动移除
function std_impact_543:is_over_timed()
    return true
end

-- 周期触发：每 WATCH_INTERVAL ms 检查一次
function std_impact_543:is_intervaled()
    return true
end

-- 状态挂载时初始化：设置动态持续时间和检查间隔，初始化飞剑计数缓存
-- （StandardImpact.txt 已配置 is_over_timed=1, continuance=20000, interval=500）
function std_impact_543:on_active(imp, obj)
    imp._last_sword_count = 0
    imp._potianshi_found  = true   -- 刚投递时破天式应该还在

    skynet.error("[IMPACT_543] on_active: obj=", obj:get_obj_id(),
        " continuance=", imp:get_continuance(),
        " interval=", imp:get_interval(),
        " is_over_timed=", imp:get_is_over_timed())
end

-- 辅助：在 sender 的 impact_list 中查找破天式状态（logic_id=96）
local function find_potianshi_impact(sender)
    local list = sender:get_impact_list()
    for i = 1, #list do
        local imp = list[i]
        if imp:get_logic_id() == POTIANSHI_LOGIC_ID then
            return imp
        end
    end
    return nil
end

-- 辅助：获取施法者当前选择的敌对目标位置（追击目标）
-- 优先使用当前选择的敌对目标位置作为陷阱创建中心，无有效目标时回退到施法者自身位置
local function get_explosion_center(sender)
    if sender.get_cur_target_id then
        local target_id = sender:get_cur_target_id()
        if target_id and target_id > 0 then
            local scene = sender:get_scene()
            if scene then
                local target = scene:get_obj_by_id(target_id)
                if target and target:is_alive() and target:is_character_obj() and sender:is_enemy(target) then
                    local pos = target:get_world_pos()
                    skynet.error("[IMPACT_543] trap center: target obj_id=", target_id,
                        " pos=(", pos.x, ",", pos.y, ")")
                    return pos, target_id
                end
            end
        end
    end
    local pos = sender:get_world_pos()
    skynet.error("[IMPACT_543] trap center: fallback to sender pos=(", pos.x, ",", pos.y, ")")
    return pos, nil
end

-- 辅助：创建归一剑飞剑陷阱 SpecialObj
-- 陷阱由 trap.lua 驱动，3秒后 on_time_over → activate → effect_on_char 投递伤害
local function create_guiyijian_trap(imp, sender, sword_count, damage_rate)
    if sword_count <= 0 then
        skynet.error("[IMPACT_543] create_guiyijian_trap: sword_count=0, skip")
        return
    end

    local total_rate = sword_count * damage_rate

    -- 按技能等级选取对应的伤害/减速 impact ID
    local level = imp:get_skill_level() or 1
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end
    local damage_impact_id = DAMAGE_IMPACT_IDS[level]
    local slow_impact_id   = SLOW_IMPACT_IDS[level]

    -- 获取陷阱创建位置：优先追击当前选择的敌对目标
    local center_pos, target_id = get_explosion_center(sender)
    local skill_id = imp:get_skill_id()

    skynet.error("[IMPACT_543] create_guiyijian_trap: sword_count=", sword_count,
        " damage_rate=", damage_rate, " total_rate=", total_rate,
        " level=", level, " damage_impact_id=", damage_impact_id,
        " slow_impact_id=", slow_impact_id,
        " center_target=", target_id or "self")

    -- 创建 SpecialObj（飞剑陷阱）
    local trap_obj = sender:skill_create_obj_specail(center_pos, GUIYIJIAN_TRAP_DATA_ID, skill_id)
    if not trap_obj then
        skynet.error("[IMPACT_543] create_guiyijian_trap FAILED: skill_create_obj_specail returned nil")
        return
    end

    -- 设置飞剑数量和总伤害倍率（trap.lua effect_on_char 读取 _potianshi_rate 作为 extra_ng_rate）
    trap_obj._sword_count = sword_count
    trap_obj._potianshi_rate = total_rate

    -- 设置 per-instance 描述符覆盖（trap.lua get_impact 优先读取 _custom_descriptor）
    -- 这样每个陷阱实例可以携带不同等级的 impact ID，不依赖共享配置
    trap_obj._custom_descriptor = {
        ["效果1"] = damage_impact_id,
        ["效果2"] = slow_impact_id,
    }

    skynet.error("[IMPACT_543] trap created OK: obj_id=", trap_obj:get_obj_id(),
        " sword_count=", sword_count, " total_rate=", total_rate,
        " 效果1=", damage_impact_id, " 效果2=", slow_impact_id)
end

-- 每隔 interval ms 触发一次：
--   1. 如果破天式还在，更新飞剑数量缓存
--   2. 如果破天式已消失，创建飞剑陷阱并移除自身
function std_impact_543:on_interval_over(imp, obj)
    if not obj or not obj:is_alive() then
        skynet.error("[IMPACT_543] on_interval_over: obj dead or nil, skip")
        -- obj 已死亡，impact 引擎会自动处理 heart_beat 中的 remove
        return
    end

    local caster_obj_id = imp:get_caster_obj_id()
    local sender = obj:get_scene():get_obj_by_id(caster_obj_id)
    if not sender then
        skynet.error("[IMPACT_543] on_interval_over: sender not found id=", caster_obj_id)
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
        return
    end

    local poti_imp = find_potianshi_impact(sender)
    if poti_imp then
        -- 破天式还在，更新飞剑数量缓存
        local cnt = poti_imp._sword_count or 0
        if cnt > 0 then
            imp._last_sword_count = cnt
        end
        imp._potianshi_found = true
        -- skynet.error("[IMPACT_543] on_interval_over: still alive, sword_count=", cnt)
    else
        -- 破天式已消失，且之前曾找到过（排除破天式还没投递的情况）
        if imp._potianshi_found then
            skynet.error("[IMPACT_543] on_interval_over: potianshi ended, sword_count=",
                imp._last_sword_count)
            -- 读取配置参数
            local damage_rate = imp.params["伤害百分比"] or 12

            -- 创建飞剑陷阱（替代原来的直接 AoE 伤害）
            -- 陷阱会在 3 秒后由 trap.lua 自动触发 activate → effect_on_char
            -- 通过 _potianshi_rate 传递 sword_count × damage_rate 作为 extra_ng_rate
            -- 通过 _custom_descriptor 传递等级对应的伤害/减速 impact ID
            create_guiyijian_trap(imp, sender, imp._last_sword_count, damage_rate)
            -- 标记已触发，避免 on_fade_out 重复触发
            imp._exploded = true
        end
        -- 移除自身
        obj:on_impact_fade_out(imp)
        obj:remove_impact(imp)
    end
end

-- 超时自然消亡时（20秒到期）：说明破天式持续时间内没有正常结束（异常情况），不创建陷阱
function std_impact_543:on_fade_out(imp, obj)
    if not imp._exploded then
        skynet.error("[IMPACT_543] on_fade_out: timed out without explosion (potianshi may still be active)")
    end
end

return std_impact_543
