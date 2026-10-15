-- exterior_bonus.lua
-- 外观属性加成模块：华商阁收藏中存在时装/坐骑/武器外观即自动获得属性加成，无需穿戴
-- 支持槽位（仅3个）：时装（扫描华商阁收藏格子）、坐骑（扫描坐骑收藏列表）、武器外观（扫描已激活列表）
-- 依赖: configenginer (get_exterior_bonus), human (装备容器/db属性读取)

local configenginer = require "configenginer":getinstance()
local impactenginer = require "impactenginer":getinstance()
local define = require "define"

local skynet = require "skynet"
local M = {}
local _debug_logged = false
local _local_cfg_cache = nil

-- 直接读取配置表(绕过sharetable，避免序列化丢数据)
local function load_local_cfg()
    if _local_cfg_cache then return _local_cfg_cache end
    local ok, reader = pcall(require, "txtreader")
    if not ok then
        return nil
    end
    local read = reader.new()
    local configs = read:load("ExteriorBonus.txt")
    local result = {}
    for _, conf in pairs(configs) do
        local id = conf["Index"]
        local slot_type = conf["类型"]
        if id and slot_type then
            if not result[slot_type] then result[slot_type] = {} end
            result[slot_type][id] = conf
        end
    end
    local count = 0
    for _, sub in pairs(result) do
        for _ in pairs(sub) do count = count + 1 end
    end
    _local_cfg_cache = result
    return result
end

-- 中文属性名 → 内部属性key + 加成类型(point/rate)的映射表
-- 基于 human_attrib.lua 中 item_effct_shift 的结构
local ATTR_MAP = {
    ["增加HP的上限"]                 = { key = "hp_max",              field = "point" },
    ["百分比增加HP的上限"]           = { key = "hp_max",              field = "rate"  },
    ["增加MP的上限"]                 = { key = "mp_max",              field = "point" },
    ["百分比增加MP的上限"]           = { key = "mp_max",              field = "rate"  },
    ["外功攻击"]                     = { key = "attrib_att_physics",  field = "point" },
    ["按百分比增加外功攻击"]         = { key = "attrib_att_physics",  field = "rate"  },
    ["外功防御"]                     = { key = "attrib_def_physics",  field = "point" },
    ["按百分比增加外功防御"]         = { key = "attrib_def_physics",  field = "rate"  },
    ["内功攻击"]                     = { key = "attrib_att_magic",    field = "point" },
    ["按百分比增加内功攻击"]         = { key = "attrib_att_magic",    field = "rate"  },
    ["内功防御"]                     = { key = "attrib_def_magic",    field = "point" },
    ["按百分比增加内功防御"]         = { key = "attrib_def_magic",    field = "rate"  },
    ["命中"]                         = { key = "attrib_hit",          field = "point" },
    ["闪避"]                         = { key = "attrib_miss",         field = "point" },
    ["会心"]                         = { key = "mind_attack",         field = "point" },
    ["会心防御"]                     = { key = "mind_defend",         field = "point" },
    ["力量"]                         = { key = "str",                 field = "point" },
    ["灵气"]                         = { key = "spr",                 field = "point" },
    ["体力"]                         = { key = "con",                 field = "point" },
    ["定力"]                         = { key = "int",                 field = "point" },
    ["身法"]                         = { key = "dex",                 field = "point" },
    ["冰攻击"]                       = { key = "att_cold",            field = "point" },
    ["冰抵抗"]                       = { key = "def_cold",            field = "point" },
    ["火攻击"]                       = { key = "att_fire",            field = "point" },
    ["火抵抗"]                       = { key = "def_fire",            field = "point" },
    ["玄攻击"]                       = { key = "att_light",           field = "point" },
    ["玄抵抗"]                       = { key = "def_light",           field = "point" },
    ["毒攻击"]                       = { key = "att_poison",          field = "point" },
    ["毒抵抗"]                       = { key = "def_poison",          field = "point" },
    ["降低目标冰抵抗"]               = { key = "reduce_def_cold",     field = "point" },
    ["降低目标火抵抗"]               = { key = "reduce_def_fire",     field = "point" },
    ["降低目标玄抵抗"]               = { key = "reduce_def_light",    field = "point" },
    ["降低目标毒抵抗"]               = { key = "reduce_def_poison",   field = "point" },
    ["移动速度百分比"]               = { key = "speed",               field = "rate"  },
}

