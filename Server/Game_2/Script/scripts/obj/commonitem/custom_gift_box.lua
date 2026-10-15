local class = require "class"
local script_base = require "script_base"
local configenginer = require "configenginer":getinstance()

local custom_gift_box = class("custom_gift_box", script_base)
custom_gift_box.script_id = 999261
custom_gift_box.max_count = 27
custom_gift_box.pet_page_size = 12
custom_gift_box.gm_pet_page_size = 9
custom_gift_box.gm_pet_open_command = 999261012
custom_gift_box.gm_pet_page_command = 999261013
custom_gift_box.gm_pet_model_command = 999261014
custom_gift_box.pet_gift_model_command = 999261004
custom_gift_box.pet_gift_fixed_aptitude = 4888

custom_gift_box.item = {
    [38008202] = {
        max_select = 1,
        { id = 30302573, num = 1, bind = true },
        { id = 30302584, num = 1, bind = true },
        { id = 30302400, num = 1, bind = true },
        { id = 30302401, num = 1, bind = true },
        { id = 30302402, num = 1, bind = true },
        { id = 30302403, num = 1, bind = true },
    },
    [38008203] = {
        max_select = 1,
        { id = 10302000, num = 1, bind = true },
        { id = 10300000, num = 1, bind = true },
        { id = 10304000, num = 1, bind = true },
        { id = 10305000, num = 1, bind = true },
        { id = 10306000, num = 1, bind = true },
        { id = 10307000, num = 1, bind = true },
    },
    [38008204] = {
        max_select = 1,
        { id = 30700226, num = 1, bind = true },
        { id = 30700227, num = 1, bind = true },
        { id = 30700228, num = 1, bind = true },
        { id = 30700229, num = 1, bind = true },
    },
    [38008205] = {
        max_select = 1,
        { id = 10422016, num = 1, bind = true },
        { id = 10423024, num = 1, bind = true },
    },
    [38008206] = {
        max_select = 1,
        { id = 20310228, num = 1, bind = true },
        { id = 20310230, num = 1, bind = true },
    },
    [38008186] = {
        max_select = 1,
        { id = 10142536, num = 1, bind = true },
        { id = 10142554, num = 1, bind = true },
        { id = 10142572, num = 1, bind = true },
        { id = 10142590, num = 1, bind = true },
        { id = 10143024, num = 1, bind = true },
        { id = 10143004, num = 1, bind = true },
    },
    [38008208] = {
        max_select = 1,
        { id = 10125382, num = 1, bind = true },
        { id = 10126034, num = 1, bind = true },
    },
}

custom_gift_box.pet_gift = {
    [38008302] = {
        max_aptitude = custom_gift_box.pet_gift_fixed_aptitude,
        default_aptitude = custom_gift_box.pet_gift_fixed_aptitude,
    },
}

local pet_gift_list = nil
local gm_pet_gift_list = nil
custom_gift_box.gm_pet_sessions = custom_gift_box.gm_pet_sessions or {}

local gm_take_levels = { 85, 95 }
local gm_take_level_index = { [85]=1, [95]=2 }

local function is_integer(value)
    return type(value) == "number" and value == math.floor(value)
end

local get_gm_pet_gift_list

local function get_pet_gift_list()
    if pet_gift_list == nil then
        pet_gift_list = get_gm_pet_gift_list()
    end
    return pet_gift_list
end

local function get_pet_variant_base(info, data_id)
    local configured_base = info and tonumber(info.similar_pet_type) or nil
    local configured_mutation = configured_base and (data_id - configured_base) or 0
    if configured_mutation >= 0 and configured_mutation <= 9 then
        return configured_base
    end
    return data_id - (data_id % 10)
end

