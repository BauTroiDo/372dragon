local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mc = require "skynet.multicast"
local queue = require "skynet.queue"
local Net = require "net":getinstance()
local server_conf = require "server_conf"
local define = require "define"
local utils = require "utils"
local configenginer = require "configenginer":getinstance()
local packet_def = require "game.packet"
local ma_func = require "ma_func"
require "ma_relation"
require "ma_guild"
local CMD = {}
local request = {}
local my_scene
local my_obj_id
local my_client_res
local my_connect_key
local world_chat_channel
local guild_multicast_channel
local confederate_multicast_channel
local scene_chat_channel
local menpai_chat_channel
local change_scene_args
local change_scene_generation = 0
local team_follow_sync_generation = 0
local last_heartbeat_trace_time = 0
local auction_box_list
local world_chat_retry_scheduled = false

local function timeout_call(timeout, addr, ...)
    local co = coroutine.running()
    local ret = nil
    local timed_out = false
    skynet.fork(function(...)
        local r = table.pack(pcall(skynet.call, addr, "lua", ...))
        if not timed_out then
            ret = r
            skynet.wakeup(co)
        end
    end, ...)
    skynet.timeout(timeout, function()
        if ret == nil then
            timed_out = true
            skynet.wakeup(co)
        end
    end)
    skynet.wait(co)
    if ret then
        return table.unpack(ret)
    end
    return false, "timeout"
end
local function init_world_multicast()
    -- [FIX] 先取消旧订阅，防止重复订阅（幂等保护）
    if world_chat_channel then
        world_chat_channel:unsubscribe()
        world_chat_channel = nil
    end

    local channel_id = datacenter.get("channels", "world_chat_channel")
    -- [FIX] channel_id 空检查，若为 nil 则等待 1s 后重试一次
    if not channel_id then
        if not world_chat_retry_scheduled then
            world_chat_retry_scheduled = true
            skynet.timeout(100, function()
                world_chat_retry_scheduled = false
                init_world_multicast()
            end)
        end
        return false
    end


    world_chat_channel = mc.new {
        channel = channel_id,
        dispatch = function (channel, source, ...)
            -- skynet.logi("channel =>", channel, "; source=>", source, ";... =>", ...)
            CMD.world_chat_channel_msg(...)
        end
    }
    world_chat_channel:subscribe()
    return true
end
local DEFAULT_EQUIP = {
    [define.WG_KEY_A] = -1,
    [define.WG_KEY_B] = -1,
    [define.WG_KEY_C] = 0
}
local DEFAULT_FASHION = {
    [define.WG_KEY_A] = -1,
    [define.WG_KEY_D] = -1,
    [define.WG_KEY_E] = -1,
    [define.WG_KEY_F] = -1,
    [define.WG_KEY_C] = 0
}

local direct_commands = {
	-- set_fd = true,
	set_game_ip = true,
	send2client = true,
	exit = true,
	on_user_guild_recruit_or_guild_expe_or_guild_leave = true,
	on_user_guild_position_changed = true,
	get_user_guild_id = true,
	char_enter_team_follow = true,
	char_stop_team_follow_self = true,
	char_del_team_follow_member = true,
	get_relation_list = true,
	set_realtion_list = true,
	on_guild_info_update = true,
	get_player_info = true,
	get_top_up_point = true,
	cost_top_up_point = true,
	get_prerechage_money = true,
	award_item = true,
	check_right_limit_exchange = true,
}

function CMD.set_fd(source, fd)
	-- skynet.logi("CMD:set_fd:source = ",source,"fd = ",fd)
    Net:set_fd(fd)
    ma_func:set_my_gate(source)
end

function CMD.set_game_ip(game_ip)
    ma_func:set_game_ip(game_ip)
end

function CMD.set_uuid(uuid)
    ma_func:set_uuid(uuid)
end

function CMD.set_right(right)
    ma_func:set_right(right)
end


local function on_notify_change_scene(notify)
    local pos = notify.world_pos or {}
    skynet.logi("[AUTO_ROUTE_NOTIFY_AGENT] guid=", tostring(ma_func:get_guid()),
        " from=", tostring(notify.scene_from), " to=", tostring(notify.scene_to),
        " x=", tostring(pos.x), " y=", tostring(pos.y),
        " enter_type=", tostring(notify.unknow_3),
        " client_res=", tostring(notify.client_res))
    change_scene_args = {}
    change_scene_args.sceneid = notify.scene_to
    change_scene_args.world_pos = notify.world_pos
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_start_change_scene", my_guid)
end

local function on_notify_raid_result(packet)
    if my_scene then
        return skynet.call(my_scene, "lua", "on_notify_raid_result", my_obj_id, packet)
    end
end

local function on_notify_raid_list(packet)
    if my_scene then
        return skynet.call(my_scene, "lua", "on_notify_raid_list", my_obj_id, packet)
    end
end

local function on_notify_team_result(packet)
    if not my_scene or not my_obj_id then
        return true
    end
    local ok, ret = timeout_call(200, my_scene, "on_notify_team_result", my_obj_id, packet)
    if not ok or ret == nil then
        return true
    end
    return ret
end

local function on_notify_team_list(packet)
    if my_scene then
        return skynet.call(my_scene, "lua", "on_notify_team_list", my_obj_id, packet)
    end
end

local function on_notify_team_option_changed(packet)
    if my_scene then
        return skynet.call(my_scene, "lua", "on_notify_team_option_changed", my_obj_id, packet)
    end
end
function CMD.get_new_connection()

end

