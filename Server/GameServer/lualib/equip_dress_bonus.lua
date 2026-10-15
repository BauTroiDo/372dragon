local skynet = require "skynet"
local define = require "define"

local M = {}

local cfg_cache

local SIT_RECOVER_BY_TEXT = {
    [52501] = 1,
    [52502] = 3,
    [52503] = 6,
    [52504] = 9,
    [52505] = 12,
}

local function split_tab(line)
    local result = {}
    local pos = 1
    while true do
        local next_pos = string.find(line, "\t", pos, true)
        if not next_pos then
            table.insert(result, string.sub(line, pos))
            break
        end
        table.insert(result, string.sub(line, pos, next_pos - 1))
        pos = next_pos + 1
    end
    return result
end

local function to_number_list(list)
    local nums = {}
    for i, v in ipairs(list) do
        nums[i] = tonumber(v) or 0
    end
    return nums
end

local function config_file_path(name)
    local config_path = skynet.getenv("config_path")
    if config_path then
        return string.format(config_path, name)
    end
    return name
end

local function load_rows(name)
    local rows = {}
    local f = io.open(config_file_path(name), "r")
    if not f then
        return rows
    end
    local data_line = 0
    for line in f:lines() do
        line = string.gsub(line, "\r", "")
        if #line > 0 and string.sub(line, 1, 1) ~= "#" then
            data_line = data_line + 1
            if data_line > 2 then
                table.insert(rows, to_number_list(split_tab(line)))
            end
        end
    end
    f:close()
    return rows
end

local function set_effect_by_score(effects, score, key, value)
    if score and score > 0 and value and value > 0 then
        effects[score] = effects[score] or {}
        effects[score][key] = value
    end
end

local function build_effects()
    local effects = { jinyi = {}, xiuyi = {} }
    for _, row in ipairs(load_rows("DressCollectionEffect.txt")) do
        if row[2] == 1 then
            local score = row[3]
            local reduce = row[7]
            if score and score > 0 and reduce and reduce > 0 then
                effects.jinyi[score] = reduce
            end
        else
            local score = row[4]
            if score and score > 0 then
                local sit = SIT_RECOVER_BY_TEXT[row[7]] or 0
                set_effect_by_score(effects.xiuyi, score, "sit_recover_rate", sit)
                set_effect_by_score(effects.xiuyi, score, "durability_protect_rate", row[9])
                set_effect_by_score(effects.xiuyi, score, "soul_color_slot", row[11])
                set_effect_by_score(effects.xiuyi, score, "hp_bonus", row[13])
            end
        end
    end

    if not next(effects.jinyi) then
        for score = 1, 5 do
            effects.jinyi[score] = score * 50
        end
    end
    if not next(effects.xiuyi) then
        effects.xiuyi = {
            [1] = { sit_recover_rate = 1 },
            [3] = { durability_protect_rate = 300 },
            [6] = { hp_bonus = 200, durability_protect_rate = 300, sit_recover_rate = 1 },
            [10] = { hp_bonus = 200, durability_protect_rate = 300, sit_recover_rate = 3 },
            [15] = { hp_bonus = 200, durability_protect_rate = 700, sit_recover_rate = 3 },
            [20] = { hp_bonus = 500, durability_protect_rate = 700, sit_recover_rate = 3 },
            [25] = { hp_bonus = 500, durability_protect_rate = 700, sit_recover_rate = 6 },
            [30] = { hp_bonus = 500, durability_protect_rate = 1200, sit_recover_rate = 6 },
            [40] = { hp_bonus = 1000, durability_protect_rate = 1200, sit_recover_rate = 6 },
            [50] = { hp_bonus = 1000, durability_protect_rate = 1200, sit_recover_rate = 6, soul_color_slot = 1 },
            [60] = { hp_bonus = 1000, durability_protect_rate = 1200, sit_recover_rate = 9, soul_color_slot = 1 },
            [70] = { hp_bonus = 1000, durability_protect_rate = 1800, sit_recover_rate = 9, soul_color_slot = 1 },
            [80] = { hp_bonus = 1800, durability_protect_rate = 1800, sit_recover_rate = 9, soul_color_slot = 1 },
            [90] = { hp_bonus = 1800, durability_protect_rate = 1800, sit_recover_rate = 12, soul_color_slot = 1 },
            [100] = { hp_bonus = 1800, durability_protect_rate = 2400, sit_recover_rate = 12, soul_color_slot = 1 },
            [110] = { hp_bonus = 2600, durability_protect_rate = 2400, sit_recover_rate = 12, soul_color_slot = 1 },
            [120] = { hp_bonus = 2600, durability_protect_rate = 2400, sit_recover_rate = 12, soul_color_slot = 2 },
        }
    end
    return effects
