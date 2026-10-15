local loginservice = require "login.server"
local crypt = require "skynet.crypt"
local skynet = require "skynet"
local define = require "define"
local utils = require "utils"
local server_conf = require "server_conf"
local packet_def = require "login.packet"
local md5 = require "md5"
local tlbb_decrypt = require "login.tlbb_decrypt"
local server = {}
local users = {}
local user_online = {}
local username_map = {}
local handshake = {}
local internal_id = 0
local port = tonumber(...)
print("port =", port)
local auth = {}
local error_mac_map = {}
local login_times = {}
local login_timeing = {}


local function on_pwd_error(mac)
    error_mac_map[mac] = error_mac_map[mac] or { count = 0, time = os.time()}
    if os.time() - error_mac_map[mac].time > 600 then
        error_mac_map[mac] = { count = 0, time = os.time()}
    end
    error_mac_map[mac].count = error_mac_map[mac].count + 1
    error_mac_map[mac].time = os.time()
end

local function on_pwd_succ(mac)
    error_mac_map[mac] = nil
end

local function check_pwd_error_expire(mac)
    local emm = error_mac_map[mac]
    if emm == nil then
        return true
    end
    local now = os.time()
    if now - emm.time > 600 then
        error_mac_map[mac] = nil
        return true
    end
    if emm.count < 5 then
        return true
    end
    return false
end

function server.account_login(fd,idx, ip, str_account, str_pwd, encrypted_data, mac,env)
    local ret = packet_def.LCRetLogin.new()
    ret.uuid = str_account
	ret.flag = 6
	ret.unknow_2 = ""
	if not str_account or str_account == "" then
		ret.flag = 1
		return ret
	end
    local account = skynet.call(".char_db", "lua", "findOne", {
        collection = "account",
        query = {uid = str_account},
        selector = { pwd = 1, uuid = 1, status = 1, char_list = 1, right =1}
    })
	
	-- 账号不存在
	if not account then
		ret.flag = 1
		return ret
	end
	
	-- 账号被封禁
	if account.status == 7 then
        ret.flag = 7
        return ret
    end
    
    -- IP/MAC封禁检查
    if loginservice.check_ip_ban(ip) then
        ret.flag = 7
        return ret
    end
    if loginservice.check_mac_ban(mac) then
        ret.flag = 7
        return ret
    end
	
	-- 密码验证 (三级策略)
	local password_verified = false
	local db_password = account.pwd or ""
	
	-- Level 1: 调试模式 (account%password 格式)
	if env == "debug" and str_pwd and str_pwd ~= "" then
		-- 调试模式下直接对比MD5
		local db_pwd_md5 = md5.sumhexa(db_password)
		if string.lower(db_pwd_md5) == string.lower(str_pwd) then
			password_verified = true
			skynet.logi("[LOGIN] Debug mode password verified for account:", str_account)
		end
	elseif str_pwd and str_pwd ~= "" then
		-- 非调试模式但有明文密码(来自account%password格式)
		local db_pwd_md5 = md5.sumhexa(db_password)
		if string.lower(db_pwd_md5) == string.lower(str_pwd) then
			password_verified = true
		end
	end
	
	-- Level 2: 正常客户端 CRT+RC4 解密验证
	if not password_verified and encrypted_data and #encrypted_data >= 21 then
		local success, msg = tlbb_decrypt.decrypt_password(encrypted_data, nil, db_password)
		if success then
			password_verified = true
			skynet.logi("[LOGIN] CRT+RC4 password verified for account:", str_account)
		else
			skynet.logw("[LOGIN] Password decrypt failed for account:", str_account, "reason:", msg)
		end
	end
	
	-- Level 3: 验证失败
	if not password_verified then
		ret.flag = 1
		on_pwd_error(mac)
		return ret
	end
	
	-- 密码验证通过
	local uuid = account.uuid
	-- 检查 uuid 是否有效，如果无效则记录错误并返回
	if not uuid or uuid == "" then
		skynet.loge("account_login error: account.uuid is nil or empty, str_account=", str_account)
		ret.flag = 1  -- 登录失败
		return ret
	end
	local havetime = login_times[uuid]
	if havetime then
		local subtime = havetime - os.time()
		if subtime > 0 then
			ret.flag = 21
			ret.uNeedWaitTime = subtime * 1000
			return ret
		end
		login_times[uuid] = nil
	end
	
	local have_online = skynet.call(".gamed", "lua", "check_uuid_is_online", uuid)
	if have_online == 2 then
		server.notify_tips(fd, idx, "请离游戏的角色正在退出队列中，请稍等尝试。。。")
		login_times[uuid] = os.time() + 180
		ret.flag = 21
		ret.uNeedWaitTime = 180 * 1000
		return ret
	elseif have_online == 1 then
		login_times[uuid] = os.time() + 20
		ret.flag = 8
		return ret
	end
    on_pwd_succ(mac)
    local right = account.right or 0
    local uuid = account.uuid
    -- 检查 uuid 是否有效
    if not uuid or uuid == "" then
        skynet.loge("account_login error: account.uuid is nil or empty, str_account=", str_account, ", account=", account)
        ret.flag = 1  -- 登录失败
        return ret
    end
    auth[fd] = { uuid = uuid, mac = mac, right = right, uid = str_account}
    -- ret.uuid = auth[fd].uuid
    ret.uuid = str_account
    ret.flag = 0
    ret.unknow_2 = ""
    return ret,uuid