-- 仅3个槽位：时装(华商阁收藏)、坐骑(收藏列表)、武器外观(已激活列表)
-- 每个getter返回ID列表，支持累加多个收藏项的属性加成
local SLOT_GETTERS = {
    -- 时装：扫描华商阁收藏格子 + 当前穿戴的时装，两处都生效
    function(human)
        local ids = {}
        local seen = {}
        -- 1. 扫描华商阁收藏格子
        local container = human:get_fasion_bag_container()
        if container then
            local size = tonumber(container:get_size()) or 0
            for i = 0, size - 1 do
                local item = container:get_item(i)
                if item then
                    local idx = item:get_index()
                    if idx and idx ~= 0 and not seen[idx] then
                        seen[idx] = true
                        ids[#ids + 1] = idx
                    end
                end
            end
        end
        -- 2. 检查当前穿戴在身上的时装（穿戴后物品从收藏移到装备栏）
        local equip_container = human:get_equip_container()
        if equip_container then
            local fashion = equip_container:get_item(define.HUMAN_EQUIP.HEQUIP_FASHION)
            if fashion then
                local idx = fashion:get_index()
                if idx and idx ~= 0 and not seen[idx] then
                    seen[idx] = true
                    ids[#ids + 1] = idx
                end
            end
        end
        return ids
    end,
    -- 坐骑：扫描所有已收藏坐骑，永久或未过期的均生效
    function(human)
        local ids = {}
        local rides = human.exterior and human.exterior.rides
        if rides then
            local now = os.time()
            for _, ride in ipairs(rides) do
                if ride.id and ride.id ~= 0 and (ride.term == -1 or ride.term > now) then
                    ids[#ids + 1] = ride.id
                end
            end
        end
        return ids
    end,
    -- 武器外观：扫描所有已激活的武器外观，只要激活过就生效
    function(human)
        local ids = {}
        local visuals = human.exterior and human.exterior.weapon_visuals
        if visuals then
            for _, v in ipairs(visuals) do
                if v.id and v.id ~= 0 then
                    ids[#ids + 1] = v.id
                end
            end
        end
        return ids
    end,
}

-- 所有外观加成可能影响的属性key（从ATTR_MAP去重提取）
local BONUS_DIRTY_KEYS = {
    "hp_max", "mp_max",
    "attrib_att_physics", "attrib_def_physics",
    "attrib_att_magic", "attrib_def_magic",
    "attrib_hit", "attrib_miss",
    "mind_attack", "mind_defend",
    "str", "spr", "con", "int", "dex",
    "att_cold", "def_cold", "att_fire", "def_fire",
    "att_light", "def_light", "att_poison", "def_poison",
    "reduce_def_cold", "reduce_def_fire", "reduce_def_light", "reduce_def_poison",
    "speed",
}

-- 计算所有槽位的属性加成总和
-- getter返回ID列表，对每个ID在配置表中查找并累加属性加成
-- @return { [internal_key] = { point = N, rate = N } }
function M.calc_total_bonus(human)
    local result = {}
    local need_debug = not _debug_logged
    local local_cfg = load_local_cfg()
    for i, getter in ipairs(SLOT_GETTERS) do
        local ids = getter(human)
        local type_cfg = local_cfg and local_cfg[i] or nil
        for _, id in ipairs(ids) do
            if id and id ~= 0 then
                local cfg = type_cfg and type_cfg[id] or nil
                if cfg then
                    for cn_name, mapping in pairs(ATTR_MAP) do
                        local val = cfg[cn_name]
                        if val and val ~= 0 then
                            local k = mapping.key
                            if not result[k] then result[k] = {} end
                            local f = mapping.field
                            result[k][f] = (result[k][f] or 0) + val
                        end
                    end
                end
            end
        end
    end
    if need_debug then
        local count = 0
        for k, v in pairs(result) do
            count = count + 1
        end
        _debug_logged = true
    end
    return result
end

-- 收集所有已激活外观配置中的状态ID
function M.collect_exterior_impacts(human)
    local impacts = {}
    local local_cfg = load_local_cfg()
    if not local_cfg then return impacts end
    for i, getter in ipairs(SLOT_GETTERS) do
        local ids = getter(human)
        local type_cfg = local_cfg[i]
        if type_cfg then
            for _, id in ipairs(ids) do
                if id and id ~= 0 then
                    local cfg = type_cfg[id]
                    if cfg then
                        local s1 = cfg["状态ID1"]
                        local s2 = cfg["状态ID2"]
                        if s1 and s1 ~= 0 then
                            impacts[s1] = true
                        end
                        if s2 and s2 ~= 0 then
                            impacts[s2] = true
                        end
                    end
                end
            end
        end
    end
    return impacts
end

-- 应用外观状态：移除不再需要的，添加新需要的
function M.apply_exterior_impacts(human)
    local new_impacts = M.collect_exterior_impacts(human)
    local old_impacts = human._exterior_impact_cache or {}

    -- 移除不再需要的状态
    local impact_list = human:get_impact_list()
    for old_id in pairs(old_impacts) do
        if not new_impacts[old_id] then
            for _, imp in ipairs(impact_list) do
                if imp:get_data_index() == old_id then
                    human:on_impact_fade_out(imp)
                    human:remove_impact(imp)
                    break
                end
            end
        end
    end

    -- 添加新的状态（检查是否已存在，避免重复）
    for new_id in pairs(new_impacts) do
        if not old_impacts[new_id] then
            local already_has = false
            impact_list = human:get_impact_list()
            for _, imp in ipairs(impact_list) do
                if imp:get_data_index() == new_id then
                    already_has = true
                    break
                end
            end
            if not already_has then
                impactenginer:send_impact_to_unit(human, new_id, human, 0, false, 0)
            end
        end
    end

    -- 更新缓存
    human._exterior_impact_cache = new_impacts
end

-- 刷新缓存并通知属性更新
function M.refresh_bonus(human)
    human._exterior_bonus_cache = M.calc_total_bonus(human)
    for _, key in ipairs(BONUS_DIRTY_KEYS) do
        human.db:mark_attrib_dirty(key)
    end
    human:send_refresh_attrib()
    -- 应用外观状态
    M.apply_exterior_impacts(human)
end

-- 获取缓存的外观加成（懒加载）
function M.get_bonus(human)
    if not human._exterior_bonus_cache then
        human._exterior_bonus_cache = M.calc_total_bonus(human)
    end
    return human._exterior_bonus_cache
end

return M
