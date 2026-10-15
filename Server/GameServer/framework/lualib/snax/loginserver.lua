local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local anysocket = require "anysocket"
local crypt = require "skynet.crypt"
local table = table
local string = string
local assert = assert

--[[

Protocol:

	line (\n) based text protocol

	1. Server->Client : base64(8bytes random challenge)
	2. Client->Server : base64(8bytes handshake client key)
	3. Server: Gen a 8bytes handshake server key
	4. Server->Client : base64(DH-Exchange(server key))
	5. Server/Client secret := DH-Secret(client key/server key)
	6. Client->Server : base64(HMAC(challenge, secret))
	7. Client->Server : DES(secret, base64(token))
	8. Server : call auth_handler(token) -> server, uid (A user defined method)
	9. Server : call login_handler(server, uid, secret) ->subid (A user defined method)
	10. Server->Client : 200 base64(subid)

Error Code:
	400 Bad Request . challenge failed
	401 Unauthorized . unauthorized by auth_handler
	403 Forbidden . login_handler failed
	406 Not Acceptable . already in login (disallow multi login)

Success:
	200 base64(subid)
]]

local socket_error = {}
local function assert_socket(service, v, fd)
	if v then
		return v
	else
		skynet.error(string.format("%s failed: socket (fd = %d) closed", service, fd))
		error(socket_error)
	end
end

local function launch_slave(auth_handler,command_handler)
	local function auth(fd, addr)
		local challenge = crypt.randomkey()
		local secret = challenge
		local etoken = assert_socket("auth", anysocket.readline(fd),fd)
		print("token =",etoken)
		local token = crypt.base64decode(etoken)
		local ok, server, uid, pass, id, sdk, osv, version, session_key, login_channel =  pcall(auth_handler, token, addr)
		print("launch_slave", ok, server, uid, secret, pass, id,sdk,osv, version, session_key, login_channel)
		return ok, server, uid, secret, pass, id, sdk, osv, version, session_key, login_channel
	end

	local function ret_pack(ok, err, ...)
		if ok then
			return skynet.pack(err, ...)
		else
			if err == socket_error then
				return skynet.pack(nil, "socket error")
			else
				return skynet.pack(false, err)
			end
		end
	end

	local function auth_fd(fd,addr)
		skynet.error(string.format("connect from %s (fd = %d)", addr, fd))
		anysocket.start(fd, addr)	-- may raise error here
		local msg, len = ret_pack(pcall(auth, fd, addr))
		return msg, len
	end

	local function write(fd, text)
		anysocket.send(fd, text)
	end

	local function close(fd)
		anysocket.close(fd)
	end

	skynet.dispatch("lua", function(_,_,command, ...)
		print("slave dispatch command=", command)
		if type(command) == "string" then
			local args = { ... }
	        if command == "lua" then
				command = args[1]
	            table.remove(args, 1)
	        end
			if command == "write" then
				skynet.ret(skynet.pack(write(table.unpack(args))))
			elseif command == "close" then
				skynet.ret(skynet.pack(close(table.unpack(args))))
			else
				skynet.ret(skynet.pack(command_handler(command, table.unpack(args))))
			end
        else
			local ok, msg, len = pcall(auth_fd,command,...)
			if ok then
				skynet.ret(msg,len)
			else
				skynet.ret(skynet.pack(false, msg))
			end
        end
	end)
end

local user_login = {}
local function accept(conf, s, fd, addr)
	-- call slave auth
	print("accept1",fd, addr)
	print("s=", s)
	local ok, server, uid, secret, token, id,sdk, osv, version, session_key, login_channel = skynet.call(s, "lua",  fd, addr)
	print("ok=", ok, ";server=", server, ";uid=", uid, ";token=", token, ";version=", version, ";login_channel=", login_channel)
	if not ok then
		if ok ~= nil then
			skynet.call(s, "lua", "write", fd, "401 Unauthorized")
		end
		error(server)
	end
	print("accept2")
	if not conf.multilogin then
		if user_login[uid] then
			skynet.call(s, "lua", "write", fd, "401 Unauthorized")
			error(string.format("User %s is already login", uid))
		end

		user_login[uid] = true
	end
	print("accept3")
	local ok, err, domain, port = pcall(conf.login_handler, server, uid, secret, addr, token, id,sdk,osv,version, session_key, login_channel)
	-- unlock login
	user_login[uid] = nil
	if ok then
		port = math.floor(tonumber(port))
		print("accept4",err, domain, port)
		err = err or ""
		local loginresult = err .. " " .. uid .. " " .. domain .. " " .. port
		print("loginresult =", loginresult)
		skynet.call(s, "lua", "write", fd, "200 "..crypt.base64encode(err .. " " .. uid .. " " .. domain .. " " .. port))
	else
		print("accept5")
		skynet.call(s, "lua", "write", fd,  "403 Forbidden")
		error(err)
	end
end

local server_conf
local function launch_master(conf)
	server_conf = conf
	skynet.dispatch("lua", function(_,_,command, ...)
		local args = { ... }
        if command == "lua" then
            command = args[1]
            table.remove(args, 1)
        end
		skynet.ret(skynet.pack(conf.command_handler(command, table.unpack(args))))
	end)
end

local init_login_server = function()
	local instance = server_conf.instance or 8
	assert(instance > 0)
	local host = server_conf.host or "0.0.0.0"
	local port = assert(tonumber(server_conf.port))
	local slave = {}
	local balance = 1
	for i=1,instance do
		table.insert(slave, skynet.newservice(SERVICE_NAME, port, server_conf.protocol))
	end

	skynet.error(string.format("login server listen at : %s %d", host, port))
	local id = socket.listen(host, port)
	socket.start(id , function(fd, addr)
		local s = slave[balance]
		balance = balance + 1
		if balance > #slave then
			balance = 1
		end
		local ok, err = pcall(accept, server_conf, s, fd, addr)
		if not ok then
			if err ~= socket_error then
				skynet.error(string.format("invalid client (fd = %d) error = %s", fd, err))
			end
		end
		skynet.sleep(100)  --suport ios platform
		skynet.call(s, "lua", "close", fd)
	end)
end

local function login(conf, protocol)
	local name = "." .. (conf.name or "wslogin")
	print("login socket protocol =>", protocol)
	anysocket.init(protocol)
	skynet.start(function()
		local loginmaster = skynet.localname(name)
		--print("name =>", name)
		if loginmaster then
			local auth_handler = assert(conf.auth_handler)
			local command_handler = assert(conf.command_handler)
			launch_master = nil
			conf = nil
			skynet.call(loginmaster, 'lua', 'launch_logind', skynet.self())
			launch_slave(auth_handler,command_handler)
		else
			launch_slave = nil
			conf.auth_handler = nil
			assert(conf.login_handler)
			assert(conf.command_handler)
			skynet.register(name)
			launch_master(conf)
		end
	end)
	return init_login_server
end

return login