get_gm_pet_gift_list = function()
    if gm_pet_gift_list ~= nil then return gm_pet_gift_list end

    local pet_attr_table = configenginer:get_config("pet_attr_table")
    local pet_collection = configenginer:get_config("pet_collection")
    local groups = {}

    -- PetCollection contains every selectable mutation. PetAttrTable remains the
    -- authority for carry levels and the actual data IDs used during creation.
    for _, entry in ipairs(pet_collection) do
        local info = pet_attr_table[entry.data_id]
        local take_level = info and tonumber(info.take_level) or nil
        local base_id = info and get_pet_variant_base(info, entry.data_id) or nil
        local mutation = base_id and (entry.data_id - base_id) or 0
        if info and info.is_var_type and gm_take_level_index[take_level]
            and mutation >= 0 and mutation <= 9 then
            local key = tostring(entry.group).."|"..entry.name
            local group = groups[key]
            if group == nil then
                group = {
                    name = entry.name,
                    order = entry.order,
                    levels = {},
                    preview_levels = {},
                }
                groups[key] = group
            elseif entry.order < group.order then
                group.order = entry.order
            end
            local level = group.levels[take_level]
            if level == nil then
                level = { base_id = base_id, variants = {}, mutation_levels = {} }
                group.levels[take_level] = level
            end
            if level.variants[mutation] == nil then
                table.insert(level.mutation_levels, mutation)
            end
            level.variants[mutation] = entry.data_id
            group.preview_levels[take_level] = true
        end
    end

    gm_pet_gift_list = {}
    for _, group in pairs(groups) do
        local take_levels = {}
        for _, take_level in ipairs(gm_take_levels) do
            local level = group.levels[take_level]
            if level ~= nil then
                table.sort(level.mutation_levels)
                table.insert(take_levels, take_level)
            end
        end
        local preview_take_level = group.preview_levels[95] and 95
            or (group.preview_levels[85] and 85 or nil)
        if preview_take_level == nil and #take_levels > 0 then
            preview_take_level = take_levels[#take_levels]
        end
        if preview_take_level and #take_levels > 0 then
            local preview_level = group.levels[preview_take_level]
            local preview_mutation = preview_level.mutation_levels[1]
            table.insert(gm_pet_gift_list, {
                name = group.name,
                order = group.order,
                levels = group.levels,
                take_levels = take_levels,
                preview_take_level = preview_take_level,
                preview_data_id = preview_level.variants[preview_mutation],
            })
        end
    end

    table.sort(gm_pet_gift_list, function(left, right)
        if left.order == right.order then return left.name < right.name end
        return left.order < right.order
    end)

    local name_count = {}
    for _, pet in ipairs(gm_pet_gift_list) do
        local name_key = tostring(pet.preview_take_level).."|"..pet.name
        name_count[name_key] = (name_count[name_key] or 0) + 1
        pet.name_occurrence = name_count[name_key]
    end
    return gm_pet_gift_list
end

function custom_gift_box:SendItemCustomGiftPage(selfId, bagpos, itemid)
    if self:LuaFnGetItemTableIndexByIndex(selfId, bagpos) ~= itemid then
        return 0
    end

    local item = self.item[itemid]
    if item == nil or item.max_select < 1 or item.max_select > 5 then
        return 0
    end

    local total_count = math.min(#item, self.max_count)
    local packed_count = total_count * 10 + item.max_select
    local item_ids = {}
    local item_nums = {}

    self:BeginUICommand()
    self:UICommand_AddInt(bagpos)
    self:UICommand_AddInt(packed_count)
    self:UICommand_AddInt(self.script_id)
    for index, info in ipairs(item) do
        table.insert(item_nums, info.num)
        if index <= 12 then
            self:UICommand_AddInt(info.id)
        elseif index <= self.max_count then
            table.insert(item_ids, info.id)
        else
            break
        end
    end
    table.insert(item_nums, 1)
    self:UICommand_AddStr("SelectItem")
    self:UICommand_AddStr(table.concat(item_ids))
    self:UICommand_AddStr(table.concat(item_nums, ";"))
    self:EndUICommand()
    self:DispatchUICommand(selfId, 614052021)
    return 1
end

function custom_gift_box:OnDefaultEvent(selfId, bagIndex)
    local itemid = self:LuaFnGetItemTableIndexByIndex(selfId, bagIndex)
    if self.pet_gift[itemid] then
        self:SendPetCustomGiftPage(selfId, bagIndex, itemid, 1, true)
        return 0
    end

    self:SendItemCustomGiftPage(selfId, bagIndex, itemid)
    return 0
end

function custom_gift_box:IsSkillLikeScript(selfId)
    return 0
end

function custom_gift_box:CancelImpacts(selfId)
    return 0
end

function custom_gift_box:OnConditionCheck(selfId)
    if not self:LuaFnVerifyUsedItem(selfId) then
        return 0
    end
    local itemid = self:LuaFnGetItemIndexOfUsedItem(selfId)
    if self.item[itemid] == nil and self.pet_gift[itemid] == nil then
        return 0
    end
    if self.pet_gift[itemid] then
        local bagpos = self:LuaFnGetBagIndexOfUsedItem(selfId)
        self:SendPetCustomGiftPage(selfId, bagpos, itemid, 1, true)
        -- This item only opens a selection UI. Do not enqueue a skill action.
        return 0
    end
    return 1
end

function custom_gift_box:OnDeplete(selfId)
    return 1
end

function custom_gift_box:OnActivateOnce(selfId)
    local itemid = self:LuaFnGetItemIndexOfUsedItem(selfId)
    local bagpos = self:LuaFnGetBagIndexOfUsedItem(selfId)
    if self:LuaFnGetItemTableIndexByIndex(selfId, bagpos) ~= itemid then
        return 0
    end

    if self.pet_gift[itemid] then
        return self:SendPetCustomGiftPage(selfId, bagpos, itemid, 1, true)
    end

    return self:SendItemCustomGiftPage(selfId, bagpos, itemid)
end

function custom_gift_box:SendPetCustomGiftPage(selfId, bagpos, itemid, page, is_open)
    local gm_session = bagpos == -1 and itemid == 0 and self.gm_pet_sessions[selfId] or nil
    local gift = gm_session and {
        max_aptitude = gm_session.max_aptitude,
        default_aptitude = gm_session.default_aptitude,
    } or self.pet_gift[itemid]
    if gift == nil then return 0 end
    if not gm_session and self:LuaFnGetItemTableIndexByIndex(selfId, bagpos) ~= itemid then return 0 end

    local pets = gm_session and get_gm_pet_gift_list() or get_pet_gift_list()
    local page_size = gm_session and self.gm_pet_page_size or self.pet_page_size
    local total_count = #pets
    local page_count = math.max(1, math.ceil(total_count / page_size))
    page = tonumber(page)
    if not is_integer(page) or page < 1 or page > page_count then
        return 0
    end

    local first = (page - 1) * page_size + 1
    local last = math.min(first + page_size - 1, total_count)
    local current_count = math.max(0, last - first + 1)

    self:BeginUICommand()
    self:UICommand_AddInt(bagpos)
    self:UICommand_AddInt(itemid)
    self:UICommand_AddInt(gift.max_aptitude)
    self:UICommand_AddInt(gift.default_aptitude)
    self:UICommand_AddInt(total_count)
    self:UICommand_AddInt(page)
    self:UICommand_AddInt(page_count)
    self:UICommand_AddInt(current_count)
    for index = first, last do
        local pet = pets[index]
        local level_counts = {}
        for _, take_level in ipairs(gm_take_levels) do
            local level = pet.levels[take_level]
            table.insert(level_counts, tostring(level and #level.mutation_levels or 0))
        end
        self:UICommand_AddStr(tostring(pet.name_occurrence).."|"
            ..tostring(pet.preview_take_level).."|"
            ..table.concat(level_counts, ",").."|"
            ..tostring(pet.preview_data_id).."|"..pet.name)
    end
    self:EndUICommand()
    local commandId
    if gm_session then
        commandId = is_open and self.gm_pet_open_command or self.gm_pet_page_command
    else
        commandId = is_open and 999261002 or 999261003
    end
    self:DispatchUICommand(selfId, commandId)
    return 1
end

function custom_gift_box:OpenGmPetGift(selfId, targetId, max_aptitude, default_aptitude)
    targetId = tonumber(targetId)
    max_aptitude = tonumber(max_aptitude) or 8888
    default_aptitude = tonumber(default_aptitude) or max_aptitude
    if not is_integer(targetId) or not is_integer(max_aptitude) or not is_integer(default_aptitude)
        or max_aptitude < 1 or max_aptitude > 99999
        or default_aptitude < 1 or default_aptitude > max_aptitude then
        return 0
    end
    local target = self:get_scene():get_obj_by_id(targetId)
    if not target or target:get_obj_type() ~= "human" then return 0 end
    self.gm_pet_sessions[selfId] = {
        target_id = targetId,
        max_aptitude = max_aptitude,
        default_aptitude = default_aptitude,
    }
    return self:SendPetCustomGiftPage(selfId, -1, 0, 1, true)
end

function custom_gift_box:PetCustomGiftPage(selfId, bagpos, itemid, page)
    bagpos = tonumber(bagpos)
    itemid = tonumber(itemid)
    page = tonumber(page)
    if not is_integer(bagpos) or not is_integer(itemid) or not is_integer(page) then
        return
    end
    self:SendPetCustomGiftPage(selfId, bagpos, itemid, page, false)
end

function custom_gift_box:PetCustomGiftPreview(selfId, bagpos, itemid, pet_index, take_level, mutation)
    bagpos = tonumber(bagpos)
    itemid = tonumber(itemid)
    pet_index = tonumber(pet_index)
    take_level = tonumber(take_level)
    mutation = tonumber(mutation)
    if not is_integer(bagpos) or not is_integer(itemid) or not is_integer(pet_index)
        or not is_integer(take_level) or not is_integer(mutation)
        or self.pet_gift[itemid] == nil
        or self:LuaFnGetItemTableIndexByIndex(selfId, bagpos) ~= itemid then
        return
    end

    local pet = get_pet_gift_list()[pet_index]
    local level = pet and pet.levels[take_level] or nil
    local actual_mutation = level and level.mutation_levels[mutation] or nil
    local pet_data_id = actual_mutation ~= nil and level.variants[actual_mutation] or nil
    if pet_data_id == nil then return end

    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    local monster = monster_attr_ex and monster_attr_ex[pet_data_id] or nil
    local model_id = tonumber(monster and (monster.model_id or monster["澶栧瀷ID"])) or 0

    self:BeginUICommand()
    self:UICommand_AddInt(pet_index)
    self:UICommand_AddInt(take_level)
    self:UICommand_AddInt(mutation)
    self:UICommand_AddInt(model_id)
    self:UICommand_AddInt(pet_data_id)
    self:EndUICommand()
    self:DispatchUICommand(selfId, self.pet_gift_model_command)
end

function custom_gift_box:GmPetGiftPage(selfId, page)
    page = tonumber(page)
    if not is_integer(page) or self.gm_pet_sessions[selfId] == nil then
        return 0
    end
    return self:SendPetCustomGiftPage(selfId, -1, 0, page, false)
end

function custom_gift_box:GmPetPreview(selfId, bagpos, itemid, pet_index, take_level, mutation)
    bagpos = tonumber(bagpos)
    itemid = tonumber(itemid)
    pet_index = tonumber(pet_index)
    take_level = tonumber(take_level)
    mutation = tonumber(mutation)
    if bagpos ~= -1 or itemid ~= 0 or not is_integer(pet_index)
        or not is_integer(take_level) or not is_integer(mutation)
        or self.gm_pet_sessions[selfId] == nil then
        return
    end

    local pet = get_gm_pet_gift_list()[pet_index]
    local level = pet and pet.levels[take_level] or nil
    local actual_mutation = level and level.mutation_levels[mutation] or nil
    local pet_data_id = actual_mutation ~= nil and level.variants[actual_mutation] or nil
    if pet_data_id == nil then return end

    local monster_attr_ex = configenginer:get_config("monster_attr_ex")
    local monster = monster_attr_ex and monster_attr_ex[pet_data_id] or nil
    local model_id = tonumber(monster and (monster.model_id or monster["外型ID"])) or 0

    self:BeginUICommand()
    self:UICommand_AddInt(pet_index)
    self:UICommand_AddInt(take_level)
    self:UICommand_AddInt(mutation)
    self:UICommand_AddInt(model_id)
    self:UICommand_AddInt(pet_data_id)
    self:EndUICommand()
    self:DispatchUICommand(selfId, self.gm_pet_model_command)
end

function custom_gift_box:GmPetChoosePet(selfId, bagpos, itemid, pet_index, take_level, mutation, ...)
    bagpos = tonumber(bagpos)
    itemid = tonumber(itemid)
    pet_index = tonumber(pet_index)
    take_level = tonumber(take_level)
    mutation = tonumber(mutation)
    if bagpos ~= -1 or itemid ~= 0 or not is_integer(pet_index)
        or not is_integer(take_level) or not is_integer(mutation) then
        return
    end

    local gm_session = self.gm_pet_sessions[selfId]
    if gm_session == nil then return end
    local receiveId = gm_session.target_id
    local receiver = self:get_scene():get_obj_by_id(receiveId)
    if not receiver or receiver:get_obj_type() ~= "human" then return end

    local pet = get_gm_pet_gift_list()[pet_index]
    local level = pet and pet.levels[take_level] or nil
    local actual_mutation = level and level.mutation_levels[mutation] or nil
    local pet_data_id = actual_mutation ~= nil and level.variants[actual_mutation] or nil
    if pet_data_id == nil then return end

    local aptitudes = { ... }
    if #aptitudes ~= 5 then return end
    for index = 1, 5 do
        aptitudes[index] = tonumber(aptitudes[index])
        if not is_integer(aptitudes[index]) or aptitudes[index] < 1
            or aptitudes[index] > gm_session.max_aptitude then
            return
        end
    end

    if not self:TryCreatePet(receiveId, 1) then return end
    local ret, pet_guid_h, pet_guid_l = self:CallScriptFunction(
        800105, "CreateRMBPetToHuman34534", receiveId, pet_data_id, 1)
    if not ret then return end

    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "str_perception", aptitudes[1])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "spr_perception", aptitudes[2])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "con_perception", aptitudes[3])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "int_perception", aptitudes[4])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "dex_perception", aptitudes[5])
    --self.gm_pet_sessions[selfId] = nil
    self:LuaFnSendSpecificImpactToUnit(receiveId, receiveId, receiveId, 18, 0)
