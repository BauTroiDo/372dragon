local skynet = require "skynet"
local gbk = require "wire_charset"
local class = require "class"
local define = require "define"
local utils = require "utils"
local packet_def = require "game.packet"
local Net = require "net":getinstance()
local ma_func = class("ma_func")
local delta_time = 100
local eRightNum = {
    ban = 0,
    limit_exchange = 1,
}
function ma_func:on_enter_scene(my_scene, my_obj_id,my_scene_id)
    self.my_scene_id = my_scene_id
    self.my_scene = my_scene
    self.my_obj_id = my_obj_id
    self.check_heart_beat = false
    self.no_heart_beat_count = 0
    self.save_data_tick = 0
	self.agent_tick = 0
	self.del_obj_flag = false
	self.is_exiting = false
end

function ma_func:get_del_obj_flag()
	return self.del_obj_flag
end

function ma_func:set_my_gate(gate)
    self.my_gate = gate
end

function ma_func:get_my_data()
    return self.my_data
end

function ma_func:set_my_data(my_data)
    self.my_data = my_data
end

function ma_func:set_uuid(uuid)
    self.uuid = uuid
end

function ma_func:set_right(right)
    self.right = right
end

function ma_func:get_my_agent()
    return skynet.self()
end

function ma_func:check_right_ban()
    local bit = (0x1 << eRightNum.ban)
    return self.right & bit == bit
end

function ma_func:check_right_limit_exchange()
    local bit = (0x1 << eRightNum.limit_exchange)
    local limit_change = self.right & bit == bit
	if limit_change then
		return true
	else
		local zhu_bo_flag = self.my_data.game_flag.zhu_bo_flag or 0
		if zhu_bo_flag ~= 0 then
			return true
		end
		local def_player_flag = self.my_data.game_flag.def_player_flag or 0
		if def_player_flag == 189 then
			def_player_flag = 0
		end
		if def_player_flag ~= 0 then
			return true
		end
		
		
	end
end

function ma_func:check_card_exchange(my_scene, my_obj_id)
    local enddate = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_mission_data_by_script_id", 533)
    if enddate == 0 then
        return false
    end
    enddate = tostring(enddate)
    local tbl = {}
    tbl.year = tonumber(string.sub(enddate, 1, 2)) + 2000
    tbl.month = tonumber(string.sub(enddate, 3, 4))
    tbl.day = tonumber(string.sub(enddate, 5, 6))
    local endtime = os.time(tbl) + 24 * 60 * 60
    local now = os.time()
    return endtime >= now
end

function ma_func:set_game_ip(game_ip)
    self.game_ip = game_ip
end

function ma_func:get_game_ip()
    return self.game_ip
end

function ma_func:get_minor_password()
    return self.my_data.minor_password
end

function ma_func:set_minor_password(minor_password)
    self.my_data.minor_password = minor_password
    local updater = {}
    updater["$set"] = {minor_password = minor_password}
    skynet.send(".char_db", "lua", "update", { collection = "character", selector = {["attrib.guid"] = self.my_guid}, update = updater})
end

function ma_func:set_minor_password_is_unlock()
    self.minor_password_is_unlock = true
end

function ma_func:is_minor_password_is_unlock()
    if self.my_data.minor_password == nil then
        return true
    end
    return self.minor_password_is_unlock
end

function ma_func:get_top_up_point()
    local r, err = pcall(self.convert_top_up_point, self)
    if not r then
        skynet.loge("convert_top_up_point error =", err)
    end
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account", query = {uuid = self.uuid}, selector = {top_up_point = 1}})
    return response.top_up_point or 0
end