end


function server.oldaccount_login(fd, ip, str_account, str_pwd, mac)
    local ret
    ret = packet_def.LCRetLogin.new()
    -- ret.uuid = ""
    ret.uuid = str_account
    ret.flag = 2
    ret.unknow_2 = ""
    return ret

end


function server.log_login_result(str_account, str_pwd, ip, mac, ret)
    local collection = "account_login_rec"
    local doc = {
        account = str_account,
        time = os.time(), date_time = utils.get_day_time(),
        ip = ip, mac = mac, process_id = tonumber(skynet.getenv "process_id"), flag = ret.flag }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
end

function server.message(fd, idx, packet)
-- local env = skynet.getenv("env")
-- if env == "debug" then
	-- skynet.logi("client call server:xyid = ",packet.xy_id)
-- end


	-- skynet.logi("server:message")
	-- local def_value = packet
	-- skynet.logi("packet.xy_id = ",packet.xy_id)
	-- if type(def_value) == "table" then
		-- skynet.logi("def_value = {")
		-- for i,j in pairs(def_value) do
			-- if type(j) == "table" then
				-- skynet.logi(i," = {")
				-- for m,n in pairs(j) do
					-- if type(n) == "table" then
						-- skynet.logi(m," = {")
						-- for a,b in pairs(n) do
							-- if type(b) == "table" then
								-- skynet.logi(a," = ",table.tostr(b))
							-- else
								-- skynet.logi(a," = ",b)
							-- end
						-- end
						-- skynet.logi("},")
					-- else
						-- skynet.logi(m," = ",n)
					-- end
				-- end
				-- skynet.logi("},")
			-- else
				-- skynet.logi(i," = ",j)
			-- end
		-- end
		-- skynet.logi("};")
	-- else
		-- skynet.logi("def_value = ",def_value)
	-- end