end

function custom_gift_box:SpecialPetEggChoosePet(selfId, bagpos, itemid, pet_index, take_level, mutation, ...)
    bagpos = tonumber(bagpos)
    itemid = tonumber(itemid)
    pet_index = tonumber(pet_index)
    take_level = tonumber(take_level)
    mutation = tonumber(mutation)
    if not is_integer(bagpos) or not is_integer(itemid)
        or not is_integer(pet_index) or not is_integer(take_level)
        or not is_integer(mutation) then
        return
    end

    local gift = self.pet_gift[itemid]
    if gift == nil then return end
    if self:LuaFnGetItemTableIndexByIndex(selfId, bagpos) ~= itemid then return end
    local receiveId = selfId
    local receiver = self:get_scene():get_obj_by_id(receiveId)
    if not receiver or receiver:get_obj_type() ~= "human" then return end

    local pets = get_pet_gift_list()
    local pet = pets[pet_index]
    local level = pet and pet.levels[take_level] or nil
    local actual_mutation = level and level.mutation_levels[mutation] or nil
    local pet_data_id = actual_mutation ~= nil and level.variants[actual_mutation] or nil
    if pet_data_id == nil then return end

    local aptitude = self.pet_gift_fixed_aptitude
    local aptitudes = { aptitude, aptitude, aptitude, aptitude, aptitude }

    if not self:TryCreatePet(receiveId, 1) then
        return
    end
    local ret, pet_guid_h, pet_guid_l = self:CallScriptFunction(
        800105, "CreateRMBPetToHuman34534", receiveId, pet_data_id, 1)
    if not ret then
        return
    end

    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "str_perception", aptitudes[1])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "spr_perception", aptitudes[2])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "con_perception", aptitudes[3])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "int_perception", aptitudes[4])
    self:LuaFnSetPetData(receiveId, pet_guid_h, pet_guid_l, "dex_perception", aptitudes[5])
    self:LuaFnDecItemLayCount(selfId, bagpos, 1)
    self:LuaFnSendSpecificImpactToUnit(receiveId, receiveId, receiveId, 18, 0)
end

function custom_gift_box:SelectItem(selfId, bagpos, ...)
    bagpos = tonumber(bagpos)
    if not is_integer(bagpos) then
        return
    end

    local selected = { ... }
    local itemid = self:LuaFnGetItemTableIndexByIndex(selfId, bagpos)
    local item = self.item[itemid]
    if item == nil or #selected ~= item.max_select then
        return
    end

    local used = {}
    for _, selected_index in ipairs(selected) do
        selected_index = tonumber(selected_index)
        if not is_integer(selected_index) or item[selected_index] == nil or used[selected_index] then
            return
        end
        used[selected_index] = true
    end

    self:BeginAddItem()
    for _, selected_index in ipairs(selected) do
        local info = item[selected_index]
        self:AddItem(info.id, info.num, info.bind)
    end
    if not self:EndAddItem(selfId) then
        return
    end
    self:LuaFnDecItemLayCount(selfId, bagpos, 1)
    self:AddItemListToHuman(selfId)
    for _, selected_index in ipairs(selected) do
        local info = item[selected_index]
        self:GiveItemTip(selfId, info.id, info.num, 18)
    end
end

function custom_gift_box:OnActivateEachTick(selfId)
    return 1
end

return custom_gift_box
