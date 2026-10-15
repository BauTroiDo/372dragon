-- 蓄云欲雨状态
-- 继承059抗性/血量修正，扩展：被控制技能命中时概率获得对应蓄气
local class = require "class"
local define = require "define"
local skynet = require "skynet"
local impactenginer = require "impactenginer":getinstance()
local configenginer = require "configenginer":getinstance()
local std_impact_059 = require "scene.skill.impact_logic.std_impact_059"
local std_impact_533 = class("std_impact_533", std_impact_059)

-- 控制类型 mutex_id → 对应蓄气参数键名
local CONTROL_MUTEX_MAP = {
    [11]  = "围困蓄气效果ID",
    [13]  = "封穴蓄气效果ID",
    [122] = "封穴蓄气效果ID",
    [15]  = "昏睡蓄气效果ID",
    [17]  = "失明蓄气效果ID",
    [19]  = "定身蓄气效果ID",
    [21]  = "散功蓄气效果ID",
}

-- 981 五级蓄气覆盖优先级（从低到高，封穴>失明>散功>围困>昏睡>定身，索引越大优先级越高）
-- 新蓄气优先级 > 旧蓄气时才能覆盖
local XUQI_PRIORITY = { "定身蓄气效果ID", "昏睡蓄气效果ID", "围困蓄气效果ID", "散功蓄气效果ID", "失明蓄气效果ID", "封穴蓄气效果ID" }

function std_impact_533:get_trigger_rate(imp, obj)
    local base_rate = imp.params["蓄气触发概率"] or 0
    -- 917 山雨欲来：蓄气概率加成
    if obj and obj.get_talent then
        local talent = obj:get_talent()
        if talent and talent.study then
            local sect_desc = configenginer:get_config("sect_desc")
            if sect_desc then
                for _, t in ipairs(talent.study) do
                    if t.id == 917 then
                        local cfg = sect_desc[917]
                        if cfg and cfg.params then
                            local lv = t.level == 0 and 1 or t.level
                            base_rate = base_rate + (cfg.params[lv] and cfg.params[lv][1] or 0)
                        end
                        break
                    end
                end
            end
        end
    end
    if base_rate > 100 then base_rate = 100 end
    return base_rate
end

-- 检查是否学习了 981 五级（蓄气可覆盖）
local function has_981_lv5(obj)
    if not obj.get_talent then return false end
    local talent = obj:get_talent()
    if not talent or not talent.study then return false end
    for _, t in ipairs(talent.study) do
        if t.id == 981 and t.level >= 5 then return true end
    end
    return false
end