function ma_func:convert_top_up_point()
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account", query = {uuid = self.uuid}, selector = {uid = 1}})
    if response and response.uid then
		local env = skynet.getenv("env")
		local sql
        local point = 0
		local server_id = self.my_data.server_id or 0
		if env == "publish_xws" then
			sql = string.format("SELECT point, uid, unix_time, money FROM `webpay`.`ordersny` WHERE `uid` = '%s' and `status` = 0 and `server_id` = '%d'", response.uid,server_id)
			local records = skynet.call(".mysqldb", "lua", "query", sql)
			for _, record in ipairs(records) do
				-- skynet.logi("convert_top_up_point record =", table.tostr(record))
				sql = string.format("UPDATE `webpay`.`ordersny` SET `status`= 1 WHERE `uid` = '%s' AND `unix_time` = %d", record.uid, record.unix_time)
				local result = skynet.call(".mysqldb", "lua", "query", sql)
				-- skynet.logi("convert_top_up_point result =", table.tostr(result))
				point = point + record.point
				skynet.send(".payend", "lua", "sync_mysql_pay", record.uid, record.money)
			end
		elseif env == "publish_xhz" then
			sql = string.format("SELECT point, uid, unix_time, money FROM `xrxwebpay`.`order` WHERE `uid` = '%s' and `status` = 0 and `server_id` = '%d'", response.uid,server_id)
			local records = skynet.call(".mysqldb", "lua", "query", sql)
			for _, record in ipairs(records) do
				-- skynet.logi("convert_top_up_point record =", table.tostr(record))
				sql = string.format("UPDATE `xrxwebpay`.`order` SET `status`= 1 WHERE `uid` = '%s' AND `unix_time` = %d", record.uid, record.unix_time)
				local result = skynet.call(".mysqldb", "lua", "query", sql)
				-- skynet.logi("convert_top_up_point result =", table.tostr(result))
				point = point + record.point
				skynet.send(".payend", "lua", "sync_mysql_pay", record.uid, record.money)
			end
		else
			sql = string.format("SELECT point, uid, unix_time, money FROM `webpay`.`order` WHERE `uid` = '%s' and `status` = 0 and `server_id` = '%d'", response.uid,server_id)
			local records = skynet.call(".mysqldb", "lua", "query", sql)
			for _, record in ipairs(records) do
				-- skynet.logi("convert_top_up_point record =", table.tostr(record))
				sql = string.format("UPDATE `webpay`.`order` SET `status`= 1 WHERE `uid` = '%s' AND `unix_time` = %d", record.uid, record.unix_time)
				local result = skynet.call(".mysqldb", "lua", "query", sql)
				-- skynet.logi("convert_top_up_point result =", table.tostr(result))
				point = point + record.point
				skynet.send(".payend", "lua", "sync_mysql_pay", record.uid, record.money)
			end
		end
        local updater = {}
        updater["$inc"] = { top_up_point = point }
        local result = skynet.call(".char_db", "lua", "safe_update", { collection = "account", selector = { uuid = self.uuid}, update = updater, upsert = false, multi = false})
        -- skynet.logi("result =", table.tostr(result))
    end
end

function ma_func:get_prerechage_money(begin, stop)
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "account", query = {uuid = self.uuid}, selector = {uid = 1}})
	local env = skynet.getenv("env")
    if response and response.uid then
		local sql 
        local money = 0
		if env == "publish_xws" then
			sql = string.format("SELECT point, uid, unix_time, money FROM `webpay`.`ordersny` WHERE `uid` = '%s' and `unix_time` >= %d and `unix_time` < %d ", response.uid, begin, stop)
		elseif env == "publish_xhz" then
			sql = string.format("SELECT point, uid, unix_time, money FROM `xrxwebpay`.`order` WHERE `uid` = '%s' and `unix_time` >= %d and `unix_time` < %d ", response.uid, begin, stop)
		elseif env == "publish_xrx" then
			sql = string.format("SELECT point, uid, unix_time, money FROM `webpay`.`orderwm` WHERE `uid` = '%s' and `unix_time` >= %d and `unix_time` < %d ", response.uid, begin, stop)
		else
			sql = string.format("SELECT point, uid, unix_time, money FROM `webpay`.`order` WHERE `uid` = '%s' and `unix_time` >= %d and `unix_time` < %d ", response.uid, begin, stop)
		end		
        local records = skynet.call(".mysqldb", "lua", "query", sql)
        for _, record in ipairs(records) do
            if record.point * 2 == record.money then
                money = money + record.money
            end
        end
        return money
    end
end

function ma_func:cost_top_up_point(cost)
    local point = self:get_top_up_point()
    if point < cost then
        return false
    end
    local updater = {}
    updater["$set"] = { top_up_point = point - cost }
    skynet.send(".char_db", "lua", "update", { collection = "account", selector = { uuid = self.uuid}, update = updater, upsert = false, multi = false})
    local doc = { time = os.time(), uuid = self.uuid, cost = cost, before = point, after =  point - cost, guid = self:get_guid(), name = self:get_name(), date_time = utils.get_day_time() }
    skynet.send(".char_db", "lua", "insert", { collection = "toppoint_cost", doc = doc})
    return true
