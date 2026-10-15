local skynet = require "skynet"
local crypt = require "skynet.crypt"
local netpack = require "netpack"
local socketdriver = require "skynet.socketdriver"
local class = require "class"
local utils = require "utils"
local net = class("net")
local REQUEST = {}

function net:getinstance()
    if net.instance == nil then
        net.instance = net.new()
    end
    return net.instance
end

function net:ctor()
    self.fd = nil
    self.idx = 0x7b
    self.packets = {}
    self.process_packets = {}
    self:register_packets()
end

function net:set_fd(fd)
	-- skynet.logi("net:set_fd:fd = ",fd)
    self.fd = fd
    self.last_idx = nil
end

function net:get_fd()
    return self.fd
end

function net:register_packets()
	local packet = require "game.packet"
	local table_count = 0
	local xyid_count = 0
	for name, p in pairs(packet) do
		if type(p) == "table" then
			assert(p.xy_id, string.format("xyid == nil name =%s", name))
			self.packets[p.xy_id] = { name = name, p = p}
			table_count = table_count + 1
		elseif type(p) == "number" then
			xyid_count = xyid_count + 1
		end
	end
end

function net:unpack_message_gate(id, idx, message)
    assert(id > 0, "协议id必须大于0")
	local p = self.packets[id]
    if p then
        local packet = p.p
        local name = p.name
		local request = packet.new()
		request:bis(message)
		
		return name, request
	else
        local r, err = pcall(self.check_is_record_xy, self, idx, "unsupport xy", {})
        if not r then
            skynet.loge("check_is_record_xy error =", err)
        end
	end
end

function net:unpack_message(id, idx, message)
    assert(id > 0, "协议id必须大于0")
	local p = self.packets[id]
	if p then
        local packet = p.p
        local name = p.name
		local request = packet.new()
		request:bis(message)
        local r, err = xpcall(self.check_is_record_xy, debug.traceback, self, idx, name, request)
        if not r then
            -- skynet.loge("check_is_record_xy error =", err)
        end
        -- print("unpack_message id =", id, ";idx =", self.last_idx, ";name =", p.name, ";message =", crypt.hexencode(message))
		return name, request
	else
        local r, err = pcall(self.check_is_record_xy, self, idx, "unsupport xy", {})
        if not r then
            -- skynet.loge("check_is_record_xy error =", err)
        end
        -- print("unpack_message unsupport id =", id, ";idx =", self.last_idx)
	end
end

function net:check_is_record_xy(idx, request_name, request)
    local right = idx & 0xff
    local left = idx >> 8
    idx = right * 256 + left
    if self.last_idx then
        local diff = idx - self.last_idx
        if diff ~= 1 and self.last_idx ~= 255 then
            local ma_func = require "ma_func"
            local guid = ma_func:get_guid()
            local name = ma_func:get_name()
            local collection = "record_xy_rec"
            local doc = { guid = guid, name = name, request_name = request_name,
            request = request, unix_time = os.time(), date_time = utils.get_day_time(),
            idx = idx, last_idx = self.last_idx, process_id = tonumber(skynet.getenv "process_id")}
            skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
        else
            self.last_idx = idx
        end
    else
        self.last_idx = idx
    end
end

function net:dispatch_message(...)
    local xy_id, idx, packet, uname = ...
    local name, request = self:unpack_message(xy_id, idx, packet)
    local filterd_request = self:filter_packet(name, request)
    if filterd_request then
        local f = REQUEST[name]
        if f then
            if name ~= "CGNetDelay" then
                -- print("dispatch_message ", name, ";tbl =", table.tostr(filterd_request), ";uname =", uname)
            end
            f(filterd_request)
        else
            -- print("unsupport process request =", name, ";tbl =", table.tostr(filterd_request))
        end
        -- local ma_func = require "ma_func"
        -- local guid = ma_func:get_guid()
        self.process_packets[name] = { packet = request, time = os.time() }
            --skynet.send(".xylogger", "lua", "log", guid, name)
    else
        -- skynet.logi("dispatch_message filter_packet name =", name, ";request =", table.tostr(request))
    end
end

function net:dispatch_server_client_message(name, request)
    local f = REQUEST[name]
    if f then
        if name ~= "CGNetDelay" then
            print("dispatch_message ", name, ";tbl =", table.tostr(request))
        end
        f(request)
    else
        print("unsupport process request =", name, ";tbl =", table.tostr(request))
    end
    -- local ma_func = require "ma_func"
    -- local guid = ma_func:get_guid()
    --skynet.send(".xylogger", "lua", "log", guid, name)
end

local define = require "define"

function net:send(packet)
    if self.fd then
        local p = self.packets[packet.xy_id]
		
		local env = skynet.getenv("env")
		if env == "debug" then
			-- if not define.CESHI_XYID[packet.xy_id] then
				-- -- local ma_func = require "ma_func"
				-- -- local guid = ma_func:get_my_guid()
				-- -- skynet.logi("server call client:xy_id = ",packet.xy_id,"guid = ",guid,"date = ",utils.get_day_time())
				-- skynet.logi("server call client:xy_id = ",packet.xy_id)
			-- end
		end
        -- if p.name ~= "GCRetNetDelay" and p.name ~= "GCCharBaseAttrib" then
            -- skynet.logi("net send name =", p.name, ";xy_id =", packet.xy_id, ";idx =", self.idx, ";tbl =", table.tostr(packet))
        -- end
        local stream = packet:bos()
        local message, size = netpack.pack(stream, packet.xy_id, self.idx * 0x100)
        socketdriver.send(self.fd, message, size)
        self.idx = self.idx + 1
        -- local ma_func = require "ma_func"
        -- local guid = ma_func:get_guid()
        --skynet.send(".xylogger", "lua", "log", guid, p.name)
    end
end

function net:send2client(xyid, data, my_obj_id)
    -- print("send2client self.fd =", self.fd)
    if self.fd then
        local p = self.packets[xyid]
        local packet = p.p
        local msg = packet.new()
        setmetatable(data, {__index = msg})
        if p.name ~= "GCRetNetDelay" and p.name ~= "GCCharBaseAttrib" then
            -- print("net send name =", p.name, ";xy_id =", packet.xy_id, ";idx =", self.idx, ";tbl =", table.tostr(data))
        end
        local stream = data:bos()
        local message, size = netpack.pack(stream, packet.xy_id, self.idx * 0x100)
        socketdriver.send(self.fd, message, size)
        self.idx = self.idx + 1
        -- local ma_func = require "ma_func"
        -- local guid = ma_func:get_guid()
        --skynet.send(".xylogger", "lua", "log", guid, p.name)
    end
end

function net:add_requests(request)
    for name, f in pairs(request) do
        REQUEST[name] = f
    end
end

local compare_packet_func = function(process_packet, packet)
    if packet.equal == nil then
        return false
    end
    local last_packet = process_packet.packet
    local last_time = process_packet.time
    local now = os.time()
    if last_time ~= now then
        return false
    end
    return packet:equal(last_packet)
end

function net:filter_packet(packet_name, packet)
    return packet
end

return net