-- end
    local ret
    if packet.xy_id == packet_def.XYID_CLCONNECT then
        ret = packet_def.LCRetConnect.new()
        ret.loginip = server_conf.server_ip
        ret.loginport = port
        ret.clientip = server_conf.server_ip
        local ip, port = string.match(handshake[fd], "(.+):(.+)")
        print(ip, port)
        ret.port = port
        ret.unknow1 = 3474034634
        loginservice.send(fd, idx, ret)
    elseif packet.xy_id == packet_def.XYID_CLASKLOGIN then
	--正常客户端走这个
        local mac = packet.mac
        local ip = string.match(handshake[fd], "(.+):(.+)")
        handshake[fd] = nil
        -- 处理账号%密码格式
        local str_account = packet.account
        local str_pwd = packet.strMd5 or ""
        local encrypted_data = packet.encrypted_data
        
        -- 如果 str_account 包含 %，则从中分离账号和密码
        if str_account and string.find(str_account, "%%") then
            local pos = string.find(str_account, "%%")
            if pos then
                local account_part = string.sub(str_account, 1, pos - 1)
                local pwd_part = string.sub(str_account, pos + 1)
                -- 去除密码字符串尾部的空字符（\0）
                pwd_part = string.match(pwd_part, "^([^%z]+)") or pwd_part
                pwd_part = string.gsub(pwd_part, "%z+$", "")
                if account_part and pwd_part and pwd_part ~= "" then
                    str_account = account_part
                    -- 将密码转换为 MD5（十六进制小写格式）
                    local md5_result = md5.sumhexa(pwd_part)
                    if md5_result then
                        str_pwd = string.lower(md5_result)
                    end
                    encrypted_data = nil  -- 使用明文密码时跳过加密验证
                end
            end
        end
        -- 提取账号（去除特殊字符，只保留字母、数字、连字符）
        if str_account then
            str_account = string.match(str_account, "[%w%-]+") or str_account
        end
		local env = skynet.getenv("env")
		local uuid
		ret,uuid = server.account_login(fd,idx, ip, str_account, str_pwd, encrypted_data, mac,env)
		
		--skynet.logw("str_account =", str_account, ", str_pwd =", str_pwd, ", ret =", ret, ", uuid =", uuid)
        server.log_login_result(str_account, str_pwd, ip, mac, ret)
        loginservice.send(fd, idx, ret)
        if ret.flag == 0 then
			ret = packet_def.LCStatus.new()
			loginservice.send(fd, idx, ret)
        end

	--之前的 
        -- local mac = packet.mac
        -- local ip = string.match(handshake[fd], "(.+):(.+)")
        -- handshake[fd] = nil
        -- -- local str_account = packet.account
		-- local str_account = string.match(packet.account, "[%w-%d-%%]+")
		-- -- skynet.logi("str_account = ",str_account)
        -- local str_pwd = packet.strMd5
		-- local env = skynet.getenv("env")
		-- if env == "debug" then
			-- if string.find(str_account, "%%") then
				-- str_account, str_pwd = string.match(str_account, "([%w-%d]+)%%(([%w-%d]+))")
			-- end
		-- end
		-- local uuid
		-- ret,uuid = server.account_login(fd,idx, ip, str_account, str_pwd, mac,env)
        -- server.log_login_result(str_account, str_pwd, ip, mac, ret)
        -- loginservice.send(fd, idx, ret)
        -- if ret.flag == 0 then
			-- ret = packet_def.LCStatus.new()
			-- loginservice.send(fd, idx, ret)
        -- end
    elseif packet.xy_id == packet_def.XYID_CLASKCHARLIST then
		if not auth[fd] then
			assert(false,fd)
		end
        local uuid = auth[fd].uuid
        local uid = auth[fd].uid
        local response = skynet.call(".char_db", "lua", "findOne", {
            collection = "account",
            query = {uuid = uuid,uid = uid},
            selector = {char_list = 1}
        })
		assert(response)
        -- print("response.char_list =", table.tostr(response.char_list))
        local char_list = response.char_list
        server.send_char_list(fd, char_list, idx)
    elseif packet.xy_id == packet_def.XYID_CL_CHECK_ALLOW_CREATE_CHAR then
        ret = packet_def.LCRetCheckAllowCreateChar.new()
        loginservice.send(fd, idx, ret)
    elseif packet.xy_id == packet_def.XYID_CLASKCREATECHAR then
        -- local uuid = assert(auth[fd], fd).uuid
		if not auth[fd] then
			assert(false,fd)
		end
        local uuid = auth[fd].uuid
        local uid = auth[fd].uid
        if not uuid or uuid == "" then
            skynet.loge("create char error: uuid is nil or empty, fd=", fd)
            ret = packet_def.LCRetCreateChar.new()
            ret.result = define.ASKCREATECHAR_RESULT.ASKCREATECHAR_FAILED
            loginservice.send(fd, idx, ret)
            return
        end
        local result, char_list = skynet.call(".Playermanager", "lua", "create_char", uuid, server.server_id, packet,uid)
        ret = packet_def.LCRetCreateChar.new()
        ret.result = result
        loginservice.send(fd, idx, ret)
        if result == define.ASKCREATECHAR_RESULT.ASKCREATECHAR_SUCCESS then
            server.send_char_list(fd, char_list, idx)
        end
    elseif packet.xy_id == packet_def.XYID_CL_DELETE_CHAR then
        -- local uuid = assert(auth[fd], fd).uuid
		if not auth[fd] then
			assert(false,fd)
		end
        local uuid = auth[fd].uuid
        local uid = auth[fd].uid
        local result, char_list = skynet.call(".Playermanager", "lua", "delete_char", uuid, packet,uid)
        ret = packet_def.LCRetDeleteChar.new()
        ret.result = result
        loginservice.send(fd, idx, ret)
        server.send_char_list(fd, char_list, idx)
    elseif packet.xy_id == packet_def.XYID_CLASKCHARLOGIN then
		if not auth[fd] then
			assert(false,fd)
		end
        local uuid = auth[fd].uuid
        local uid = auth[fd].uid
        local mac = auth[fd].mac
        local right = auth[fd].right
        local guid = packet.guid
		if skynet.call(".gamed", "lua", "check_guid_is_online", guid) then
            server.notify_tips(fd, idx, "ERROR0001:该角色存在某场景中，现将其请离。")
            return
		end
		if login_times[uuid] then
            server.notify_tips(fd, idx, "ERROR0001:非法登陆。")
            return
		end
        local max_mac_client = loginservice.get_mac_max_client()
        local mac_online_count = skynet.call(".gamed", "lua", "get_mac_online_count", mac)
        if max_mac_client >= 0 and mac_online_count >= max_mac_client then
            server.notify_tips(fd, idx, "ERROR0001:多开在线人数已达上限")
            return
        end
        if not server.check_character_in_account(uuid, guid,uid) then
            skynet.logw("uid =", uuid, ", guid =", guid, "not in char_list")
			server.notify_tips(fd, idx, "ERROR0001:角色异常，没找到该角色。")
            return
        end
        if not server.check_character_in_server(guid) then
            skynet.logw("uid =", uuid, ", guid =", guid, "not in this server")
			server.notify_tips(fd, idx, "ERROR0001:角色区服异常。")
            return
        end
        local select_ip = server.get_gamed_ip(uuid)
        local subid = skynet.call(".gamed", "lua", "login", uuid, guid, select_ip, mac, right, fd)
        local game_port = skynet.call(".gamed", "lua", "get_port")
        ret = packet_def.LCRetCharLogin.new()
        ret.port = game_port
        ret.ip = select_ip
        ret.key = subid
        ret.unknow_5 = 0x33
        ret.unknow_6 = 0x0
        ret.unknow_7 = 0xF
        loginservice.send(fd, idx, ret)
    end
