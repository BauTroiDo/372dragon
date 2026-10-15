local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local http_url = require "http.url"
local sockethelper = require "http.sockethelper"
local httpc = require "http.httpc"
local cjson = require "cjson"
cjson.encode_sparse_array(true)
local cluster = require "skynet.cluster"
local server_conf = require "server_conf"
local string = string
local zlib = require "zlib"
local md5 = require "md5"
local agents = {}

local port, mode, protocol = ...
protocol = protocol or "http"
local SERVICE_NAME = "payend"
local CMD = {}

if mode == "agent" then
	local custom_id = "16968720084787465"
	local custom_key = "f30f0d80cd9e672c3e08e38ebf330be9"
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
	
	local function check_sign(tbl)
		local str = string.format("customerid=%s&sd51no=%s&sdcustomno=%s&mark=%s&key=%s", tbl.customerid, tbl.sd51no, tbl.sdcustomno, tbl.mark, custom_key)
		local signstr = md5.sumhexa(str)
		signstr = string.upper(signstr)
		skynet.logi(string.format("check_sign str = %s, signstr = %s, tbl.sign = %s", str, signstr, tbl.sign))
		return tbl.sign == signstr
	end
	
	local function check_resign(tbl)
		local str = string.format("sign=%s&customerid=%s&ordermoney=%s&sd51no=%s&state=%d&key=%s", tbl.sign, tbl.customerid, tostring(tbl.ordermoney), tbl.sd51no, tbl.state, custom_key)
		local signstr = md5.sumhexa(str)
		signstr = string.upper(signstr)
		skynet.logi(string.format("check_resign str = %s, signstr = %s, tbl.sign = %s", str, signstr, tbl.resign))
		return tbl.resign == signstr
	end
	
	local function process_order(tbl)
		if not check_sign(tbl) then
			return false, "验证签名失败"
		end
		if not check_resign(tbl) then
			return false, "验证二次签名失败"
		end
		if tonumber(custom_id) ~= tonumber(tbl.customerid) then
			return false, "商户id不正确"
		end
		local order_id = tbl.sdcustomno
		local response = skynet.call(".char_db", "lua", "findOne", {collection = "order", query = {order_id = tostring(order_id)} ,selector = { uuid = 1, money = 1 }})
		print("response =", table.tostr(response))
		if response == nil then
			return false, "订单不存在"
		end
		local account = skynet.call(".char_db", "lua", "findOne",  {collection = "account", query = {uuid = response.uuid},selector = {}})
		print("account =", table.tostr(account))
		if account == nil then
			return false, string.format("发货异常 %s", tostring(response.uuid))
		end
		print("status =", response.status)
		if response.status ~= nil then
			return false, string.format("订单状态异常 status = %s", tostring(response.status))
		end
		if tbl.ordermoney * 100 ~= tonumber(response.money) then
			print(string.format("支付金额异常 order_id = %s, ordermoney = %s, money = %s", order_id, tbl.ordermoney, response.money))
		end
		do
			local updater = {}
			updater["$set"] = { status = tbl.state }
			skynet.call(".char_db", "lua", "update", { collection = "order", selector = {order_id = order_id},update = updater,upsert = false,multi = false})
		end
		local top_up_rate = 250
		local top_up_point = tbl.ordermoney * top_up_rate
		do
			local updater = {}
			updater["$inc"] = { top_up_point = top_up_point }
			skynet.call(".char_db", "lua", "update", { collection = "account", selector = {uuid = response.uuid}, update = updater, upsert = false, multi = false})
		end
		local host = "http://18.177.39.195:10181"
		local url = "/proxypay"
		local header = {}
		local data = cjson.encode({account = account.uid, money = tbl.ordermoney })
		local r, err = xpcall(httpc.request, debug.traceback, "POST", host, url, {}, header, data)
		skynet.logi("process_order r =", r, ", err =", err, ", host =", host, ", url =", url, ", header =", table.tostr(header), ", data =", table.tostr(data))
		if not r then
			skynet.loge("payend to proxypay error =", err)
		end
		return true, "<result>1</result>"
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
		print("code=", code, ";url=", url, ";method=", method, ";body=", body)
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
				local ret, response
				if method == "OPTIONS" then
					print("option request")
				else
					local path, arg_str = http_url.parse(url)
					if path == "/notify" then
						local tbl = http_url.parse_query(arg_str)
						ret, response = process_order(tbl)
					else
						skynet.logw("unsupport api request name=", url)
						response = "unsupport request"
					end
				end
				if need_zip then
					response = compress(response)
					header["Content-Encoding"] = "gzip"
				end
				skynet.logi("url =", url, "response =", response)
				if not ret then
					response = ""
				end
				CMD.response(id, interface.write, code, response, header)
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
	
	skynet.start(function ()
		skynet.dispatch("lua", function (_, _, command, ...)
			print("command=", command)
			local f = assert(CMD[command])
			skynet.ret(skynet.pack(f(...)))
		end)
	end)
	
else
	
	function CMD.sync_mysql_pay(uid, money)
		skynet.logi("sync_mysql_pay uid =", uid, ", money =", money)
		local config = server_conf.proxy_notify
		if config then
			local host = config.host
			local url = config.url
			local header = {}
			local data = cjson.encode({account = uid, money = string.format("%.1f", money) })
			local r, err = xpcall(httpc.request, debug.traceback, "POST", host, url, {}, header, data)
			skynet.logi("sync_mysql_pay r =", r, ", err =", err, ", host =", host, ", url =", url, ", header =", table.tostr(header), ", data =", table.tostr(data))
			if not r then
				skynet.loge("CMD.sync_mysql_pay payend to proxypay error =", err)
			end
		end
	end
	
	skynet.start(function ()
		local agent_count = 20
		for i = 1, agent_count do
			agents[i] = skynet.newservice(SERVICE_NAME, port, "agent", "http")
		end
		local balance = 1
		print("pay port=", port)
		local id = socket.listen("127.0.0.1", port)
		
		skynet.dispatch("lua", function (_, _, command, ...)
			local f = assert(CMD[command], command)
			skynet.ret(skynet.pack(f(...)))
		end)
		
		socket.start(id , function (socket_id, addr)
			skynet.logi(string.format("pay:[%s] %s connected, pass it to agent :%08x",os.date(),addr, agents[balance]))
			skynet.send(agents[balance], "lua", "handle_socket", socket_id)
			balance = balance + 1
			if balance > #agents then
				balance = 1
			end
		end)
	end)
	
end