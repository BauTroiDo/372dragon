local skynet = require "skynet"
local cjson = require "cjson"
local crypt = require "skynet.crypt"
local gbk = require "wire_charset"
local cluster = require "skynet.cluster"
local class = require "class"
local utils = require "utils"
local packet_def = require "game.packet"
local define = require "define"
local server_conf = require "server_conf"
local xylogger_core = class("xylogger_core")

function xylogger_core:getinstance()
    if xylogger_core.instance == nil then
        xylogger_core.instance = xylogger_core.new()
    end
    return xylogger_core.instance
end

function xylogger_core:init()
    self.delta_time = 60
    self.xy_counts = {}
    self.user_xy_counts = {}
    skynet.timeout(self.delta_time * 100, function()
        self:safe_message_update()
    end)
end

function xylogger_core:log(guid, xy)
    guid = guid or define.INVAILD_ID
    if xy then
        self.xy_counts[xy] = self.xy_counts[xy] or 0
        self.xy_counts[xy] = self.xy_counts[xy] + 1
        self.user_xy_counts[guid] = self.user_xy_counts[guid] or {}
        self.user_xy_counts[guid][xy] = self.user_xy_counts[guid][xy] or 0
        self.user_xy_counts[guid][xy] = self.user_xy_counts[guid][xy] + 1
    end
end

function xylogger_core:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        skynet.logw("xylogger_core:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function xylogger_core:message_update(delta_time)
    self:log_xy_counts()
    self:log_user_xy_counts()
end

function xylogger_core:log_xy_counts()
    local xy_counts = {}
    for xy, count in pairs(self.xy_counts) do
        table.insert(xy_counts, { xy = xy, count = count})
    end
    table.sort(xy_counts, function(x1, x2) return x1.count > x2.count end)
    local collection = "log_xy_counts"
    for i = 1, 20 do
        local xy_count = xy_counts[i]
        if xy_count then
            local doc = { date_time = utils.get_day_time(), unix_time = os.time(), xy = xy_count.xy, count = xy_count.count  }
            skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
        end
    end
    self.xy_counts = {}
end

function xylogger_core:log_user_xy_counts()
    local user_xy_counts = {}
    for guid, xys in pairs(self.user_xy_counts) do
        local xy_count = 0
        for _, count in pairs(xys) do
            xy_count = xy_count + count
        end
        table.insert(user_xy_counts, { guid = guid, xy_count = xy_count, xys = xys})
    end
    table.sort(user_xy_counts, function(x1, x2) return x1.xy_count > x2.xy_count end)
    local collection = "log_user_xy_counts"
    for i = 1, 100 do
        local user_xy_count = user_xy_counts[i]
        if user_xy_count then
            local guid = user_xy_count.guid
            local xy_counts= {}
            for xy, count in pairs(user_xy_count.xys) do
                table.insert(xy_counts, { xy = xy, count = count})
            end
            table.sort(xy_counts, function(x1, x2) return x1.count > x2.count end)
            for i = 1, 20 do
                local xy_count = xy_counts[i]
                if xy_count then
                    local doc = { date_time = utils.get_day_time(), unix_time = os.time(), guid = guid, xy = xy_count.xy, count = xy_count.count  }
                    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
                end
            end
        end
    end
    self.user_xy_counts = {}
end

return xylogger_core