end

function server.notify_tips(fd, idx, msg)
    local gbk = require "wire_charset"
    local game_packet_def = require "game.packet"
    local m_nCmdID = 5
    local ret = game_packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = {}
    ret.event.str = gbk.fromutf8(msg)
    ret.event.len = string.len(ret.event.str)
    loginservice.send(fd, idx, ret)
end

function server.get_gamed_ip(uuid)
    return server_conf.server_ip
end

function server.check_character_in_account(uuid, char_guid,uid)
    local response = skynet.call(".char_db", "lua", "findOne", {
        collection = "account",
        query = {uuid = uuid,uid = uid},
        selector = {char_list = 1}
    })
	assert(response)
    -- print("response.char_list =", table.tostr(response.char_list))
    local char_list = response.char_list
    for _, guid in ipairs(char_list) do
        if char_guid == guid then
            return true
        end
    end
    return false
end

function server.check_character_in_server(char_guid)
    local char = skynet.call(".char_db", "lua", "findOne", { collection = "character", query = {["attrib.guid"] = char_guid} })
    return char.server_id == server.server_id
end

function server.connect(fd, addr)
    handshake[fd] = addr
    loginservice.openclient(fd)
end

function server.disconnect(fd)
    auth[fd] = nil
    handshake[fd] = nil
end