end

function ma_func:set_my_guid(guid)
    self.my_guid = guid
end

function ma_func:get_guid()
    return self.my_data.attrib.guid
end

function ma_func:get_name()
    return self.my_data.attrib.name
end

function ma_func:get_guild_id()
    return self.my_data.attrib.guild_id
end

function ma_func:get_my_scene()
    return self.my_scene
end

function ma_func:get_my_scene_id()
    return self.my_scene_id
end

function ma_func:get_obj_id()
    return self.my_obj_id
end

function ma_func:get_server_id()
    return self.my_data.server_id
end

function ma_func:get_minor_password()
    return self.my_data.minor_password
end

function ma_func:get_my_guid()
    return self.my_guid
end

function ma_func:get_login_user()
    return self.my_data.game_flag.login_user
end


function ma_func:set_guild_id(id)
    self.my_data.attrib.guild_id = id
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_guild_id", id)
end

function ma_func:set_guild_name(name)
    self.my_data.attrib.guild_name = name
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_guild_name", name)
end

function ma_func:set_confederate_id(id)
    self.my_data.attrib.confederate_id = id
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_confederate_id", id)
end

function ma_func:set_confederate_name(name)
    self.my_data.attrib.confederate_name = name
    skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_confederate_name", name)
end

function ma_func:get_copy_scene_sn(destsceneid)
    local scene = string.format(".SCENE_%d", destsceneid)
    return skynet.call(scene, "lua", "get_sn")
end

function ma_func:set_quit_tick(tick)
    self.quit_tick = tick
end

function ma_func:do_quit()
	self:leave_scene()
    local ret = packet_def.GCRetAskQuit.new()
    ret.flag = 0
    self:send2client(ret)
    self:ExitComplete()
end

function ma_func:do_quit_ex()
	self:leave_scene()
    -- local ret = packet_def.GCRetAskQuit.new()
    -- ret.flag = 0
    -- self:send2client(ret)
    self:ExitComplete()
end

function ma_func:exit_ex()
	self.is_exiting = true
	self:leave_scene_ex()
    skynet.fork(function()
        skynet.exit()
    end)
end

function ma_func:ExitComplete()
    -- self:notify_friends_offline()
	self.is_exiting = true
	if self.my_guid then
		pcall(self.notify_friends_offline, self)
		local r, err = xpcall(skynet.call, debug.traceback, ".world", "lua", "leave_world", self.my_guid)
		if not r then
			skynet.logw("ma_func:ExitComplete error =", err)
		end
		skynet.call(".gamed", "lua", "logout", self.my_guid)
	end
    skynet.fork(function()
        skynet.exit()
    end)
end



function ma_func:notify_tips(msg)
    local m_nCmdID = 5
    local ret = packet_def.GCScriptCommand.new()
    ret.m_nCmdID = m_nCmdID
    ret.event = {}
    ret.event.str = gbk.fromutf8(msg)
    ret.event.len = string.len(ret.event.str)
    self:send2client(ret)
end

function ma_func:send_operate_result_msg(result)
    local msg = packet_def.GCOperateResult.new()
    msg.result = result
    self:send2client(msg)
end

function ma_func:send2client(msg)
    Net:send(msg)
end

function ma_func:start_check_heart_beat()
    self.check_heart_beat = true
end

function ma_func:CGHeartBeat()
    self.no_heart_beat_count = 0
end

function ma_func:get_my_cur_data()
    if self.my_scene then
		-- skynet.logi("log:ma_func:get_my_cur_data guid = ",self.my_guid,"scene = ",self.my_scene)
        local data = skynet.call(self.my_scene, "lua", "get_my_save_data", self.my_guid,self.del_obj_flag)
        return data
    end
end

function ma_func:set_switch_scene_info(sceneid,world_pos)
    if self.my_scene and self.my_obj_id then
		skynet.call(self.my_scene, "lua", "set_switch_scene_info", self.my_obj_id, sceneid,world_pos)
	end
	self.my_data.attrib.sceneid = sceneid
    self.my_data.attrib.world_pos = world_pos
