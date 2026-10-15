local define = require "define"

local M = {}

local cfg_cache

local EFFECT_RIDE_SPEED = 1
local EFFECT_LUOMAJIAN_RESIST = 2
local EFFECT_RIDE_DAMAGE_REDUCE = 3

local function get_ints(conf)
    local ints = conf and conf["INT"]
    if type(ints) == "table" then
        return ints
    end
    if type(ints) == "number" then
        return { ints }
    end
    return {}
end

local function load_txt(name)
    local ok, reader = pcall(require, "txtreader")
    if not ok then
        return {}
    end
    return reader.new():load(name) or {}
end

local function load_series()
    local series = {}
    for _, conf in pairs(load_txt("RideSeries.txt")) do
        local ints = get_ints(conf)
        local id = tonumber(ints[1]) or 0
        if id > 0 then
            local ride_ids = {}
            for i = 5, #ints do
                local ride_id = tonumber(ints[i]) or 0
                if ride_id > 0 then
                    ride_ids[#ride_ids + 1] = ride_id
                end
            end
            series[id] = {
                id = id,
                ride_count = tonumber(ints[2]) or #ride_ids,
                count_type = tonumber(ints[3]) or 0,
                min_req = tonumber(ints[4]) or 1,
                ride_ids = ride_ids,
            }
        end
    end
    return series
end

local function load_entries(series)
    local entries = {}
    for _, conf in pairs(load_txt("RideCollection.txt")) do
        local ints = get_ints(conf)
        local id = tonumber(ints[2]) or 0
        local id_type = tonumber(ints[3]) or 0
        if id > 0 then
            if id_type == 0 then
                entries[#entries + 1] = { type = "ride", ride_id = id }
            elseif id_type == 1 and series[id] then
                entries[#entries + 1] = { type = "series", series = series[id] }
            end
        end
    end
    return entries
end

local function load_effects()
    local effects = {}
    for _, conf in pairs(load_txt("RideCollectionEffect.txt")) do
        local ints = get_ints(conf)
        for i = 2, #ints, 3 do
            local effect_type = tonumber(ints[i]) or 0
            local effect_value = tonumber(ints[i + 1]) or 0
            local req_count = tonumber(ints[i + 2]) or 0
            if effect_type > 0 and effect_value > 0 and req_count > 0 then
                effects[#effects + 1] = {
                    type = effect_type,
                    value = effect_value,
                    count = req_count,
                }
            end
        end
    end
    return effects
end

local function load_cfg()
    if not cfg_cache then
        local series = load_series()
        cfg_cache = {
            series = series,
            entries = load_entries(series),
            effects = load_effects(),
        }
    end
    return cfg_cache
end

local function collect_valid_rides(human)
    local collected = {}
    local rides = human and human.exterior and human.exterior.rides
    if not rides then
        return collected
    end

    local now = os.time()
    for _, ride in ipairs(rides) do
        local ride_id = tonumber(ride.id) or 0
        if ride_id > 0 and (ride.term == -1 or ride.term > now) then
            collected[ride_id] = true
        end
    end
    return collected
end

local function is_riding(human)
    if not human or not human.get_ride_model then
        return false
    end
    local ride_model = human:get_ride_model()
    return ride_model and ride_model > 0 and ride_model ~= define.INVAILD_ID
end

local function get_series_active_count(series, collected)
    local have_count = 0
    for _, ride_id in ipairs(series.ride_ids or {}) do
        if collected[ride_id] then
            have_count = have_count + 1
        end
    end

    if (series.count_type or 0) == 1 then
        return have_count
    end
    if have_count >= (series.min_req or 1) then
        return 1
    end
    return 0
end

local function get_active_count(human, collected)
    if not human then
        return 0
    end

    local count = 0
    for _, entry in ipairs(load_cfg().entries) do
        if entry.type == "ride" then
            if collected[entry.ride_id] then
                count = count + 1
            end
        elseif entry.type == "series" then
            count = count + get_series_active_count(entry.series, collected)
        end
    end
    return count
end

local function get_effect_value(human, effect_type, need_ride)
    if not human then
        return 0
    end

    local collected = collect_valid_rides(human)
    if need_ride and not is_riding(human) then
        return 0
    end

    local active_count = get_active_count(human, collected)
    local total = 0
    for _, effect in ipairs(load_cfg().effects) do
        if effect.type == effect_type and active_count >= effect.count then
            total = total + effect.value
        end
    end
    return total
end

function M.get_huayu_count(human)
    return get_active_count(human, collect_valid_rides(human))
end

function M.get_ride_speed_rate(human)
    return get_effect_value(human, EFFECT_RIDE_SPEED, true)
end

function M.get_luomajian_resist_rate(human)
    return get_effect_value(human, EFFECT_LUOMAJIAN_RESIST, true)
end

function M.get_damage_reduce_rate(human)
    return get_effect_value(human, EFFECT_RIDE_DAMAGE_REDUCE, true)
end

function M.invalidate_config()
    cfg_cache = nil
end

return M
