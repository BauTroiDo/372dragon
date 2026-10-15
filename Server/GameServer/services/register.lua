local skynet = require "skynet"
local crypt = require "skynet.crypt"
local socket = require "skynet.socket"
local server_conf = require "server_conf"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local cjson = require "cjson"
cjson.encode_sparse_array(true)
local cluster = require "skynet.cluster"
local string = string
local utils = require "utils"
local zlib = require "zlib"
local agents = {}

local port, mode, protocol = ...
protocol = protocol or "http"
local SERVICE_NAME = "register"
local CMD = {}

if mode == "agent" then
function CMD.response(id, write, ...)
	local ok, err = httpd.write_response(write, ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local SSLCTX_SERVER = nil
local function gen_interface(protocol, fd)
	if protocol == "http" then
		return {
			init = nil,
			close = nil,
			read = sockethelper.readfunc(fd),
			write = sockethelper.writefunc(fd),
		}
	elseif protocol == "https" then
		local tls = require "http.tlshelper"
		if not SSLCTX_SERVER then
			SSLCTX_SERVER = tls.newctx()
			-- gen cert and key
			-- openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout server-key.pem -out server-cert.pem
			local certfile = skynet.getenv("certfile") or "./server-cert.pem"
			local keyfile = skynet.getenv("keyfile") or "./server-key.pem"
			print(certfile, keyfile)
			SSLCTX_SERVER:set_cert(certfile, keyfile)
		end
		local tls_ctx = tls.newtls("server", SSLCTX_SERVER)
		return {
			init = tls.init_responsefunc(fd, tls_ctx),
			close = tls.closefunc(tls_ctx),
			read = tls.readfunc(fd, tls_ctx),
			write = tls.writefunc(fd, tls_ctx),
		}
	else
		error(string.format("Invalid protocol: %s", protocol))
	end
end

local function response_need_zip(header)
	local ecs = header["accept-encoding"]
	if ecs then
		ecs = string.split(ecs, ",")
		for _, ec in ipairs(ecs) do
			ec = string.trim(ec)
			if ec == "gzip" then
				return true
			end
		end
	end
end

local function compress(str)
	local level = 5
	local windowSize = 15+16
	return zlib.deflate(level, windowSize)(str, "finish")
end

local function check_account(account)
    account = account or ""
	if #account == 0 then
		return false, "账号不能为空"
	end
	if #account < 5 or #account > 16 then
		return false, "账号长度为5-16位"
	end
	local numberCnt, letterCnt, specialCnt, otherCnt, UpperCnt = 0, 0, 0, 0, 0
	for s in string.gmatch(account, ".") do
		-- print(s)
        local ASCIICode = string.byte(s)
        if ASCIICode >= 48 and ASCIICode <= 57 then
            numberCnt = numberCnt + 1
        elseif (ASCIICode >= 65 and ASCIICode <= 90) or
            (ASCIICode >= 97 and ASCIICode <= 122) then
            letterCnt = letterCnt + 1
			if ASCIICode >= 65 and ASCIICode <= 90 then
				UpperCnt = UpperCnt + 1
			end
        elseif (ASCIICode >= 33 and ASCIICode <= 47) or (ASCIICode >= 58 and ASCIICode <= 64) or
                ASCIICode == 91 or (ASCIICode >= 93 and ASCIICode <= 96) or (ASCIICode >= 123 and ASCIICode <= 126) then
                    -- 转义字符（\ 92）要从特殊字符中剔除
                specialCnt = specialCnt + 1
        else
            otherCnt = otherCnt + 1
        end
    end
    if otherCnt > 0 then
        return false, "账号不能含有非法字符"
    elseif specialCnt > 0 then
        return false, "账号不能含有特殊字符"
	elseif UpperCnt > 0 then
		return false, "账号不能含有大写字母"
    end
    return true
end

local function check_password(pwd)
    pwd = pwd or ""
	if #pwd < 5 or #pwd > 500 then
		return false, "密码长度为5-16位"
	end
	local numberCnt, letterCnt, specialCnt, otherCnt = 0, 0, 0, 0
	for s in string.gmatch(pwd, ".") do
        local ASCIICode = string.byte(s)
        if ASCIICode >= 48 and ASCIICode <= 57 then
            numberCnt = numberCnt + 1
        elseif (ASCIICode >= 65 and ASCIICode <= 90) or (ASCIICode >= 97 and ASCIICode <= 122) then
                letterCnt = letterCnt + 1
        elseif (ASCIICode >= 33 and ASCIICode <= 47) or (ASCIICode >= 58 and ASCIICode <= 64) or ASCIICode == 91 or
            (ASCIICode >= 93 and ASCIICode <= 96) or (ASCIICode >= 123 and ASCIICode <= 126) then
                -- 转义字符（\ 92）要从特殊字符中剔除
                specialCnt = specialCnt + 1
        else
            otherCnt = otherCnt + 1
        end
    end
    if otherCnt > 0 then
        return false, "密码含有非法字符"
	elseif specialCnt > 0 then
        return false, "密码不能含有特殊字符"
    end
    return true
end

local function check_super_password(pwd)
    pwd = pwd or ""
	local numberCnt, letterCnt, specialCnt, otherCnt = 0, 0, 0, 0
	for s in string.gmatch(pwd, ".") do
        local ASCIICode = string.byte(s)
        if ASCIICode >= 48 and ASCIICode <= 57 then
            numberCnt = numberCnt + 1
        elseif (ASCIICode >= 65 and ASCIICode <= 90) or (ASCIICode >= 97 and ASCIICode <= 122) then
                letterCnt = letterCnt + 1
        elseif (ASCIICode >= 33 and ASCIICode <= 47) or (ASCIICode >= 58 and ASCIICode <= 64) or ASCIICode == 91 or
            (ASCIICode >= 93 and ASCIICode <= 96) or (ASCIICode >= 123 and ASCIICode <= 126) then
                -- 转义字符（\ 92）要从特殊字符中剔除
                specialCnt = specialCnt + 1
        else
            otherCnt = otherCnt + 1
        end
    end
    return true
end

local function get_ip_register_count(real_ip)
    local pipeline = {}
    local query_tbl = {ip = real_ip}
	local step = {["$group"] = {_id = false, ["count"] = {["$sum"] = 1}}}
    table.insert(pipeline, {["$match"] = query_tbl})
    table.insert(pipeline, step)
    local coll_name = "account"
    local result = skynet.call(".char_db", "lua", "runCommand", "aggregate",  coll_name, "pipeline", pipeline, "cursor", {},  "allowDiskUse", false)
    if result and result.ok == 1 then
        if result.cursor and result.cursor.firstBatch then
            local r = result.cursor.firstBatch[1]
            if r then
				return r["count"]
            end
        end
    end
	return 0
end

local function register(tbl, real_ip)
    local account_ok, account_err = check_account(tbl.account)
    if not account_ok then
        return cjson.encode({result = account_err})
    end
    local password_ok, passworld_err = check_password(tbl.password)
    if not password_ok then
        return cjson.encode({result = passworld_err})
    end
    local super_password_ok, super_password_err = check_super_password(tbl.super_password)
    if not super_password_ok then
        return cjson.encode({result = super_password_err})
    end
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uid = tbl.account},selector = {}})
    if response then
        return cjson.encode({result = "账号已存在"})
    end
	if real_ip then
		local count = get_ip_register_count(real_ip)
		if count > 100 then
			--return cjson.encode({result = "未知异常1"})
		end
	end
	local password = tostring(tbl.password)
	local super_password = tostring(tbl.super_password)
	if server_conf.password_salt then
		password = crypt.hexencode(crypt.sha1(password .. server_conf.password_salt))
		super_password = crypt.hexencode(crypt.sha1(super_password .. server_conf.password_salt))
	end

    local max_uuid = skynet.call(".register", "lua", "inc_uuid")
    local doc = { uid = tbl.account, pwd = password, super_pwd = super_password, uuid = tostring(max_uuid), char_list = {}, top_up_point = 0, status = 0, ip = real_ip, date = utils.get_day_time(), qq = tbl.qq}
    skynet.call(".char_db", "lua", "safe_insert", { collection = "account", doc = doc })
    return cjson.encode({result = string.format("注册成功,你的账号为%s,密码为*******, 超级密码为%s 请妥善保存", tbl.account, tbl.super_password) })
