local skynet = require "skynet"
local crypt = require "skynet.crypt"
local cluster = require "skynet.cluster"
local class = require "class"
local utils = require "utils"
local monitor_core = class("monitor_core")

function monitor_core:getinstance()
    if monitor_core.instance == nil then
        monitor_core.instance = monitor_core.new()
    end
    return monitor_core.instance
end

function monitor_core:init()
    self.delta_time = 100 * 60
    self.last_log_cluster_world_user_count_time = 0
    self.last_log_yunabo_blance = nil --self:get_last_log_yunabo_blance()
    self.last_log_tianwai_bi_count_time = 0
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
        self:log_cluster_world_user_count()
    end)
end

function monitor_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        print("monitor_core:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function monitor_core:message_update(delta_time)
    self:log_cluster_world_user_count(delta_time)
    self:log_yunabo_blance(delta_time)
    self:log_tianwai_bi_blance(delta_time)
end

function monitor_core:log_cluster_world_user_count()
    local now = os.time()
    if now - self.last_log_cluster_world_user_count_time > 60 then
        self.last_log_cluster_world_user_count_time = now
        local collection = "log_online_count"
        local total_online_count = 0
        local node_list = utils.get_cluster_specific_server_by_server_alias(".world")
        for _, node in pairs(node_list) do
            local online_count = cluster.call(node, ".world", "get_online_users_count")
            total_online_count = total_online_count + online_count
            local doc = { node = node, online_count = online_count, date_time = utils.get_day_time(), unix_time = os.time()}
            skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
        end
        local doc = { node = "总计在线人数", online_count = total_online_count, date_time = utils.get_day_time(), unix_time = os.time()}
        skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
    end
end

function monitor_core:log_yunabo_blance()
    if self.last_log_yunabo_blance == nil then
        self.last_log_yunabo_blance = self:get_last_log_yunabo_blance()
    end
    local now = os.time()
    if now - self.last_log_yunabo_blance > 1 * 60 then
        local character_yuanbao = self:sum_character_yuanbao()
        local coll_name = "log_yuanbao_blance"
        local doc = { desc = "玩家持有元宝数量", num = character_yuanbao,  date_time = utils.get_day_time(), unix_time = os.time()}
        skynet.send(".logdb", "lua", "insert", { collection = coll_name, doc = doc})
        local yuanbao_exchanges = self:sum_yuanbao_exchanges(self.last_log_yunabo_blance )
        print("character_yuanbao =", character_yuanbao, ";yuanbao_exchanges =", table.tostr(yuanbao_exchanges))
        for _, exchange in ipairs(yuanbao_exchanges) do
            doc = { desc = exchange.reason, num = exchange.count,  date_time = utils.get_day_time(), unix_time = os.time()}
            skynet.send(".logdb", "lua", "insert", { collection = coll_name, doc = doc})
        end
        self.last_log_yunabo_blance = now
    end
end

function monitor_core:sum_character_yuanbao()
    local pipeline = {}
    local query_tbl = {}
	local step = {["$group"] = {_id = false, ["count"] = {["$sum"] = "$attrib.yuanbao"}}}
    table.insert(pipeline, {["$match"] = query_tbl})
    table.insert(pipeline, step)
    local coll_name = "character"
    local result = skynet.call(".char_db", "lua", "runCommand", "aggregate",  coll_name, "pipeline", pipeline, "cursor", {},  "allowDiskUse", false)
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            local r = result.cursor.firstBatch[1]
            if r then
				return r["count"]
            end
        end
    end
	return {}
end

function monitor_core:sum_yuanbao_exchanges(start_time)
    local exchanges = {}
    local pipeline = {}
    local query_tbl = {["unix_time"] = {["$gte"] = start_time},  ["coin_type"] = "元宝"}
	local step = {["$group"] = {_id = "$reason", ["count"] = {["$sum"] = "$num"}}}
    table.insert(pipeline, {["$match"] = query_tbl})
    table.insert(pipeline, step)
    local coll_name = "log_money_rec"
    local result = skynet.call(".logdb", "lua", "runCommand", "aggregate",  coll_name, "pipeline", pipeline, "cursor", {},  "allowDiskUse", false)
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            for _, batch in ipairs(result.cursor.firstBatch) do
                local reason = batch["_id"]
                local count = batch["count"]
                table.insert(exchanges, { reason = reason, count = count})
            end
        end
    end
	return exchanges
end

function monitor_core:get_last_log_yunabo_blance()
    local coll_name = "log_yuanbao_blance"
    local response = skynet.call(".logdb", "lua", "findAll",  {collection = coll_name, query = nil, selector = nil, skip = 0, sorter = { {["unix_time"] = -1} }, limit = 1})
    return response and response["unix_time"] or 0
end

function monitor_core:log_tianwai_bi_blance()
    local now = os.time()
    if now - self.last_log_tianwai_bi_count_time > 3600 then
        self.last_log_tianwai_bi_count_time = now
        self:log_tianwai_bi_blance_by_type("$bank_bag_list")
        self:log_tianwai_bi_blance_by_type("$prop_bag_list")
    end
end

function monitor_core:log_tianwai_bi_blance_by_type(by_type)
    local pipeline = {}
	local step_project = {["$project"] = {["dictionaryArray"] = { ["$objectToArray"] = by_type}, ["attrib.guid"] = 1}}
    local step_unwind = {["$unwind"] = "$dictionaryArray"}
    local step_add_fields = {["$addFields"] = {["dictionaryArray.v.player_id"] = "$attrib.guid"}}
    local step_match = {["$match"] = {["$or"] = { {["dictionaryArray.v.item_index"] = 38008157}, {["dictionaryArray.v.item_index"] = 38008158}}}}
    local step_group = { ["$group"] = { ["_id"] = "$dictionaryArray.v.item_index", ["total_count"] = {["$sum"] = "$dictionaryArray.v.lay_count"}}}
    table.insert(pipeline, step_project)
    table.insert(pipeline, step_unwind)
    table.insert(pipeline, step_add_fields)
    table.insert(pipeline, step_match)
    table.insert(pipeline, step_group)
    local coll_name = "character"
    local result = skynet.call(".char_db", "lua", "runCommand", "aggregate",  coll_name, "pipeline", pipeline, "cursor", {},  "allowDiskUse", false)
    print("log_tianwai_bi_blance_by_type by_type =", by_type, ";result =", table.tostr(result))
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            print("log_tianwai_bi_blance_by_type by_type =", by_type, ";firstBatch =", table.tostr(result.cursor.firstBatch))
            for i = 1, 2 do
                local r = result.cursor.firstBatch[i]
                if r then
                    local doc = { by_type = by_type, id = r["_id"], total_count = r["total_count"], date_time = utils.get_day_time(), unix_time = os.time()}
                    skynet.send(".logdb", "lua", "insert", { collection = "log_tianwai_bi_count", doc = doc})
                end
            end
        end
    end
end

return monitor_core