end

local function build_item_to_collection()
    local map = {}
    for _, row in ipairs(load_rows("DressCollectionInfo.txt")) do
        local collection_id = row[2]
        if collection_id and collection_id > 0 then
            local range_start = row[7]
            local range_end = row[9]
            if range_start and range_start >= 10000000 and range_end and range_end >= range_start then
                for item_id = range_start, range_end do
                    map[item_id] = collection_id
                end
            end
            for i = 7, #row do
                local item_id = row[i]
                if item_id and item_id >= 10000000 then
                    map[item_id] = collection_id
                end
            end
        end
    end
    return map
end

local function build_collection_rules()
    local rules = {}
    for _, row in ipairs(load_rows("DressCollection.txt")) do
        local row_type = row[2]
        if row_type == 0 then
            local collection_id = row[3]
            if collection_id and collection_id > 0 then
                local r = rules[collection_id] or { xiuyi = 0, jinyi = 0 }
                r.xiuyi = math.max(r.xiuyi or 0, row[6] or 0)
                if row[4] and row[4] > 0 then
                    r.jinyi = math.max(r.jinyi or 0, row[4])
                end
                rules[collection_id] = r
            end
        end
    end
    return rules
end

local function build_series_rules()
    local rules = {}
    for _, row in ipairs(load_rows("DressCollectionSeries.txt")) do
        local score = row[4] or 0
        if score > 0 then
            local collections = {}
            for i = 5, #row do
                local collection_id = row[i]
                if collection_id and collection_id > 0 then
                    collections[collection_id] = true
                end
            end
            table.insert(rules, { score = score, collections = collections })
        end
    end
    return rules
end

local function build_fuben_set()
    local set = {}
    for _, row in ipairs(load_rows("DressCollectionFuBen.txt")) do
        local scene_id = row[2]
        if scene_id and scene_id > 0 then
            set[scene_id] = true
        end
    end
    return set
end

local function load_cfg()
    if cfg_cache then
        return cfg_cache
    end
    cfg_cache = {
        item_to_collection = build_item_to_collection(),
        collection_rules = build_collection_rules(),
        series_rules = build_series_rules(),
        effects = build_effects(),
        sit_fuben = build_fuben_set(),
    }
    return cfg_cache
end

local function get_score_effect(effect_map, score)
    local ret = {}
    for need_score, effect in pairs(effect_map) do
        if score >= need_score then
            for key, value in pairs(effect) do
                ret[key] = math.max(ret[key] or 0, value)
            end
        end
    end
    return ret
end

local function get_jinyi_reduce(effect_map, score)
    local reduce = 0
    for need_score, value in pairs(effect_map) do
        if score >= need_score then
            reduce = math.max(reduce, value)
        end
    end
    return reduce
end

local function is_countable_item(item)
    if not item or item:is_empty() then
        return false
    end
    local permanent = true
    if item.get_can_add_expairation_time then
        local ok, remain = pcall(item.get_can_add_expairation_time, item)
        if ok and remain ~= nil then
            permanent = remain == -1
            if remain ~= -1 and remain <= 0 then
                return false
            end
        end
    end
    if permanent then
        return true
    end
    return item:is_bind()
end

