local skynet = require "skynet"
local netpack = require "netpack"
local socketdriver = require "skynet.socketdriver"
local crypt = require "skynet.crypt"

local loginserver = {}

local socket	-- listen socket
local queue		-- message queue
local maxclient	-- max client
local client_number = 0
local CMD = setmetatable({}, { __gc = function() netpack.clear(queue) end })
local nodelay = false
local port
local mac_max_client
local ip_limits = {}
local mac_limits = {}

local connection = {}
-- true : connected
-- nil : closed
-- false : close read

function loginserver.openclient(fd)
	if connection[fd] then
		socketdriver.start(fd)
	end
end

function loginserver.closeclient(fd)
	local c = connection[fd]
	if c ~= nil then
		connection[fd] = nil
		client_number = client_number - 1
		socketdriver.close(fd)
	end
end

function loginserver.send(fd, idx, packet)
	local message, size = packet:bos()
	print(crypt.hexencode(message), "size =", size)
	print("len =", string.len(message))
	--message = crypt.hexdecode("00000000950e000034372e3130312e3137352e3232320000000000000000000043fc000036302e3138382e3139342e31333800000000000000000000e3e433c8")
	message, size = netpack.pack(message, packet.xy_id, 0)
	print(message)
	socketdriver.send(fd, message, size)
end

local packets = {}
local function register_packets()
	local packet = require "login.packet"
	for name, p in pairs(packet) do
		if type(p) == "table" then
			p.name = name
			packets[p.xy_id] = p
		end
	end
end

local function unpack_message(id, message)
	local xy_id = id
	local p = packets[xy_id]
	if p then 
		p = p.new()
		p:bis(message)
		return p
	else
		print("unsupport xy_id =", xy_id)
	end
end

local function load_ip_limits()
	local response = skynet.call(".char_db", "lua", "findAll",  {collection = "ip_limit",query = nil, selector = {}})
    response = response or {}
	for _, x in ipairs(response) do
		ip_limits[x.ip] = true
	end
end

local function load_mac_limits()
	local response = skynet.call(".char_db", "lua", "findAll",  {collection = "mac_limit",query = nil, selector = {}})
    response = response or {}
	for _, x in ipairs(response) do
		mac_limits[x.mac] = true
	end
end

function loginserver.check_ip_ban(ip)
	return ip_limits[ip] ~= nil
end

function loginserver.check_mac_ban(mac)
	return mac_limits[mac] ~= nil
end

function loginserver.ban_ip(ip)
	if ip_limits[ip] == nil then
		ip_limits[ip] = true
		skynet.send(".char_db", "lua", "insert", { collection = "ip_limit", doc = { ip = ip}})
	end
	return string.format("ip = %s 已封禁", ip)
end

function loginserver.ban_mac(mac)
	if mac_limits[mac] == nil then
		mac_limits[mac] = true
		skynet.send(".char_db", "lua", "insert", { collection = "mac_limit", doc = { mac = mac}})
	end
	return string.format("mac = %s 已封禁", mac)
end

function loginserver.unlock_ip(ip)
	ip_limits[ip] = nil
	local query_tbl = { ip = ip }
    local sql = { collection = "ip_limit", selector = query_tbl}
    skynet.call(".char_db", "lua", "delete", sql)
	return string.format("ip = %s 已解禁", ip)
end

function loginserver.unlock_mac(mac)
	mac_limits[mac] = nil
	local query_tbl = { mac = mac }
    local sql = { collection = "mac_limit", selector = query_tbl}
    skynet.call(".char_db", "lua", "delete", sql)
	return string.format("mac = %s 已解禁", mac)
end

function loginserver.reload_ip_mac_limit()
	ip_limits = {}
	mac_limits = {}
	load_ip_limits()
	load_mac_limits()
end

function loginserver.get_mac_max_client()
	return mac_max_client
end

function loginserver.start(handler)
	port = handler.port
	assert(handler.message)
	assert(handler.connect)

	function CMD.init(conf)
		assert(not socket)
		local address = conf.address or "0.0.0.0"
		maxclient = conf.maxclient or 1024
		nodelay = conf.nodelay
		handler.server_id = conf.server_id
		mac_max_client = conf.mac_max_client or 12
		print(string.format("Listen on %s:%d", address, port))
		socket = socketdriver.listen(address, port)
		socketdriver.start(socket)
		register_packets()
		load_ip_limits()
		load_mac_limits()
	end

	function CMD.close()
		assert(socket)
		socketdriver.close(socket)
	end

	function CMD.set_mac_max_client(max)
		mac_max_client = max
	end

	local MSG = {}

	local function dispatch_msg(fd, id, sz, idx, msg)
		print(fd, id, sz, idx, msg)
		if connection[fd] then
			local message = netpack.tostring(msg, sz)
			local packet = unpack_message(id, message)
			print("recive packet =", packet.name, ";tbl =", table.tostr(packet))
			if handler.message then
				handler.message(fd, idx, packet)
			end
		else
			skynet.error(string.format("Drop message from fd (%d) : %s", fd, netpack.tostring(msg,sz)))
		end
	end

	MSG.data = dispatch_msg

	local function dispatch_queue()
		local fd, msg, sz = netpack.pop(queue)
		if fd then
			-- may dispatch even the handler.message blocked
			-- If the handler.message never block, the queue should be empty, so only fork once and then exit.
			skynet.fork(dispatch_queue)
			dispatch_msg(fd, msg, sz)

			for fd, msg, sz in netpack.pop, queue do
				dispatch_msg(fd, msg, sz)
			end
		end
	end

	MSG.more = dispatch_queue

	function MSG.open(fd, msg)
		print("MSG.open", fd, msg, client_number, maxclient)
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
			return netpack.filter( queue, msg, sz)
		end,
		dispatch = function (_, _, q, type, ...)
			queue = q
			if type then
				MSG[type](...)
			end
		end
	}
	skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			if f then
				skynet.ret(skynet.pack(f(...)))
			else
				skynet.ret(skynet.pack(handler.command(cmd, ...)))
			end
		end)
	end)
end

return loginserver