function CMD.load_my_data(guid,login_user,save_lv,agent)
	local addvalue = login_user + 1
	local my_data = skynet.call(".char_db", "lua", "findOne", {collection = "character", query = {["attrib.guid"] = guid} })
	if addvalue ~= 1 then
		local collection = "log_load_my_data"
		local doc = { 
		name = my_data.attrib.name,
		guid = guid,
		loadcount = addvalue,
		date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
	end
	my_data.game_flag = my_data.game_flag or {}
	my_data.game_flag.login_user = addvalue
	my_data.game_flag.agent = agent
	my_data.game_flag.sb_on_scene = -1
	if not save_lv then
		my_data.game_flag.save_lv = 0
	elseif my_data.game_flag.save_lv ~= save_lv then
		local collection = "log_load_my_data"
		local doc = { 
			fun_name = "load_my_data",
			error_msg = "加载数据版本号异常",
			guid = guid,
			name = my_data.attrib.name,
			curlv = save_lv,
			datalv = my_data.game_flag.save_lv,
			sceneid = my_data.attrib.sceneid,
			world_pos = my_data.attrib.world_pos,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		--暂时记录日志，不断言
		-- assert(false,"加载数据版本号不同步。")
	end
	if not my_data.game_flag.save_lv or not tonumber(my_data.game_flag.save_lv) then
		my_data.game_flag.save_lv = 1
	else
		my_data.game_flag.save_lv = my_data.game_flag.save_lv + 1
	end
	ma_func:set_my_guid(guid)
    ma_func:set_my_data(my_data)
	-- skynet.logi("load_my_data:guid = ",guid)
	return addvalue,my_data.game_flag.save_lv
end

function CMD.disconnect()
    skynet.logw("[CLIENT_LINK] disconnected guid=", ma_func:get_guid(), "scene=", my_scene, "obj=", my_obj_id)
    Net:set_fd(nil)
end

function CMD.send2client(...)
	-- local checkxy = true
    local xy_id, packet = ...
	
	-- local env = skynet.getenv("env")
	-- if env == "debug" then
		-- if not define.CESHI_XYID[xy_id] then
			-- -- local guid = ma_func:get_my_guid()
			-- -- skynet.logi("server call client:xy_id = ",xy_id,"guid = ",guid,"date = ",utils.get_day_time())
			-- skynet.logi("server call client:xy_id = ",xy_id)
		-- end
	-- end
	
    local ret = true
    if xy_id == packet_def.GCNotifyChangeScene.xy_id then
		local my_data = ma_func:get_my_data()
		if packet.scene_to == my_data.attrib.sceneid then
			local collection = "log_player_data"
			local doc = { 
			fun_name = "CMD:send2client",
			name = my_data.attrib.name,
			guid = my_data.attrib.guid,
			logmsg = {param1 = "场景号相同",param2 = packet.scene_to},
			date_time = utils.get_day_time()
			}
			skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
			-- checkxy = false
			-- assert(false,"CMD.send2client error!!!")
			assert(false,"场景号相同")
		else
			on_notify_change_scene(packet)
		end
    elseif xy_id == packet_def.GCRaidResult.xy_id then
        ret = on_notify_raid_result(packet)
    elseif xy_id == packet_def.GCRaidList.xy_id then
        on_notify_raid_list(packet)
    elseif xy_id == packet_def.GCTeamResult.xy_id then
        ret = on_notify_team_result(packet)
    elseif xy_id == packet_def.GCTeamList.xy_id then
        on_notify_team_list(packet)
    elseif xy_id == packet_def.GCTeamOptionChanged.xy_id then
        on_notify_team_option_changed(packet)
    end
    if ret then
        Net:send2client(xy_id, packet, my_obj_id)
    end
	-- assert(checkxy,"CMD.send2client error!!!")
end

function CMD.unpack_message(...)
    return Net:unpack_message(...)
end

function CMD.unpack_server_message(...)
    return Net:dispatch_server_client_message(...)
end

function request:CGConnect()
    local my_guid = ma_func:get_guid()
	-- skynet.logi("CGConnect:my_guid = ",my_guid)
    local my_data = ma_func:get_my_data()
    ma_func:start_timer()
	
    skynet.call(".world", "lua", "online", my_guid, { name = my_data.attrib.name,
	agent = skynet.self(), guid = my_guid, sceneid = my_data.attrib.sceneid,
        portrait_id = my_data.attrib.portrait_id, model = my_data.attrib.model,
		level = my_data.attrib.level, menpai = my_data.attrib.menpai,
        mood = my_data.relation.mood, exterior = 10124007
    })
    local ret = packet_def.KeyExchange.new()
    ret.data = {0, 0, 0, 0, 0, 0, 0, 0}
    Net:send(ret)
    ret = packet_def.GCConnect.new()
    ret.sceneid = my_data.attrib.sceneid
    ret.position.x = my_data.attrib.world_pos.x
    ret.position.y = my_data.attrib.world_pos.y
    ret.result = my_connect_key == self.key and 3 or 0
    ret.unknow = 0
    Net:send(ret)
    -- skynet.logi("666 handler.message CGConnect guid =", my_guid, ", now =", os.time())
end

local function subscribe_scene_multicast(channel_id)
    if scene_chat_channel then
        scene_chat_channel:unsubscribe()
    end
    scene_chat_channel = mc.new {
        channel = channel_id,
        dispatch = function (channel, source, ...)
            CMD.scene_chat_channel_msg(...)
        end
    }
    scene_chat_channel:subscribe()
end

local function subscribe_menpai_multicast(menpai)
    if menpai_chat_channel then
        menpai_chat_channel:unsubscribe()
    end
    if menpai ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI then
        local channel_id = datacenter.get("channels", string.format("menpai_%d_channel", menpai))
        menpai_chat_channel = mc.new {
            channel = channel_id,
            dispatch = function (channel, source, ...)
                CMD.menpai_chat_channel_msg(...)
            end
        }
        menpai_chat_channel:subscribe()
    end
end

local function subscribe_guild_multicast(guild_id)
    if guild_multicast_channel then
        guild_multicast_channel:unsubscribe()
    end
    guild_id = guild_id or define.INVAILD_ID
    if guild_id ~= define.INVAILD_ID then
        local channel_id = datacenter.get("channels", string.format("guild_chat_channel_%d",guild_id))
        if channel_id then
            guild_multicast_channel = mc.new {
                channel = channel_id,
                dispatch = function (channel, source, ...)
                    CMD.guild_multicast_channel(...)
                end
            }
            guild_multicast_channel:subscribe()
        end
    end
end

local function subscribe_confederate_multicast(confederate_id)
    if confederate_multicast_channel then
        confederate_multicast_channel:unsubscribe()
    end
    confederate_id = confederate_id or define.INVAILD_ID
    if confederate_id ~= define.INVAILD_ID then
        local channel_id = datacenter.get("channels", string.format("league_chat_channel_%d", confederate_id))
        if channel_id then
            confederate_multicast_channel = mc.new {
                channel = channel_id,
                dispatch = function (channel, source, ...)
                    CMD.league_multicast_channel(...)
                end
            }
            confederate_multicast_channel:subscribe()
        end
    end
end



function request:CGRankingLists()
	skynet.send(my_scene, "lua", "char_ranking_lists", my_obj_id, self)

    -- local ret = packet_def.WGCRetNormalRankList.new()
	-- Net:send(ret)
end

function request:CGAskDynamicRegion()
    local ret = packet_def.GCAskDynamicRegionResult.new()
    Net:send(ret)
end

function request:CGExecuteScript()
	if not self.m_ScriptID or not self.m_szFunName then
		return
	end
	local index =self.m_ScriptID -- tostring(self.m_szFunName).."_"..tostring(self.m_ScriptID)
	local configs = configenginer:get_config("allowable_script_fun")
	if configs[index] then
		skynet.send(my_scene, "lua", "char_excute_Script", self.m_ScriptID, self.m_szFunName, my_obj_id, table.unpack(self.m_aParam))
		 --return self.scriptenginer:raw_call(script_id, func, ...)
	else
	    local cnt = 0; if configs then for _ in pairs(configs) do cnt = cnt + 1 end end
	end
end

function request:CGNetDelay()
    local ret = packet_def.GCRetNetDelay.new()
    Net:send(ret)
end

function request:CGAskQuit()
    if self.unknow_2 == 0 then
        -- PHAI dung skynet.call: skynet.send tra nil => set_quit_tick(nil) => KHONG dem
        -- nguoc => nhan vat KHONG roi scene (bot/nguoi thuc "logout khong hieu luc").
        local tick = skynet.call(my_scene, "lua", "get_quit_tick")
        ma_func:set_quit_tick(tick)
    elseif self.unknow_2 == 1 then
        ma_func:set_quit_tick(nil)
    end
end

function request:CGShopBuy()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.send(my_scene, "lua", "char_shop_buy", my_obj_id, self)
end

function request:CGShopClose()
end

function request:CGAskDetailAttrib()
    skynet.send(my_scene, "lua", "ask_detail_attrib", my_obj_id, self)
end

function request:CGCharAskBaseAttrib()
    skynet.send(my_scene, "lua", "ask_base_attrib", self.m_objID, my_obj_id)
end

function request:CGCharAskEquipment()
    skynet.send(my_scene, "lua", "ask_char_equipment", self.m_objID, my_obj_id)
end

function request:CGCharAskImpactList()
    skynet.send(my_scene, "lua", "ask_impact_list", self.m_objID, my_obj_id)
end

function request:CGUseItem()
    -- local baglist = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_item_bag_list")
    -- if baglist then
        -- local bagIndex = self.bagIndex
        -- local item_row = baglist[bagIndex]
        -- if item_row then
            -- if item_row.item_index == 30501036 then
                -- skynet.logi("CGUseItem  guid =", ma_func:get_guid(), ";item =", table.tostr(item_row))
                -- if item_row.lay_count < 1 then
                    -- skynet.logi("CGUseItem guid =", ma_func:get_guid(), ";")
                -- end
            -- end
        -- end
    -- end
    skynet.send(my_scene, "lua", "char_use_item", my_obj_id, self)
end

function request:CGAskDetailAbilityInfo()
    skynet.send(my_scene, "lua", "ask_detail_ability_info", self.m_objID, my_obj_id)
end

function request:CGAskDetailXinFaList()
    skynet.send(my_scene, "lua", "ask_detail_xinfa_list", self.m_objID, my_obj_id)
end

function request:CGAskDetailSkillList()
    skynet.send(my_scene, "lua", "ask_detail_skill_list", self.m_objID, my_obj_id)
end

function request:CGAskJuqingPoint()
    local ret = packet_def.GCJuqingPoint.new()
    ret.unknow_1 = 0
    Net:send(ret)
end

function request:CGPetExteriorCollectionRequest()
    local ret = packet_def.GCPetExteriorCollectionInfo.new()
    ret.list = { -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }
    ret.type = 0
    ret.unknow_2 = -1
    Net:send(ret)
end

function request:CGWuhunWG()
    skynet.send(my_scene, "lua", "ask_wuhun_wg", my_obj_id, self)
end

function request:CGAskFashionDepotData()
    skynet.send(my_scene, "lua", "ask_fashion_depot_data", my_obj_id)
end

function request:CGAskServerTime()
    local ret = packet_def.GCAskServerTime.new()
    ret.secneid = self.unknow_2
    ret.servertime = os.time()
    local date = os.date("*t")
    ret.year = date.year
    ret.month = date.month - 1
    ret.day = date.day
    ret.hour = date.hour
    ret.min = date.min
    ret.sec = date.sec
    Net:send(ret)
end

function request:CGFriendGroupName()
    local ret = packet_def.GCGroupingNameRet.new()
    ret.unknow = 0
    ret.list = {
        {data = "#{KDHYYH_211025_37}", size = 19},
        {data = "#{KDHYYH_211025_38}", size = 19},
        {data = "#{KDHYYH_211025_39}", size = 19},
        {data = "#{KDHYYH_211025_40}", size = 19}
    }
    Net:send(ret)
end

function request:CGAskGSChitChatInfo()
    local ret = packet_def.GCRetGSChitChatInfo.new()
    ret.unknow_1 = 0
    ret.unknow_2 = 0
    Net:send(ret)
end

function request:CGWAskAladdinToken()
    local ret = packet_def.WGCAladdinToken.new()
    ret.unknow_1 = 6114
    ret.unknow_2 = 270213680
    ret.unknow_3 = "}\19-\5\24D\0\0\4I\v'7$\3$"
    ret.unknow_4 = 0
    Net:send(ret)
end

function request:CGMinorPasswd()
    local FLAG = define.MINORPASSWD_REQUEST_TYPE
    local minor_password = ma_func:get_minor_password()
    local msg = packet_def.GCMinorPasswd.new()
    if self.flag == FLAG.MREQT_PASSWDSETUP then
        msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_PASSWDSETUP
        msg.m_ReturnSetup.m_uFlag = minor_password ~= nil and 1 or 0
        if ma_func:is_minor_password_is_unlock() then
            msg.m_ReturnSetup.m_uFlag = 0
        end
    elseif self.flag == FLAG.MREQT_DELETEPASSWDTIME then
        msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_DELETEPASSWDTIME
        if minor_password == nil then
            msg.m_ReturnSetup.m_uTime =  0
        else
            msg.m_ReturnSetup.m_uTime = 0--minor_password.delete_time or 0
        end
        return
    elseif self.flag == FLAG.MREQT_SETPASSWD then
        if minor_password and not ma_func:is_minor_password_is_unlock() then
            msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_SETPASSWDFAIL
        else
            minor_password = { password = self.password }
            ma_func:set_minor_password(minor_password)
            msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_SETPASSWDSUCC
        end
    elseif self.flag == FLAG.MREQT_MODIFYPASSWD then
        if minor_password == nil then
            msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_MODIFYPASSWDFAIL
        else
            if self.old_password ~= minor_password.password then
                msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_MODIFYPASSWDFAIL
            else
                if self.new_password == nil then
                    msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_MODIFYPASSWDFAIL
                else
                    minor_password.password = self.new_password
                    msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_MODIFYPASSWDSUCC
                end
            end
        end
    elseif self.flag == FLAG.MREQT_UNLOCKPASSWD then
        if minor_password == nil then
            msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_UNLOCKPASSWDFAIL
        else
            if self.password ~= minor_password.password then
                msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_UNLOCKPASSWDFAIL
            else
                ma_func:set_minor_password_is_unlock()
                msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_UNLOCKPASSWDSUCC
            end
        end
    elseif self.flag == FLAG.MREQT_DELETEPASSWD then
        --[[if minor_password == nil then
            msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_ERR_DELETEPASSWDFAIL
        else
            msg.m_Type = define.MINORPASSWD_RETURN_TYPE.MRETT_DELETEPASSWDTIME
            msg.m_ReturnSetup.m_uTime = minor_password.delete_time
        end]]
        ma_func:notify_tips("强制解除二级密码请联系客服")
        return
    end
    Net:send(msg)
end

function request:CGAskDetailEquipList()
    skynet.send(my_scene, "lua", "ask_detail_equip_list", my_obj_id, self)
end

function request:CGAskMyBagSize()
    local ret = packet_def.GCBagSizeChange.new()
    local size = skynet.call(my_scene, "lua", "get_my_bag_size", my_obj_id)
    ret.prop_size = size.prop
    ret.material_size = size.material
    Net:send(ret)
end

function request:CGAskMyBagList()
    local item_list = skynet.call(my_scene, "lua", "ask_my_bag_list", my_obj_id)
    local ret = packet_def.GCMyBagList.new()
    local list = {}
    for pos, item in pairs(item_list) do
        local l = {}
        l.index = pos
        l.unknow = {0, 0, 0}
        l.unknow_1 = {0, 0, 0}
        l.guid = item.guid
        l.item_index = item.item_index
        l.count = item.count
        table.insert(list, l)
    end
    ret.m_AskCount = table.nums(list)
    ret.m_Mode = 0
    ret.list = list
    Net:send(ret)
end

function request:CGAskCheDiFuLuData()
    skynet.send(my_scene, "lua", "char_ask_chedifulu_data", my_obj_id, self)
end

function request:CGAskMissionList()
    skynet.send(my_scene, "lua", "char_ask_mission_list", my_obj_id, self)
end

function request:CGAskSetting()
    skynet.send(my_scene, "lua", "char_ask_setting", my_obj_id, self)
end

function request:CGPlayerShopEstablish()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_player_shop_establish", my_obj_id, self)
end

function request:CGPlayerShopMoney()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_player_shop_money", my_obj_id, self)
end

function request:CGPlayerShopBuyItem()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_player_shop_buy_item", my_obj_id, self)
end

function request:CGPlayerShopOpenStall()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_player_shop_open_stall", my_obj_id, self)
end

function request:CGPlayerShopDesc()
    skynet.send(my_scene, "lua", "char_player_shop_desc", my_obj_id, self)
end

function request:CGPlayerShopName()
    skynet.send(my_scene, "lua", "char_player_shop_name", my_obj_id, self)
end

function request:CGPlayerShopPartner()
	-- skynet.logi("CGPlayerShopPartner")
    skynet.send(my_scene, "lua", "char_player_shop_partner", my_obj_id, self)
end

function request:CGPlayerShopAskForRecord()
	-- skynet.logi("CGPlayerShopAskForRecord")
    skynet.send(my_scene, "lua", "char_player_shop_ask_for_record", my_obj_id, self)
end

function request:CGPlayerShopAcquireShopList()
	-- skynet.logi("CGPlayerShopAcquireShopList")
    skynet.send(my_scene, "lua", "char_player_shop_acquire_shop_list", my_obj_id, self)
end

function request:CGPlayerShopAcquireItemList()
	-- skynet.logi("CGPlayerShopAcquireItemList")
    skynet.send(my_scene, "lua", "char_player_shop_acquire_item_list", my_obj_id, self)
end

function request:CGPlayerShopOnSale()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_player_shop_on_sale", my_obj_id, self)
end

function request:CGPlayerShopSize()
    skynet.send(my_scene, "lua", "char_player_shop_size", my_obj_id, self)
end

function request:CGItemSynch()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_item_sync", my_obj_id, self)
end

function request:CGCharAllTitles()
    skynet.send(my_scene, "lua", "char_all_titles", my_obj_id, self)
end

function request:CGEXchangeYuanBaoPiao()
    -- skynet.logi("CGEXchangeYuanBaoPiao guid =", ma_func:get_guid(), ";request =", table.tostr(self))
    skynet.call(my_scene, "lua", "char_exchange_yuanbao_piao", my_obj_id, self)
    local baglist = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_item_bag_list")
    -- if baglist then
        -- for _, item_row in pairs(baglist) do
            -- if item_row.item_index == 30501036 then
                -- skynet.logi("CGUseItem  guid =", ma_func:get_guid(), ";item =", table.tostr(item_row))
            -- end
        -- end
    -- end
end

function request:CGRelation()
    ma_func:CGRelation(self)
end

function CMD.char_enter_team_follow(followd_members)
    team_follow_sync_generation = team_follow_sync_generation + 1
    local generation = team_follow_sync_generation
    local expected_guid = ma_func:get_guid()
    skynet.logi("[TEAM_FOLLOW_SYNC] enter guid=", expected_guid, "generation=", generation,
        "scene=", my_scene, "obj=", my_obj_id, "members=", #(followd_members or {}))
    if my_scene and my_obj_id then
        local ok, handled = timeout_call(200, my_scene, "char_enter_team_follow", my_obj_id, followd_members, generation, expected_guid)
        if not ok or not handled then
            skynet.logw("[TEAM_FOLLOW_SYNC] enter failed guid=", expected_guid, "generation=", generation)
        end
    end
end

function CMD.char_stop_team_follow_self()
    team_follow_sync_generation = team_follow_sync_generation + 1
    local generation = team_follow_sync_generation
    local expected_guid = ma_func:get_guid()
    skynet.logi("[TEAM_FOLLOW_SYNC] stop guid=", expected_guid, "generation=", generation,
        "scene=", my_scene, "obj=", my_obj_id)
    if my_scene and my_obj_id then
        local ok, handled = timeout_call(200, my_scene, "char_stop_team_follow_self", my_obj_id, generation, expected_guid)
        if ok and handled then
            return
        end
    end
    local msg = packet_def.GCReturnTeamFollow.new()
    msg.return_type = define.TEAM_FOLLOW_RESULT.TF_RESULT_STOP_FOLLOW
    msg.guid = ma_func:get_guid()
    Net:send2client(msg.xy_id, msg, my_obj_id)
end

function CMD.char_del_team_follow_member(del_guid)
    if my_scene and my_obj_id then
        local ok, handled = timeout_call(200, my_scene, "char_del_team_follow_member", my_obj_id, del_guid)
        if ok and handled then
            return
        end
    end
    local msg = packet_def.GCReturnTeamFollow.new()
    msg.return_type = define.TEAM_FOLLOW_RESULT.TF_RESULT_STOP_FOLLOW
    msg.guid = del_guid
    Net:send2client(msg.xy_id, msg, my_obj_id)
end

function CMD.be_notifyd_friend_online(uinfo)
    ma_func:be_notifyd_friend_online(uinfo)
end

function CMD.be_notify_friend_be_add(tar_guid, relation_type)
    ma_func:be_notify_friend_be_add(tar_guid, relation_type)
end

function CMD.be_notify_friend_be_del(tar_guid, relation_type)
    ma_func:be_notify_friend_be_del(tar_guid, relation_type)
end

function CMD.be_notifyd_friend_offline(uinfo)
    ma_func:be_notifyd_friend_offline(uinfo)
end

local function delete_mail(mail)
    local my_guid = ma_func:get_guid()
    local selector = {["attrib.guid"] = my_guid}
    local updater = {}
    updater["$pull"] = { mail_list = mail }
    local sql = { collection = "character", selector = selector, update = updater}
    skynet.call(".char_db", "lua", "safe_update", sql)
end

local function execute_script_mail(mail)
    if my_scene then
        delete_mail(mail)
        skynet.call(my_scene, "lua", "execute_script_mail", my_obj_id, mail)
    end
end

local function get_db_mail_list()
    local my_guid = ma_func:get_guid()
    local selector = {mail_list = 1}
    local response = skynet.call(".char_db", "lua", "findOne",  {collection = "character", query = {["attrib.guid"] = my_guid}, selector = selector})
    local mail_list = response.mail_list or {}
    local common_mail_list = {}
    for i = #mail_list, 1, -1 do
        local mail = mail_list[i]
        if mail.flag == define.MAIL_TYPE.MAIL_TYPE_SCRIPT then
            execute_script_mail(mail)
        else
            table.insert(common_mail_list, mail)
        end
    end
    return common_mail_list
end

function CMD.new_mail()
    local mail_list = get_db_mail_list()
    if #mail_list > 0 then
        local msg = packet_def.GCNotifyMail.new()
        msg.m_MailCount = #mail_list
        Net:send(msg)
    end
end

function request:CGLookUpOther()
    ma_func:CGLookUpOther(self)
end

function request:CGHeartBeat()
    ma_func:CGHeartBeat()
    local now = os.time()
    if now - last_heartbeat_trace_time >= 10 then
        last_heartbeat_trace_time = now
        skynet.logi("[CLIENT_HEARTBEAT] guid=", ma_func:get_guid(), "scene=", my_scene, "obj=", my_obj_id)
    end
end

function request:CGCharDefaultEvent()
    skynet.send(my_scene, "lua", "char_default_event", my_obj_id, self)
end

function request:CGEventRequest()
    skynet.logi("[AUTO_ROUTE_EVENT] guid=", tostring(ma_func:get_guid()),
        " scene=", tostring(my_scene), " obj=", tostring(my_obj_id),
        " script=", tostring(self.m_objID), " index=", tostring(self.index),
        " target=", tostring(self.arg), " extra=", tostring(self.unknow))
    skynet.send(my_scene, "lua", "char_event_request", my_obj_id, self)
end

function request:CGEnterScene()
	change_scene_generation = change_scene_generation + 1
	local bug_name
    local my_data = ma_func:get_my_data()
	local my_guid = ma_func:get_my_guid()
	local ma_func_agent = ma_func:get_my_agent()
	local game_lv,game_agent = skynet.call(".gamed", "lua", "check_save_lv", my_guid)
	local data_guid,data_lv
	local sceneid,world_pos
	if my_data then
		data_guid = my_data.attrib.guid
		data_lv = my_data.game_flag.save_lv
		sceneid = my_data.attrib.sceneid
		world_pos = my_data.attrib.world_pos
		if not game_lv or game_lv ~= data_lv then
			bug_name = "服务数据版本号不同"
		elseif game_agent ~= ma_func_agent then
			bug_name = "角色服务ID异常"
		elseif my_guid ~= data_guid then
			bug_name = "数据GUID与服务GUID不符"
		else
			if change_scene_args then
				sceneid = change_scene_args.sceneid
				world_pos = change_scene_args.world_pos
				change_scene_args = nil
			else
				if my_data.game_flag.login_user ~= 1 then
					bug_name = "重连"
				end
			end
		end
	else
		bug_name = "角色服务没有角色数据"
	end
	if bug_name then
		local collection = "log_CGEnterScene"
		local doc = {
			bug_name = bug_name,
			guid = my_guid,
			data_guid = data_guid,
			game_lv = game_lv,
			data_lv = data_lv,
			game_agent = game_agent,
			ma_func_agent = ma_func_agent,
			sceneid = sceneid,
			my_scene = my_scene,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
		ma_func:notify_tips("ERROR0001:"..bug_name)
		CMD.logout_ex(my_guid)
		-- ma_func:do_quit()
	end
    local sceneid = my_data.attrib.sceneid
    local restore_scene_and_pos = my_data.attrib.restore_scene_and_pos
    my_scene = nil
	if sceneid > 10000 then
		if restore_scene_and_pos then
			local dest_scene = string.format(".SCENE_%d", sceneid)
			local exist = pcall(skynet.call, dest_scene, "debug", "PING")
			if exist then
				if ma_func:get_copy_scene_sn(sceneid) == restore_scene_and_pos.sn then
					my_scene = dest_scene
				else
					sceneid = restore_scene_and_pos.sceneid
					world_pos = restore_scene_and_pos.world_pos
				end
			else
				sceneid = restore_scene_and_pos.sceneid
				world_pos = restore_scene_and_pos.world_pos
			end
		else
			sceneid = define.DEFAULT_SCENEID_AND_WORLD_POS.sceneid
			world_pos = define.DEFAULT_SCENEID_AND_WORLD_POS.world_pos
		end
	else
		local dest_scene = string.format(".SCENE_%d", sceneid)
		local exist = pcall(skynet.call, dest_scene, "debug", "PING")
		if not exist then
			-- 帮会城市由动态场景管理器恢复，普通场景再交给 SceneManager。
			local dynamic_ok, dynamic_scene_id = pcall(skynet.call, ".Dynamicscenemanager", "lua", "ensure_city_scene", sceneid)
			if dynamic_ok and tonumber(dynamic_scene_id) == tonumber(sceneid) then
				exist = pcall(skynet.call, dest_scene, "debug", "PING")
			end
			if not exist then
				local ok, ready = pcall(skynet.call, ".SceneManager", "lua", "ensure_scene", sceneid)
				if ok and ready then
					exist = pcall(skynet.call, dest_scene, "debug", "PING")
				end
			end
			if not exist then
				sceneid = define.DEFAULT_SCENEID_AND_WORLD_POS.sceneid
				world_pos = define.DEFAULT_SCENEID_AND_WORLD_POS.world_pos
			end
		end
	end
    local teaminfo,new_sceneId = skynet.call(".world", "lua", "get_my_teaminfo", my_guid,sceneid)
	if new_sceneId then
		local team_scene = string.format(".SCENE_%d", new_sceneId)
		local team_scene_exist = pcall(skynet.call, team_scene, "debug", "PING")
		if not team_scene_exist and new_sceneId < 10000 then
			local dynamic_ok, dynamic_scene_id = pcall(skynet.call, ".Dynamicscenemanager", "lua", "ensure_city_scene", new_sceneId)
			if dynamic_ok and tonumber(dynamic_scene_id) == tonumber(new_sceneId) then
				team_scene_exist = pcall(skynet.call, team_scene, "debug", "PING")
			end
			if not team_scene_exist then
				local normal_ok, normal_ready = pcall(skynet.call, ".SceneManager", "lua", "ensure_scene", new_sceneId)
				if normal_ok and normal_ready then
					team_scene_exist = pcall(skynet.call, team_scene, "debug", "PING")
				end
			end
		end
		if team_scene_exist then
			sceneid = new_sceneId
		else
			skynet.loge("[LOGIN_SCENE_RECOVERY] ignore unavailable team scene, guid =", my_guid, ", scene_id =", new_sceneId)
		end
	end
	my_data.attrib.sceneid = sceneid
	my_data.attrib.world_pos = world_pos
	my_scene = string.format(".SCENE_%d", sceneid)
	local guildinfo = skynet.call(".Guildmanager", "lua", "get_guild_by_id", my_data.attrib.guild_id)
    -- local scene_type = skynet.call(my_scene, "lua", "get_type")
	local agent_or_node_name
	local save_true = my_data.game_flag.save_true or 0
	local fun_sceneid = ma_func:get_my_scene_id()
    
    local new_save_true,scene_type,new_data
    local cb_ok, cb_err
    cb_ok, new_save_true, scene_type, new_data = timeout_call(500, my_scene, "check_before_enter", my_guid,save_true,fun_sceneid)
    if cb_ok then
        cb_err = nil
    else
        cb_err = new_save_true
        local collection = "log_CGEnterScene"
        local doc = {
            bug_name = "check_before_enter 调用失败或超时",
            guid = my_guid,
            sceneid = sceneid,
            my_scene = my_scene,
            error = tostring(cb_err),
            date_time = os.date("%y-%m-%d %H:%M:%S")
        }
        skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
        ma_func:notify_tips("ERROR0001:场景服务异常，请稍后再试。")
        CMD.logout_ex(my_guid)
        return
    end
	if not scene_type then
		local collection = "log_CGEnterScene"
		local doc = {
			bug_name = "进入场景失败，存在角色",
			guid = my_guid,
			data_guid = data_guid,
			game_lv = game_lv,
			data_lv = data_lv,
			game_agent = game_agent,
			ma_func_agent = ma_func_agent,
			sceneid = sceneid,
			my_scene = my_scene,
			my_func_scene_id = fun_sceneid,
			save_true = save_true,
			new_save_true = new_save_true,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
		ma_func:notify_tips("ERROR0001:进入的场景存在该角色，请离游戏。")
		CMD.logout_ex(my_guid)
		return
    elseif scene_type == 4 then
        agent_or_node_name = utils.get_node_name()
    else
		agent_or_node_name = skynet.self()
	end
	if new_data then
		new_data.attrib.sceneid = sceneid
		new_data.attrib.world_pos = world_pos
		ma_func:save_my_data(new_data,"enter_scene")
		my_data = ma_func:get_my_data()
		data_guid = my_data.attrib.guid
		data_lv = my_data.game_flag.save_lv
		local collection = "log_CGEnterScene"
		local doc = {
			bug_name = "进入场景失败，更新存档数据",
			guid = my_guid,
			data_guid = data_guid,
			game_lv = game_lv,
			data_lv = data_lv,
			game_agent = game_agent,
			ma_func_agent = ma_func_agent,
			sceneid = sceneid,
			my_scene = my_scene,
			my_func_scene_id = fun_sceneid,
			save_true = save_true,
			new_save_true = new_save_true,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
	end
	local is_login = false
	if my_data.game_flag.login_user == 1 then
		is_login = true
		my_data.game_flag.login_user = 2
	else
		my_data.game_flag.login_user = my_data.game_flag.login_user + 1
	end
	my_obj_id, my_client_res = skynet.call(my_scene, "lua", "player_enter_scene", my_data, agent_or_node_name, teaminfo, guildinfo, is_login)
	if not my_obj_id or not my_client_res then
		local collection = "log_CGEnterScene"
		local doc = {
			bug_name = "进入场景失败，场景已满员",
			guid = my_guid,
			data_guid = data_guid,
			game_lv = game_lv,
			data_lv = data_lv,
			game_agent = game_agent,
			ma_func_agent = ma_func_agent,
			sceneid = sceneid,
			my_scene = my_scene,
			my_func_scene_id = fun_sceneid,
			save_true = save_true,
			new_save_true = new_save_true,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
		ma_func:notify_tips("ERROR0001:进入场景失败，场景已满员。")
		CMD.logout_ex(my_guid)
		return
    end
    ma_func:on_enter_scene(my_scene, my_obj_id, sceneid)
	local attrib = my_data.attrib
	local game_flag = my_data.game_flag
    -- [FIX] Subscribe world multicast before update_uinfo to avoid missing announcements during the blocking RPC
    init_world_multicast()
    skynet.call(".world", "lua", "update_uinfo", my_guid, 
	{
	name = attrib.name,
	sceneid = sceneid,
	m_objID = my_obj_id,
	client_res = my_client_res,
	world_pos = {x = attrib.world_pos.x,y = attrib.world_pos.y},
	level = attrib.level,
	menpai = attrib.menpai,
	model = attrib.model,
	hp = attrib.hp,
	hp_max = attrib.hp_max or 1,
	hair_id = attrib.hair_style,
	hair_color = attrib.hair_color,
	face_id = attrib.face_style,
	portrait_id = attrib.portrait_id,
	weapon  = game_flag.equip_0_visual or DEFAULT_EQUIP,
	cap     = game_flag.equip_1_visual or DEFAULT_EQUIP,
	armour  = game_flag.equip_2_visual or DEFAULT_EQUIP,
	cuff    = game_flag.equip_3_visual or DEFAULT_EQUIP,
	foot    = game_flag.equip_4_visual or DEFAULT_EQUIP,
	fashion = game_flag.equip_16_visual or DEFAULT_FASHION
	},true)
    skynet.call(".world", "lua", "player_enter_scene", my_guid)
    if scene_type ~= 4 then
        local channelid = skynet.call(my_scene, "lua", "get_multicast_channel")
        subscribe_scene_multicast(channelid)
    end
    subscribe_guild_multicast(attrib.guild_id)
    subscribe_confederate_multicast(attrib.confederate_id)
    subscribe_menpai_multicast(attrib.menpai)
    ma_func:start_check_heart_beat()
    if is_login then
        skynet.call(my_scene, "lua", "on_human_login", my_obj_id)
        skynet.send(".world", "lua", "notify_friends_online", { guid = my_guid, mood = my_data.relation.mood, name = my_data.attrib.name }, my_data.relation.friends)
    end
end

function request:CGAskChangeScene()
	-- skynet.logi("request:CGAskChangeScene")
	local my_guid = ma_func:get_my_guid()
	local my_scene_id = ma_func:get_my_scene_id()
	local ma_func_agent = ma_func:get_my_agent()
	local error_params = {}
	local route_pos = change_scene_args and change_scene_args.world_pos or {}
	skynet.logi("[AUTO_ROUTE_ASK_CHANGE] guid=", tostring(my_guid),
		" current_scene=", tostring(my_scene_id),
		" packet_from=", tostring(self.scene_from),
		" packet_to=", tostring(self.scene_to),
		" packet_extra1=", tostring(self.unknow_1),
		" packet_extra2=", tostring(self.unknow_2),
		" route_to=", tostring(change_scene_args and change_scene_args.sceneid),
		" route_x=", tostring(route_pos.x), " route_y=", tostring(route_pos.y))
	if not change_scene_args then
		table.insert(error_params,"没有切换场景数据")
		return
	end
	change_scene_generation = change_scene_generation + 1
	local transition_generation = change_scene_generation
	local data
	local call_name = "change_scene"
	if my_scene then
		local ok, leave_data = timeout_call(500, my_scene, "leave", my_guid, ma_func:get_del_obj_flag())
        if ok and leave_data then
            data = leave_data
			call_name = "leave_scene"
		else
			if not ok then
                table.insert(error_params, "场景离开超时或场景服务异常")
            else
                table.insert(error_params, "场景找不到角色数据，存在回档的可能性")
            end

            -- 普通 leave 未确认完成时，必须先由旧场景执行无脚本强制解绑。
            -- 未确认解绑绝不能继续创建新场景对象，否则会形成双对象和 AOI/路由分裂。
            local force_ok, force_data, force_detached = timeout_call(200, my_scene, "force_leave", my_guid)
            if force_ok and force_detached then
                data = force_data or ma_func:get_my_data()
                call_name = "force_leave_scene"
            else
                table.insert(error_params, "旧场景强制解绑失败，已中止切换")
                local collection = "log_CGAskChangeScene"
                local doc = {
                    guid = my_guid,
                    my_scene_id = my_scene_id,
                    ma_func_agent = ma_func_agent,
                    error_params = error_params,
                    date_time = utils.get_day_time()
                }
                skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
                change_scene_args = nil
                local fail = packet_def.GCRetChangeScene.new()
                fail.result = 0
                fail.key = my_connect_key or 0
                Net:send(fail)
                ma_func:notify_tips("场景切换失败，旧场景尚未安全释放，请重试。")
                return
            end
		end
	else
		table.insert(error_params,"没有场景，登陆即切换，不合理的触发")
		data = ma_func:get_my_data()
	end
	if not data or not data.attrib or not data.game_flag then
		table.insert(error_params, "场景切换缺少有效存档数据")
		change_scene_args = nil
		local fail = packet_def.GCRetChangeScene.new()
		fail.result = 0
		fail.key = my_connect_key or 0
		Net:send(fail)
		return
	end
	if data.attrib.guid ~= my_guid then
		table.insert(error_params,"数据GUID与角色服务GUID不符")
	end
	local data_lv = data.game_flag.save_lv
	local data_guid = data.attrib.guid
    data.attrib.sceneid = change_scene_args.sceneid
    data.attrib.world_pos = change_scene_args.world_pos
    ma_func:save_my_data(data,call_name)
    my_scene = nil
    my_obj_id = nil
	local port,game_lv,game_agent
	port,my_connect_key,game_lv,game_agent = skynet.call(".gamed", "lua", "get_change_scene_data", my_guid)
	if game_lv ~= data_lv then
		table.insert(error_params,"存档lv异常")
	end
	if game_agent ~= ma_func_agent then
		table.insert(error_params,"服务ID异常")
	end
	if #error_params > 0 then
		local collection = "log_CGAskChangeScene"
		local doc = { 
		guid = my_guid,
		my_scene_id = my_scene_id,
		data_lv = my_scene_id,
		game_lv = game_lv,
		ma_func_agent = ma_func_agent,
		game_agent = game_agent,
		my_scene_id = my_scene_id,
		error_params = error_params,
		date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		-- CMD.logout_ex(my_guid)
		-- return
	end
    local ret = packet_def.GCRetChangeScene.new()
    ret.ip = ma_func:get_game_ip() or server_conf.server_ip
    ret.port = port
    ret.result = 1
    ret.key = my_connect_key
    Net:send(ret)
    skynet.timeout(500, function()
        if transition_generation == change_scene_generation
            and my_scene == nil
            and change_scene_args ~= nil then
            Net:send(ret)
        end
    end)
end

function request:CGPackage_SwapItem()
    skynet.send(my_scene, "lua", "package_swap_item", my_obj_id, self)
end

function request:CGSplitItem()
    skynet.send(my_scene, "lua", "char_split_item", my_obj_id, self)
end

function request:CGAskItemInfo()
    skynet.send(my_scene, "lua", "ask_item_info", my_obj_id, self)
end

function request:CGUseEquip()
    skynet.send(my_scene, "lua", "char_use_equip", my_obj_id, self)
end

function request:CGUnEquip()
    skynet.send(my_scene, "lua", "char_un_equip", my_obj_id, self)
end

function request:CGDispelBuffReq()
    skynet.send(my_scene, "lua", "char_diepel_buff", my_obj_id, self)
end

function request:CGSetMoodToHead()
    skynet.send(my_scene, "lua", "char_set_mood_to_head", my_obj_id, self)
end

function request:CGPackUpPacket()
    skynet.send(my_scene, "lua", "char_pack_up_packet", my_obj_id, self)
end

function request:CGShowFashionDepotData()
    -- CYS fix 2026-09-14: id 1032 phia client la GCYuanBao (server->client), client
    -- khong gui goi nay. GCShowFashionDepotData da bi chu thich (mission.lua:307)
    -- nen tra loi se loi nil. Bo qua goi, khong tra loi.
    return
end

function request:CGCharMove()
    skynet.send(my_scene, "lua", "char_move", my_obj_id, self)
end

function request:CGCharPositionWarp()
    skynet.send(my_scene, "lua", "char_position_warp", self)
end

function request:CGOrnamentsOperation()
    skynet.send(my_scene, "lua", "char_headwear_backwear_sync_request", my_obj_id, self)
end

-- 处理 CGExteriorSharePlan (opcode 287, 珍藏/鉴赏阁)
function request:CGExteriorSharePlan()
    -- 【珍藏功能已恢复】
    self.op_type = self.op_code or 1  -- 映射字段名
    request.GCTarExteriorSharePlan(self)  -- 转发到实际处理逻辑
end

function request:CGExteriorRequest()
    skynet.send(my_scene, "lua", "char_exterior_request", my_obj_id, self)
end

function request:CGCharUseSkill()
    skynet.send(my_scene, "lua", "char_use_skill", my_obj_id, self)
end

function request:CGLockTarget()
    skynet.send(my_scene, "lua", "char_lock_target", my_obj_id, self)
end

function request:CGOpenItemBox()
    skynet.send(my_scene, "lua", "char_open_box_item", my_obj_id, self)
end

function request:CGPickBoxItem()
    skynet.send(my_scene, "lua", "char_pick_box_item", my_obj_id, self)
end

function request:CGModifySetting()
    skynet.send(my_scene, "lua", "char_modify_setting", my_obj_id, self)
end

function request:CGAskStudyXinfa()
    local xinfa = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_xinfa", self.xinfa)
    if not xinfa then
        ma_func:notify_tips("心法数据不存在")
        return
    end
    if xinfa.m_nXinFaLevel ~= self.now_level then
        ma_func:notify_tips("非法请求")
        return
    end
    skynet.send(my_scene, "lua", "char_study_xinfa", my_obj_id, self)
end

function request:CGReqLevelUp()
    skynet.send(my_scene, "lua", "char_req_level_up", my_obj_id, self)
end

function request:CGRemoveGem()
    skynet.send(my_scene, "lua", "char_remove_gem", my_obj_id, self)
end

function request:CGRemoveDressGem()
    skynet.send(my_scene, "lua", "char_remove_dress_gem", my_obj_id, self)
end

function request:CGGemCompound()
    skynet.send(my_scene, "lua", "char_gem_compound", my_obj_id, self)
end

function request:CGDisplaceGem()
    skynet.send(my_scene, "lua", "char_displace_gem", my_obj_id, self)
end

local function log_char_use_ability(request_body, mat)
    local collection = "log_char_use_ability_rec"
    local doc = {
        guid = ma_func:get_guid(),
        name = ma_func:get_name(),
        request = request_body,
        unix_time = os.time(),
        day_time = utils.get_day_time(),
        process_id = tonumber(skynet.getenv "process_id"),
        mat = mat
    }
    skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc})
end

function request:CGUseAbility()
    local compound_mat_item_indexs = define.COMPOUND_MAT_ITEM_INDEX[self.ability]
    if compound_mat_item_indexs then
        local baglist = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_item_bag_list")
        local mat = baglist[self.mat_index]
		assert(mat,self.mat_index)
        local item_index = mat.item_index
        if compound_mat_item_indexs[item_index] == nil then
            log_char_use_ability(self, mat)
            return
        end
    end
    skynet.send(my_scene, "lua", "char_use_ability", my_obj_id, self)
end

function request:CGDiscardItem()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.send(my_scene, "lua", "char_discard_item", my_obj_id, self)
end

function request:CGBankAcquireList()
    skynet.send(my_scene, "lua", "char_bank_acquire_list", my_obj_id, self)
end

function request:CGBankAddItem()
    skynet.send(my_scene, "lua", "char_bank_add_item", my_obj_id, self)
end

function request:CGBankSwapItem()
    skynet.send(my_scene, "lua", "char_bank_swap_item", my_obj_id, self)
end

function request:CGBankRemoveItem()
    skynet.send(my_scene, "lua", "char_bank_remove_item", my_obj_id, self)
end

function request:CGPackUpBank()
    skynet.send(my_scene, "lua", "char_bank_pack_up", my_obj_id, self)
end

function request:CGPlayerDieResult()
    skynet.send(my_scene, "lua", "char_die_result", my_obj_id, self)
end

function request:CGPetBankAddPet()
    skynet.send(my_scene, "lua", "char_pet_bank_add_pet", my_obj_id, self)
end

function request:CGShopSell()
    skynet.send(my_scene, "lua", "char_shop_sell", my_obj_id, self)
end

local last_world_chat_time = nil
local last_menpai_chat_time = nil
local last_city_chat_time = nil
function request:CGChat()
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_SCENE then
        local now = os.time()
        if last_world_chat_time and now - last_world_chat_time < 150 then
            ma_func:notify_tips("世界聊天暂时关闭")
            return
        end
        last_world_chat_time = now
    end
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_MENPAI then
        local now = os.time()
        if last_menpai_chat_time and now - last_menpai_chat_time < 150 then
            ma_func:notify_tips("门派聊天需要等待3分钟")
            return
        end
        last_menpai_chat_time = now
    end
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_CITY then
        local now = os.time()
        if last_city_chat_time and now - last_city_chat_time < 10 then
            ma_func:notify_tips("城市聊天需要等待10秒钟")
            return
        end
        last_city_chat_time = now
    end
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_MAIL then
        local friend_point = ma_func:get_friend_point(self.dest_guid)
        if friend_point == 0 then
            ma_func:notify_tips("双向好友才能好友聊天")
        else
            skynet.send(my_scene, "lua", "char_chat", my_obj_id, self)
        end
    else
        skynet.send(my_scene, "lua", "char_chat", my_obj_id, self)
    end
end

function request:CGCharFly()
    skynet.send(my_scene, "lua", "char_fly", my_obj_id, self)
end

function request:CGFlyOperation()
    skynet.send(my_scene,"lua","mount_flight_operation",my_obj_id,self)
end

function request:CGCharAutoRide()
    skynet.send(my_scene, "lua", "char_auto_ride", my_obj_id, self.flag)
end

function request:CGReqManualAttr()
    skynet.send(my_scene, "lua", "char_manual_attr", my_obj_id, self)
end

function request:CGFashionDepotOperation()
    skynet.send(my_scene, "lua", "char_fashion_depot_operation", my_obj_id, self)
end

function request:CGAskDoubleExp()
    skynet.send(my_scene, "lua", "char_ask_double_exp_info", my_obj_id, self)
end

function request:CGManipulatePet()
    if self.type == define.ENUM_MANIPULATE_TYPE.MANIPULATE_FREEPET then
        if not ma_func:is_minor_password_is_unlock() then
            ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
            return
        end
    end
    skynet.send(my_scene, "lua", "char_manipulate_pet", my_obj_id, self)
end

function request:CGSetPetAttrib()
    skynet.send(my_scene, "lua", "char_set_pet_attrib", my_obj_id, self)
end

function request:CGAskDarkAdjust()
    skynet.send(my_scene, "lua", "char_adjust_dark", my_obj_id, self)
end

function request:CGPetUseEquip()
    skynet.send(my_scene, "lua", "char_use_pet_equip", my_obj_id, self)
end

function request:CGPetUnEquip()
    skynet.send(my_scene, "lua", "char_un_pet_equip", my_obj_id, self)
end

function request:CGMissionSubmit()
    skynet.send(my_scene, "lua", "char_mission_submit", my_obj_id, self)
end

function request:CGChangePkModeReq()
    skynet.send(my_scene, "lua", "char_req_change_pk_mode", my_obj_id, self)
end

function request:CGCharJump()
    skynet.send(my_scene, "lua", "char_jump", my_obj_id, self)
end

function request:CGKfsOperate()
    skynet.send(my_scene, "lua", "char_kfs_operate", my_obj_id, self)
end

function request:CGAskPrivateInfo()
    skynet.send(my_scene, "lua", "char_ask_private_info", my_obj_id, self)
end

function request:CGPetSoulXiShuXing()
    skynet.send(my_scene, "lua", "char_pet_xishuxing", my_obj_id, self)
end

function request:CGChallenge()
    skynet.send(my_scene, "lua", "char_challenge", my_obj_id, self)
end

function request:CGStallApply()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    local scene_type = skynet.call(my_scene, "lua", "get_type")
    if scene_type == 0 then
        skynet.send(my_scene, "lua", "char_stall", my_obj_id, self)
    end
end

function request:CGStallEstablish()
	local my_data = ma_func:get_my_data()
	if not my_data then
		return
	end
	local guid = my_data.attrib.guid
	local save_lv,game_agent = skynet.call(".gamed", "lua", "check_save_lv", guid)
	if not save_lv or save_lv ~= my_data.game_flag.save_lv then
		local collection = "log_save_lv_change"
		local doc = { 
			fun_name = "CGStallEstablish",
			error_msg = "数据版本号异常_请求摆摊",
			guid = guid,
			name = my_data.attrib.name,
			curlv = save_lv,
			game_agent = game_agent,
			datalv = my_data.game_flag.save_lv,
			data_agent = my_data.game_flag.agent,
			sceneid = my_data.attrib.sceneid,
			world_pos = my_data.attrib.world_pos,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		ma_func:notify_tips("角色数据异常，请重新登陆游戏再进行操作。")
		return
	end
    skynet.send(my_scene, "lua", "char_stall_establish", my_obj_id, self)
end

function request:CGStallOpen()
    skynet.send(my_scene, "lua", "char_stall_open", my_obj_id, self)
end

function request:CGStallAddItem()
    skynet.send(my_scene, "lua", "char_stall_add_item", my_obj_id, self)
end

function request:CGStallItemPrice()
    skynet.send(my_scene, "lua", "char_stall_item_price", my_obj_id, self)
end

function request:CGStallRemoveItem()
    skynet.send(my_scene, "lua", "char_stall_remove_item", my_obj_id, self)
end

function request:CGStallClose()
    skynet.send(my_scene, "lua", "char_close_stall", my_obj_id, self)
end

function request:CGStallBuy()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    local scene_type = skynet.call(my_scene, "lua", "get_type")
    if scene_type == 0 then
        skynet.send(my_scene, "lua", "char_stall_buy", my_obj_id, self)
    end
end

function request:CGStallShopName()
    skynet.send(my_scene, "lua", "char_stall_shop_name", my_obj_id, self)
end

function request:CGAntagonistReq()
    skynet.send(my_scene, "lua", "char_antagonist_req", my_obj_id, self)
end

function request:CGBBSApply()
    skynet.send(my_scene, "lua", "char_bbs_apply", my_obj_id, self)
end

function request:CGBBSSychMessages()
    skynet.send(my_scene, "lua", "char_bbs_sync_messages", my_obj_id, self)
end

function request:CGAcqStallOpen()
    skynet.send(my_scene, "lua", "char_acq_stall_open", my_obj_id, self)
end

function request:CGAcqStallAddItem()
    skynet.send(my_scene, "lua", "char_acq_stall_add_item", my_obj_id, self)
end

function request:CGAcqStallRemoveItem()
    skynet.send(my_scene, "lua", "char_acq_stall_remove_item", my_obj_id, self)
end

function request:CGAcqStallSell()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_acq_stall_sell", my_obj_id, self)
end

function request:CGMissionAbandon()
    skynet.send(my_scene, "lua", "char_mission_abandon", my_obj_id, self)
end

function request:CGMissionAccept()
    skynet.send(my_scene, "lua", "char_mission_accept", my_obj_id, self)
end

function request:CGMissionContinue()
    skynet.send(my_scene, "lua", "char_mission_continue", my_obj_id, self)
end

function request:CGExchangeApplyI()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
	local my_data = ma_func:get_my_data()
	if not my_data then
		return
	end
	local guid = my_data.attrib.guid
	local save_lv,game_agent = skynet.call(".gamed", "lua", "check_save_lv", guid)
	if not save_lv or save_lv ~= my_data.game_flag.save_lv then
		local collection = "log_save_lv_change"
		local doc = { 
			fun_name = "CGExchangeApplyI",
			error_msg = "数据版本号异常_请求交易",
			guid = guid,
			name = my_data.attrib.name,
			curlv = save_lv,
			game_agent = game_agent,
			datalv = my_data.game_flag.save_lv,
			data_agent = my_data.game_flag.agent,
			sceneid = my_data.attrib.sceneid,
			world_pos = my_data.attrib.world_pos,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		ma_func:notify_tips("角色数据异常，请重新登陆游戏再进行操作。")
		return
	end
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.send(my_scene, "lua", "char_exchange_apply_I", my_obj_id, self)
end

function request:CGSectOper()
    skynet.send(my_scene, "lua", "char_sect_oper", my_obj_id, self)
end

function request:CGBankMoney()
    skynet.send(my_scene, "lua", "char_bank_money", my_obj_id, self)
end

function request:CGAskTargetESPlan()
    -- 【珍藏功能已恢复】
    skynet.send(my_scene, "lua", "char_ask_target_es_plan", my_obj_id, self)
end

-- 客户端用 wire opcode 1168 C->S 请求/保存 珍藏外观分享方案
-- op_type 1-6=查看请求, 7=保存标签, 8=保存时装, 9=保存坐骑, 10=保存幻饰, 15=提交时装到方案, 20=保存方案ID
function request:GCTarExteriorSharePlan()
    -- 【珍藏功能已恢复】
    local op = self.op_type or 1

    if op <= 6 then
        -- ======== 查看请求 ========
        local sub_code = op
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)

        local msg = packet_def.GCExteriorSharePlan.new()
        msg.plan_id = plan.plan_id or 0
        msg.tag = plan.tag
        msg.dress_a = plan.dress_a
        msg.dress_b = plan.dress_b
        msg.weapon_a = plan.weapon_a
        msg.weapon_b = plan.weapon_b
        msg.ride_a = plan.ride_a
        msg.ride_b = plan.ride_b

        if sub_code == 1 then
            msg.type_code = 2     -- 全量数据
        elseif sub_code == 3 then
            msg.type_code = 3     -- 个性标签 (打开编辑框, event 1141)
        elseif sub_code == 4 or sub_code == 5 or sub_code == 6 then
            -- IDA确认: type=16触发OPEN_EXTERIOR_SHAREPLAN(方案保存窗口), 不是编辑器
            -- 时装编辑器: GCAskFashionDepotData flag=1 → event 1142 (OPEN_EXTERIOR_DRESSCHOOSE)
            -- 坐骑编辑器: GCExteriorInfo type=4,sub=5 → event 1143 (OPEN_EXTERIOR_RIDECHOOSE)
            -- 幻饰编辑器: GCExteriorInfo type=8,sub=5 → event 1144 (OPEN_EXTERIOR_WEAPONCHOOSE)
            if sub_code == 4 then
                -- 时装编辑器: 发送FashionDepot数据, open_editor=1触发编辑器打开
                skynet.call(my_scene, "lua", "ask_fashion_depot_data", my_obj_id, true)
            elseif sub_code == 5 then
                -- 坐骑编辑器: 发送ride数据 + sub_type=5触发编辑器
                skynet.call(my_scene, "lua", "send_exterior_ride_editor", my_obj_id)
            elseif sub_code == 6 then
                -- 幻饰编辑器: 发送weapon_visual数据 + sub_type=5触发编辑器
                skynet.call(my_scene, "lua", "send_exterior_weapon_editor", my_obj_id)
            end
            return  -- 不再发送GCExteriorSharePlan
        else
            msg.type_code = 2
        end

        Net:send(msg)

    elseif op == 7 then
        -- ======== 保存个性标签 ========
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "tag", {
            tag = self.save_tag
        })
        -- 回传标签数据确认 (type=11 触发 event 1139 刷新, 而非 type=3 触发 event 1141 重新打开编辑框)
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 11
        msg.tag = plan.tag
        Net:send(msg)

    elseif op == 8 then
        -- ======== 保存时装 ========
        -- 1. 保存到 share_plan (分享方案)
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "dress", {
            dress_a = self.save_dress_a,
            dress_b = self.save_dress_b
        })
        -- 2. 同时保存到 profile_dress (资料页时装，供客户端 ProfileData("DRESS") 读取)
        -- dress_a = VecIndex(槽位索引), dress_b = ExteriorID(外观ID)
        skynet.call(my_scene, "lua", "char_save_profile_dress", my_obj_id, self.save_dress_a, self.save_dress_b)
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 12
        msg.dress_a = plan.dress_a
        msg.dress_b = plan.dress_b
        Net:send(msg)

    elseif op == 9 then
        -- ======== 保存坐骑 ========
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "ride", {
            ride = self.save_ride
        })
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 13
        msg.ride_a = plan.ride_a
        msg.ride_b = plan.ride_b
        Net:send(msg)

    elseif op == 10 then
        -- ======== 保存幻饰 ========
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "weapon", {
            weapon = self.save_weapon
        })
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 14
        msg.weapon_a = plan.weapon_a
        msg.weapon_b = plan.weapon_b
        Net:send(msg)

    elseif op == 15 then
        -- ======== 提交时装到分享方案 ========
        -- 客户端 op=8 只是缓存时装到 profile_dress，op=15 才是真正提交到 share_plan
        local pd = skynet.call(my_scene, "lua", "char_get_profile_dress", my_obj_id)
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "dress", {
            dress_a = pd.idx,
            dress_b = pd.id
        })
        -- 全量发回客户端刷新方案界面
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 2
        msg.plan_id = plan.plan_id or 0
        msg.tag = plan.tag
        msg.dress_a = plan.dress_a
        msg.dress_b = plan.dress_b
        msg.weapon_a = plan.weapon_a
        msg.weapon_b = plan.weapon_b
        msg.ride_a = plan.ride_a
        msg.ride_b = plan.ride_b
        Net:send(msg)

    elseif op == 17 or op == 18 then
        -- ======== 槽位flag切换 ========
        -- 客户端发送op=17/18 + 1字节value, 响应type=19
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 19
        msg.flag_value = self.flag_value or 0
        Net:send(msg)

    elseif op == 20 then
        -- ======== 点赞 ========
        -- IDA确认: 客户端LuaFnDianZan发送CGExteriorSharePlan op=20, 值=target_obj_id
        -- op=20始终作为点赞处理, 不再fallthrough到保存plan_id
        -- 避免点赞失败时把target_obj_id错误存为plan_id(导致610116被污染)
        local target_val = self.save_plan_id or 0
        local is_zan = skynet.call(my_scene, "lua", "char_dianzan_es_plan", my_obj_id, target_val)
        if is_zan then
            -- 点赞成功: 发送873 type_code=20 result=1 触发客户端event 1191刷新UI
            local zan_msg = packet_def.GCExteriorSharePlan.new()
            zan_msg.type_code = 20
            zan_msg.zan_result = 1  -- 1=成功
            Net:send(zan_msg)
        else
            -- 点赞失败(自己/目标不存在等): 发送失败通知
            local zan_msg = packet_def.GCExteriorSharePlan.new()
            zan_msg.type_code = 20
            zan_msg.zan_result = 2  -- 2=失败, 客户端显示 #{GRYM_221213_28}
            Net:send(zan_msg)
        end
    end
end

function request:CGExteriorCoupleFashion()
    local msg = packet_def.GCExteriorCoupleFashion.new()
    msg.unknow_1 = self.unknow_1
    msg.unknow_2 = self.unknow_2
    Net:send(msg)
    skynet.send(my_scene, "lua", "char_exterior_couple_fashion", my_obj_id, self)
end

function request:CGRaidRetApply()
	local my_guid = ma_func:get_guid()
	skynet.send(".world", "lua", "char_ret_raid_apply", my_guid, self)
end

function request:CGRaidLeave()
    self.guid = ma_func:get_guid()
	skynet.send(".world", "lua", "char_leave_raid", self.guid)
end

--​申请加入团队
function request:CGRaidApply()
    self.m_SourGUID = ma_func:get_guid()
	skynet.send(".world", "lua", "char_apply_raid",self)
end
--​邀请玩家加入团队
function request:CGRaidInvite()
    self.m_SourObjID = ma_func:get_guid()
	skynet.send(".world", "lua", "char_invite_raid",self)
end
--调整团队成员位置
function request:CGRaidModifyMemberPosition()
    self.m_OperateGUID = ma_func:get_guid()
	skynet.send(".world", "lua", "raid_modify_member_position", self)
    -- local msg = packet_def.GCRetRaidModifyMemberPosition.new()
    -- msg.m_OperateGUID = self.m_OperateGUID
    -- msg.m_sSquadIndex = self.m_sSquadIndex
    -- msg.m_sMemIndex = self.m_sMemIndex
    -- msg.m_dSquadIndex = self.m_dSquadIndex
    -- msg.m_dMemIndex = self.m_dMemIndex
    -- Net:send(msg)
end
--回复邀请
function request:CGRaidRetInvite()
	local my_guid = ma_func:get_guid()
	skynet.send(".world", "lua", "char_ret_raid_invite", my_guid,self)
end
--​踢出团队成员
function request:CGRaidKick()
    self.m_OperateGUID = ma_func:get_guid()
	skynet.send(".world", "lua", "char_raid_kick", self)
end
--​任命团队职位​
function request:CGRaidAppoint()
    self.m_OperateGUID = ma_func:get_guid()
    -- local my_guid = ma_func:get_guid()
	-- if my_guid == self.m_OperateGUID then
		skynet.send(".world", "lua", "char_raid_appoint", self)
	-- end
end
--​创建团队
function request:CGRaidCreate()
    self.m_CreateGUID = ma_func:get_guid()
    -- local my_guid = ma_func:get_guid()
	-- if my_guid == self.m_CreateGUID then
		skynet.send(".world", "lua", "char_create_raids", self)
	-- end
end
--​请求团队信息
function request:CGAskRaiInfo()
    -- local my_guid = ma_func:get_guid()
    -- local attrib, equip_visuals,is_die = skynet.call(my_scene, "lua", "ask_team_member_info", my_obj_id, {m_objID = self.m_objID,guid = my_guid})
    -- if attrib then
		-- skynet.logi("raid_id = ",attrib.raid_id)
	-- end
	-- if attrib and attrib.raid_id ~= -1 then
		-- local msg = packet_def.GCRaidMemberInfo.new()
		-- msg.m_RaidID = attrib.raid_id
		-- msg.flag = 0
		-- msg:set_menpai(attrib.menpai)
		-- msg:set_level(attrib.level)
		-- msg:set_world_pos({x = attrib.world_pos.x,y = attrib.world_pos.y})
		-- msg:set_hp(attrib.hp)
		-- msg:set_hp_max(attrib.hp_max)
		-- msg:set_mp(attrib.mp)
		-- msg:set_mp_max(attrib.mp_max)
		-- msg:set_is_die(is_die)
		-- msg:set_hair_id(attrib.hair_id)
		-- msg:set_hair_color(attrib.hair_color)
		-- msg:set_portrait_id(attrib.portrait_id)
        -- msg:set_weapon(equip_visuals.weapon)
        -- msg:set_cap(equip_visuals.cap)
        -- msg:set_armour(equip_visuals.armour)
        -- msg:set_cuff(equip_visuals.cuff)
        -- msg:set_foot(equip_visuals.foot)
        -- msg:set_fashion(equip_visuals.fashion)
		-- Net:send(msg)
    -- end
	-- skynet.logi("CGAskRaiInfo",table.tostr(self))
end



--​邀请玩家加入队伍
-- 请求团队成员详细信息（门派、等级、HP、装备等）
function request:CGAskRaidMemberInfo()
    local my_guid = ma_func:get_guid()
    local msg = packet_def.GCRaidMemberInfo.new()
    msg.flag = 0
    msg.data_index = 0
    -- 从场景服获取目标成员的真实属性和装备外观
    local attrib, equip_visuals, is_die = skynet.call(my_scene, "lua", "ask_team_member_info", my_obj_id, self)
    if attrib then
        msg.guid = attrib.guid
        -- 从世界服获取raid_id
        local raid_id = skynet.call(".world", "lua", "get_player_raid_id", my_guid)
        msg.m_RaidID = raid_id or -1
        -- 通过反射调用所有匹配的set_xxx设置器
        for k, v in pairs(attrib) do
            local fn = string.format("set_%s", k)
            local f = msg[fn]
            if f then f(msg, v) end
        end
        msg:set_is_die(is_die)
        if equip_visuals then
            msg:set_weapon(equip_visuals.weapon)
            msg:set_cap(equip_visuals.cap)
            msg:set_armour(equip_visuals.armour)
            msg:set_cuff(equip_visuals.cuff)
            msg:set_foot(equip_visuals.foot)
            msg:set_fashion(equip_visuals.fashion)
        end
    else
        -- 目标不在同一场景，回退到世界服获取基本信息
        skynet.call(".world", "lua", "char_ask_raid_member_info", my_guid, self)
        return
    end
    Net:send(msg)
end


function request:CGTeamInvite()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_invite_team", my_guid, self)
end
--	​解散队伍
function request:CGTeamDismiss()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_dismiss_team", my_guid, self)
end
--回复队伍邀请​
function request:CGTeamRetInvite()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_ret_invite", my_guid, self)
end
-- ​ 踢出队伍成员
function request:CGTeamKick()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_team_kick", my_guid, self)
end
--​任命队伍职位
function request:CGTeamAppoint()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_team_appoint", my_guid, self)
end
--修改队伍设置
function request:CGTeamChangeOption()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_team_change_option", my_guid, self)
end

function request:CGTeamApply()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_team_apply", my_guid, self)
end

function request:CGTeamRetApply()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_ret_team_apply", my_guid, self)
end

-- 队长回复转发邀请（非队长成员邀请时，转给队长审批）
function request:CGTeamLeaderRetInvite()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_leader_ret_invite", my_guid, self)
end

function request:CGAskTeamInfo()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_ask_team_info", my_guid)
end

-- 客户端登录时发送，请求自动恢复/创建队伍
function request:CGAutoCreateTeam()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_ask_team_info", my_guid)
end


function request:CGAskTeamMemberInfo()
    local my_guid = ma_func:get_guid()
    local msg = packet_def.GCTeamMemberInfo.new()
    local attrib, equip_visuals
    if my_scene and my_obj_id then
        local scene_ok
        scene_ok, attrib, equip_visuals = timeout_call(200, my_scene, "ask_team_member_info", my_obj_id, self)
        if not scene_ok then
            attrib = nil
            equip_visuals = nil
        end
    end

    local function set_visuals(visuals)
        if not visuals then
            return
        end
        if visuals.weapon then msg:set_weapon(visuals.weapon) end
        if visuals.cap then msg:set_cap(visuals.cap) end
        if visuals.armour then msg:set_armour(visuals.armour) end
        if visuals.cuff then msg:set_cuff(visuals.cuff) end
        if visuals.foot then msg:set_foot(visuals.foot) end
        if visuals.fashion then msg:set_fashion(visuals.fashion) end
        if visuals.exterior_back_id ~= nil then
            msg:set_exterior_back(visuals.exterior_back_id, visuals.exterior_back_pos)
        end
        if visuals.exterior_head_id ~= nil then
            msg:set_exterior_head(visuals.exterior_head_id, visuals.exterior_head_pos)
        end
    end

    if attrib then
        if not attrib.guid then
            return
        end
        msg.guid = attrib.guid
        for k, v in pairs(attrib) do
            local fn = string.format("set_%s", k)
            local f = msg[fn]
            if f then
                f(msg, v)
            end
        end
        set_visuals(equip_visuals)
    else
        local world_ok
        world_ok, attrib = timeout_call(200, ".world", "ask_team_member_info", my_guid, self)
        if not world_ok or not attrib or not attrib.guid then
            return
        end
        msg.data_index = 0
        msg.flag = 0
        msg.guid = attrib.guid
        if attrib.menpai ~= nil then msg:set_menpai(attrib.menpai) end
        if attrib.level ~= nil then msg:set_level(attrib.level) end
        if attrib.world_pos then msg:set_world_pos(attrib.world_pos) end
        if attrib.hp ~= nil then msg:set_hp(attrib.hp) end
        if attrib.hp_max ~= nil then msg:set_hp_max(attrib.hp_max) end
        if attrib.face_id ~= nil then msg:set_face_style(attrib.face_id) end
        if attrib.hair_id ~= nil then msg:set_hair_style(attrib.hair_id) end
        if attrib.hair_color ~= nil then msg:set_hair_color(attrib.hair_color) end
        set_visuals(attrib)
        if attrib.pet_soul_melting_model ~= nil then
            msg:set_pet_soul_melting_model(attrib.pet_soul_melting_model)
        end
        if attrib.ride_model ~= nil then
            msg:set_ride_model(attrib.ride_model)
        end
    end
    Net:send(msg)
end

function request:CGTeamLeave()
    local my_guid = ma_func:get_guid()
    skynet.send(".world", "lua", "char_leave_team", my_guid, self)
end

function request:CGAskTeamFollow()
    skynet.send(my_scene, "lua", "char_ask_team_follow", my_obj_id, self)
end

function request:CGReturnTeamFollow()
    skynet.send(my_scene, "lua", "char_return_team_follow", my_obj_id, self)
end

function request:CGStopTeamFollow()
    skynet.logi("[TEAM_FOLLOW_REQUEST] client_stop guid=", ma_func:get_guid(), "scene=", my_scene, "obj=", my_obj_id)
    skynet.send(".world", "lua", "stop_team_follow", ma_func:get_guid())
end

function request:CGCGWPacket()
    local my_guid = ma_func:get_guid()
    local function refresh_war_list(subtype)
        local id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local g, list = skynet.call(".Guildmanager", "lua", "guild_zhengtao", my_guid, {guild_id=id,args={0,0,6+subtype}})
        if not g or not list then return end
        local msg = packet_def.GCWGCPacket.new();msg.type=4;msg.wgc_guild=g;Net:send(msg)
        msg = packet_def.GCWGCPacket.new();msg.type=10;msg.wgc_zhengtao=list;Net:send(msg)
    end
    if self.type == 1 then
        local guild_id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local result = skynet.call(my_scene, "lua", "check_human_occupy_city", my_obj_id)
        if not result then
            return
        end
        local city_apply = self.city_apply
        city_apply.guild_id = guild_id
        local city_id
        result, city_id = skynet.call(".Guildmanager", "lua", "city_apply", my_guid, city_apply)
        if result then
            local cost_call_ok, cost_ok = pcall(skynet.call, my_scene, "lua",
                "cost_human_occupy_city", my_obj_id)
            if not cost_call_ok or cost_ok ~= true then
                skynet.loge("[CITY_APPLY_COST_FAIL] rollback, guild_id =", guild_id,
                    ", city_id =", tostring(city_id), ", error =", tostring(cost_ok))
                pcall(skynet.call, ".Guildmanager", "lua", "rollback_city_apply", guild_id, city_id)
            end
        else
            ma_func:notify_tips("帮会城市创建失败，请稍后重试")
        end
    elseif self.type == 2 then
        local guild_id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local packet = {}
        packet.guild_id = guild_id
        packet.args = self.data
        local guild, zhengtao_info = skynet.call(".Guildmanager", "lua", "guild_zhengtao", my_guid, packet)
        if not guild or not zhengtao_info then return end
        local msg = packet_def.GCWGCPacket.new()
        msg.type = 4
        msg.wgc_guild = guild
        Net:send(msg)
        msg = packet_def.GCWGCPacket.new()
        msg.type = 10
        msg.wgc_zhengtao = zhengtao_info
        Net:send(msg)
    elseif self.type == 3 then
        self.guild_wild_war.my_guild_id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local ambi_level = skynet.call(".Guildmanager", "lua", "city_get_attr", self.guild_wild_war.my_guild_id, 5)
        if ambi_level < 100 then
            ma_func:notify_tips("帮会宣战需要消耗100点扩张")
            return
        end
        skynet.call(".Guildmanager", "lua", "guild_wild_war", my_guid, self.guild_wild_war)
        refresh_war_list(0)
    elseif self.type == 7 then
        local kick_guild_id = (self.data[3] or 0) + 256 * (self.data[4] or 0)
        ma_func:guild_league_kick(kick_guild_id)
    elseif self.type == 11 then
        skynet.call(".Guildmanager", "lua", "guild_war", my_guid, self.guild_war)
        refresh_war_list(self.guild_war.initiate_or_accept == 0 and 3 or 2)
    elseif self.type == 12 then
        local guild_id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local params = skynet.call(".Guildmanager", "lua", "get_guild_int_nums", my_guid, guild_id)
        if params == nil then
            return
        end
        local msg = packet_def.GCWGCPacket.new()
        msg.type = 12
        msg.wgc_int_nums = params
        Net:send(msg)
    end
end

function request:CGWGuildLeagueList()
   ma_func:CGWGuildLeagueList(self)
end

function request:CGWGuildLeagueInfo()
    ma_func:CGWGuildLeagueInfo(self)
end

function request:CGWGuildLeagueAskEnter()
    ma_func:CGWGuildLeagueAskEnter(self)
end

function request:CGWGuildLeagueQuit()
    ma_func:CGWGuildLeagueQuit(self)
end

function request:CGWGuildLeagueMemberApplyList()
    ma_func:CGWGuildLeagueMemberApplyList(self)
end

function request:CGWGuildLeagueAnswerEnter()
    ma_func:CGWGuildLeagueAnswerEnter(self)
end

function request:CGCreateGuildLeague()
    ma_func:CGCreateGuildLeague(self)
end

function request:CGGuildApply()
    ma_func:CGGuildApply(self)
    subscribe_guild_multicast(ma_func:get_guild_id())
end

function request:CGGuild()
    ma_func:CGGuild(self)
end

function request:CGGuildJoin()
    ma_func:CGGuildJoin(self)
end

function request:CGMissionCheck()
    skynet.send(my_scene, "lua", "char_mission_check", my_obj_id, self)
end

function request:CGExchangeReplyI()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
	local my_data = ma_func:get_my_data()
	if not my_data then
		return
	end
	local guid = my_data.attrib.guid
	local save_lv,game_agent = skynet.call(".gamed", "lua", "check_save_lv", guid)
	if not save_lv or save_lv ~= my_data.game_flag.save_lv then
		local collection = "log_save_lv_change"
		local doc = { 
			fun_name = "CGExchangeReplyI",
			error_msg = "数据版本号异常_请求接受交易",
			guid = guid,
			name = my_data.attrib.name,
			curlv = save_lv,
			game_agent = game_agent,
			datalv = my_data.game_flag.save_lv,
			data_agent = my_data.game_flag.agent,
			sceneid = my_data.attrib.sceneid,
			world_pos = my_data.attrib.world_pos,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		ma_func:notify_tips("角色数据异常，请重新登陆游戏再进行操作。")
		return
	end
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.send(my_scene, "lua", "char_exchange_reply_I", my_obj_id, self)
end

function request:CGExchangeSynchItemII()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_exchange_sync_item_II", my_obj_id, self)
end

function request:CGExchangeSynchMoneyII()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_exchange_sync_money_II", my_obj_id, self)
end

function request:CGExchangeSynchLock()
    skynet.send(my_scene, "lua", "char_exchange_synch_lock", my_obj_id, self)
end

function request:CGExchangeCancel()
    skynet.send(my_scene, "lua", "char_exchange_cancel", my_obj_id, self)
end

function request:CGExchangeOkIII()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    skynet.send(my_scene, "lua", "char_exchange_ok_III", my_obj_id, self)
end

function request:CGAskCampaignCount()
    skynet.send(my_scene, "lua", "char_ask_campaign_count", my_obj_id, self)
end

function request:CGAskSecKillNum()
    skynet.send(my_scene, "lua", "char_ask_sec_kill_num", my_obj_id, self)
end

function request:CGAskSecKillData()
    skynet.send(my_scene, "lua", "char_ask_sec_kill_data", my_obj_id, self)
end

function request:CGCharUpdateCurTitle()
    skynet.send(my_scene, "lua", "char_update_cur_title", my_obj_id, self)
end

function request:CGByname()
    skynet.send(my_scene, "lua", "char_by_name", my_obj_id, self)
end

function request:CGZdZdRequest()
    skynet.send(my_scene, "lua", "char_zdzd_request", my_obj_id, self)
end

function request:CGSecKillRemoveItem()
    skynet.send(my_scene, "lua", "char_sec_kill_remove_item", my_obj_id, self)
end

function request:CGReportWaigua()
    if ma_func:check_right_ban() then
        local str = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", self.guid))
        local _, account = string.match(str, "GUID是(%d+)的玩家的账号是 (.+)")
        if account then
            skynet.send(".gamed", "lua", "ban_user", account)
        end
    end
end

local cys_mail_guard = require "cys_mail_guard"
local cys_mail_admission = {}
function request:CGMail()
    local guid = ma_func:get_guid()
    if self.guid ~= guid then return end
    if not cys_mail_guard.accept(cys_mail_admission, self, skynet.now()/100) then return end
    self.source = ma_func:get_name()
    self.flag = define.MAIL_TYPE.MAIL_TYPE_NORMAL
    self.create_time = os.time()
    self.param_1,self.param_2,self.param_3,self.param_4,self.param_5 = nil,nil,nil,nil,nil
    skynet.send(".world", "lua", "send_player_mail", guid, self)
end

function request:CGAuctionSell()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    if self.price < 2 then
        ma_func:notify_tips("价格不能低于2元宝")
        return
    end
    if self.price > 200000 then
        ma_func:notify_tips("价格不能高于20万元宝")
        return
    end
    -- local my_data = ma_func:get_my_data()
    local my_guid = ma_func:get_guid()
	local my_name = ma_func:get_name()
    local is_full = skynet.call(".Ybexchange", "lua", "before_sell_check_is_full", my_guid, self.type)
    if is_full then
        local msg = packet_def.GCAuctionError.new()
        msg.result = msg.ERR_CODE.SELL_LIST_FULL
        msg.msg = ""
        Net:send(msg)
        return
    end
    local item, item_name, take_level = skynet.call(my_scene, "lua", "auction_sell_before_check", my_obj_id, self)
    if not item then
        return
    end
    local auction_request = {}
    auction_request.type = self.type
    auction_request.take_level = take_level
    auction_request.item = item
    auction_request.item_name = item_name
    auction_request.price = self.price
    auction_request.seller_guid = my_guid
    auction_request.seller_name = my_name
    auction_request.on_sale_date = tonumber(os.date("%y%m%d%H%M"))
    local serial = skynet.call(".Ybexchange", "lua", "sell", auction_request)
    if serial then
        local bag_index = skynet.call(my_scene, "lua", "auction_sell_after_remove", my_obj_id, self)
        if not bag_index or bag_index == define.INVAILD_ID then
			local doc = { 
				logfun = "request:CGAuctionSell",
				logname = "交易市场上架扣除失败",
				logparamx = item,
				logparamz = auction_request,
				name = my_name,
				guid = my_guid,
				date_time = os.date("%y-%m-%d %H:%M:%S")
			}
			skynet.send(".logdb", "lua", "insert", { collection = "log_shanghui_and_shichang", doc = doc})
		end
		bag_index = bag_index or define.INVAILD_ID
        local msg = packet_def.GCAuctionChangeStatus.new()
        msg.unknow_1 = (self.type == 1) and 1 or 0
        msg.bag_index = bag_index
        msg.type = self.type
        msg.prices = { self.price }
        msg.serial = serial
        Net:send(msg)
    end
end

function request:CGAuctionSearch()
    local result = skynet.call(".Ybexchange", "lua", "search", self)
    local msg = packet_def.GCAuctionSearch.new()
    msg.type = self.type
    msg.sub_type = 117--self.sub_type
    msg.order = self.order
    msg.cur_page_num = self.page
    msg.page_total = result.page_total
    msg.merchandise_list = result.merchandise_list
    Net:send(msg)
end

function request:CGAuctionBuy()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("账号限制交易，请联系客服处理")
        return
    end
    local my_guid = ma_func:get_guid()
    local auction_request = {}
    auction_request.guid = my_guid
    auction_request.type = self.type
    auction_request.guid = self.pet_guid or self.item_guid
    auction_request.seller_guid = self.seller_guid
    auction_request.price = self.price
    local merchadise = skynet.call(".Ybexchange", "lua", "find", auction_request)
    if merchadise == nil then
        return
    end
    local can_buy = skynet.call(my_scene, "lua", "auction_buy_before_check", my_obj_id, merchadise)
    if not can_buy then
        return
    end
    local buyd_merchadise = skynet.call(".Ybexchange", "lua", "buy", auction_request)
    if buyd_merchadise == nil then
        return
    end
    local msg = packet_def.GCAuctionChangeStatus.new()
    msg.unknow_1 = 3
    msg.bag_index = 0
    msg.type = self.type
    msg.prices = { self.price }
    msg.serial = 18
    Net:send(msg)
    skynet.call(my_scene, "lua", "auction_buy_after_do", my_obj_id, buyd_merchadise)
end

function request:CGAuctionBoxList()
    local my_guid = ma_func:get_guid()
    local merchadise_list = skynet.call(".Ybexchange", "lua", "get_box_list", my_guid)
    local msg = packet_def.GCAuctionBoxList.new()
    msg.merchadise_list = merchadise_list
    auction_box_list = merchadise_list
    Net:send(msg)
end

function request:CGAuctionGetYB()
    assert(auction_box_list)
    local merchadise
    if self.type == 1 then
        merchadise = auction_box_list.pets[self.index - 10]
    else
        merchadise = auction_box_list.items[self.index]
    end
    local item_name, yuanbao = skynet.call(".Ybexchange", "lua", "get_sold_out_yuanbao", merchadise)
    skynet.call(my_scene, "lua", "auction_get_yb_after_do", my_obj_id, item_name, yuanbao)
    local msg = packet_def.GCAuctionChangeStatus.new()
    msg.unknow_1 = 4
    msg.bag_index = 0
    msg.type = self.type
    msg.prices = { yuanbao }
    msg.serial = 255
    Net:send(msg)
end

function request:CGAuctionModify()
    assert(auction_box_list)
    local merchadise
    if self.type == 1 then
        merchadise = auction_box_list.pets[self.index + 1]
    else
        merchadise = auction_box_list.items[self.index + 1]
    end
    local auction_request = {}
    auction_request.price = self.new_price
    skynet.call(".Ybexchange", "lua", "modify", merchadise, auction_request)
    skynet.call(my_scene, "lua", "auction_modify_after_do", my_obj_id, merchadise.price, self.new_price)
    local msg = packet_def.GCAuctionChangeMoney.new()
    msg.type = self.type
    msg.index = self.index
    msg.new_price = self.new_price
    Net:send(msg)
end

function request:CGAuctionTakeBack()
    assert(auction_box_list)
    local merchadise
    if self.type == 1 then
        merchadise = auction_box_list.pets[self.index - 10]
    else
        merchadise = auction_box_list.items[self.index]
    end
    local can_take_back = skynet.call(my_scene, "lua", "auction_merchadise_take_back_before_check", my_obj_id, merchadise)
    if not can_take_back then
        return
    end
    local take_backd_merchadise = skynet.call(".Ybexchange", "lua", "take_back", merchadise)
    if take_backd_merchadise == nil then
        return
    end
    local msg = packet_def.GCAuctionChangeStatus.new()
    msg.unknow_1 = 2
    msg.bag_index = 0
    msg.type = self.type
    msg.prices = { self.price }
    msg.serial = 18
    Net:send(msg)
    skynet.call(my_scene, "lua", "auction_take_back_after_do", my_obj_id, take_backd_merchadise)
end

function request:CGAuctionExpireBack()
    assert(auction_box_list)
    local merchadise
    if self.type == 1 then
        merchadise = auction_box_list.pets[self.index - 10]
    else
        merchadise = auction_box_list.items[self.index]
    end
    local can_take_back, err_msg = skynet.call(my_scene, "lua", "auction_merchadise_take_back_before_check", my_obj_id, merchadise)
    if not can_take_back then
        ma_func:notify_tips(err_msg)
        return
    end
    local expire_backd_merchadise = skynet.call(".Ybexchange", "lua", "expire_back", merchadise)
    if expire_backd_merchadise == nil then
        ma_func:notify_tips("元宝交易市场取回道具失败，联系客服处理")
        return
    end
    local msg = packet_def.GCAuctionChangeStatus.new()
    msg.unknow_1 = 2
    msg.bag_index = 0
    msg.type = self.type
    msg.prices = { self.price }
    msg.serial = 18
    Net:send(msg)
    skynet.call(my_scene, "lua", "auction_take_back_after_do", my_obj_id, expire_backd_merchadise)
end

function request:CGFinger()
    if self.type == -1 then return end  -- 客户端定时心跳同步包，不需要响应
    local my_guid = ma_func:get_guid()
    local users, finger_flag, position = skynet.call(".world", "lua", "finger", my_guid, self)
    users = users or {}
    finger_flag = finger_flag or 0
    position = position or 0
    local msg = packet_def.GCFinger.new()
    msg.flag = 1
    msg.size = #users
    msg.users = users
    msg.finger_flag = finger_flag
    msg.position = position
    Net:send(msg)
end

function request:CGAskMail()
    local mail_list = get_db_mail_list()
    if self.m_askType == define.ASK_TYPE.ASK_TYPE_LOGIN then
        local msg = packet_def.GCNotifyMail.new()
        msg.m_MailCount = #mail_list
        Net:send(msg)
    else
        local msg = packet_def.GCMail.new()
        if #mail_list > 0 then
            table.insert(msg.mails, mail_list[1])
            delete_mail(mail_list[1])
            msg.count = 1
        else
            msg.count = 0
        end
        msg.leave_count = #mail_list - #msg.mails
        Net:send(msg)
    end
end

function CMD.change_restore_scene_and_pos(scene_id, world_pos)
	ma_func:set_switch_scene_info(scene_id,world_pos)
	local my_data = ma_func:get_my_cur_data()
	if not my_data then
		local my_guid = ma_func:get_my_guid()
		local my_name = ma_func:get_name()
		--封禁
		local account = "找不到帐号"
		local query_tbl = {char_list = {["$elemMatch"] = {["$eq"] = my_guid}}}
		local response = skynet.call(".char_db", "lua", "findOne", {collection = "account",query = query_tbl, selector = {uid = 1}})
		if response and response.uid then
			account = response.uid
		end
		
		local collection = "log_player_data"
		local doc = { 
		fun_name = "CMD:change_restore_scene_and_pos",
		name = my_name,
		guid = my_guid,
		logmsg = {param1 = "数据获取异常(卡回档)",param2 = my_scene,param3 = my_obj_id,account = account},
		date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		
		if account ~= "找不到帐号" then
			skynet.send(".gamed", "lua", "ban_user", account,my_guid)
		end
		ma_func:notify_tips("数据获取异常，您已被清离游戏。")
		skynet.send(".gamed", "lua", "kick", my_guid)
		return 
	end
    -- my_data.attrib.sceneid = scene_id
    -- my_data.attrib.world_pos = world_pos
    ma_func:save_my_data(my_data,"restore_scene")
end

function CMD.relation_on_be_human_kill(name)
    local packet = {}
    local request_relation_info = {}
    request_relation_info.name = name
    request_relation_info.relation_type = define.RELATION_TYPE.RELATION_TYPE_ENEMIES
    request_relation_info.group = "enemy"
    packet.type = 4
    packet.request_relation_info = request_relation_info
    ma_func:CGRelation(packet)
end

function CMD.get_relation_list()
    return ma_func:get_relation_list()
end

function CMD.get_player_info()
    local character = ma_func:get_my_data()
    local setting = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_setting")
    local uinfo = {
        guid = character.attrib.guid,
        name = character.attrib.name,
        level = character.attrib.level,
        menpai = character.attrib.menpai,
        portrait = character.attrib.portrait_id,
        guild = character.attrib.guild or define.INVAILD_ID,
        guild_name = character.attrib.guild_name or "",
        confederate = define.INVAILD_ID,
        confederate_name = "",
        mood = character.relation.mood,
        sceneid = character.attrib.sceneid,
        title = "",
        relation = character.relation,
        client_res = my_client_res,
        game_flags = (setting and setting["2"] or {}).data or 0,
    }
    return uinfo
end

function CMD.get_top_up_point()
    return ma_func:get_top_up_point()
end

function CMD.cost_top_up_point(cost)
    return ma_func:cost_top_up_point(cost)
end

function CMD.get_prerechage_money(...)
    return ma_func:get_prerechage_money(...)
end

function CMD.set_realtion_list(relation_list)
    ma_func:set_relation_list(relation_list)
    local packet = { type = 1 }
    ma_func:CGRelation(packet)
end

function CMD.on_user_guild_recruit_or_guild_expe_or_guild_leave(data)
    ma_func:on_user_guild_recruit_or_guild_expe_or_guild_leave(data)
    subscribe_guild_multicast(data.guild_id)
    local guild_request = { packet_type = 3, type = 3, askid = 0 }
    if data.guild_id ~= -1 then ma_func:CGGuild(guild_request) end
    return true
end

function CMD.on_user_guild_position_changed(updater)
    skynet.send(my_scene, "lua", "on_user_guild_position_changed", my_obj_id, updater)
end

function CMD.get_user_guild_id()
    return skynet.call(my_scene, "lua", "get_user_guild_id", my_obj_id)
end

function CMD.message(xyid, idx, packet)
	-- local guid = ma_func:get_my_guid()
	-- skynet.logi("client call server:xyid = ",xyid,"guid = ",guid,"date = ",utils.get_day_time())
	-- skynet.logi("client call server:xyid = ",xyid)
    Net:dispatch_message(xyid, idx, packet)
end

function CMD.scene_chat_channel_msg(...)
    CMD.send2client(packet_def.GCChat.xy_id, ...)
end

function CMD.menpai_chat_channel_msg(...)
    CMD.send2client(packet_def.GCChat.xy_id, ...)
end

function CMD.world_chat_channel_msg(...)
    local args = { ... }
    local visited = {}
    local function find_newmsg_token(node)
        local t = type(node)
        if t == "string" then
            local script_id, func_name = string.match(node, "_NEWMSG_(%d+)([%w_]+)")
            if script_id and func_name then
                return script_id, func_name, node
            end
            return nil
        end
        if t ~= "table" then
            return nil
        end
        if visited[node] then
            return nil
        end
        visited[node] = true
        for _, vv in pairs(node) do
            local sid, fn, raw = find_newmsg_token(vv)
            if sid and fn then
                return sid, fn, raw
            end
        end
        return nil
    end

    local handled_daily_reset_msg = false
    for i, v in ipairs(args) do
        local script_id, func_name, raw = find_newmsg_token(v)
        if script_id and func_name and my_scene and my_obj_id then
            local ok, err = pcall(
                skynet.call,
                my_scene,
                "lua",
                "char_excute_Script",
                tonumber(script_id),
                func_name,
                my_obj_id
            )
            if not ok then
                skynet.logw(
                    "msgagent: NEWMSG auto call failed, script_id =",
                    script_id,
                    "func =",
                    func_name,
                    "err =",
                    tostring(err)
                )
            end
            handled_daily_reset_msg = script_id == tostring(define.UPDATE_CLIENT_ICON_SRIPTID)
                and func_name == "GetNewDayRestData"
            break
        end
    end
    if handled_daily_reset_msg then
        return
    end
    CMD.send2client(packet_def.GCChat.xy_id, ...)
end

function CMD.update_confederate_id(confederate_id, confederate_name)
    local ret = skynet.call(my_scene, "lua", "update_confederate_id", my_obj_id, confederate_id, confederate_name)
    ma_func:set_confederate_id(confederate_id)
    ma_func:set_confederate_name(confederate_name)
    subscribe_confederate_multicast(confederate_id)
    if ret then
        local guild_request = { packet_type = 3, type = 3, askid = 0 }
        ma_func:CGGuild(guild_request)
    end
end

function CMD.on_guild_info_update(guild_info)
    ma_func:on_guild_info(guild_info)
end

function CMD.guild_multicast_channel(...)
    local xy_id = ...
    if xy_id == define.INVAILD_ID then
        local args = { ... }
        local func_name = args[2]
        local f = CMD[func_name]
        assert(f, func_name)
        table.remove(args, 1)
        table.remove(args, 1)
        f(table.unpack(args))
    else
        CMD.send2client(...)
    end
end

function CMD.league_multicast_channel(...)
    CMD.send2client(...)
end

function CMD.exit()
    ma_func:leave_scene()
end

function CMD.ExitComplete()
	-- ma_func:do_quit()
    ma_func:ExitComplete()
end

function CMD.logout_ex(guid)
	if guid == ma_func:get_my_guid() then
		ma_func:leave_scene()
		CMD.ExitComplete()
	else
		local collection = "log_human_online"
		local doc = { 
			fun_name = "logout_ex",
			error_msg = "服务ID角色已不同",
			guid = guid,
			exist = ma_func:get_my_guid(),
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
	end
end

function CMD.logout(reason)
    if my_scene then
        if reason == "squeeze_out" then
            skynet.call(my_scene, "lua", "squeeze_out", my_obj_id)
        elseif reason == "maintenance" then
            skynet.call(my_scene, "lua", "maintenance", my_obj_id)
        elseif reason == "ban" then
            skynet.call(my_scene, "lua", "ban", my_obj_id)
        end
    end
    ma_func:leave_scene()
	CMD.ExitComplete()
end

function CMD.award_item(item_id, item_count, is_bind)
    if my_scene == nil then
        return "玩家不在场景中"
    end
    return skynet.call(my_scene, "lua", "agent_command_award_item", my_obj_id, item_id, item_count, is_bind)
end

function CMD.resource_update(item_id, item_count)
    if my_scene == nil then
        return { result = false, reason = "玩家不在场景中"}
    end
    return skynet.call(my_scene, "lua", "agent_command_resource_update", my_obj_id, item_id, item_count)
end

function CMD.change_user_nickname(new_nickname)
    if my_scene == nil then
        return "玩家不在场景中"
    end
    return skynet.call(my_scene, "lua", "agent_command_change_user_nickname", my_obj_id, new_nickname)
end

function CMD.change_user_money(new_level)
    if my_scene == nil then
        return "玩家不在场景中"
    end
    return skynet.call(my_scene, "lua", "agent_command_change_user_level", my_obj_id, new_level)
end

function CMD.call_script(script_id, func, params, params_type)
    if my_scene == nil then
        return "玩家不在场景中"
    end
	if params_type == "table" then
		return skynet.call(my_scene, "lua", "agent_command_call_script", script_id, func, my_obj_id, params)
	else
		return skynet.call(my_scene, "lua", "agent_command_call_script", script_id, func, my_obj_id, table.unpack(params))
	end
end

function CMD.check_right_limit_exchange()
    return ma_func:check_right_limit_exchange()
end

local function init_multicast()
    init_world_multicast()
end

local lock = queue()
skynet.start(function()
    -- If you want to fork a work thread , you MUST do it in CMD.login
    Net:add_requests(request)
    init_multicast()
    -- 不再 loadall，依赖 get_config 按需自动加载
    configenginer:loadmany({"allowable_script_fun"})
    skynet.dispatch("lua", function(_, source, command, ...)
        local args = {...}
		if direct_commands[command] then
            local f = assert(CMD[command], command)
            skynet.ret(skynet.pack(f(table.unpack(args))))
        elseif command == "set_fd" then
            local f = assert(CMD[command], command)
            skynet.ret(skynet.pack(f(source, table.unpack(args))))
        else
            lock(function ()
                local f = assert(CMD[command], command)
                skynet.ret(skynet.pack(f(table.unpack(args))))
            end)
        end
    end)
end)
