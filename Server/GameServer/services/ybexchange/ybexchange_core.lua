local skynet = require "skynet"
local define = require "define"
local class = require "class"
local configenginer = require "configenginer":getinstance()
local ybexchange_core = class("ybexchange_core")
local MAX_ITEM_SELL_COUNT = 10
local MAX_PET_SELL_COUNT = 5
local ItemSubTypes = {
    [2] = {
        [30503123] = true,
        [30501355] = true,
        [30501357] = true,
        [30501168] = true,
        [30505816] = true,
        [30505817] = true,
        [30505908] = true,
        [20310113] = true,
        [30503124] = true,
        [30503125] = true,
        [30503122] = true,
        [20310166] = true,
        [30503126] = true,
        [30008069] = true,
        [30501172] = true
    },
    [3] = {
        [20310115] = true,
        [30503034] = true,
        [30503035] = true,
        [30503036] = true,
        [30503037] = true,
        [30503038] = true,
        [30503039] = true,
        [30503040] = true,
        [30503041] = true,
        [30503042] = true,
        [30503043] = true,
        [30503044] = true,
        [30503045] = true,
        [30503046] = true,
        [30503047] = true,
        [30503048] = true,
        [30503049] = true,
        [30503050] = true,
        [30503051] = true,
        [30503052] = true,
        [30503053] = true,
        [30503054] = true,
        [30503055] = true,
        [30503056] = true,
        [30503057] = true,
        [30503058] = true,
        [30503059] = true,
        [30503060] = true,
        [30503061] = true,
        [30503062] = true,
        [30503063] = true,
        [30503064] = true,
        [30503065] = true,
        [30503066] = true,
        [30503067] = true,
        [30503068] = true,
        [30503069] = true,
        [30900058] = true,
        [20301009] = true,
        [20310160] = true
    },
    [4] = {
        [20310117] = true,
        [20310118] = true,
        [20310119] = true,
        [20310120] = true,
        [20310121] = true,
        [20310122] = true,
        [20310123] = true,
        [20310124] = true,
        [20310125] = true,
        [20310126] = true,
        [20310127] = true,
        [20310128] = true,
        [20310129] = true,
        [20310130] = true,
        [20310131] = true,
        [20310132] = true,
        [20310133] = true,
        [20310134] = true,
        [20310135] = true,
        [20310136] = true,
        [20310137] = true,
        [20310138] = true,
        [20310139] = true,
        [20310140] = true,
        [20310141] = true,
        [20310142] = true,
        [20310143] = true,
        [20310144] = true,
        [20310145] = true,
        [20310146] = true,
        [20310147] = true,
        [20310148] = true,
        [20310149] = true,
        [20310150] = true,
        [20310151] = true,
        [20310152] = true,
        [20310153] = true,
        [20310154] = true,
        [20310155] = true,
        [20310156] = true,
        [20310157] = true,
        [30700213] = true,
        [30700242] = true,
        [30700214] = true,
        [30700215] = true,
        [30700216] = true,
        [30700217] = true,
        [30700218] = true,
        [30700219] = true,
        [30700220] = true,
        [30700221] = true,
        [30700222] = true,
        [30700223] = true,
        [30700224] = true,
        [30700225] = true,
        [30700226] = true,
        [30700227] = true,
        [30700228] = true,
        [30700229] = true
    }
}

local PetSubTypes = {
    [5] = 2,
    [45] = 3,
    [55] = 4,
    [65] = 5,
    [75] = 6,
    [85] = 7,
    [95] = 8
}

function ybexchange_core:getinstance()
    if ybexchange_core.instance == nil then
        ybexchange_core.instance = ybexchange_core.new()
    end
    return ybexchange_core.instance
end

function ybexchange_core:ctor()
    self.delta_time = 60 * 60
end

function ybexchange_core:init()
    -- 依赖 get_config 自动按需加载，不再 loadall
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
    end)
end