end

-- function ma_func:set_login_user(login_user)
    -- if self.my_scene and self.my_obj_id then
		-- skynet.call(self.my_scene, "lua", "set_login_user", self.my_obj_id,login_user)
	-- end
-- end

function ma_func:leave_scene()
    if self.my_scene then
		-- skynet.logi("log:ma_func:leave_scene guid = ",self.my_guid,"scene = ",self.my_scene)
        local data = skynet.call(self.my_scene, "lua", "leave", self.my_guid,self.del_obj_flag)
        self:save_my_data(data,"leave_scene")
    end
end

function ma_func:leave_scene_ex()
    if self.my_scene then
		-- skynet.logi("log:ma_func:leave_scene guid = ",self.my_guid,"scene = ",self.my_scene)
        local data = skynet.call(self.my_scene, "lua", "leave", self.my_guid,self.del_obj_flag)
        self:save_my_data_ex(data)
    end
end

function ma_func:logout()
    skynet.call(".gamed", "lua", "logout", self.my_guid)
end

function ma_func:save_my_data_ex(data)
    if data then
		if data.attrib.guid ~= self.my_guid then
			local collection = "log_save_my_data_ex"
			local doc = {
				error_msg = "多个角色服务存档GUID异常",
				data_guid = data.attrib.guid,
				ma_func_guid = self.my_guid,
				sceneid = self.my_scene_id,
				date_time = os.date("%y-%m-%d %H:%M:%S")
			}
			skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
			skynet.logi("log:多个角色服务存档GUID异常，请离游戏。my_guid = ",self.my_guid,"sceneid = ",self.my_scene_id)
			self.del_obj_flag = true
			return
		end
		local game_lv,game_agent = skynet.call(".gamed", "lua", "update_save_lv", self.my_guid)
		if not game_lv or game_lv ~= data.game_flag.save_lv then
			local collection = "log_save_my_data_ex"
			local doc = { 
				error_msg = "多个角色服务存档数据版本号异常",
				ma_func_guid = self.my_guid,
				game_lv = game_lv,
				data_lv = data.game_flag.save_lv,
				game_agent = game_agent,
				ma_func_agent = self:get_my_agent(),
				sceneid = self.my_scene_id,
				date_time = utils.get_day_time()
			}
			skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
			skynet.logi("log:多个角色服务存档数据版本号异常，请离游戏。my_guid = ",self.my_guid,"sceneid = ",self.my_scene_id)
			self.del_obj_flag = true
			return
		end
		self.del_obj_flag = true
        data.relation = self.my_data.relation
		data.game_flag.save_true = (data.game_flag.save_true or 0) + 1
        local updater = {}
        updater["$set"] = data
        skynet.call(".char_db", "lua", "update", {
            collection = "character",
            selector = {["attrib.guid"] = self.my_guid},
            update = updater,
            upsert = false,
            multi = false
        })
        data.server_id = self.my_data.server_id
        data.minor_password = self.my_data.minor_password
        self.my_data = data
		local collection = "log_save_my_data_ex"
		local doc = { 
			error_msg = "多个角色服务存档成功",
			ma_func_guid = self.my_guid,
			game_lv = game_lv,
			data_lv = data.game_flag.save_lv,
			game_agent = game_agent,
			ma_func_agent = self:get_my_agent(),
			sceneid = self.my_scene_id,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
    end
end

function ma_func:save_my_data(data,fun_name)
    if data then
		if data.attrib.guid ~= self.my_guid then
			local collection = "log_save_my_data"
			local doc = {
				fun_name = fun_name,
				error_msg = "存档GUID异常",
				data_guid = data.attrib.guid,
				ma_func_guid = self.my_guid,
				sceneid = self.my_scene_id,
				date_time = os.date("%y-%m-%d %H:%M:%S")
			}
			skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
			skynet.logi("log:存档GUID异常，请离游戏。my_guid = ",self.my_guid,"sceneid = ",self.my_scene_id)
			if fun_name ~= "leave_scene" then
				self:do_quit_ex()
			else
				self.del_obj_flag = true
			end
			return
		end
		local game_lv,game_agent = skynet.call(".gamed", "lua", "update_save_lv", self.my_guid)
		if not game_lv or game_lv ~= data.game_flag.save_lv then
			local collection = "log_save_my_data"
			local doc = { 
				fun_name = fun_name,
				error_msg = "存档数据版本号异常",
				ma_func_guid = self.my_guid,
				game_lv = game_lv,
				data_lv = data.game_flag.save_lv,
				game_agent = game_agent,
				ma_func_agent = self:get_my_agent(),
				sceneid = self.my_scene_id,
				date_time = utils.get_day_time()
			}
			skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
			skynet.logi("log:存档数据版本号异常，请离游戏。my_guid = ",self.my_guid,"sceneid = ",self.my_scene_id)
			if fun_name ~= "leave_scene" then
				self:do_quit_ex()
			else
				self.del_obj_flag = true
			end
			return
		end
		if fun_name == "leave_scene" then
			self.del_obj_flag = true
		end
        data.relation = self.my_data.relation
		data.game_flag.save_true = (data.game_flag.save_true or 0) + 1
        local updater = {}
        updater["$set"] = data
        skynet.call(".char_db", "lua", "update", {
            collection = "character",
            selector = {["attrib.guid"] = self.my_guid},
            update = updater,
            upsert = false,
            multi = false
        })
        data.server_id = self.my_data.server_id
        data.minor_password = self.my_data.minor_password
        self.my_data = data
    end
end

function ma_func:send_world(...)
    skynet.send(".world", ...)
end

function ma_func:message_update()
    skynet.timeout(delta_time, function() self:message_update() end)
    if self.is_exiting then return end
    local r, err = pcall(function()
        self.save_data_tick = (self.save_data_tick or 0) + 1
        self.agent_tick = (self.agent_tick or 0) + 1

        if self.agent_tick > 30 then
            self.agent_tick = 0
            local save_lv,game_agent = skynet.call(".gamed", "lua", "update_save_lv", self.my_guid)
            local ma_func_agent = self:get_my_agent()
            if game_agent ~= ma_func_agent then
                if game_agent == nil then
                    local collection = "log_agent_error"
                    local doc = {
                        fun_name = "message_update",
                        error_msg = "agent已注销，静默退出",
                        guid = self.my_guid,
                        curlv = save_lv,
                        game_agent = game_agent,
                        ma_func_agent = ma_func_agent,
                        date_time = utils.get_day_time()
                    }
                    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
                    self:exit_ex()
                    return
                end
                local data = self:get_my_data()
                local datalv = -1
                if data and data.game_flag then
                    datalv = data.game_flag.save_lv
                end
                local collection = "log_agent_error"
                local doc = { 
                    fun_name = "message_update",
                    error_msg = "同个角色存在多个服务",
                    guid = self.my_guid,
                    curlv = save_lv,
                    datalv = datalv,
                    game_agent = game_agent,
                    ma_func_agent = ma_func_agent,
                    date_time = utils.get_day_time()
                }
                skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
                self:exit_ex()
                return
            end
        end

        if self.save_data_tick > 300 then
            self.save_data_tick = 0
            if self.my_scene then
                local ok2, save_data = pcall(skynet.call, self.my_scene, "lua", "get_my_save_data", self.my_guid, self.del_obj_flag)
                if ok2 and save_data then
                    self:save_my_data(save_data,"message_update")
                else
                    skynet.logw("ma_func:get_my_save_data failed guid=", self.my_guid, "scene=", self.my_scene)
                end
            end
        end
        if self.check_heart_beat then
            self.no_heart_beat_count = self.no_heart_beat_count + 1
        else
            self.no_heart_beat_count = 0
            self.check_heart_beat = false
        end
        local conn_fd = Net:get_fd()
        if conn_fd == nil then
            self.disconnect_ticks = (self.disconnect_ticks or 0) + 1
            if self.disconnect_ticks > 30 then
                self:exit_ex()
                return
            end
        else
            self.disconnect_ticks = 0
        end
        if self.quit_tick then
            self.quit_tick = self.quit_tick - 1
            if self.quit_tick <= 0 then
                self:do_quit()
            end
        end
    end)
    if not r then
        skynet.logw("ma_func:message_update error =", err)
    end
end


function ma_func:start_timer()
    if not self.timer_is_start then
        skynet.timeout(delta_time, function()
            ma_func:message_update()
        end)
        self.timer_is_start = true
    end
end

return ma_func