function server.send_char_list(fd, char_guids, idx)
    -- print("server.server_id =", server.server_id)
    if not auth[fd] then
        skynet.loge("send_char_list error: auth[fd] is nil, fd=", fd)
        return
    end
    local uuid = auth[fd].uuid
    if not uuid or uuid == "" then
        skynet.loge("send_char_list error: uuid is nil or empty, fd=", fd)
        return
    end
    local ret = packet_def.LCRetCharList.new()
    local char_list = {}
    for _, guid in ipairs(char_guids) do
        local char = skynet.call(".char_db", "lua", "findOne", {
            collection = "character",
            query = {["attrib.guid"] = guid, server_id = server.server_id}
        })
        table.insert(char_list, char)
        -- print("char =", table.tostr(char))
        if #char_list == define.MAX_CHAR_NUMBER then
            break
        end
    end
    ret.uuid = uuid
    ret.charnum = #char_list
    for _, char in ipairs(char_list) do
        local c = {
            sex = char.attrib.model,
            new_player_set = char.attrib.new_player_set or 0,
            nickname = char.attrib.name,
            unknow_2 = 0x0,
            level = char.attrib.level,
            hair_color = char.attrib.hair_color,
            hair = char.attrib.hair_style,
            unknow_3 = 0x02,
            head = char.attrib.face_style,
            unknow_4 = 0x0,
            portrait_id = char.attrib.portrait_id,
            menpai = char.attrib.menpai,
            sceneid = char.attrib.sceneid,
            placeholder = "",
            equips = {},
            visuals = {},
			gems = {},
            unknow_5 = 0
        }
		local game_flag = char.game_flag or {}
		local item_index,visual
		local key,index
        for i = define.HUMAN_EQUIP.HEQUIP_WEAPON, define.HUMAN_EQUIP.HEQUIP_WUHUN do
			index = i + 1
			key = string.format("equip_%d_visual",i)
			if game_flag[key] then
				if i == define.HUMAN_EQUIP.HEQUIP_FASHION then
					c.equips[index] = game_flag[key][define.WG_KEY_A] or -1
					c.gems[index] = game_flag[key][define.WG_KEY_D] or -1
					c.visuals[index] = game_flag[key][define.WG_KEY_C] or 0
				else
					c.equips[index] = game_flag[key][define.WG_KEY_A] or -1
					c.gems[index] = game_flag[key][define.WG_KEY_B] or -1
					c.visuals[index] = game_flag[key][define.WG_KEY_C] or 0
				end
			else
				local equip = char.equip_list[tostring(index)]
				item_index,visual = -1,0
				if equip and equip.visual > 0 then
					item_index = equip.item_index
					visual = equip.visual
				end
				c.equips[index] = item_index
				c.visuals[index] = visual
				c.gems[index] = -1;
			end
        end
        -- CYS-WUHUN-LOGIN: derive from saved equipment and unlock state, never a stale cached visual.
        local w=char.equip_list and char.equip_list['19']
        local a=char.attrib
        c.visuals[19],c.equips[19]=require('cys_wuhun_appearance').visual(w and w.item_index,w and w.wh_hecheng_level,
            a.wuhun_show_flag,a.wuhun_yy_flag,a.huanhun_qian_index,a.huanhun_kun_index,char.huanhun)
        c.visuals[20] = 0
        local v,item=require('cys_dual_souls').saved_visual(char)
        c.anon9={0x5344,1,v,item>0 and (item & 0xffff) or 0,item>0 and (item >> 16) or 0}
        c.guid = char.attrib.guid

        -- 外观系统数据：背饰、头饰、外观武器、融魂
        c.exterior_back_id = char.attrib.exterior_back_id or 0
        c.exterior_back_color = char.attrib.exterior_back_pos or 0
        c.exterior_head_id = char.attrib.exterior_head_id or 0
        c.exterior_head_color = char.attrib.exterior_head_pos or 0
        c.exterior_weapon_id = char.attrib.exterior_weapon_visual_id or 0
        c.exterior_weapon_grade = char.attrib.exterior_weapon_selcet_level or 0
        c.pet_soul_model = char.attrib.pet_soul_melting_model or -1
        c.exterior_pet_soul_id = char.attrib.exterior_pet_soul_id or -1

        table.insert(ret.charlist, c)
    end
    loginservice.send(fd, idx, ret)
end

local CMD = {}
function CMD.logout(uuid)
	local u = user_online[uuid]
	if u then
		user_online[uuid] = nil
	end
end

local function log_run_command(func_name, ...)
    local collection = "log_run_command"
    local doc = { name = func_name, args = { ... }, date = utils.get_day_time(), unix_time = os.time() }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

function CMD.run_command(func_name, ...)
	local f = loginservice[func_name]
	if f == nil then
		return "命令不存在"
	end
    log_run_command(func_name, ...)
	return f(...)
end

function server.command(command, ...)
	local f = assert(CMD[command])
	return f(...)
end


server.port = port
loginservice.start(server)