end

local function modify_password(tbl)
	tbl.account = tbl.account or ""
	tbl.super_password = tbl.super_password or ""
	if tbl.account == "" then
		return cjson.encode({result = "账号不能为空"})
	end
	if tbl.super_password == "" then
		return cjson.encode({result = "超级密码不能为空"})
	end
	local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uid = tbl.account},selector = { _id = 0}})
    if response == nil then
        return cjson.encode({result = "账号不存在"})
    end
	--print("response =", table.tostr(response), ",tbl =", table.tostr(tbl))
	if response.super_pwd ~= tbl.super_password then
        return cjson.encode({result = "超级密码不正确"})
	end
	local password_ok, passworld_err = check_password(tbl.password)
    if not password_ok then
        return cjson.encode({result = passworld_err})
    end
	local updater = {}
	local password = tostring(tbl.password)
	if server_conf.password_salt then
		password = crypt.hexencode(crypt.sha1(password .. server_conf.password_salt))
	end
    updater["$set"] = { pwd = password }
    skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uid = tbl.account},update = updater,upsert = false,multi = false})
	return cjson.encode({result = string.format("修改密码成功,你的新密码为%s 请妥善保存", tbl.password) })
end

function CMD.handle_socket(id)
	print("id=", id)
	socket.start(id)
	print("protocol=", protocol)

	local interface = gen_interface(protocol, id)
	if interface.init then
		interface.init()
	end
	-- limit request body size to 8192 (you can pass nil to unlimit)
	print("start read_request")
	local code, url, method, header, body = httpd.read_request(interface.read, 8192)
	header = header or {}
	local need_zip = response_need_zip(header)
	skynet.logi("code=", code, ";url=", url, ";method=", method, ";body=", body, ";header =", table.tostr(header))
	local real_ip = header["x-real-ip"]
	if code then
		header = {
			['Access-Control-Allow-Origin'] = '*',
			['Access-Control-Allow-Credentials'] = true,
			['Access-Control-Allow-Headers'] = '*'
		}
		if code ~= 200 then
			body = cjson.encode({result = "error code"})
			CMD.response(id, interface.write, code, body, header)
		else
			local jsonstr
			if method == "OPTIONS" then
				print("option request")
				jsonstr = cjson.encode({result = "unsupport method"})
			else
				if url == "/register" then
					local tbl = cjson.decode(body)
					skynet.logi("real_ip =", real_ip)
                    jsonstr = register(tbl, real_ip)
				elseif url == "/modify_password" then
					local tbl = cjson.decode(body)
					jsonstr = modify_password(tbl)
				else
					skynet.logw("unsupport api request name=", url)
					jsonstr = cjson.encode({result = "unsupport request"})
				end
			end
			if need_zip then
				jsonstr = compress(jsonstr)
				header["Content-Encoding"] = "gzip"
			end
			CMD.response(id, interface.write, code, jsonstr, header)
		end
	else
		if url == sockethelper.socket_error then
			skynet.error("socket closed")
		else
			skynet.error(url)
		end
	end
	socket.close(id)
	if interface.close then
		interface.close()
	end
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, command, ...)
		print("command=", command)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)
end)

else
local max_uuid
skynet.start(function()
    local agent_count = 20
	for i = 1, agent_count do
		agents[i] = skynet.newservice(SERVICE_NAME, port, "agent", "http")
	end
	local balance = 1
	print("register port=", port)
	local id = socket.listen("127.0.0.1", port)

	skynet.dispatch("lua", function(_, _, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)

	socket.start(id , function(socket_id, addr)
		skynet.logi(string.format("hs_config:[%s] %s connected, pass it to agent :%08x",os.date(),addr, agents[balance]))
		skynet.send(agents[balance], "lua", "handle_socket", socket_id)
		balance = balance + 1
		if balance > #agents then
			balance = 1
		end
	end)
end)

function CMD.init()
    local response = skynet.call(".char_db", "lua", "findAll",  {collection = "account",query = nil, selector = {["uuid"] = 1}, skip = 0})
    max_uuid = 100000
	for _, r in pairs(response or {}) do
		local r_uuid = tonumber(r.uuid)
		if r_uuid and r_uuid > max_uuid then
			max_uuid = r_uuid
		end
	end
	skynet.logi("register init finish max_uuid =", max_uuid)
end

function CMD.inc_uuid()
    max_uuid = max_uuid + 1
    return max_uuid
end

end