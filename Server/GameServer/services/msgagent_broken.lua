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
local auction_box_list
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
    if my_scene then
        return skynet.call(my_scene, "lua", "on_notify_team_result", my_obj_id, packet)
    end
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
			error_msg = "鍔犺浇鏁版嵁鐗堟湰鍙峰紓甯?,
			guid = guid,
			name = my_data.attrib.name,
			curlv = save_lv,
			datalv = my_data.game_flag.save_lv,
			sceneid = my_data.attrib.sceneid,
			world_pos = my_data.attrib.world_pos,
			date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		--鏆傛椂璁板綍鏃ュ織锛屼笉鏂█
		-- assert(false,"鍔犺浇鏁版嵁鐗堟湰鍙蜂笉鍚屾銆?)
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
			logmsg = {param1 = "鍦烘櫙鍙风浉鍚?,param2 = packet.scene_to},
			date_time = utils.get_day_time()
			}
			skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
			-- checkxy = false
			-- assert(false,"CMD.send2client error!!!")
			assert(false,"鍦烘櫙鍙风浉鍚?)
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
            print("channel =>", channel, "; source=>", source, ";... =>", ...)
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
                print("channel =>", channel, "; source=>", source, ";... =>", ...)
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
                    print("channel =>", channel, "; source=>", source, ";... =>", ...)
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
                    print("channel =>", channel, "; source=>", source, ";... =>", ...)
                    CMD.league_multicast_channel(...)
                end
            }
            confederate_multicast_channel:subscribe()
        end
    end
end



function request:CGRankingLists()
	skynet.call(my_scene, "lua", "char_ranking_lists", my_obj_id, self)

    -- local ret = packet_def.WGCRetNormalRankList.new()
	-- Net:send(ret)
end

function request:CGAskDynamicRegion()
    local ret = packet_def.GCAskDynamicRegionResult.new()
    Net:send(ret)
end

function request:CGExecuteScript()
	skynet.logi("[XSCRIPT] CGExecuteScript: scriptID=", self.m_ScriptID, " func=", self.m_szFunName,
		" paramCount=", self.m_aParam and #self.m_aParam or 0,
		" params=", table.concat(self.m_aParam or {}, ","))
	if not self.m_ScriptID or not self.m_szFunName then
		skynet.logi("[XSCRIPT] REJECT: scriptID or funcName is nil")
		return
	end
	local index =self.m_ScriptID -- tostring(self.m_szFunName).."_"..tostring(self.m_ScriptID)
	local configs = configenginer:get_config("allowable_script_fun")
	if configs[index] then
		skynet.logi("[XSCRIPT] DISPATCH: scriptID=", index, " func=", self.m_szFunName, " objId=", my_obj_id)
		skynet.call(my_scene, "lua", "char_excute_Script", self.m_ScriptID, self.m_szFunName, my_obj_id, table.unpack(self.m_aParam))
		 --return self.scriptenginer:raw_call(script_id, func, ...)
	else
	    local cnt = 0; if configs then for _ in pairs(configs) do cnt = cnt + 1 end end
	    skynet.logi("[XSCRIPT] NOT_REGISTERED: scriptID=", self.m_ScriptID, " func=", self.m_szFunName,
			" configCount=", cnt)
	end
end

function request:CGNetDelay()
    local ret = packet_def.GCRetNetDelay.new()
    Net:send(ret)
end

function request:CGAskQuit()
    if self.unknow_2 == 0 then
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
    skynet.call(my_scene, "lua", "char_shop_buy", my_obj_id, self)
end

function request:CGShopClose()
end

function request:CGAskDetailAttrib()
    skynet.call(my_scene, "lua", "ask_detail_attrib", my_obj_id, self)
end

function request:CGCharAskBaseAttrib()
    skynet.call(my_scene, "lua", "ask_base_attrib", self.m_objID, my_obj_id)
end

function request:CGCharAskEquipment()
    skynet.call(my_scene, "lua", "ask_char_equipment", self.m_objID, my_obj_id)
end

function request:CGCharAskImpactList()
    skynet.call(my_scene, "lua", "ask_impact_list", self.m_objID, my_obj_id)
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
    skynet.call(my_scene, "lua", "char_use_item", my_obj_id, self)
end

function request:CGAskDetailAbilityInfo()
    skynet.call(my_scene, "lua", "ask_detail_ability_info", self.m_objID, my_obj_id)
end

function request:CGAskDetailXinFaList()
    skynet.call(my_scene, "lua", "ask_detail_xinfa_list", self.m_objID, my_obj_id)
end

function request:CGAskDetailSkillList()
    skynet.call(my_scene, "lua", "ask_detail_skill_list", self.m_objID, my_obj_id)
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
    skynet.call(my_scene, "lua", "ask_wuhun_wg", my_obj_id, self)
end

function request:CGAskFashionDepotData()
    skynet.call(my_scene, "lua", "ask_fashion_depot_data", my_obj_id)
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
        ma_func:notify_tips("寮哄埗瑙ｉ櫎浜岀骇瀵嗙爜璇疯仈绯诲鏈?)
        return
    end
    Net:send(msg)
end

function request:CGAskDetailEquipList()
    skynet.call(my_scene, "lua", "ask_detail_equip_list", my_obj_id, self)
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
    skynet.call(my_scene, "lua", "char_ask_chedifulu_data", my_obj_id, self)
end

function request:CGAskMissionList()
    skynet.call(my_scene, "lua", "char_ask_mission_list", my_obj_id, self)
end

function request:CGAskSetting()
    skynet.call(my_scene, "lua", "char_ask_setting", my_obj_id, self)
end

function request:CGPlayerShopEstablish()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_player_shop_establish", my_obj_id, self)
end

function request:CGPlayerShopMoney()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_player_shop_money", my_obj_id, self)
end

function request:CGPlayerShopBuyItem()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_player_shop_buy_item", my_obj_id, self)
end

function request:CGPlayerShopOpenStall()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_player_shop_open_stall", my_obj_id, self)
end

function request:CGPlayerShopDesc()
    skynet.call(my_scene, "lua", "char_player_shop_desc", my_obj_id, self)
end

function request:CGPlayerShopName()
    skynet.call(my_scene, "lua", "char_player_shop_name", my_obj_id, self)
end

function request:CGPlayerShopPartner()
	-- skynet.logi("CGPlayerShopPartner")
    skynet.call(my_scene, "lua", "char_player_shop_partner", my_obj_id, self)
end

function request:CGPlayerShopAskForRecord()
	-- skynet.logi("CGPlayerShopAskForRecord")
    skynet.call(my_scene, "lua", "char_player_shop_ask_for_record", my_obj_id, self)
end

function request:CGPlayerShopAcquireShopList()
	-- skynet.logi("CGPlayerShopAcquireShopList")
    skynet.call(my_scene, "lua", "char_player_shop_acquire_shop_list", my_obj_id, self)
end

function request:CGPlayerShopAcquireItemList()
	-- skynet.logi("CGPlayerShopAcquireItemList")
    skynet.call(my_scene, "lua", "char_player_shop_acquire_item_list", my_obj_id, self)
end

function request:CGPlayerShopOnSale()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_player_shop_on_sale", my_obj_id, self)
end

function request:CGPlayerShopSize()
    skynet.call(my_scene, "lua", "char_player_shop_size", my_obj_id, self)
end

function request:CGItemSynch()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_item_sync", my_obj_id, self)
end

function request:CGCharAllTitles()
    skynet.call(my_scene, "lua", "char_all_titles", my_obj_id, self)
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

function CMD.char_enter_team_follow(...)
    if my_scene and my_obj_id then
        skynet.call(my_scene, "lua", "char_enter_team_follow", my_obj_id, ...)
    end
end

function CMD.char_stop_team_follow_self()
    if my_scene and my_obj_id then
        skynet.call(my_scene, "lua", "char_stop_team_follow_self", my_obj_id)
    end
end

function CMD.char_del_team_follow_member(del_guid)
    if my_scene and my_obj_id then
        skynet.call(my_scene, "lua", "char_del_team_follow_member", my_obj_id, del_guid)
    end
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
    print("mail_list =", table.tostr(mail_list))
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
end

function request:CGCharDefaultEvent()
    skynet.call(my_scene, "lua", "char_default_event", my_obj_id, self)
end

function request:CGEventRequest()
    print("event request self =", table.tostr(self))
    skynet.call(my_scene, "lua", "char_event_request", my_obj_id, self)
end

			bug_name = "鏈嶅姟鏁版嵁鐗堟湰鍙蜂笉鍚?
		elseif game_agent ~= ma_func_agent then
			bug_name = "瑙掕壊鏈嶅姟ID寮傚父"
		elseif my_guid ~= data_guid then
			bug_name = "鏁版嵁GUID涓庢湇鍔UID涓嶇"
		else
			if change_scene_args then
				sceneid = change_scene_args.sceneid
				world_pos = change_scene_args.world_pos
				change_scene_args = nil
			else
				if my_data.game_flag.login_user ~= 1 then
					bug_name = "閲嶈繛"
				end
			end
		end
	else
		bug_name = "瑙掕壊鏈嶅姟娌℃湁瑙掕壊鏁版嵁"
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
			-- 鎸夐渶鍒涘缓闈炴牳蹇冨満鏅?
			local ok = pcall(skynet.call, ".SceneManager", "lua", "ensure_scene", sceneid)
			if ok then
				exist = pcall(skynet.call, dest_scene, "debug", "PING")
			end
			if not exist then
				sceneid = define.DEFAULT_SCENEID_AND_WORLD_POS.sceneid
				world_pos = define.DEFAULT_SCENEID_AND_WORLD_POS.world_pos
			end
		end
	end
    local teaminfo,new_sceneId = skynet.call(".world", "lua", "get_my_teaminfo", my_guid,sceneid)
    if new_sceneId then
		sceneid = new_sceneId
	end
	my_data.attrib.sceneid = sceneid
	my_data.attrib.world_pos = world_pos
	my_scene = string.format(".SCENE_%d", sceneid)
	local guildinfo = skynet.call(".Guildmanager", "lua", "get_guild_by_id", my_data.attrib.guild_id)
    -- local scene_type = skynet.call(my_scene, "lua", "get_type")
	local agent_or_node_name
	local save_true = my_data.game_flag.save_true or 0
	local fun_sceneid = ma_func:get_my_scene_id()
	local new_save_true,scene_type,new_data = skynet.call(my_scene, "lua", "check_before_enter", my_guid,save_true,fun_sceneid)
	if not scene_type then
		local collection = "log_CGEnterScene"
		local doc = {
			bug_name = "杩涘叆鍦烘櫙澶辫触锛屽瓨鍦ㄨ鑹?,
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
		ma_func:notify_tips("ERROR0001:杩涘叆鐨勫満鏅瓨鍦ㄨ瑙掕壊锛岃绂绘父鎴忋€?)
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
			bug_name = "杩涘叆鍦烘櫙澶辫触锛屾洿鏂板瓨妗ｆ暟鎹?,
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
			bug_name = "杩涘叆鍦烘櫙澶辫触锛屽満鏅凡婊″憳",
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
		ma_func:notify_tips("ERROR0001:杩涘叆鍦烘櫙澶辫触锛屽満鏅凡婊″憳銆?)
		CMD.logout_ex(my_guid)
		return
	end
    ma_func:on_enter_scene(my_scene, my_obj_id, sceneid)
	local attrib = my_data.attrib
	local game_flag = my_data.game_flag
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
    -- 鍏堝畬鎴愭墍鏈夐閬撹闃咃紙鍖呮嫭閲嶆柊璁㈤槄涓栫晫棰戦亾锛夛紝鍐嶉€氱煡涓栫晫锛岄伩鍏嶆紡娑堟伅
    init_world_multicast()
    if scene_type ~= 4 then
        local channelid = skynet.call(my_scene, "lua", "get_multicast_channel")
        subscribe_scene_multicast(channelid)
    end
    subscribe_guild_multicast(attrib.guild_id)
    subscribe_confederate_multicast(attrib.confederate_id)
    subscribe_menpai_multicast(attrib.menpai)
    skynet.call(".world", "lua", "player_enter_scene", my_guid)
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
	if not change_scene_args then
		table.insert(error_params,"娌℃湁鍒囨崲鍦烘櫙鏁版嵁")
	end
	local data
	local call_name = "change_scene"
	if my_scene then
		data = skynet.call(my_scene, "lua", "leave",my_guid,ma_func:get_del_obj_flag())
		if data then
			call_name = "leave_scene"
		else
			table.insert(error_params,"鍦烘櫙鎵句笉鍒拌鑹叉暟鎹紝瀛樺湪鍥炴。鐨勫彲鑳芥€?)
			data = ma_func:get_my_data()
		end
	else
		table.insert(error_params,"娌℃湁鍦烘櫙锛岀櫥闄嗗嵆鍒囨崲锛屼笉鍚堢悊鐨勮Е鍙?)
		data = ma_func:get_my_data()
	end
	if data.attrib.guid ~= my_guid then
		table.insert(error_params,"鏁版嵁GUID涓庤鑹叉湇鍔UID涓嶇")
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
		table.insert(error_params,"瀛樻。lv寮傚父")
	end
	if game_agent ~= ma_func_agent then
		table.insert(error_params,"鏈嶅姟ID寮傚父")
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
end

function request:CGPackage_SwapItem()
    skynet.call(my_scene, "lua", "package_swap_item", my_obj_id, self)
end

function request:CGSplitItem()
    skynet.call(my_scene, "lua", "char_split_item", my_obj_id, self)
end

function request:CGAskItemInfo()
    skynet.call(my_scene, "lua", "ask_item_info", my_obj_id, self)
end

function request:CGUseEquip()
    skynet.call(my_scene, "lua", "char_use_equip", my_obj_id, self)
end

function request:CGUnEquip()
    skynet.call(my_scene, "lua", "char_un_equip", my_obj_id, self)
end

function request:CGDispelBuffReq()
    skynet.call(my_scene, "lua", "char_diepel_buff", my_obj_id, self)
end

function request:CGSetMoodToHead()
    skynet.call(my_scene, "lua", "char_set_mood_to_head", my_obj_id, self)
end

function request:CGPackUpPacket()
    local ret = packet_def.GCPackUpPacket.new()
    ret.unknow = self.unknow
    Net:send(ret)
end

function request:CGShowFashionDepotData()
    local ret = packet_def.GCShowFashionDepotData.new()
    ret.unknow = self.unknow
    Net:send(ret)
end

function request:CGCharMove()
    skynet.call(my_scene, "lua", "char_move", my_obj_id, self)
end

function request:CGCharPositionWarp()
    skynet.call(my_scene, "lua", "char_position_warp", self)
end

function request:CGOrnamentsOperation()
    skynet.call(my_scene, "lua", "char_headwear_backwear_sync_request", my_obj_id, self)
end

-- 澶勭悊 CGExteriorSharePlan (opcode 287, 鐝嶈棌/閴磋祻闃?
function request:CGExteriorSharePlan()
    self.op_type = self.op_code or 1  -- 鏄犲皠瀛楁鍚?
    request.GCTarExteriorSharePlan(self)  -- 杞彂鍒板疄闄呭鐞嗛€昏緫
end

function request:CGExteriorRequest()
    skynet.call(my_scene, "lua", "char_exterior_request", my_obj_id, self)
end

function request:CGCharUseSkill()
    skynet.call(my_scene, "lua", "char_use_skill", my_obj_id, self)
end

function request:CGLockTarget()
    skynet.call(my_scene, "lua", "char_lock_target", my_obj_id, self)
end

function request:CGOpenItemBox()
    skynet.call(my_scene, "lua", "char_open_box_item", my_obj_id, self)
end

function request:CGPickBoxItem()
    skynet.call(my_scene, "lua", "char_pick_box_item", my_obj_id, self)
end

function request:CGModifySetting()
    skynet.call(my_scene, "lua", "char_modify_setting", my_obj_id, self)
end

function request:CGAskStudyXinfa()
    local xinfa = skynet.call(my_scene, "lua", "call_human_function", my_obj_id, "get_xinfa", self.xinfa)
    if not xinfa then
        ma_func:notify_tips("蹇冩硶鏁版嵁涓嶅瓨鍦?)
        return
    end
    if xinfa.m_nXinFaLevel ~= self.now_level then
        ma_func:notify_tips("闈炴硶璇锋眰")
        return
    end
    skynet.call(my_scene, "lua", "char_study_xinfa", my_obj_id, self)
end

function request:CGReqLevelUp()
    skynet.call(my_scene, "lua", "char_req_level_up", my_obj_id, self)
end

function request:CGRemoveGem()
    skynet.call(my_scene, "lua", "char_remove_gem", my_obj_id, self)
end

function request:CGRemoveDressGem()
    skynet.call(my_scene, "lua", "char_remove_dress_gem", my_obj_id, self)
end

function request:CGGemCompound()
    skynet.call(my_scene, "lua", "char_gem_compound", my_obj_id, self)
end

function request:CGDisplaceGem()
    skynet.call(my_scene, "lua", "char_displace_gem", my_obj_id, self)
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
    skynet.call(my_scene, "lua", "char_use_ability", my_obj_id, self)
end

function request:CGDiscardItem()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.call(my_scene, "lua", "char_discard_item", my_obj_id, self)
end

function request:CGBankAcquireList()
    skynet.call(my_scene, "lua", "char_bank_acquire_list", my_obj_id, self)
end

function request:CGBankAddItem()
    skynet.call(my_scene, "lua", "char_bank_add_item", my_obj_id, self)
end

function request:CGBankSwapItem()
    skynet.call(my_scene, "lua", "char_bank_swap_item", my_obj_id, self)
end

function request:CGBankRemoveItem()
    skynet.call(my_scene, "lua", "char_bank_remove_item", my_obj_id, self)
end

function request:CGPackUpBank()
    skynet.call(my_scene, "lua", "char_bank_pack_up", my_obj_id, self)
end

function request:CGPlayerDieResult()
    skynet.call(my_scene, "lua", "char_die_result", my_obj_id, self)
end

function request:CGPetBankAddPet()
    skynet.call(my_scene, "lua", "char_pet_bank_add_pet", my_obj_id, self)
end

function request:CGShopSell()
    skynet.call(my_scene, "lua", "char_shop_sell", my_obj_id, self)
end

local last_world_chat_time = nil
local last_menpai_chat_time = nil
local last_city_chat_time = nil
function request:CGChat()
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_SCENE then
        local now = os.time()
        if last_world_chat_time and now - last_world_chat_time < 150 then
            ma_func:notify_tips("涓栫晫鑱婂ぉ鏆傛椂鍏抽棴")
            return
        end
        last_world_chat_time = now
    end
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_MENPAI then
        local now = os.time()
        if last_menpai_chat_time and now - last_menpai_chat_time < 150 then
            ma_func:notify_tips("闂ㄦ淳鑱婂ぉ闇€瑕佺瓑寰?鍒嗛挓")
            return
        end
        last_menpai_chat_time = now
    end
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_CITY then
        local now = os.time()
        if last_city_chat_time and now - last_city_chat_time < 10 then
            ma_func:notify_tips("鍩庡競鑱婂ぉ闇€瑕佺瓑寰?0绉掗挓")
            return
        end
        last_city_chat_time = now
    end
    if self.ChatType == define.ENUM_CHAT_TYPE.CHAT_TYPE_MAIL then
        local friend_point = ma_func:get_friend_point(self.dest_guid)
        if friend_point == 0 then
            ma_func:notify_tips("鍙屽悜濂藉弸鎵嶈兘濂藉弸鑱婂ぉ")
        else
            skynet.call(my_scene, "lua", "char_chat", my_obj_id, self)
        end
    else
        skynet.call(my_scene, "lua", "char_chat", my_obj_id, self)
    end
end

function request:CGCharFly()
    skynet.call(my_scene, "lua", "char_fly", my_obj_id, self)
end

function request:CGCharAutoRide()
    skynet.call(my_scene, "lua", "char_auto_ride", my_obj_id, self.flag)
end

function request:CGReqManualAttr()
    skynet.call(my_scene, "lua", "char_manual_attr", my_obj_id, self)
end

function request:CGFashionDepotOperation()
    skynet.call(my_scene, "lua", "char_fashion_depot_operation", my_obj_id, self)
end

function request:CGAskDoubleExp()
    skynet.call(my_scene, "lua", "char_ask_double_exp_info", my_obj_id, self)
end

function request:CGManipulatePet()
    if self.type == define.ENUM_MANIPULATE_TYPE.MANIPULATE_FREEPET then
        if not ma_func:is_minor_password_is_unlock() then
            ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
            return
        end
    end
    skynet.call(my_scene, "lua", "char_manipulate_pet", my_obj_id, self)
end

function request:CGSetPetAttrib()
    skynet.call(my_scene, "lua", "char_set_pet_attrib", my_obj_id, self)
end

function request:CGAskDarkAdjust()
    skynet.call(my_scene, "lua", "char_adjust_dark", my_obj_id, self)
end

function request:CGPetUseEquip()
    skynet.call(my_scene, "lua", "char_use_pet_equip", my_obj_id, self)
end

function request:CGPetUnEquip()
    skynet.call(my_scene, "lua", "char_un_pet_equip", my_obj_id, self)
end

function request:CGMissionSubmit()
    skynet.call(my_scene, "lua", "char_mission_submit", my_obj_id, self)
end

function request:CGChangePkModeReq()
    skynet.call(my_scene, "lua", "char_req_change_pk_mode", my_obj_id, self)
end

function request:CGCharJump()
    skynet.call(my_scene, "lua", "char_jump", my_obj_id, self)
end

function request:CGKfsOperate()
    skynet.call(my_scene, "lua", "char_kfs_operate", my_obj_id, self)
end

function request:CGAskPrivateInfo()
    skynet.call(my_scene, "lua", "char_ask_private_info", my_obj_id, self)
end

function request:CGPetSoulXiShuXing()
    skynet.call(my_scene, "lua", "char_pet_xishuxing", my_obj_id, self)
end

function request:CGChallenge()
    skynet.call(my_scene, "lua", "char_challenge", my_obj_id, self)
end

function request:CGStallApply()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    local scene_type = skynet.call(my_scene, "lua", "get_type")
    if scene_type == 0 then
        skynet.call(my_scene, "lua", "char_stall", my_obj_id, self)
    else
        skynet.logi("CGStallApply invaild guid =", ma_func:get_guid(), ";scene_type =", scene_type, ";my_scene =", my_scene)
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
			error_msg = "鏁版嵁鐗堟湰鍙峰紓甯竉璇锋眰鎽嗘憡",
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
		ma_func:notify_tips("瑙掕壊鏁版嵁寮傚父锛岃閲嶆柊鐧婚檰娓告垙鍐嶈繘琛屾搷浣溿€?)
		return
	end
    skynet.call(my_scene, "lua", "char_stall_establish", my_obj_id, self)
end

function request:CGStallOpen()
    skynet.call(my_scene, "lua", "char_stall_open", my_obj_id, self)
end

function request:CGStallAddItem()
    skynet.call(my_scene, "lua", "char_stall_add_item", my_obj_id, self)
end

function request:CGStallItemPrice()
    skynet.call(my_scene, "lua", "char_stall_item_price", my_obj_id, self)
end

function request:CGStallRemoveItem()
    skynet.call(my_scene, "lua", "char_stall_remove_item", my_obj_id, self)
end

function request:CGStallClose()
    skynet.call(my_scene, "lua", "char_close_stall", my_obj_id, self)
end

function request:CGStallBuy()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    local scene_type = skynet.call(my_scene, "lua", "get_type")
    if scene_type == 0 then
        skynet.call(my_scene, "lua", "char_stall_buy", my_obj_id, self)
    else
        skynet.logi("CGStallBuy invaild guid =", ma_func:get_guid(), ";scene_type =", scene_type, ";my_scene =", my_scene)
    end
end

function request:CGStallShopName()
    skynet.call(my_scene, "lua", "char_stall_shop_name", my_obj_id, self)
end

function request:CGAntagonistReq()
    skynet.call(my_scene, "lua", "char_antagonist_req", my_obj_id, self)
end

function request:CGBBSApply()
    skynet.call(my_scene, "lua", "char_bbs_apply", my_obj_id, self)
end

function request:CGBBSSychMessages()
    skynet.call(my_scene, "lua", "char_bbs_sync_messages", my_obj_id, self)
end

function request:CGAcqStallOpen()
    skynet.call(my_scene, "lua", "char_acq_stall_open", my_obj_id, self)
end

function request:CGAcqStallAddItem()
    skynet.call(my_scene, "lua", "char_acq_stall_add_item", my_obj_id, self)
end

function request:CGAcqStallRemoveItem()
    skynet.call(my_scene, "lua", "char_acq_stall_remove_item", my_obj_id, self)
end

function request:CGAcqStallSell()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_acq_stall_sell", my_obj_id, self)
end

function request:CGMissionAbandon()
    skynet.call(my_scene, "lua", "char_mission_abandon", my_obj_id, self)
end

function request:CGMissionAccept()
    skynet.call(my_scene, "lua", "char_mission_accept", my_obj_id, self)
end

function request:CGMissionContinue()
    skynet.call(my_scene, "lua", "char_mission_continue", my_obj_id, self)
end

function request:CGExchangeApplyI()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
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
			error_msg = "鏁版嵁鐗堟湰鍙峰紓甯竉璇锋眰浜ゆ槗",
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
		ma_func:notify_tips("瑙掕壊鏁版嵁寮傚父锛岃閲嶆柊鐧婚檰娓告垙鍐嶈繘琛屾搷浣溿€?)
		return
	end
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.call(my_scene, "lua", "char_exchange_apply_I", my_obj_id, self)
end

function request:CGSectOper()
    skynet.call(my_scene, "lua", "char_sect_oper", my_obj_id, self)
end

function request:CGBankMoney()
    skynet.call(my_scene, "lua", "char_bank_money", my_obj_id, self)
end

function request:CGAskTargetESPlan()
    skynet.call(my_scene, "lua", "char_ask_target_es_plan", my_obj_id, self)
end

-- 瀹㈡埛绔敤 wire opcode 1168 C->S 璇锋眰/淇濆瓨 鐝嶈棌澶栬鍒嗕韩鏂规
-- op_type 1-6=鏌ョ湅璇锋眰, 7=淇濆瓨鏍囩, 8=淇濆瓨鏃惰, 9=淇濆瓨鍧愰獞, 10=淇濆瓨骞婚グ, 15=鎻愪氦鏃惰鍒版柟妗? 20=淇濆瓨鏂规ID
function request:GCTarExteriorSharePlan()
    local op = self.op_type or 1

    if op <= 6 then
        -- ======== 鏌ョ湅璇锋眰 ========
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
            msg.type_code = 2     -- 鍏ㄩ噺鏁版嵁
        elseif sub_code == 3 then
            msg.type_code = 3     -- 涓€ф爣绛?(鎵撳紑缂栬緫妗? event 1141)
        elseif sub_code == 4 or sub_code == 5 or sub_code == 6 then
            -- IDA纭: type=16瑙﹀彂OPEN_EXTERIOR_SHAREPLAN(鏂规淇濆瓨绐楀彛), 涓嶆槸缂栬緫鍣?
            -- 鏃惰缂栬緫鍣? GCAskFashionDepotData flag=1 鈫?event 1142 (OPEN_EXTERIOR_DRESSCHOOSE)
            -- 鍧愰獞缂栬緫鍣? GCExteriorInfo type=4,sub=5 鈫?event 1143 (OPEN_EXTERIOR_RIDECHOOSE)
            -- 骞婚グ缂栬緫鍣? GCExteriorInfo type=8,sub=5 鈫?event 1144 (OPEN_EXTERIOR_WEAPONCHOOSE)
            if sub_code == 4 then
                -- 鏃惰缂栬緫鍣? 鍙戦€丗ashionDepot鏁版嵁, open_editor=1瑙﹀彂缂栬緫鍣ㄦ墦寮€
                skynet.call(my_scene, "lua", "ask_fashion_depot_data", my_obj_id, true)
            elseif sub_code == 5 then
                -- 鍧愰獞缂栬緫鍣? 鍙戦€乺ide鏁版嵁 + sub_type=5瑙﹀彂缂栬緫鍣?
                skynet.call(my_scene, "lua", "send_exterior_ride_editor", my_obj_id)
            elseif sub_code == 6 then
                -- 骞婚グ缂栬緫鍣? 鍙戦€亀eapon_visual鏁版嵁 + sub_type=5瑙﹀彂缂栬緫鍣?
                skynet.call(my_scene, "lua", "send_exterior_weapon_editor", my_obj_id)
            end
            return  -- 涓嶅啀鍙戦€丟CExteriorSharePlan
        else
            msg.type_code = 2
        end

        Net:send(msg)

    elseif op == 7 then
        -- ======== 淇濆瓨涓€ф爣绛?========
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "tag", {
            tag = self.save_tag
        })
        -- 鍥炰紶鏍囩鏁版嵁纭 (type=11 瑙﹀彂 event 1139 鍒锋柊, 鑰岄潪 type=3 瑙﹀彂 event 1141 閲嶆柊鎵撳紑缂栬緫妗?
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 11
        msg.tag = plan.tag
        Net:send(msg)

    elseif op == 8 then
        -- ======== 淇濆瓨鏃惰 ========
        -- 1. 淇濆瓨鍒?share_plan (鍒嗕韩鏂规)
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "dress", {
            dress_a = self.save_dress_a,
            dress_b = self.save_dress_b
        })
        -- 2. 鍚屾椂淇濆瓨鍒?profile_dress (璧勬枡椤垫椂瑁咃紝渚涘鎴风 ProfileData("DRESS") 璇诲彇)
        -- dress_a = VecIndex(妲戒綅绱㈠紩), dress_b = ExteriorID(澶栬ID)
        skynet.call(my_scene, "lua", "char_save_profile_dress", my_obj_id, self.save_dress_a, self.save_dress_b)
        local plan = skynet.call(my_scene, "lua", "char_get_share_plan", my_obj_id)
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 12
        msg.dress_a = plan.dress_a
        msg.dress_b = plan.dress_b
        Net:send(msg)

    elseif op == 9 then
        -- ======== 淇濆瓨鍧愰獞 ========
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
        -- ======== 淇濆瓨骞婚グ ========
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
        -- ======== 鎻愪氦鏃惰鍒板垎浜柟妗?========
        -- 瀹㈡埛绔?op=8 鍙槸缂撳瓨鏃惰鍒?profile_dress锛宱p=15 鎵嶆槸鐪熸鎻愪氦鍒?share_plan
        local pd = skynet.call(my_scene, "lua", "char_get_profile_dress", my_obj_id)
        skynet.call(my_scene, "lua", "char_save_share_plan", my_obj_id, "dress", {
            dress_a = pd.idx,
            dress_b = pd.id
        })
        -- 鍏ㄩ噺鍙戝洖瀹㈡埛绔埛鏂版柟妗堢晫闈?
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
        -- ======== 妲戒綅flag鍒囨崲 ========
        -- 瀹㈡埛绔彂閫乷p=17/18 + 1瀛楄妭value, 鍝嶅簲type=19
        local msg = packet_def.GCExteriorSharePlan.new()
        msg.type_code = 19
        msg.flag_value = self.flag_value or 0
        Net:send(msg)

    elseif op == 20 then
        -- ======== 鐐硅禐 ========
        -- IDA纭: 瀹㈡埛绔疞uaFnDianZan鍙戦€丆GExteriorSharePlan op=20, 鍊?target_obj_id
        -- op=20濮嬬粓浣滀负鐐硅禐澶勭悊, 涓嶅啀fallthrough鍒颁繚瀛榩lan_id
        -- 閬垮厤鐐硅禐澶辫触鏃舵妸target_obj_id閿欒瀛樹负plan_id(瀵艰嚧610116琚薄鏌?
        local target_val = self.save_plan_id or 0
        local is_zan = skynet.call(my_scene, "lua", "char_dianzan_es_plan", my_obj_id, target_val)
        if is_zan then
            -- 鐐硅禐鎴愬姛: 鍙戦€?73 type_code=20 result=1 瑙﹀彂瀹㈡埛绔痚vent 1191鍒锋柊UI
            local zan_msg = packet_def.GCExteriorSharePlan.new()
            zan_msg.type_code = 20
            zan_msg.zan_result = 1  -- 1=鎴愬姛
            Net:send(zan_msg)
        else
            -- 鐐硅禐澶辫触(鑷繁/鐩爣涓嶅瓨鍦ㄧ瓑): 鍙戦€佸け璐ラ€氱煡
            local zan_msg = packet_def.GCExteriorSharePlan.new()
            zan_msg.type_code = 20
            zan_msg.zan_result = 2  -- 2=澶辫触, 瀹㈡埛绔樉绀?#{GRYM_221213_28}
            Net:send(zan_msg)
        end
    end
end

function request:CGExteriorCoupleFashion()
    local msg = packet_def.GCExteriorCoupleFashion.new()
    msg.unknow_1 = self.unknow_1
    msg.unknow_2 = self.unknow_2
    Net:send(msg)
    skynet.call(my_scene, "lua", "char_exterior_couple_fashion", my_obj_id, self)
end

function request:CGRaidRetApply()
	local my_guid = ma_func:get_guid()
	skynet.call(".world", "lua", "char_ret_raid_apply", my_guid, self)
end

function request:CGRaidLeave()
	skynet.call(".world", "lua", "char_leave_raid", self.guid)
end

--鈥嬬敵璇峰姞鍏ュ洟闃?
function request:CGRaidApply()
	skynet.call(".world", "lua", "char_apply_raid",self)
end
--鈥嬮個璇风帺瀹跺姞鍏ュ洟闃?
function request:CGRaidInvite()
	skynet.call(".world", "lua", "char_invite_raid",self)
end
--璋冩暣鍥㈤槦鎴愬憳浣嶇疆
function request:CGRaidModifyMemberPosition()
	skynet.call(".world", "lua", "raid_modify_member_position", self)
    -- local msg = packet_def.GCRetRaidModifyMemberPosition.new()
    -- msg.m_OperateGUID = self.m_OperateGUID
    -- msg.m_sSquadIndex = self.m_sSquadIndex
    -- msg.m_sMemIndex = self.m_sMemIndex
    -- msg.m_dSquadIndex = self.m_dSquadIndex
    -- msg.m_dMemIndex = self.m_dMemIndex
    -- Net:send(msg)
end
--鍥炲閭€璇?
function request:CGRaidRetInvite()
	local my_guid = ma_func:get_guid()
	skynet.call(".world", "lua", "char_ret_raid_invite", my_guid,self)
end
--鈥嬭涪鍑哄洟闃熸垚鍛?
function request:CGRaidKick()
	skynet.call(".world", "lua", "char_raid_kick", self)
end
--鈥嬩换鍛藉洟闃熻亴浣嶁€?
function request:CGRaidAppoint()
    -- local my_guid = ma_func:get_guid()
	-- if my_guid == self.m_OperateGUID then
		skynet.call(".world", "lua", "char_raid_appoint", self)
	-- end
end
--鈥嬪垱寤哄洟闃?
function request:CGRaidCreate()
    -- local my_guid = ma_func:get_guid()
	-- if my_guid == self.m_CreateGUID then
		skynet.call(".world", "lua", "char_create_raids", self)
	-- end
end
--鈥嬭姹傚洟闃熶俊鎭?
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



--鈥嬮個璇风帺瀹跺姞鍏ラ槦浼?
-- 璇锋眰鍥㈤槦鎴愬憳璇︾粏淇℃伅锛堥棬娲俱€佺瓑绾с€丠P銆佽澶囩瓑锛?
function request:CGAskRaidMemberInfo()
    local my_guid = ma_func:get_guid()
    local msg = packet_def.GCRaidMemberInfo.new()
    msg.flag = 0
    msg.data_index = 0
    -- 浠庡満鏅湇鑾峰彇鐩爣鎴愬憳鐨勭湡瀹炲睘鎬у拰瑁呭澶栬
    local attrib, equip_visuals, is_die = skynet.call(my_scene, "lua", "ask_team_member_info", my_obj_id, self)
    if attrib then
        msg.guid = attrib.guid
        -- 浠庝笘鐣屾湇鑾峰彇raid_id
        local raid_id = skynet.call(".world", "lua", "get_player_raid_id", my_guid)
        msg.m_RaidID = raid_id or -1
        -- 閫氳繃鍙嶅皠璋冪敤鎵€鏈夊尮閰嶇殑set_xxx璁剧疆鍣?
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
        -- 鐩爣涓嶅湪鍚屼竴鍦烘櫙锛屽洖閫€鍒颁笘鐣屾湇鑾峰彇鍩烘湰淇℃伅
        skynet.call(".world", "lua", "char_ask_raid_member_info", my_guid, self)
        return
    end
    Net:send(msg)
end


function request:CGTeamInvite()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_invite_team", my_guid, self)
end
--	鈥嬭В鏁ｉ槦浼?
function request:CGTeamDismiss()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_dismiss_team", my_guid, self)
end
--鍥炲闃熶紞閭€璇封€?
function request:CGTeamRetInvite()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_ret_invite", my_guid, self)
end
-- 鈥?韪㈠嚭闃熶紞鎴愬憳
function request:CGTeamKick()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_team_kick", my_guid, self)
end
--鈥嬩换鍛介槦浼嶈亴浣?
function request:CGTeamAppoint()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_team_appoint", my_guid, self)
end
--淇敼闃熶紞璁剧疆
function request:CGTeamChangeOption()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_team_change_option", my_guid, self)
end

function request:CGTeamApply()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_team_apply", my_guid, self)
end

function request:CGTeamRetApply()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_ret_team_apply", my_guid, self)
end

-- 闃熼暱鍥炲杞彂閭€璇凤紙闈為槦闀挎垚鍛橀個璇锋椂锛岃浆缁欓槦闀垮鎵癸級
function request:CGTeamLeaderRetInvite()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_leader_ret_invite", my_guid, self)
end

function request:CGAskTeamInfo()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_ask_team_info", my_guid)
end

-- 瀹㈡埛绔櫥褰曟椂鍙戦€侊紝璇锋眰鑷姩鎭㈠/鍒涘缓闃熶紞
function request:CGAutoCreateTeam()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_ask_team_info", my_guid)
end


function request:CGAskTeamMemberInfo()
    local my_guid = ma_func:get_guid()
    local msg = packet_def.GCTeamMemberInfo.new()
    local attrib, equip_visuals = skynet.call(my_scene, "lua", "ask_team_member_info", my_obj_id, self)
    if attrib then
        msg.guid = attrib.guid
        for k, v in pairs(attrib) do
            local fn = string.format("set_%s", k)
            local f = msg[fn]
            if f then
                f(msg, v)
            end
        end
        msg:set_weapon(equip_visuals.weapon)
        msg:set_cap(equip_visuals.cap)
        msg:set_armour(equip_visuals.armour)
        msg:set_cuff(equip_visuals.cuff)
        msg:set_foot(equip_visuals.foot)
        msg:set_fashion(equip_visuals.fashion)
    else
        attrib = skynet.call(".world", "lua", "ask_team_member_info", my_guid, self)
        if attrib == nil then
            return
        end
        msg.data_index = 3141815068
        msg.flag = 0
        msg.guid = attrib.guid
        msg.unknow_19 = 15
    end
    Net:send(msg)
end

function request:CGTeamLeave()
    local my_guid = ma_func:get_guid()
    skynet.call(".world", "lua", "char_leave_team", my_guid, self)
end

function request:CGAskTeamFollow()
    skynet.call(my_scene, "lua", "char_ask_team_follow", my_obj_id, self)
end

function request:CGReturnTeamFollow()
    skynet.call(my_scene, "lua", "char_return_team_follow", my_obj_id, self)
end

function request:CGStopTeamFollow()
    skynet.send(".world", "lua", "stop_team_follow", ma_func:get_guid())
end

function request:CGCGWPacket()
    local my_guid = ma_func:get_guid()
    if self.type == 1 then
        local guild_id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local result = skynet.call(my_scene, "lua", "check_human_occupy_city", my_obj_id)
        if not result then
            return
        end
        local city_apply = self.city_apply
        city_apply.guild_id = guild_id
        result = skynet.call(".Guildmanager", "lua", "city_apply", my_guid, city_apply)
        if result then
            skynet.call(my_scene, "lua", "cost_human_occupy_city", my_obj_id)
        end
    elseif self.type == 2 then
        local guild_id = skynet.call(my_scene, "lua", "get_obj_guild_id", my_obj_id)
        local packet = {}
        packet.guild_id = guild_id
        packet.args = self.data
        local guild, zhengtao_info = skynet.call(".Guildmanager", "lua", "guild_zhengtao", my_guid, packet)
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
            ma_func:notify_tips("甯細瀹ｆ垬闇€瑕佹秷鑰?00鐐规墿寮?)
            return
        end
        skynet.call(".Guildmanager", "lua", "guild_wild_war", my_guid, self.guild_wild_war)
    elseif self.type == 7 then
        local kick_guild_id = self.data[3]
        ma_func:guild_league_kick(kick_guild_id)
    elseif self.type == 11 then
        skynet.call(".Guildmanager", "lua", "guild_war", my_guid, self.guild_war)
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
end

function request:CGGuild()
    ma_func:CGGuild(self)
end

function request:CGGuildJoin()
    ma_func:CGGuildJoin(self)
end

function request:CGMissionCheck()
    skynet.call(my_scene, "lua", "char_mission_check", my_obj_id, self)
end

function request:CGExchangeReplyI()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
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
			error_msg = "鏁版嵁鐗堟湰鍙峰紓甯竉璇锋眰鎺ュ彈浜ゆ槗",
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
		ma_func:notify_tips("瑙掕壊鏁版嵁寮傚父锛岃閲嶆柊鐧婚檰娓告垙鍐嶈繘琛屾搷浣溿€?)
		return
	end
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    skynet.call(my_scene, "lua", "char_exchange_reply_I", my_obj_id, self)
end

function request:CGExchangeSynchItemII()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_exchange_sync_item_II", my_obj_id, self)
end

function request:CGExchangeSynchMoneyII()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_exchange_sync_money_II", my_obj_id, self)
end

function request:CGExchangeSynchLock()
    skynet.call(my_scene, "lua", "char_exchange_synch_lock", my_obj_id, self)
end

function request:CGExchangeCancel()
    skynet.call(my_scene, "lua", "char_exchange_cancel", my_obj_id, self)
end

function request:CGExchangeOkIII()
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    skynet.call(my_scene, "lua", "char_exchange_ok_III", my_obj_id, self)
end

function request:CGAskCampaignCount()
    skynet.call(my_scene, "lua", "char_ask_campaign_count", my_obj_id, self)
end

function request:CGAskSecKillNum()
    skynet.call(my_scene, "lua", "char_ask_sec_kill_num", my_obj_id, self)
end

function request:CGAskSecKillData()
    skynet.call(my_scene, "lua", "char_ask_sec_kill_data", my_obj_id, self)
end

function request:CGCharUpdateCurTitle()
    skynet.call(my_scene, "lua", "char_update_cur_title", my_obj_id, self)
end

function request:CGByname()
    skynet.call(my_scene, "lua", "char_by_name", my_obj_id, self)
end

function request:CGZdZdRequest()
    skynet.call(my_scene, "lua", "char_zdzd_request", my_obj_id, self)
end

function request:CGSecKillRemoveItem()
    skynet.call(my_scene, "lua", "char_sec_kill_remove_item", my_obj_id, self)
end

function request:CGReportWaigua()
    if ma_func:check_right_ban() then
        local str = skynet.call(".gamed", "lua", "query_roler_account", string.format("%x", self.guid))
        local _, account = string.match(str, "GUID鏄?%d+)鐨勭帺瀹剁殑璐﹀彿鏄?(.+)")
        print(account)
        if account then
            skynet.send(".gamed", "lua", "ban_user", account)
        end
    end
end

function request:CGMail()
    local my_guid = ma_func:get_guid()
    assert(self.guid == my_guid, self.guid)
    skynet.call(".world", "lua", "send_mail", self)
end

function request:CGAuctionSell()
    if not ma_func:is_minor_password_is_unlock() then
        ma_func:send_operate_result_msg(define.OPERATE_RESULT.OR_NEED_UNLOCKMINORPASSWORD)
        return
    end
    if ma_func:check_right_limit_exchange() then
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
        return
    end
    if self.price < 2 then
        ma_func:notify_tips("浠锋牸涓嶈兘浣庝簬2鍏冨疂")
        return
    end
    if self.price > 200000 then
        ma_func:notify_tips("浠锋牸涓嶈兘楂樹簬20涓囧厓瀹?)
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
				logname = "浜ゆ槗甯傚満涓婃灦鎵ｉ櫎澶辫触",
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
        ma_func:notify_tips("璐﹀彿闄愬埗浜ゆ槗锛岃鑱旂郴瀹㈡湇澶勭悊")
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
        ma_func:notify_tips("鍏冨疂浜ゆ槗甯傚満鍙栧洖閬撳叿澶辫触锛岃仈绯诲鏈嶅鐞?)
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
		--灏佺
		local account = "鎵句笉鍒板笎鍙?
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
		logmsg = {param1 = "鏁版嵁鑾峰彇寮傚父(鍗″洖妗?",param2 = my_scene,param3 = my_obj_id,account = account},
		date_time = utils.get_day_time()
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		
		if account ~= "鎵句笉鍒板笎鍙? then
			skynet.send(".gamed", "lua", "ban_user", account,my_guid)
		end
		ma_func:notify_tips("鏁版嵁鑾峰彇寮傚父锛屾偍宸茶娓呯娓告垙銆?)
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
    ma_func:CGGuild(guild_request)
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
    print("CMD.scene_chat_channel_msg", ...)
    CMD.send2client(packet_def.GCChat.xy_id, ...)
end

function CMD.menpai_chat_channel_msg(...)
    print("CMD.scene_chat_channel_msg", ...)
    CMD.send2client(packet_def.GCChat.xy_id, ...)
end

function CMD.world_chat_channel_msg(...)
    print("CMD.world_chat_channel_msg", ...)
    CMD.send2client(packet_def.GCChat.xy_id, ...)
end

function CMD.update_confederate_id(confederate_id, confederate_name)
    local ret = skynet.call(my_scene, "lua", "update_confederate_id", my_obj_id, confederate_id, confederate_name)
    print("CMD.update_confederate_id my_obj_id =", my_obj_id, ";ret =", ret, confederate_id, confederate_name)
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
			error_msg = "鏈嶅姟ID瑙掕壊宸蹭笉鍚?,
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
        return "鐜╁涓嶅湪鍦烘櫙涓?
    end
    return skynet.call(my_scene, "lua", "agent_command_award_item", my_obj_id, item_id, item_count, is_bind)
end

function CMD.resource_update(item_id, item_count)
    if my_scene == nil then
        return { result = false, reason = "鐜╁涓嶅湪鍦烘櫙涓?}
    end
    return skynet.call(my_scene, "lua", "agent_command_resource_update", my_obj_id, item_id, item_count)
end

function CMD.change_user_nickname(new_nickname)
    if my_scene == nil then
        return "鐜╁涓嶅湪鍦烘櫙涓?
    end
    return skynet.call(my_scene, "lua", "agent_command_change_user_nickname", my_obj_id, new_nickname)
end

function CMD.change_user_money(new_level)
    if my_scene == nil then
        return "鐜╁涓嶅湪鍦烘櫙涓?
    end
    return skynet.call(my_scene, "lua", "agent_command_change_user_level", my_obj_id, new_level)
end

function CMD.call_script(script_id, func, params, params_type)
    if my_scene == nil then
        return "鐜╁涓嶅湪鍦烘櫙涓?
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

local function init_world_multicast()
    local channel_id = datacenter.get("channels", "world_chat_channel")
    world_chat_channel = mc.new {
        channel = channel_id,
        dispatch = function (channel, source, ...)
            -- skynet.logi("channel =>", channel, "; source=>", source, ";... =>", ...)
            CMD.world_chat_channel_msg(...)
        end
    }
    world_chat_channel:subscribe()
end

local function init_multicast()
    init_world_multicast()
end

local function init_world_multicast()
    local channel_id = datacenter.get("channels", "world_chat_channel")
    world_chat_channel = mc.new {
        channel = channel_id,
        dispatch = function (channel, source, ...)
            -- skynet.logi("channel =>", channel, "; source=>", source, ";... =>", ...)
            CMD.world_chat_channel_msg(...)
        end
    }
    world_chat_channel:subscribe()
end

local function init_multicast()
    init_world_multicast()
end

local lock = queue()
skynet.start(function()
    -- If you want to fork a work thread , you MUST do it in CMD.login
    Net:add_requests(request)
    init_multicast()
    -- 涓嶅啀 loadall锛屼緷璧?get_config 鎸夐渶鑷姩鍔犺浇
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
