local skynet = require "skynet"
require "skynet.manager"
local netpack = require "netpack"
local socketdriver = require "skynet.socketdriver"
local crypt = require "skynet.crypt"
local profile = require "skynet.profile"
local utils = require "utils"
--local datacenter = require "skynet.datacenter"

local gateserver = {}

local socket	-- listen socket
local queue		-- message queue
local maxclient	-- max client
local client_number = 0
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local nodelay = false
local port

local connection = {}
-- true : connected
-- nil : closed
-- false : close read
function gateserver.openclient(fd)
	if connection[fd] then
		socketdriver.start(fd)
	end
end

function gateserver.closeclient(fd)
	local c = connection[fd]
	if c ~= nil then
		connection[fd] = nil
		client_number = client_number - 1
		socketdriver.close(fd)
	end
end

function gateserver.get_connection_count()
	local count = 0
	for _ in pairs(connection) do
		count = count + 1
	end
	return count
end

function gateserver.get_record_connection_count()
	return client_number
end

function gateserver.get_max_client()
	return maxclient
end

function gateserver.start(handler)
	port = handler.port
	assert(handler.message)
	assert(handler.connect)
	assert(handler.kick)
	assert(handler.gen_connect_key)
	assert(handler.get_port)

	function CMD.init(conf)
		assert(not socket)
		local address = conf.address or "0.0.0.0"
		maxclient = conf.maxclient or 1024
		nodelay = conf.nodelay
		print(string.format("Listen on %s:%d", address, port))
		socket = socketdriver.listen(address, port)
		socketdriver.start(socket)
	end

	function CMD.close()
		assert(socket)
		handler.close()
		socketdriver.close(socket)
	end

	function CMD.kick(...)
		handler.kick(...)
	end

	function CMD.gen_connect_key(...)
		return handler.gen_connect_key(...)
	end

	function CMD.start_profile()
		local lua_profile = require "luaprofile"
		lua_profile.start()
	end

	function CMD.stop_profile()
		local lua_profile = require "luaprofile"
		local result = lua_profile.stop()
		local collection = "lua_profile"
		local doc = {
			address = skynet.self(),
			process_id = tonumber(skynet.getenv "process_id"),
			unix_time = os.time(),
			date_time = utils.get_day_time(),
			result = table.tostr(result),
		}
		skynet.logi("stop_profile doc =", table.tostr(doc))
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
	end

	function CMD.is_profiling()
		local lua_profile = require "luaprofile"
		return lua_profile.is_profiling()
	end

	local MSG = {}
	local function dispatch_msg(fd, id, sz, idx, msg)
		if connection[fd] then
			local message = netpack.tostring(msg, sz)
			if handler.message then
				handler.message(fd, id, idx, message)
			end
		else
			skynet.error(string.format("Drop message from fd (%d) : %s", fd, netpack.tostring(msg,sz)))
		end
	end

	MSG.data = dispatch_msg

	local function dispatch_queue()
		local fd, id, sz, idx, msg = netpack.pop(queue)
		if fd then
			-- may dispatch even the handler.message blocked
			-- If the handler.message never block, the queue should be empty, so only fork once and then exit.
			skynet.fork(dispatch_queue)
			dispatch_msg(fd, id, sz, idx, msg)

			for fd, id, sz, idx, msg in netpack.pop, queue do
				dispatch_msg(fd, id, sz, idx, msg)
			end
		end
	end

	MSG.more = dispatch_queue

	function MSG.open(fd, msg)
		print("MSG.open", fd, msg)
		if client_number >= maxclient then
			socketdriver.shutdown(fd)
			return
		end
		if nodelay then
			socketdriver.nodelay(fd)
		end
		connection[fd] = true
		client_number = client_number + 1
		handler.connect(fd, msg)
	end

	local function close_fd(fd)
		local c = connection[fd]
		if c ~= nil then
			connection[fd] = nil
			client_number = client_number - 1
		end
	end

	function MSG.close(fd)
		if handler.disconnect then
			handler.disconnect(fd)
		end
		close_fd(fd)
	end

	function MSG.error(fd, msg)
		if fd == socket then
			skynet.error("loginserver accept error:",msg)
		else
			socketdriver.shutdown(fd)
			if handler.error then
				handler.error(fd, msg)
			end
		end
	end

	function MSG.warning(fd, size)
		if handler.warning then
			handler.warning(fd, size)
		end
	end

	skynet.register_protocol {
		name = "socket",
		id = skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
		unpack = function ( msg, sz )
			profile.start()
			local result = {netpack.filter( queue, msg, sz)}
			local use_time = profile.stop()
			if use_time > 10 then
				skynet.logi("gamed slow log unpack use_time =", use_time)
			end
			return table.unpack(result)
		end,
		dispatch = function (_, _, q, type, ...)
			queue = q
			profile.start()
			if type then
				MSG[type](...)
			end
			local use_time = profile.stop()
			if use_time > 10 then
				skynet.logi("gamed slow log socket type =", type, ", use_time =", use_time)
			end
		end
	}
	skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			profile.start()
			if f then
				skynet.ret(skynet.pack(f(...)))
			else
				assert(handler[cmd], cmd)
				skynet.ret(skynet.pack(handler[cmd](...)))
			end
			local use_time = profile.stop()
			if use_time > 10 then
				skynet.logi("gamed slow log cmd =", cmd, ", use_time =", use_time)
			end
		end)
	end)
end

return gateserver