-- 被敌对技能命中时，检测技能是否施加控制效果，概率给自己挂蓄气buff
function std_impact_533:on_be_skill(imp, obj, sender, skill_id, behaviortype)
    if behaviortype ~= define.ENUM_BEHAVIOR_TYPE.BEHAVIOR_TYPE_HOSTILITY then return end
    local rate = self:get_trigger_rate(imp, obj)
    if rate <= 0 then return end
    if math.random(100) > rate then return end

    -- 获取技能配置，检查其effect中是否包含控制类impact
    local scene = obj:get_scene()
    local skillenginer = scene:get_skill_enginer()
    local template = skillenginer:get_skill_template(skill_id)
    if not template then return end
    local level_skills = template.level_skills
    if not level_skills then return end
    local skill_info_id = level_skills[1]
    if not skill_info_id then return end
    local info = skillenginer:get_skill_info(skill_info_id)
    if not info or not info.impacts then return end

    -- 收集该技能配置的所有impact data_index
    local impact_ids = {}
    if info.impacts.effect_once then
        for _, v in pairs(info.impacts.effect_once) do
            if type(v) == "number" and v >= 0 then
                impact_ids[#impact_ids + 1] = v
            end
        end
    end
    if info.impacts.attack and info.impacts.attack >= 0 then
        impact_ids[#impact_ids + 1] = info.impacts.attack
    end
    if info.impacts.give_target and info.impacts.give_target.id and info.impacts.give_target.id >= 0 then
        impact_ids[#impact_ids + 1] = info.impacts.give_target.id
    end
    if info.impacts.effect_once and info.impacts.effect_once.target and info.impacts.effect_once.target >= 0 then
        impact_ids[#impact_ids + 1] = info.impacts.effect_once.target
    end

    -- 检查每个impact的mutex_id是否属于控制类型
    for _, data_index in ipairs(impact_ids) do
        local imp_data = impactenginer:get_data_by_data_index(data_index)
        if imp_data and imp_data.mutex_id then
            local param_key = CONTROL_MUTEX_MAP[imp_data.mutex_id]
            if param_key then
                local buff_id = imp.params[param_key]
                if buff_id and buff_id > 0 then
                    -- 981 五级：蓄气可覆盖，按优先级替换已有蓄气
                    if has_981_lv5(obj) then
                        self:try_override_xuqi(imp, obj, param_key, buff_id)
                    else
                        impactenginer:send_impact_to_unit(obj, buff_id, obj, 0, false, 0)
                    end
                    -- 982 奉雪掬霜：蓄气触发时反控（传入 buff_id 用于精确定位蓄气并反控）
                    self:try_982_counter(obj, sender, imp_data.mutex_id, buff_id)
                end
                -- 914 俯仰自得后半段：麻痹/封印命中时额外触发随机蓄气
                if imp_data.mutex_id == 19 or imp_data.mutex_id == 13 or imp_data.mutex_id == 122 then
                    self:try_914_random_xuqi(imp, obj)
                end
                return
            end
        end
    end
end

-- 981 五级蓄气覆盖逻辑
function std_impact_533:try_override_xuqi(imp, obj, new_key, new_buff_id)
    -- 获取新蓄气的优先级
    local new_pri = 0
    for i, k in ipairs(XUQI_PRIORITY) do
        if k == new_key then new_pri = i; break end
    end
    -- 查找已有蓄气状态
    local impacts = obj:get_impact_list()
    local old_imp = nil
    local old_pri = 0
    for i = #impacts, 1, -1 do
        local ei = impacts[i]
        local ei_data = impactenginer:get_data_by_data_index(ei:get_data_index())
        if ei_data and ei_data.mutex_id and CONTROL_MUTEX_MAP[ei_data.mutex_id] then
            -- 找到已有蓄气，看它的优先级
            local pk = CONTROL_MUTEX_MAP[ei_data.mutex_id]
            for j, k in ipairs(XUQI_PRIORITY) do
                if k == pk then
                    if j < new_pri then old_imp = ei; old_pri = j end
                    break
                end
            end
            break
        end
    end
    if old_imp and new_pri > old_pri then
        obj:on_impact_fade_out(old_imp)
        obj:remove_impact(old_imp)
    end
    impactenginer:send_impact_to_unit(obj, new_buff_id, obj, 0, false, 0)
end

-- 982 奉雪掬霜：蓄气触发时反控来源 + 清蓄气
-- buff_id: 刚发给 obj 的蓄气 buff 的 data_index，用于精确定位并清除
-- control_mutex: 控制类型的 mutex_id（已确认属于控制类）
function std_impact_533:try_982_counter(obj, sender, control_mutex, buff_id)
    if not obj.get_talent then return end
    local talent = obj:get_talent()
    if not talent or not talent.study then return end
    local sect_desc = configenginer:get_config("sect_desc")
    if not sect_desc then return end
    for _, t in ipairs(talent.study) do
        if t.id == 982 then
            local cfg = sect_desc[982]
            if not cfg or not cfg.params then return end
            local lv = t.level == 0 and 1 or t.level
            local chance = cfg.params[lv] and cfg.params[lv][1] or 0
            -- 30 秒内置 CD（与 std_talent_982 共享同一字段）
            local last = obj._982_last_trigger or 0
            local now = os.time()
            if now - last < 30 then
                skynet.error("[TALENT_982] CD未到，跳过反控 obj=", tostring(obj))
                return
            end
            if math.random(100) > chance then
                skynet.error("[TALENT_982] 概率未触发 chance=", chance)
                return
            end
            obj._982_last_trigger = now
            skynet.error("[TALENT_982] 触发反控 control_mutex=", control_mutex, " buff_id=", buff_id)
            -- 反控：将同类控制效果（蓄气 buff 本身的 data_index）投递给攻击来源
            if sender and sender:is_alive() then
                -- 用刚发出的 buff_id（蓄气的 data_index）直接反给来源，实现「彼行我释」反控效果
                impactenginer:send_impact_to_unit(sender, buff_id, obj, 0, false, 0)
                skynet.error("[TALENT_982] 已将控制效果反给来源 sender=", tostring(sender))
                -- 清除自身对应蓄气状态（精确匹配 buff_id）
                local impacts = obj:get_impact_list()
                for i = #impacts, 1, -1 do
                    local ei = impacts[i]
                    if ei:get_data_index() == buff_id then
                        obj:on_impact_fade_out(ei)
                        obj:remove_impact(ei)
                        skynet.error("[TALENT_982] 已清除自身蓄气 buff_id=", buff_id)
                        break
                    end
                end
            else
                skynet.error("[TALENT_982] 来源无效或已死亡，不执行反控")
            end
            return
        end
    end
end

-- 914 俯仰自得后半段：麻痹/封印命中时给自己一个随机蓄气
local XUQI_KEYS = { "围困蓄气效果ID", "封穴蓄气效果ID", "昏睡蓄气效果ID", "失明蓄气效果ID", "定身蓄气效果ID", "散功蓄气效果ID" }
function std_impact_533:try_914_random_xuqi(imp, obj)
    if not obj.get_talent then return end
    local talent = obj:get_talent()
    if not talent or not talent.study then return end
    for _, t in ipairs(talent.study) do
        if t.id == 914 then
            -- 从可用蓄气中随机选一个
            local candidates = {}
            for _, key in ipairs(XUQI_KEYS) do
                local bid = imp.params[key]
                if bid and bid > 0 then
                    candidates[#candidates+1] = bid
                end
            end
            if #candidates > 0 then
                local pick = candidates[math.random(#candidates)]
                impactenginer:send_impact_to_unit(obj, pick, obj, 0, false, 0)
            end
            return
        end
    end
end

return std_impact_533