function ybexchange_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        print(err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function ybexchange_core:message_update()
    self:check_on_sale_merchadise()
    self:check_off_merchadise()
end

function ybexchange_core:check_on_sale_merchadise()
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local query_tbl = { status = "on_sale", off_time = { ["$lte"] = os.time() }}
    local merchadise_list = skynet.call(".db", "lua", "findAll", {
         
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    merchadise_list = merchadise_list or {}
    for _, merchadise in ipairs(merchadise_list) do
        self:merchadise_off(merchadise)
    end
end

function ybexchange_core:check_off_merchadise()
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local query_tbl = { status = "off", delete_time = { ["$lte"] = os.time() }}
    local merchadise_list = skynet.call(".db", "lua", "findAll", {
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    merchadise_list = merchadise_list or {}
    for _, merchadise in ipairs(merchadise_list) do
        self:merchadise_delete(merchadise)
    end
end

function ybexchange_core:merchadise_delete(merchadise)
    local coll_name = "ybmarket"
    local query_tbl = {seller_guid = merchadise.seller_guid, status = "off"}
    if merchadise.type == 1 then
        local guid = merchadise.item.attrib.guid
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        local guid = merchadise.item.guid
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local sql = { collection = coll_name, selector = query_tbl, single = true}
    skynet.call(".db", "lua", "delete", sql)
end

function ybexchange_core:merchadise_off(merchadise)
    local coll_name = "ybmarket"
    local query_tbl = {seller_guid = merchadise.seller_guid, status = "on_sale"}
    if merchadise.type == 1 then
        local guid = merchadise.item.attrib.guid
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        local guid = merchadise.item.guid
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local updater = { ["$set"] = { status = "off", delete_time = os.time() + 7 * 24 * 60 * 60}}
    skynet.call(".db", "lua", "update", {
         
        collection = coll_name,
        selector = query_tbl,
        update = updater,
        upsert = true,
        multi = false
    })
    self:send_off_merchadise_mail(merchadise)
end

function ybexchange_core:send_off_merchadise_mail(merchadise)
    local msg = string.contact_args("#{YBSC_MAIL_2", merchadise.price, merchadise.item_name)
    msg = msg .. "}"
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest_guid = merchadise.seller_guid
    mail.content = msg
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail_to_guid", mail)
end

function ybexchange_core:before_sell_check_is_full(guid, auction_type)
    local pipeline = {}
    local query_tbl
    if auction_type == 1 then
        query_tbl = {["$and"] = {{seller_guid = guid}, {type = 1}}}
    else
        query_tbl = {
            ["$and"] = {
                {seller_guid = guid}, {["$or"] = {{type = 2}, {type = 3}}}
            }
        }
    end
    local step = {["$group"] = {_id = false, ["count"] = {["$sum"] = 1}}}
    table.insert(pipeline, {["$match"] = query_tbl})
    table.insert(pipeline, step)
    local coll_name = "ybmarket"
    local result = skynet.call(".db", "lua", "runCommand", "aggregate",
                               coll_name, "pipeline", pipeline, "cursor", {},
                               "allowDiskUse", false)
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            local r = result.cursor.firstBatch[1]
            if r then
                local count = r["count"]
                if auction_type == 1 then
                    return count >= MAX_PET_SELL_COUNT
                else
                    return count >= MAX_ITEM_SELL_COUNT
                end
            end
        end
    end
    return false
end

function ybexchange_core:is_equip(request)
    if request.type == 1 then return false end
    local item_index = request.item.item_index
    return item_index // 10000000 == 1
end

function ybexchange_core:get_sub_type(request)
    if request.type == 2 then
        if self:is_equip(request) then
            request.type = 3
            local item_index = request.item.item_index
            local equip_base = configenginer:get_config("equip_base")
            equip_base = equip_base[item_index]
            assert(equip_base, item_index)
            local equip_point = equip_base.equip_point
            local take_level = equip_base.level
            local quality = request.item.quality
            local identd = request.item.status &
                               define.ITEM_EXT_INFO.IEI_IDEN_INFO ==
                               define.ITEM_EXT_INFO.IEI_IDEN_INFO
            local last = 2
            if identd then last = quality + 2 end
            take_level = take_level // 10
            return {
                ["1"] = equip_point + 2,
                ["2"] = take_level + 2,
                ["3"] = last
            }
        else
            if ItemSubTypes[2][request.item.item_index] then
                return {["3"] = 2}
            end
            if ItemSubTypes[3][request.item.item_index] then
                return {["3"] = 3}
            end
            if ItemSubTypes[4][request.item.item_index] then
                return {["3"] = 4}
            end
            return {["3"] = 5}
        end
    elseif request.type == 1 then
        assert(request.take_level)
        local sub_type = PetSubTypes[request.take_level]
        assert(sub_type, request.take_level)
        return {["3"] = sub_type}
    end
end

function ybexchange_core:sell(request)
    assert(request.type, "Auction sell can not no type")
    assert(request.item, "Auction sell can not no item")
    assert(request.item_name, "Auction sell can not no item_name")
    assert(request.price, "Auction sell can not no price")
    assert(request.seller_guid, "Auction sell can not no seller_guid")
    assert(request.seller_guid, "Auction sell can not no seller_name")
    assert(request.on_sale_date, "Auction sell can not no on_sale_date")
    local coll_name = "ybmarket"
    request.sub_type = self:get_sub_type(request)
    request.take_level = nil
    request.status = "on_sale"
    request.off_time = os.time() + 48 * 60 * 60
    assert(request.sub_type, "Auction sell can not no sub_type")
    local args = {  collection = coll_name, doc = request}
    skynet.call(".db", "lua", "safe_insert", args)
    return 1
end

function ybexchange_core:trans_search_sub_type(request, query_tbl)
    local sub_type = request.sub_type
    local first = sub_type // 10000
    local second = (sub_type % 10000) // 100
    local last = (sub_type % 100)
    if not (first == 0 or first == 1) then query_tbl["sub_type.1"] = first end
    if not (second == 0 or second == 1) then query_tbl["sub_type.2"] = second end
    if not (last == 0 or last == 1) then query_tbl["sub_type.3"] = last end
end

function ybexchange_core:search(request)
    local query_tbl = {type = request.type, status = "on_sale"}
    if request.name ~= "" then
        query_tbl = {["item_name"] = {["$regex"] = request.name}, status = "on_sale"}
    end
    self:trans_search_sub_type(request, query_tbl)
    local sorter
    if request.order == 1 then
        sorter = {["price"] = 1}
    elseif request.order == 2 then
        sorter = {["price"] = -1}
    elseif request.order == 3 then
        sorter = {["item_name"] = 1}
    elseif request.order == 4 then
        sorter = {["item_name"] = -1}
    end
    local skip = (request.page - 1) * 10
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local merchandise_list = skynet.call(".db", "lua", "findAll", {
        collection = coll_name,
        query = query_tbl,
        selector = selector,
        skip = skip,
        sorter = sorter,
        limit = 10
    })
    local total_count = 0
    local pipeline = {}
    local step = {["$group"] = {_id = "count", ["count"] = {["$sum"] = 1}}}
    table.insert(pipeline, {["$match"] = query_tbl})
    table.insert(pipeline, step)
    local result = skynet.call(".db", "lua", "runCommand", "aggregate",
                               coll_name, "pipeline", pipeline, "cursor", {},
                               "allowDiskUse", false)
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            local r = result.cursor.firstBatch[1]
            if r then total_count = r["count"] end
        end
    end
    merchandise_list = merchandise_list or {}
    return {
        page_total = math.ceil(total_count / 10),
        merchandise_list = merchandise_list
    }
end

function ybexchange_core:modify(merchadise, request)
    local coll_name = "ybmarket"
    local query_tbl = {seller_guid = merchadise.seller_guid, status = "on_sale"}
    if merchadise.type == 1 then
        local guid = merchadise.item.attrib.guid
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        local guid = merchadise.item.guid
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local updater = { ["$set"] = { price = request.price }}
    skynet.call(".db", "lua", "update", {
         
        collection = coll_name,
        selector = query_tbl,
        update = updater,
        upsert = true,
        multi = false
    })
end

function ybexchange_core:find(request)
    assert(request.guid, "request guid can not be nil")
    assert(request.seller_guid, "request seller_guid can not be nil")
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local guid = request.guid
    local query_tbl = {seller_guid = request.seller_guid, status = "on_sale", price = request.price}
    if request.type == 1 then
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local merchadise = skynet.call(".db", "lua", "findOne", {
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    return merchadise
end

function ybexchange_core:buy(request)
    local coll_name = "ybmarket"
    local guid = request.guid
    local query_tbl = {seller_guid = request.seller_guid, status = "on_sale", price = request.price}
    if request.type == 1 then
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local doc = skynet.call(".db", "lua", "findAndModify", {
        collection = coll_name,
        query = query_tbl,
        update = { {["$set"] = { status = "buyed" }}}
    })
    local merchadise = doc.value
    if merchadise then
        self:send_sold_out_mail(merchadise)
        return merchadise
    end
end

function ybexchange_core:send_sold_out_mail(merchadise)
    local msg = string.contact_args("#{YBSC_MAIL_1", merchadise.price, merchadise.item_name)
    msg = msg .. "}"
    local mail = {}
    mail.guid = define.INVAILD_ID
    mail.source = ""
    mail.portrait_id = define.INVAILD_ID
    mail.dest_guid = merchadise.seller_guid
    mail.content = msg
    mail.flag = define.MAIL_TYPE.MAIL_TYPE_SYSTEM
    mail.create_time = os.time()
    skynet.send(".world", "lua", "send_mail_to_guid", mail)
end

function ybexchange_core:get_box_list(guid)
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local query_tbl = { seller_guid = guid  }
    local merchadise_list = skynet.call(".db", "lua", "findAll", {
         
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    merchadise_list = merchadise_list or {}
    local box_list = { items = {}, pets = {} }
    for _, merchadise in ipairs(merchadise_list) do
        if merchadise.type == 1 then
            table.insert(box_list.pets, merchadise)
        else
            table.insert(box_list.items, merchadise)
        end
    end
    return box_list
end

function ybexchange_core:get_sold_out_yuanbao(request)
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local query_tbl = {seller_guid = request.seller_guid, status = "buyed"}
    local guid
    if request.type == 1 then
        guid = request.item.attrib.guid
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        guid = request.item.guid
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local merchadise = skynet.call(".db", "lua", "findOne", {
         
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    if merchadise.type == 1 then
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local sql = { collection = coll_name, selector = query_tbl, single = true}
    skynet.call(".db", "lua", "delete", sql)
    return merchadise.item_name, merchadise.price
end

function ybexchange_core:take_back(merchadise)
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local query_tbl = {seller_guid = merchadise.seller_guid, status = "on_sale"}
    local guid
    if merchadise.type == 1 then
        guid = merchadise.item.attrib.guid
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        guid = merchadise.item.guid
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    merchadise = skynet.call(".db", "lua", "findOne", {
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    if merchadise.type == 1 then
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local sql = { collection = coll_name, selector = query_tbl, single = true}
    skynet.call(".db", "lua", "delete", sql)
    return merchadise
end

function ybexchange_core:expire_back(merchadise)
    local coll_name = "ybmarket"
    local selector = {["_id"] = false}
    local query_tbl = {seller_guid = merchadise.seller_guid, status = "off"}
    local guid
    if merchadise.type == 1 then
        guid = merchadise.item.attrib.guid
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        guid = merchadise.item.guid
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    merchadise = skynet.call(".db", "lua", "findOne", {
        collection = coll_name,
        query = query_tbl,
        selector = selector
    })
    if merchadise.type == 1 then
        query_tbl["item.attrib.guid.m_uHighSection"] = guid.m_uHighSection
        query_tbl["item.attrib.guid.m_uLowSection"] = guid.m_uLowSection
    else
        query_tbl["item.guid.server"] = guid.server
        query_tbl["item.guid.world"] = guid.world
        query_tbl["item.guid.series"] = guid.series
        query_tbl["item.guid.mask"] = 0
    end
    local sql = { collection = coll_name, selector = query_tbl, single = true}
    skynet.call(".db", "lua", "delete", sql)
    return merchadise
end

return ybexchange_core
