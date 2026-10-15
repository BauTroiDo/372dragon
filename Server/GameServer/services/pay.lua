local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local cjson = require "cjson"
cjson.encode_sparse_array(true)
local cluster = require "skynet.cluster"
local string = string
local zlib = require "zlib"
local md5 = require "md5"
local agents = {}

local port, mode, protocol = ...
protocol = protocol or "http"
local SERVICE_NAME = "pay"
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

local urls = {
	"https://open.qianjimiao.cn/intf/wpay.html",
	"https://open.qianjimiao.cn/intf/wapzpay.html",
	"https://open.qianjimiao.cn/intf/spay.html",
	"https://open.qianjimiao.cn/intf/dpay.html",
	"https://open.qianjimiao.cn/intf/wapspay.html",
	"https://open.qianjimiao.cn/intf/wapwpay.html",
	"https://open.qianjimiao.cn/intf/wapali.html",
}

local function get_order(tbl)
    local account = tbl.account
    local money = tbl.money
	local method = tbl.method
    if account == nil then
		return "账号不能为空"
    end
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account",query = {uid = account},selector = {}})
    if response == nil then
        return cjson.encode({ code = 1, result = "帐号不存在"})
    end
    local uuid = response.uuid
    if response == nil then
        return cjson.encode({ code = 2, result = "账号异常"})
    end
	method = tonumber(method)
	local url = urls[method]
	if url == nil then
        return cjson.encode({ code = 3, result = "未知充值方式"})
	end
    local date_str = os.date("%y%m%d%H%M%S")
    local order_id = string.format("%s%s", uuid, date_str)
    response = skynet.call(".char_db", "lua", "findOne",  {collection = "order",query = {id = order_id},selector = {}})
	if response then
        return cjson.encode({ code = 4, result = "生成订单失败"})
	end
	local order = {}
	order.uuid = uuid
	order.money = money
	order.order_id = order_id
    skynet.call(".char_db", "lua", "safe_insert", { collection = "order", doc = order})
	local custom_id = "16968720084787465"
	local custom_key = "f30f0d80cd9e672c3e08e38ebf330be9"
	local noticeurl = "http://116.62.69.206:13012/notify"
	local backurl = "http://116.62.69.206"
	local mark = account
	local str = string.format("customerid=%d&sdcustomno=%s&orderAmount=%s&cardno=32&noticeurl=%s&backurl=%s%s", custom_id, order_id, money, noticeurl, backurl, custom_key)
	local signstr = md5.sumhexa(str)
	signstr = string.upper(signstr)
	local result = string.format("%s?customerid=%s&sdcustomno=%s&orderAmount=%s&cardno=32&noticeurl=%s&backurl=%s&sign=%s&mark=%s", url, custom_id, order_id, money, noticeurl, backurl, signstr, mark)
	print("str =", str, ";result =", result)
	return cjson.encode({code = 0, result = result})
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
			local jsonstr
			if method == "OPTIONS" then
				print("option request")
				jsonstr = cjson.encode({result = "unsupport method"})
			else
				if url == "/get_order" then
					local tbl = cjson.decode(body)
                    jsonstr = get_order(tbl)
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
skynet.start(function()
    local agent_count = 20
	for i = 1, agent_count do
		agents[i] = skynet.newservice(SERVICE_NAME, port, "agent", "http")
	end
	local balance = 1
	print("pay port=", port)
	local id = socket.listen("127.0.0.1", port)

	skynet.dispatch("lua", function(_, _, command, ...)
		local f = assert(CMD[command])
		skynet.ret(skynet.pack(f(...)))
	end)

	socket.start(id , function(socket_id, addr)
		skynet.logi(string.format("pay:[%s] %s connected, pass it to agent :%08x",os.date(),addr, agents[balance]))
		skynet.send(agents[balance], "lua", "handle_socket", socket_id)
		balance = balance + 1
		if balance > #agents then
			balance = 1
		end
	end)
end)

end