-- Faction capacity and data readiness. No Skynet calls or game-state mutation here.
local registry = {}
registry.CAPACITY = 25
registry.MAX_ID = 25
registry.NONE_ID = 9
registry.LEGACY_MAX_ID = 12 -- CS3b: không dùng nữa, xem LEGACY_IDS
registry.LEGACY_IDS = {[0] = true, [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [10] = true, [15] = true, [16] = true} -- CS3b: phái có mã Lua riêng theo số CY (0-8, 慕容 10, 恶人谷 15, 曼陀 16 tắt)
function registry.is_legacy(id) return registry.LEGACY_IDS[id] == true end

local function integer(value, minimum, maximum)
    return type(value) == "number" and value == math.floor(value)
        and value >= minimum and value <= maximum
end

function registry.is_slot(id)
    return integer(id, 0, registry.MAX_ID) and id ~= registry.NONE_ID
end

function registry.slot_ids()
    local result = {}
    for id = 0, registry.MAX_ID do
        if registry.is_slot(id) then result[#result + 1] = id end
    end
    return result
end

local function id_list(list, count, maximum, minimum)
    if type(list) ~= "table" or #list ~= count then return false end
    local seen, keys = {}, 0
    for key in pairs(list) do
        if not integer(key, 1, count) then return false end
        keys = keys + 1
    end
    if keys ~= count then return false end
    for _, id in ipairs(list) do
        if not integer(id, minimum or 0, maximum or 2147483647) or seen[id] then return false end
        seen[id] = true
    end
    return true
end

function registry.extend_definitions(define, entries)
    define.MENPAI_CAPACITY = registry.CAPACITY
    define.MENPAI_MAX_ID = registry.MAX_ID
    define.MENPAI_NONE_ID = registry.NONE_ID
    define.MENPAI_SLOTS = registry.slot_ids()
    define.MENPAI_REGISTRATION_ERRORS = {}
    define.MENPAI_EXTENSIONS = {}
    define.MENPAI_ATTACK_TRAITS = {}
    define.MENPAI_COMPOUND_ABILITIES = {}
    if type(entries) ~= "table" then
        define.MENPAI_REGISTRATION_ERRORS.config = "extensions_must_be_table"
        return
    end
    -- Deterministic order: duplicate metadata never depends on Lua pairs ordering.
    local ids = {}
    for id in pairs(entries) do
        if registry.is_slot(id) and not registry.is_legacy(id) then
            ids[#ids + 1] = id
        else
            define.MENPAI_REGISTRATION_ERRORS[tostring(id)] = "extension_id_out_of_range"
        end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do
        local entry = entries[id]
        local reason
        if type(entry) ~= "table" then
            reason = "entry_must_be_table"
        elseif type(entry.enum) ~= "string" or not entry.enum:match("^MATTRIBUTE_[A-Z0-9_]+$")
            or define.MENPAI_ATTRIBUTE[entry.enum] ~= nil then
            reason = "invalid_or_duplicate_enum"
        elseif type(entry.name) ~= "string" or entry.name == "" then
            reason = "missing_name"
        elseif not id_list(entry.abilities, 2, 255) then
            reason = "two_unique_ability_ids_required"
        elseif not id_list(entry.skills7, 3) then
            reason = "three_unique_special_skill_ids_required"
        elseif not integer(entry.xinfa7, 1, 65535) or not integer(entry.xinfa8, 1, 65535)
            or entry.xinfa7 >= entry.xinfa8 then
            reason = "invalid_special_xinfa_ids"
        elseif not integer(entry.qinggong, 0, 2147483647)
            or not integer(entry.reputation, 0, 2147483647) then
            reason = "invalid_qinggong_or_reputation"
        elseif entry.attack_traits ~= nil and not integer(entry.attack_traits, 0, 255) then
            reason = "invalid_attack_traits"
        elseif entry.compound_ability ~= nil and (not integer(entry.compound_ability, 0, 255)
            or (entry.compound_ability ~= entry.abilities[1] and entry.compound_ability ~= entry.abilities[2])) then
            reason = "invalid_compound_ability"
        elseif entry.enabled ~= nil and type(entry.enabled) ~= "boolean" then
            reason = "invalid_enabled_flag"
        elseif entry.ranged_skill ~= nil and not integer(entry.ranged_skill, 0, 2147483647) then
            reason = "invalid_ranged_skill"
        elseif entry.quick_skills ~= nil and (type(entry.quick_skills) ~= "table"
            or #entry.quick_skills < 1 or #entry.quick_skills > 3
            or not id_list(entry.quick_skills, #entry.quick_skills, 2147483647, 1)) then
            reason = "invalid_quick_skills"
        end
        if not reason then
            for _, name in pairs(define.ENUM_MENPAI_CHN) do
                if entry.name == name then reason = "duplicate_name" end
            end
        end
        if reason then
            define.MENPAI_REGISTRATION_ERRORS[id] = reason
        else
            define.MENPAI_ATTRIBUTE[entry.enum] = id
            define.ENUM_MENPAI_CHN[id] = entry.name
            define.MENPAI_ABILITYS[id] = {entry.abilities[1], entry.abilities[2]}
            define.MENPAI_7_SKILLS[id] = {}
            for position, skill in ipairs(entry.skills7) do define.MENPAI_7_SKILLS[id][skill] = position end
            define.MENPAI_7_XINFA[id] = entry.xinfa7
            define.MENPAI_8_XINFA[id] = entry.xinfa8
            define.QINGGONG_SKILL[id] = entry.qinggong
            define.MENPAI_REPUTATIONS[id] = entry.reputation
            define.MENPAI_JINZHAN_YUANGONG_SKILL[id] = entry.ranged_skill
            define.SETTING_MENPAI_SKILLID[id] = entry.quick_skills or {}
            define.MENPAI_EXTENSIONS[id] = entry
            define.MENPAI_ATTACK_TRAITS[id] = entry.attack_traits
            if entry.compound_ability then define.MENPAI_COMPOUND_ABILITIES[entry.compound_ability] = true end
        end
    end
end

function registry.is_registered(define, id)
    if not registry.is_slot(id) or not define.ENUM_MENPAI_CHN[id] then return false end
    for _, registered_id in pairs(define.MENPAI_ATTRIBUTE) do
        if registered_id == id then return true end
    end
    return false
end

function registry.xinfa_ids(config, menpai)
    local ids = {}
    for id, entry in pairs(config or {}) do
        if type(entry) == "table" and entry.menpai == menpai and integer(id, 1, 65535) then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    return ids
end

local function read_config(get_config, name)
    local ok, config = pcall(get_config, name)
    if ok and type(config) == "table" then return config end
end

function registry.check_ready(define, id, get_config)
    if not registry.is_slot(id) then return false, "invalid_faction_id" end
    if not registry.is_registered(define, id) then return false, "faction_not_registered" end
    -- Preserve the twelve existing factions, including their known baseline quirks.
    -- CYS-MENPAIJOIN (20/09): "legacy" chi co nghia "khoi kiem CHI TIET", KHONG co nghia "khoi can du lieu".
    -- O server goc moi phai legacy deu co du 8 tam phap nen hai nghia trung nhau. O day cs3b doi Man Da sang
    -- o 16, xoa het dong cua no, roi van de no trong LEGACY_IDS => o DUY NHAT vua "khoi kiem" vua "rong":
    -- LuaFnJoinMenpai(16) doi menpai nhung cap 0 tam phap + 0 chieu. Legacy ma KHONG co dong tam phap nao => tu choi.
    if registry.is_legacy(id) then
        local xinfa_v1 = read_config(get_config, "xinfa_v1")
        if not xinfa_v1 or #registry.xinfa_ids(xinfa_v1, id) == 0 then return false, "faction_disabled_no_data" end
        return true, "legacy_configured"
    end
    local entry = define.MENPAI_EXTENSIONS[id]
    if entry and entry.enabled == false then return false, "faction_integration_pending" end
    if entry and entry.attack_traits ~= nil then
        local traits = read_config(get_config, "attck_traits")
        if not traits or not traits[entry.attack_traits] then return false, "missing_attack_traits" end
    end
    local configs = {}
    for _, name in ipairs({"xinfa_v1", "base_value_table", "attr_level_up_table",
        "xinfa_study_speed_v1", "ability", "skill_template", "skill_data"}) do
        configs[name] = read_config(get_config, name)
        if not configs[name] then return false, "missing_config:" .. name end
    end
    local ids = registry.xinfa_ids(configs.xinfa_v1, id)
    if #ids ~= 8 then return false, "eight_xinfa_required" end
    if ids[7] ~= define.MENPAI_7_XINFA[id] or ids[8] ~= define.MENPAI_8_XINFA[id] then
        return false, "xinfa_order_mismatch"
    end
    local owned_xinfa = {}
    for _, xinfa in ipairs(ids) do owned_xinfa[xinfa] = true end
    local base = configs.base_value_table["MENPAI" .. id]
    local baseline = configs.base_value_table.MENPAI0
    if type(base) ~= "table" or type(baseline) ~= "table" then return false, "missing_base_values" end
    for key, val in pairs(baseline) do
        if tonumber(val) ~= nil and tonumber(base[key]) == nil then return false, "missing_base_value:" .. key end
    end
    local name = define.ENUM_MENPAI_CHN[id]
    if not next(configs.attr_level_up_table) then return false, "missing_attr_levels" end
    for level, row in pairs(configs.attr_level_up_table) do
        for _, attr in ipairs({"str", "spr", "con", "dex", "int"}) do
            local val = type(row[attr]) == "table" and row[attr][name]
            if type(val) == "table" then val = val[1] end
            if tonumber(val) == nil then return false, "missing_level_attr:" .. tostring(level) .. ":" .. attr end
        end
    end
    if not next(configs.xinfa_study_speed_v1) then return false, "missing_xinfa_costs" end
    for level, row in pairs(configs.xinfa_study_speed_v1) do
        for _, xinfa in ipairs(ids) do
            for _, field in ipairs({"cost_exp", "cost_money"}) do
                local cost = type(row[field]) == "table" and tonumber(row[field][xinfa + 1])
                if not cost or cost < 0 then return false, "missing_xinfa_cost:" .. level .. ":" .. xinfa end
            end
        end
    end
    for _, ability in ipairs(define.MENPAI_ABILITYS[id]) do
        if not configs.ability[ability] then return false, "missing_ability:" .. ability end
    end
    local templates, data = configs.skill_template, configs.skill_data
    local has_xinfa_skill, count = {}, 0
    for skill, template in pairs(templates) do
        if template.menpai == id then
            count = count + 1
            if template.xinfa ~= -1 then
                if not owned_xinfa[template.xinfa] then return false, "foreign_xinfa:" .. skill end
                has_xinfa_skill[template.xinfa] = true
            end
            for tier = 1, define.MAX_CHAR_SKILL_LEVEL do
                local actual = template.level_skills and template.level_skills[tier]
                if not data[actual] then return false, "missing_skill_data:" .. skill .. ":" .. tier end
            end
        end
    end
    if count == 0 or count >= 128 then return false, "invalid_faction_skill_count" end
    for position = 1, 6 do
        if not has_xinfa_skill[ids[position]] then return false, "missing_basic_xinfa_skill:" .. ids[position] end
    end
    local function owns(skill)
        return templates[skill] and templates[skill].menpai == id
    end
    for skill in pairs(define.MENPAI_7_SKILLS[id]) do
        if not owns(skill) or templates[skill].xinfa ~= ids[7] then return false, "invalid_special_skill:" .. skill end
    end
    if not owns(define.QINGGONG_SKILL[id]) then return false, "invalid_qinggong_skill" end
    local ranged = define.MENPAI_JINZHAN_YUANGONG_SKILL[id]
    if ranged and not owns(ranged) then return false, "invalid_ranged_skill" end
    for _, skill in ipairs(define.SETTING_MENPAI_SKILLID[id]) do
        if not owns(skill) then return false, "invalid_quick_skill" end
    end
    return true, "server_data_ready"
end

function registry.check_join(define, id, skills, get_config)
    local ok, reason = registry.check_ready(define, id, get_config)
    if not ok or registry.is_legacy(id) then return ok, reason end
    local templates = get_config("skill_template")
    local count, present = 0, {}
    for _, skill in ipairs(skills or {}) do
        local template = templates[skill]
        if not template then return false, "unknown_owned_skill:" .. tostring(skill) end
        if template.menpai == -1 then count = count + 1; present[skill] = true end
    end
    for skill, template in pairs(templates) do
        if template.menpai == id and template.direct_study_up then
            count = count + 1; present[skill] = true
        end
    end
    local ranged = define.MENPAI_JINZHAN_YUANGONG_SKILL[id]
    if ranged and not present[ranged] then count = count + 1 end
    if count >= 128 then return false, "skill_list_capacity_exceeded" end
    return true, reason
end

-- Build changed lists without touching a player. Only extension crossings use it;
-- transitions between legacy factions keep their existing implementation.
function registry.plan_transition(define, source, target, xinfas, skills, get_config)
    if not registry.is_registered(define, source) then return nil, "invalid_source_faction" end
    for _, id in ipairs({source, target}) do
        local ok, reason = registry.check_ready(define, id, get_config)
        if not ok then return nil, reason end
    end
    local config = get_config("xinfa_v1")
    local old_ids, new_ids = registry.xinfa_ids(config, source), registry.xinfa_ids(config, target)
    if #old_ids ~= 8 or #new_ids ~= 8 then return nil, "transition_requires_eight_xinfa" end
    local old_levels, new_xinfa, learned = {}, {}, {}
    for _, xinfa in ipairs(xinfas) do old_levels[xinfa.m_nXinFaID] = xinfa.m_nXinFaLevel end
    for position, old_id in ipairs(old_ids) do
        if old_levels[old_id] then
            local new_id = new_ids[position]
            new_xinfa[#new_xinfa + 1] = {m_nXinFaID = new_id, m_nXinFaLevel = old_levels[old_id]}
            learned[new_id] = true
        end
    end
    local templates, selected, old_skills = get_config("skill_template"), {}, {}
    for _, skill in ipairs(skills) do
        local template = templates[skill]
        if not template then return nil, "unknown_owned_skill:" .. tostring(skill) end
        old_skills[skill] = true
        if template.menpai == -1 then selected[skill] = true end
    end
    for skill, template in pairs(templates) do
        if template.menpai == target and template.class_by_user == 0 and learned[template.xinfa]
            and template.xinfa ~= define.MENPAI_7_XINFA[target]
            and template.xinfa ~= define.MENPAI_8_XINFA[target] then
            selected[skill] = true
        end
    end
    if learned[define.MENPAI_7_XINFA[target]] then
        local inverse = {}
        for skill, position in pairs(define.MENPAI_7_SKILLS[target]) do inverse[position] = skill end
        for skill, position in pairs(define.MENPAI_7_SKILLS[source]) do
            if old_skills[skill] then selected[inverse[position]] = true end
        end
    end
    if old_skills[define.QINGGONG_SKILL[source]] then selected[define.QINGGONG_SKILL[target]] = true end
    local ranged = define.MENPAI_JINZHAN_YUANGONG_SKILL[target]
    if ranged then selected[ranged] = true end
    local new_skills = {}
    for skill in pairs(selected) do
        if not templates[skill] then return nil, "unknown_target_skill:" .. tostring(skill) end
        new_skills[#new_skills + 1] = skill
    end
    table.sort(new_skills)
    if #new_skills >= 128 then return nil, "skill_list_capacity_exceeded" end
    return {xinfa_list = new_xinfa, skill_list = new_skills}
end

return registry