local function collect_item(container, collection_ids, cfg, pos)
    local item = container and container:get_item(pos)
    if not is_countable_item(item) then
        return
    end
    local item_index = item:get_index()
    local collection_id = cfg.item_to_collection[item_index]
    if collection_id then
        collection_ids[collection_id] = true
    end
end

local function collect_collection_ids(human, cfg)
    local collection_ids = {}
    local bag = human:get_fasion_bag_container()
    if bag then
        local size = tonumber(bag:get_size()) or 0
        for i = 0, size - 1 do
            collect_item(bag, collection_ids, cfg, i)
        end
    end

    local equip_container = human:get_equip_container()
    if equip_container then
        collect_item(equip_container, collection_ids, cfg, define.HUMAN_EQUIP.HEQUIP_FASHION)
    end
    return collection_ids
end

function M.calc_scores(human)
    local cfg = load_cfg()
    local collection_ids = collect_collection_ids(human, cfg)
    local xiuyi = 0
    local jinyi = 0
    for collection_id in pairs(collection_ids) do
        local rule = cfg.collection_rules[collection_id]
        if rule then
            xiuyi = xiuyi + (rule.xiuyi or 0)
            jinyi = jinyi + (rule.jinyi or 0)
        end
    end
    for _, series in ipairs(cfg.series_rules) do
        for collection_id in pairs(series.collections) do
            if collection_ids[collection_id] then
                jinyi = jinyi + series.score
                break
            end
        end
    end
    return { xiuyi = xiuyi, jinyi = jinyi, collections = collection_ids }
end

function M.refresh_bonus(human)
    human._equip_dress_bonus_cache = M.calc_scores(human)
    if human.db then
        human.db:mark_attrib_dirty("hp_max")
    end
    if human.send_refresh_attrib then
        human:send_refresh_attrib()
    end
end

function M.get_scores(human)
    if not human then
        return { xiuyi = 0, jinyi = 0 }
    end
    if not human._equip_dress_bonus_cache then
        human._equip_dress_bonus_cache = M.calc_scores(human)
    end
    return human._equip_dress_bonus_cache
end

function M.get_xiuyi_effect(human)
    local scores = M.get_scores(human)
    local cfg = load_cfg()
    return get_score_effect(cfg.effects.xiuyi, scores.xiuyi or 0)
end

function M.get_xiuyi_hp_bonus(human)
    return M.get_xiuyi_effect(human).hp_bonus or 0
end

function M.get_xiuyi_sit_recover_rate(human)
    return M.get_xiuyi_effect(human).sit_recover_rate or 0
end

function M.get_xiuyi_no_durability_loss_rate(human)
    return M.get_xiuyi_effect(human).durability_protect_rate or 0
end

function M.get_soul_color_slot_bonus(human)
    return M.get_xiuyi_effect(human).soul_color_slot or 0
end

function M.get_jinyi_damage_reduce_permyriad(human)
    local scores = M.get_scores(human)
    local cfg = load_cfg()
    return get_jinyi_reduce(cfg.effects.jinyi, scores.jinyi or 0)
end

function M.is_sit_recover_scene(human)
    if not human or not human.get_scene then
        return false
    end
    local scene = human:get_scene()
    if not scene or not scene.get_id then
        return false
    end
    return load_cfg().sit_fuben[scene:get_id()] == true
end

function M.is_sit_recover_allowed(human)
    if not M.is_sit_recover_scene(human) then
        return false
    end
    if human.get_attackers then
        local attackers = human:get_attackers()
        if attackers and attackers.get_exist_count and attackers:get_exist_count() > 0 then
            return false
        end
    end
    local scene = human:get_scene()
    if scene and scene.scan and human.get_world_pos then
        local pos = human:get_world_pos()
        local enemies = scene:scan({
            obj = human,
            x = pos.x,
            y = pos.y,
            radious = 10,
            count = 1,
            target_check_by_obj_type = 2,
            target_logic_by_stand = 1,
        })
        if enemies and #enemies > 0 then
            return false
        end
    end
    return true
end

function M.invalidate_config()
    cfg_cache = nil
end

return M
