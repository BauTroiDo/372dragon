local skynet = require "skynet"
local gbk = require "wire_charset"
local datacenter = require "skynet.datacenter"
local mc = require "skynet.multicast"
require "skynet.manager"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local teamlist = require "teamlist"
local team_cls = require "team"
local raidlist = require "raidlist"
local raid_cls = require "raid"
local worldcore = class("worldcore")

function worldcore:getinstance()
    if worldcore.instance == nil then
        worldcore.instance = worldcore.new()
    end
    return worldcore.instance
end

function worldcore:init(args)
    self.server_id = args.server_id
    assert(self.server_id ~= nil)
    self.online_users = {}
    self.name_2_guid = {}
    self.world_timer = { time = define.WORLD_TIME.WT_IND_1, counter = 10800000, tick = 0 }
    self.team_list = teamlist.new()
    self.team_list:init()
    self.raid_list = raidlist.new()
    self.raid_list:init()
    self:init_multicast()
    self.delta_time = 100
	self.luoyang_human = {}
	for id in pairs(define.LUOYANG) do
		self.luoyang_human[id] = 0
	end
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
    end)
end

function worldcore:safe_message_update()
    local r, err = xpcall(self.message_update, debug.traceback, self, self.delta_time * 10)
    if not r then
        print("worldcore:safe_message_update error =", err)
    end
    skynet.timeout(self.delta_time, function() self:safe_message_update() end)
end

function worldcore:message_update()
    self.world_timer.counter = self.world_timer.counter + 8000
    self.world_timer.tick = self.world_timer.tick + 1
	-- if self.world_timer.tick % 10 == 0 then
		-- skynet.logi("server_id = ",self.server_id)
	-- end
    if self.world_timer.tick >= 150 then
        self.world_timer.tick = 0
        self.world_timer.time = self.world_timer.time + 1
        if self.world_timer.time > define.WORLD_TIME.WT_IND_12 then
            self.world_timer.time = define.WORLD_TIME.WT_IND_1
        end
        self:on_world_timer_update()
    end
    if self.world_timer.counter >= 86400000 then
        self.world_timer.counter = 0
    end
    --print("worldcore:message_update word_timer =", table.tostr(self.world_timer))
end

function worldcore:on_world_timer_update()
    local timer = self.world_timer
    --skynet.send(".Dynamicscenemanager", "lua", "world_timer_update", timer)
    skynet.send(".Copyscenemanager", "lua", "world_timer_update", timer)
    skynet.send(".SceneManager", "lua", "world_timer_update", timer)
end

function worldcore:get_id()
    return self.server_id
end

function worldcore:init_multicast()
    self.multicast_channel = mc.new()  -- 创建一个频道，成功创建后，.channel 是这个频道的 id 。
    datacenter.set("channels", "world_chat_channel", self.multicast_channel.channel)
    self.menpai_channels = {}
    for _, i in ipairs(define.MENPAI_SLOTS) do
        if i ~= define.MENPAI_ATTRIBUTE.MATTRIBUTE_WUMENPAI then
            local channel = mc.new()
            datacenter.set("channels", string.format("menpai_%d_channel", i), channel.channel)
            self.menpai_channels[i] = channel
        end
    end
end

function worldcore:check_human_on_world(guid)
	-- skynet.send(".logdb", "lua", "insert", { collection = "log_ceshi", doc = {fun_name = "check_human_on_world"} })
	local user = self.online_users[guid]
	if user then
		local exist = pcall(skynet.call, user.uinfo.agent, "debug", "PING")
		local collection = "log_human_online"
		local doc = { 
			fun_name = "check_human_on_world",
			error_msg = "登陆时还有场景存在角色数据",
			guid = guid,
			name = user.uinfo.name,
			old_sceneId = user.uinfo.old_sceneId,
			sceneid = user.uinfo.sceneid,
			world_pos = user.uinfo.world_pos,
			exist = exist,
			date_time = os.date("%y-%m-%d %H:%M:%S")
		}
		skynet.send(".logdb", "lua", "insert", { collection = collection, doc = doc })
		if exist then
			pcall(skynet.call, user.uinfo.agent, "lua", "logout_ex", guid)
		else
			self:leave_world(guid)
		end
		return true
	end
end


function worldcore:online(guid, uinfo)
    assert(guid)
    assert(uinfo.name)
    local user = self.online_users[guid]
    if user then
        uinfo.team_id = user.uinfo.team_id
        uinfo.raid_id = user.uinfo.raid_id
		uinfo.m_ZoneWorldID = user.uinfo.m_ZoneWorldID
		uinfo.m_iFightScore = user.uinfo.m_iFightScore
		uinfo.GuildName = user.uinfo.GuildName
        self:update_uinfo(guid, uinfo)
    else
        uinfo.team_id = define.INVAILD_ID
        uinfo.raid_id = define.INVAILD_ID
		uinfo.m_ZoneWorldID = self.server_id
		uinfo.m_iFightScore = 0
		uinfo.GuildName = ""
        self.online_users[guid] = {
            status = "online",
            uinfo = uinfo
        }
    end
    self.name_2_guid[uinfo.name] = guid
end

function worldcore:offline(guid)
    local user = assert(self.online_users[guid], guid)
    user.status = "offline"
    user.offline_time = os.time()
end

function worldcore:leave_world(guid)
    self:char_leave_team(guid)
    self:char_leave_raid(guid)
	local human = self.online_users[guid]
	if human then
		local sceneId = human.uinfo.sceneid
		if sceneId and self.luoyang_human[sceneId] then
			self.luoyang_human[sceneId] = self.luoyang_human[sceneId] - 1
			if self.luoyang_human[sceneId] < 0 then
				self.luoyang_human[sceneId] = 0
			end
		end
	end
    self.online_users[guid] = nil
end

-- function worldcore:empty_user_data(guid)
	-- local human = self.online_users[guid]
	-- if human then
		-- local sceneId = human.uinfo.sceneid
		-- if sceneId and self.luoyang_human[sceneId] then
			-- self.luoyang_human[sceneId] = self.luoyang_human[sceneId] - 1
			-- if self.luoyang_human[sceneId] < 0 then
				-- self.luoyang_human[sceneId] = 0
			-- end
		-- end
	-- end
    -- self.online_users[guid] = nil
-- end

function worldcore:get_world_data(guid,name)
    local teaminfo = { id = define.INVAILD_ID, leader = define.INVAILD_ID }
	if guid then
		local user = self.online_users[guid]
		if user then
			if name then
				self.name_2_guid[name] = guid
			end
			local tid = user.uinfo.team_id
			local team = self.team_list:get_team(tid)
			if team then
				local leader = team:leader()
				teaminfo.id = team:get_team_id()
				teaminfo.leader = leader.guid
			end
			return teaminfo,user
		end
	end
	return teaminfo
end

function worldcore:update_uinfo(guid, uinfo, enter_scene)
    -- skynet.logi("worldcore:update_uinfo guid =", guid, "; uinfo =", table.tostr(uinfo))
    assert(guid)
    local user = self:find_user(guid)
    if user then
		if enter_scene then
			local old_sceneId = user.uinfo.on_sceneId
			if old_sceneId and self.luoyang_human[old_sceneId] then
				self.luoyang_human[old_sceneId] = self.luoyang_human[old_sceneId] - 1
				if self.luoyang_human[old_sceneId] < 0 then
					self.luoyang_human[old_sceneId] = 0
				end
			end
			for k, v in pairs(uinfo) do
				user.uinfo[k] = v
			end
			self.name_2_guid[user.uinfo.name] = guid
			local on_sceneId = uinfo.sceneid
			if on_sceneId then
				if self.luoyang_human[on_sceneId] then
					self.luoyang_human[on_sceneId] = self.luoyang_human[on_sceneId] + 1
				end
				user.uinfo.on_sceneId = on_sceneId
			end
			local msg = packet_def.GCWorldTime.new()
			msg.counter = self.world_timer.counter
			msg.m_Time = self.world_timer.time
			self:send2client(user, msg)
		else
			for k, v in pairs(uinfo) do
				user.uinfo[k] = v
			end
			self.name_2_guid[user.uinfo.name] = guid
		end
    end
end

function worldcore:player_enter_scene(guid)
    local user = self:find_user(guid)
    if not user then return end
    local msg = packet_def.GCWorldTime.new()
    msg.counter = self.world_timer.counter
    msg.m_Time = self.world_timer.time
    self:send2client(user, msg)
    self:char_enter_scene(guid)
end

function worldcore:find_user(guid)
    return self.online_users[guid]
end


function worldcore:find_user_by_name(name)
	-- if not name then
		-- skynet.logi("查找角色名异常",name,"stack =",debug.traceback())
    assert(name)
    local guid = self.name_2_guid[name]
    if guid then
        return self.online_users[guid]
    end
end
function worldcore:raid_modify_member_position(ret)
	local guid = ret.m_OperateGUID
	if not guid then
		return
	elseif not ret.m_sSquadIndex or ret.m_sSquadIndex < 0 or ret.m_sSquadIndex > 4 then
		return
	elseif not ret.m_sMemIndex or ret.m_sMemIndex < 0 or ret.m_sMemIndex > 5 then
		return
	elseif not ret.m_dSquadIndex or ret.m_dSquadIndex < 0 or ret.m_dSquadIndex > 4 then
		return
	elseif not ret.m_dMemIndex or ret.m_dMemIndex < 0 or ret.m_dMemIndex > 5 then
		return
	elseif ret.m_sSquadIndex == ret.m_dSquadIndex and ret.m_sMemIndex == ret.m_dMemIndex then
		return
	end
	local me = self:find_user(guid)
	if not me then
		return
	end
	local raid_id = me.uinfo.raid_id
	if raid_id == define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(me, msg)
		return
	end
	local raid = self.raid_list:get_raid(raid_id)
	if not raid then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(me, msg)
		return
	end
	
	-- local raid_info = raid:get_members()
	-- for tid,team in ipairs(raid_info) do
		-- for mid,mb in ipairs(team) do
			-- skynet.logi("更换前[",tid,"][",mid,"] = {guid = ",mb.guid,"}")
		-- end
	-- end
	
	local me_mb = raid:find_member_pos(ret.m_sSquadIndex + 1,ret.m_sMemIndex + 1)
	if not me_mb then
		skynet.logi("ret.m_sSquadIndex = ",ret.m_sSquadIndex,"ret.m_sMemIndex = ",ret.m_sMemIndex)
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_CHANGE_POISTION_1
		self:send2client(me, msg)
		return
	end
	raid:change_member_pos(guid,raid_id,
	ret.m_sSquadIndex + 1,
	ret.m_sMemIndex + 1,
	ret.m_dSquadIndex + 1,
	ret.m_dMemIndex + 1)
	
	-- local raid_info = raid:get_members()
	-- for tid,team in ipairs(raid_info) do
		-- for mid,mb in ipairs(team) do
			-- skynet.logi("更换后[",tid,"][",mid,"] = {guid = ",mb.guid,"}")
		-- end
	-- end
end

function worldcore:char_ret_raid_apply(guid, ret)
	if not ret or not ret.source_guid or ret.source_guid == guid then
		return
	end
    local me = self:find_user(guid)
	if not me then
		return
	end
    local tar = self:find_user(ret.source_guid)
	if not tar then
		return
	end
	local raid_id = me.uinfo.raid_id
	if raid_id == define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(me, msg)
		return
	end
	local raid = self.raid_list:get_raid(raid_id)
	if not raid then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(me, msg)
		return
	elseif me.uinfo.m_Position ~= define.RAID_POISTION.RAID_POISTION_LEADER then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_LEADER
		self:send2client(me, msg)
		return
	end
	if ret.return_type ~= 1 then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_APPLYLEADERREFUSE
		self:send2client(me, msg)
		return
	elseif tar.uinfo.raid_id ~= define.INVAILD_ID then
		-- local msg = packet_def.GCRaidError.new()
		-- msg.error_code = define.RAID_ERROR.RAID_RESERVER_8
		-- self:send2client(tar, msg)
		msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_IN_OTHERRAID
		self:send2client(me, msg)
		return
	elseif raid:is_full() then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_FULL_CANTAPPLY
		self:send2client(me, msg)
		msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_FULL
		self:send2client(tar, msg)
		return
	end
	tar.uinfo.raid_id = raid_id
	-- tar.uinfo.m_ZoneWorldID = self.server_id
	-- tar.uinfo.m_iFightScore = tar.uinfo.m_iFightScore
	-- tar.uinfo.GuildName = tar.uinfo.GuildName
	tar.uinfo.m_Position = define.RAID_POISTION.RAID_POISTION_MEMBER
	raid:add_member(tar.uinfo,ret.source_guid)
end
function worldcore:char_ret_raid_invite(guid, ret)
	if not ret or not ret.m_GUID or ret.m_GUID == guid then
		return
	end
    local me = self:find_user(guid)
	if not me then
		return
	end
    local tar = self:find_user(ret.m_GUID)
	if not tar then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT
		self:send2client(me, msg)
		return
	end
	local raid_id = tar.uinfo.raid_id
	if raid_id == define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT
		self:send2client(me, msg)
		return
	end
	local raid = self.raid_list:get_raid(raid_id)
	if not raid then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT
		self:send2client(me, msg)
		return
	elseif tar.uinfo.m_Position ~= define.RAID_POISTION.RAID_POISTION_LEADER then
	-- and tar.uinfo.m_Position ~= define.RAID_POISTION.RAID_POISTION_ASSISTANT then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_APPOINTSOURNOLEADER
		self:send2client(me, msg)
		return
	end
	if ret.m_Return ~= 1 then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_INVITEREFUSE
		self:send2client(tar, msg)
		return
	elseif me.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_INVITEREFUSE
		self:send2client(tar, msg)
		return
	elseif raid:is_full() then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_FULL
		self:send2client(me, msg)
		msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_FULL_CANTINVITE
		self:send2client(tar, msg)
		return
	end
	me.uinfo.raid_id = raid_id
	-- me.uinfo.m_ZoneWorldID = self.server_id
	-- me.uinfo.m_iFightScore = me.uinfo.m_iFightScore
	-- me.uinfo.GuildName = me.uinfo.GuildName
	me.uinfo.m_Position = define.RAID_POISTION.RAID_POISTION_MEMBER
	raid:add_member(me.uinfo,guid)
end

function worldcore:char_apply_raid(apply)
	local guid = apply.m_SourGUID
	if not guid then
		return
	end
	local tar = self:find_user(guid)
    local me = self:find_user_by_name(apply.m_DestName)
	if not me or not tar then
		return
	elseif me.uinfo.guid == guid then
		return
	end
	local raid_id = me.uinfo.raid_id
	if tar.uinfo.raid_id == raid_id then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT
		self:send2client(tar, msg)
		return
	elseif tar.uinfo.team_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT
		self:send2client(tar, msg)
		return
	elseif tar.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_RAID_NOTEXIST_OR_LEADEROUT
		self:send2client(tar, msg)
		return
	end
	local raid = self.raid_list:get_raid(raid_id)
	if not raid then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(tar, msg)
		return
	elseif raid:is_full() then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_FULL_CANTINVITE
		self:send2client(tar, msg)
		return
	end
	local leader_member = raid:leader(define.RAID_POISTION.RAID_POISTION_LEADER)
	if leader_member then
		local msg = packet_def.GCRaidAskApply.new()
		-- msg.m_SourGUID = leader_member.guid
		msg.m_SourGUID = tar.uinfo.guid
		msg.SourceName = tar.uinfo.name
		msg.m_uFamily = tar.uinfo.menpai
		msg.sceneid = tar.uinfo.sceneid
		msg.m_Level = tar.uinfo.level
		msg.m_DetailFlag = 0
		-- msg.m_DetailFlag = 1
		msg.m_ZoneWorldID = apply.m_ZoneWorldID
		msg.m_iFightScore = tar.uinfo.m_iFightScore
		msg.GuildName = tar.uinfo.GuildName
		
		msg.face_id = tar.uinfo.face_id
		msg.hair_id = tar.uinfo.hair_id
		msg.hair_color = tar.uinfo.hair_color
		msg.weapon = tar.uinfo.weapon
		msg.cap = tar.uinfo.cap
		msg.armour = tar.uinfo.armour
		msg.cuff = tar.uinfo.cuff
		msg.foot = tar.uinfo.foot
		msg.fashion = tar.uinfo.fashion
		raid:send_msg_to_member(leader_member, msg)
	end
end

function worldcore:char_invite_raid(invite)
	local guid = invite.m_SourObjID
    local me = self:find_user(guid)
	if not me then
		return
	end
	local raid_id = me.uinfo.raid_id
	if raid_id == define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(me, msg)
		return
	end
	local me_position = me.uinfo.m_Position
	if me_position ~= define.RAID_POISTION.RAID_POISTION_LEADER
	and me_position ~= define.RAID_POISTION.RAID_POISTION_ASSISTANT then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_KICKNOTLEADER
		self:send2client(me, msg)
		return
	end
	local raid = self.raid_list:get_raid(raid_id)
	if not raid then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
		self:send2client(me, msg)
		return
	elseif raid:is_full() then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_FULL_CANTINVITE
		self:send2client(me, msg)
		return
	end
    local tar = self:find_user_by_name(invite.m_DestName)
	if not tar then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_INVITEDTARGETNOTONLINE
		self:send2client(me, msg)
		return
	elseif tar.uinfo.guid == guid then
		return
	elseif tar.status == "offline" then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_INVITEDTARGETNOTONLINE
		self:send2client(me, msg)
		return
	elseif tar.uinfo.raid_id == raid_id then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_INVITEDHASINRAID
		self:send2client(me, msg)
		return
	elseif tar.uinfo.team_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_NUMBER
		self:send2client(me, msg)
		return
	elseif tar.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_INVITEDESTHASRAID
		self:send2client(me, msg)
		return
	end
	local msg = packet_def.GCRaidAskInvite.new()
	msg.m_ZoneWorldID = invite.m_ZoneWorldID
	local leader_member = raid:leader(define.RAID_POISTION.RAID_POISTION_LEADER)
	if leader_member then
		msg.m_uLeaderLevel = leader_member.level
		msg.guid = leader_member.guid
		msg.nickname = leader_member.name
		self:send2client(tar, msg)
	else
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_ADDMEMFAILED_INVITEERR
		self:send2client(me, msg)
	end
end

function worldcore:char_raid_kick(packet)
	if not packet then
		return
	end
	local guid,guid_ex = packet.m_OperateGUID,packet.m_TargetGUID
	if not guid or not guid_ex or guid == guid_ex then
		return
	end
	local me = self:find_user(guid)
	local tar = self:find_user(guid_ex)
	if me and tar then
		local raid_id = me.uinfo.raid_id
		if raid_id == define.INVAILD_ID then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
			self:send2client(me, msg)
			return
		elseif raid_id ~= tar.uinfo.raid_id then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_NOT_IN_YOUR_RAID
			self:send2client(me, msg)
			return
		end
		local raid = self.raid_list:get_raid(raid_id)
		if not raid then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
			self:send2client(me, msg)
			return
		end
		local mb_me,tid_me,mid_me = raid:is_member(guid)
		if not mb_me then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
			self:send2client(me, msg)
			return
		end
		local mb_tar,tid_tar,mid_tar = raid:is_member(guid_ex)
		if not mb_tar then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_NOT_IN_YOUR_RAID
			self:send2client(me, msg)
			return
		end
		local me_position = mb_me.m_Position
		local tar_position = mb_tar.m_Position
		if me_position == define.RAID_POISTION.RAID_POISTION_MEMBER then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_KICKNOTLEADER
			self:send2client(me, msg)
			return
		elseif me_position == define.RAID_POISTION.RAID_POISTION_ASSISTANT then
			if tar_position == define.RAID_POISTION.RAID_POISTION_LEADER then
				local msg = packet_def.GCRaidError.new()
				msg.error_code = define.RAID_ERROR.RAID_ERROR_KICKLEADER
				self:send2client(me, msg)
				return
			elseif tar_position == define.RAID_POISTION.RAID_POISTION_ASSISTANT then
				local msg = packet_def.GCRaidError.new()
				msg.error_code = define.RAID_ERROR.RAID_ERROR_KICK_ASSISTANT
				self:send2client(me, msg)
				return
			end
		end
        if raid:member_count() <= 2 then
			local msg = packet_def.GCRaidResult.new()
			msg.name = mb_me.name
			msg.return_type = define.RAID_RESULT.RAID_RESULT_DISMISS
			msg.guid = define.INVAILD_ID
			msg.raid_id = raid_id
			msg.guid_ex = define.INVAILD_ID
			msg.m_objID = define.INVAILD_ID
			msg.sceneid = define.INVAILD_ID
			msg.client_res = define.INVAILD_ID
			msg.portrait_id = mb_me.portrait_id
			msg.sex = mb_me.model
			msg.m_Position = me_position
			msg.m_SquadIdx = tid_me
			msg.m_MemberIdx = mid_me
			msg.m_ZoneWorldID = mb_me.m_ZoneWorldID
			msg.m_iFightScore = mb_me.m_iFightScore
			msg.GuildName = mb_me.GuildName
			raid:broad_raid_msg(msg)
            self.raid_list:destory_raid(raid_id)
		else
			local msg = packet_def.GCRaidResult.new()
			msg.name = mb_tar.name
			msg.return_type = define.RAID_RESULT.RAID_RESULT_KICK
			msg.guid = guid_ex
			msg.raid_id = raid_id
			msg.guid_ex = guid
			msg.m_objID = mb_tar.m_objID
			msg.sceneid = mb_tar.sceneid
			msg.client_res = mb_tar.client_res
			msg.portrait_id = mb_tar.portrait_id
			msg.sex = mb_tar.model
			msg.m_Position = tar_position
			msg.m_SquadIdx = tid_tar
			msg.m_MemberIdx = mid_tar
			msg.m_ZoneWorldID = mb_tar.m_ZoneWorldID
			msg.m_iFightScore = mb_tar.m_iFightScore
			msg.GuildName = mb_tar.GuildName
			raid:broad_raid_msg(msg)
			raid:del_member(guid_ex)
		end
	end
end

function worldcore:char_leave_raid(guid,not_tip)
    local me = self:find_user(guid)
    -- assert(me, guid)
	if me then
		local raid_id = me.uinfo.raid_id
		local raid = self.raid_list:get_raid(raid_id)
		if raid then
			local mb_me,tid_me,mid_me = raid:is_member(guid)
			if not mb_me then
				if not not_tip then
					local msg = packet_def.GCRaidError.new()
					msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
					self:send2client(me, msg)
				end
				return
			end
			if raid:member_count() <= 2 then
				local msg = packet_def.GCRaidResult.new()
				msg.name = mb_me.name
				msg.return_type = define.RAID_RESULT.RAID_RESULT_DISMISS
				msg.guid = define.INVAILD_ID
				msg.raid_id = raid_id
				msg.guid_ex = define.INVAILD_ID
				msg.m_objID = define.INVAILD_ID
				msg.sceneid = define.INVAILD_ID
				msg.client_res = define.INVAILD_ID
				msg.portrait_id = mb_me.portrait_id
				msg.sex = mb_me.model
				msg.m_Position = mb_me.m_Position
				msg.m_SquadIdx = tid_me
				msg.m_MemberIdx = mid_me
				msg.m_ZoneWorldID = mb_me.m_ZoneWorldID
				msg.m_iFightScore = mb_me.m_iFightScore
				msg.GuildName = mb_me.GuildName
				raid:broad_raid_msg(msg)
				self.raid_list:destory_raid(raid_id)
			else
				local find_member,tid_find,mid_find
				local msg = packet_def.GCRaidResult.new()
				msg.name = mb_me.name
				if mb_me.m_Position == define.RAID_POISTION.RAID_POISTION_LEADER then
					find_member,tid_find,mid_find = raid:leader(define.RAID_POISTION.RAID_POISTION_ASSISTANT)
					if not find_member then
						find_member,tid_find,mid_find = raid:leader(define.RAID_POISTION.RAID_POISTION_MEMBER)
					end
					if not find_member then
						local msg_error = packet_def.GCRaidError.new()
						msg_error.error_code = define.RAID_ERROR.RAID_ERROR_APPOINT_FAIL
						self:send2client(me, msg_error)
						return
					end
					msg.return_type = define.RAID_RESULT.RAID_RESULT_LEADERLEAVE
				else
					msg.return_type = define.RAID_RESULT.RAID_RESULT_MEMBERLEAVE
				end
				msg.guid = guid
				msg.raid_id = raid_id
				msg.guid_ex = guid
				msg.m_objID = mb_me.m_objID
				msg.sceneid = mb_me.sceneid
				msg.client_res = mb_me.client_res
				msg.portrait_id = mb_me.portrait_id
				msg.sex = mb_me.model
				msg.m_Position = mb_me.m_Position
				msg.m_SquadIdx = tid_me
				msg.m_MemberIdx = mid_me
				msg.m_ZoneWorldID = mb_me.m_ZoneWorldID
				msg.m_iFightScore = mb_me.m_iFightScore
				msg.GuildName = mb_me.GuildName
				raid:broad_raid_msg(msg)
				raid:del_member(guid)
				if find_member then
					find_member.m_Position = define.RAID_POISTION.RAID_POISTION_LEADER
					local msg = packet_def.GCRaidResult.new()
					msg.name = find_member.name
					msg.return_type = define.RAID_RESULT.RAID_RESULT_APPOINT
					msg.guid = find_member.guid
					msg.raid_id = raid_id
					msg.guid_ex = find_member.guid
					msg.m_objID = find_member.m_objID
					msg.sceneid = find_member.sceneid
					msg.client_res = find_member.client_res
					msg.portrait_id = find_member.portrait_id
					msg.sex = find_member.model
					msg.m_Position = find_member.m_Position
					msg.m_SquadIdx = tid_find
					msg.m_MemberIdx = mid_find
					msg.m_ZoneWorldID = find_member.m_ZoneWorldID
					msg.m_iFightScore = find_member.m_iFightScore
					msg.GuildName = find_member.GuildName
					raid:broad_raid_msg(msg)
				end
			end
		end
	end
end


function worldcore:char_raid_appoint(appoint)
	local guid_me = appoint.m_OperateGUID
	local guid_tar = appoint.m_TargetGUID
	local position = appoint.m_Position
	if not guid_me or not guid_tar or not position
	or position < define.RAID_POISTION.RAID_POISTION_LEADER or position > define.RAID_POISTION.RAID_POISTION_MEMBER then
		return
	elseif guid_me == guid_tar then
		return
	end
	local me = self:find_user(guid_me)
	local tar = self:find_user(guid_tar)
	if me and tar then
		local raid_id = me.uinfo.raid_id
		if raid_id == define.INVAILD_ID then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
			self:send2client(me, msg)
			return
		elseif raid_id ~= tar.uinfo.raid_id then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_NOT_IN_YOUR_RAID
			self:send2client(me, msg)
			return
		end
		local raid = self.raid_list:get_raid(raid_id)
		if not raid then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
			self:send2client(me, msg)
			return
		end
		local mb_me,tid_me,mid_me = raid:is_member(guid_me)
		if not mb_me then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_IN_RAID
			self:send2client(me, msg)
			return
		end
		local mb_tar,tid_tar,mid_tar = raid:is_member(guid_tar)
		if not mb_tar then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_NOT_IN_YOUR_RAID
			self:send2client(me, msg)
			return
		end
		
		if mb_me.m_Position ~= define.RAID_POISTION.RAID_POISTION_LEADER then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_NOT_LEADER
			self:send2client(me, msg)
			return
		elseif mb_tar.m_Position == position then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_APPOINT_FAIL
			self:send2client(me, msg)
			return
		end
		if position == define.RAID_POISTION.RAID_POISTION_ASSISTANT then
			if raid:get_appoint_count(position) >= 2 then
				local msg = packet_def.GCRaidError.new()
				msg.error_code = define.RAID_ERROR.RAID_ERROR_ASSISTANT_MAX
				self:send2client(me, msg)
				return
			end
		end
		mb_tar.m_Position = position
		local msg = packet_def.GCRaidResult.new()
		msg.name = mb_tar.name
		msg.return_type = define.RAID_RESULT.RAID_RESULT_APPOINT
		msg.guid = guid_me
		msg.raid_id = raid_id
		msg.guid_ex = guid_tar
		msg.m_objID = mb_tar.m_objID
		msg.sceneid = mb_tar.sceneid
		msg.client_res = mb_tar.client_res
		msg.portrait_id = mb_tar.portrait_id
		msg.sex = tar.uinfo.model
		msg.m_Position = appoint.m_Position
		msg.m_SquadIdx = tid_tar
		msg.m_MemberIdx = mid_tar
		msg.m_ZoneWorldID = mb_tar.m_ZoneWorldID
		msg.m_iFightScore = mb_tar.m_iFightScore
		msg.GuildName = mb_tar.GuildName
		raid:broad_raid_msg(msg)
		if appoint.m_Position == define.RAID_POISTION.RAID_POISTION_LEADER then
			mb_me.m_Position = define.RAID_POISTION.RAID_POISTION_MEMBER
			msg = packet_def.GCRaidResult.new()
			msg.name = mb_me.name
			msg.return_type = define.RAID_RESULT.RAID_RESULT_APPOINT
			msg.guid = guid_tar
			msg.raid_id = raid_id
			msg.guid_ex = guid_me
			msg.m_objID = mb_me.m_objID
			msg.sceneid = mb_me.sceneid
			msg.client_res = mb_me.client_res
			msg.portrait_id = mb_me.portrait_id
			msg.sex = mb_me.model
			msg.m_Position = define.RAID_POISTION.RAID_POISTION_MEMBER
			msg.m_SquadIdx = tid_me
			msg.m_MemberIdx = mid_me
			msg.m_ZoneWorldID = mb_me.m_ZoneWorldID
			msg.m_iFightScore = mb_me.m_iFightScore
			msg.GuildName = mb_me.GuildName
			raid:broad_raid_msg(msg)
		end
	end
end

function worldcore:char_create_raids(create)
	local guid = create.m_CreateGUID
	if not guid then
		return
	end
	local online = self:find_user(guid)
	if online then
		if online.uinfo.raid_id ~= define.INVAILD_ID then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_ADDMEMFAILED_INVITEERR
			self:send2client(online, msg)
		else
			local tid = online.uinfo.team_id or define.INVAILD_ID
			if tid == define.INVAILD_ID or tid ~= create.m_CreateTeamId then
				local msg = packet_def.GCRaidError.new()
				msg.error_code = define.RAID_ERROR.RAID_ERROR_ADDMEMFAILED_INVITEERR
				self:send2client(online, msg)
				return
			end
			local team = self.team_list:get_team(tid)
			if team and team:leader().guid ~= guid then
				local msg = packet_def.GCRaidError.new()
				msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYLEADERCANTANSWER
				self:send2client(online, msg)
				return
			end
			local raid_id = self.raid_list:create_raid()
			assert(raid_id)
			local raid = self.raid_list:get_raid(raid_id)
			raid:set_raid_id(raid_id)
			local msg = packet_def.GCRaidList.new()
			msg.m_nEventID = define.RAID_EVENT_ID.RAID_EVENT_CREATE
			msg.m_TeamID = tid
			-- msg.m_TeamID = -1
			msg.m_RaidID = raid_id
			msg.m_bLeaveRaid = 0
			local raid_count = team:member_count()
			msg.m_nMemberCount = raid_count
			msg.member_list = {{},{},{},{},{}}
			local index = 1
			local member
			for i = 1,raid_count do
				member = team:member(i)
				member.raid_id = raid_id
				member.m_ZoneWorldID = self.server_id
				member.m_iFightScore = 0
				member.GuildName = ""
				if member.guid == guid then
					member.m_Position = define.RAID_POISTION.RAID_POISTION_LEADER
				else
					member.m_Position = define.RAID_POISTION.RAID_POISTION_MEMBER
				end
				msg.member_list[index][i] = member
				raid:add_member(member)
			end
			self:char_dismiss_team(guid)
			raid:broad_raid_msg(msg)
			for _,mb in ipairs(msg.member_list[index]) do
				local msg = packet_def.GCRaidMemberInfo.new()
				msg.flag = 0
				msg.data_index = 0
				msg.guid = mb.guid
				msg.m_RaidID = raid_id
				msg:set_menpai(mb.menpai)
				msg:set_level(mb.level)
				
				msg:set_world_pos(mb.world_pos)
				msg:set_hp(mb.hp)
				msg:set_hp_max(mb.hp_max)
				-- msg:set_mp(mb.model)
				-- msg:set_mp_max(mb.model)
				-- msg:set_rage(mb.model)
				-- msg:set_offline(mb.model)
				-- msg:set_is_die(mb.model)
				msg:set_hair_id(mb.hair_id)
				msg:set_hair_color(mb.hair_color)
				msg:set_portrait_id(mb.portrait_id)
				msg:set_weapon(mb.weapon)
				msg:set_cap(mb.cap)
				msg:set_armour(mb.armour)
				msg:set_cuff(mb.cuff)
				msg:set_foot(mb.foot)
				msg:set_fashion(mb.fashion)
				raid:broad_raid_msg(msg)
			end
		end
	end
end

function worldcore:char_invite_team(guid, invite)
    local inviter = self:find_user(guid)
    local accpter = self:find_user_by_name(invite.dest_name)
    if not accpter then
        skynet.logw("char_invite_team fail dest_name =", invite.dest_name)
        return
    end
    if not inviter then return end
    local target_info = skynet.call(accpter.uinfo.agent, "lua", "get_player_info")
    if target_info and ((target_info.game_flags or 0) & 8) ~= 0 and guid ~= accpter.uinfo.guid then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_RESULT.TEAM_ERROR_REFUSEINVITESETTING
        self:send2client(inviter, msg)
        return
    end
    inviter.uinfo.team_id = inviter.uinfo.team_id or define.INVAILD_ID
    accpter.uinfo.team_id = accpter.uinfo.team_id or define.INVAILD_ID
	if inviter.uinfo.raid_id ~= define.INVAILD_ID then
		if accpter.uinfo.raid_id ~= define.INVAILD_ID
		or accpter.uinfo.team_id ~= define.INVAILD_ID then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_IN_OTHERRAID
			self:send2client(inviter, msg)
			return
		end
		self:char_invite_raid({m_SourObjID = guid,m_DestName = invite.dest_name})
		return
	elseif accpter.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_IN_OTHERRAID
		self:send2client(inviter, msg)
		return
	end
    local dGuid = accpter.uinfo.guid
    if accpter.uinfo.team_id ~= define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_RESULT.TEAM_ERROR_INVITEDESTHASTEAM
        self:send2client(inviter, msg)
		return
    elseif guid == dGuid and inviter.uinfo.team_id == define.INVAILD_ID then
        local tid = self.team_list:create_team()
        assert(tid)
        local team = self.team_list:get_team(tid)
        local member = inviter.uinfo
        team:add_member(member)
        local msg = packet_def.GCTeamList.new()
        msg.team_id = tid
        msg.exp_mode = team:get_exp_mode()
        msg.leader_guid = team:leader().guid
        msg.member_size = team:member_count()
        msg.member_list = team:get_members()
        msg.uinfos = team:get_members()
        team:broad_team_msg(msg)
    else
        local tid = inviter.uinfo.team_id
        local team = self.team_list:get_team(tid)
        if team and team:leader().guid ~= guid then
            local msg = packet_def.GCTeamLeaderAskInvite.new()
            msg.source_guid = guid
            msg.dest_guid = dGuid
            msg.source_name = inviter.uinfo.name
            msg.dest_name = accpter.uinfo.name

            local team_leader = team:leader()
            local leader_guid = team_leader.guid
            local leader = self:find_user(leader_guid)
            self:send2client(leader, msg)
        else
            local msg = packet_def.GCTeamAskInvite.new()
            msg.guid = guid
            msg.nickname = inviter.uinfo.name
            if team then
                self:create_invite_info(msg, team:get_members())
            else
                self:create_invite_info(msg, { inviter.uinfo })
            end
            self:send2client(accpter, msg)
        end
    end
end

function worldcore:create_invite_info(msg, members)
    msg.member_list = {}
    msg.member_size = #members
    for i, mb in ipairs(members) do
        -- local uinfo = mb
        -- local member = { detail_flag = uinfo.equip ~= nil and 1 or 0 }
		local member = {detail_flag = 0}
        member.nickname = mb.name
        member.menpai = mb.menpai
        member.sceneid = mb.sceneid
        member.level = mb.level
        member.model = mb.model
		-- member.weapon = mb.weapon
		-- member.cap = mb.cap
		-- member.armour = mb.armour
		-- member.cuff = mb.cuff
		-- member.foot = mb.foot
		-- member.fashion = mb.fashion
		
		
        -- if member.detail_flag == 1 then
            -- member.weapon = uinfo.equip.weapon
            -- member.weapon_gem = uinfo.equip.weapon_gem
            -- member.weapon_visual = uinfo.equip.weapon_visual

            -- member.cap = uinfo.equip.cap
            -- member.cap_gem = uinfo.equip.cap_gem
            -- member.cap_visual = uinfo.equip.cap_visual

            -- member.armour = uinfo.equip.armour
            -- member.armour_gem = uinfo.equip.armour_gem
            -- member.armour_visual = uinfo.equip.armour_visual

            -- member.cuff = uinfo.equip.cuff
            -- member.cuff_gem = uinfo.equip.cuff_gem
            -- member.cuff_visual = uinfo.equip.cuff_visual

            -- member.foot = uinfo.equip.foot
            -- member.foot_gem = uinfo.equip.foot_gem
            -- member.foot_visual = uinfo.equip.foot_visual
            -- member.fashion = uinfo.equip.fashion
            -- member.fasion_visual = uinfo.equip.fasion_visual
        -- end
        msg.member_list[i] = member
    end
end

function worldcore:char_dismiss_team(guid)
    local user = self:find_user(guid)
    assert(user, guid)
    local tid = user.uinfo.team_id
    local team = self.team_list:get_team(tid)
    assert(team, tid)
    local leader = team:leader()
    if leader.guid == guid then
        local msg = packet_def.GCTeamResult.new()
        msg.return_type = define.TEAM_RESULT.TEAM_RESULT_TEAMDISMISS
        msg.guid = define.INVAILD_ID
        msg.team_id = tid
        msg.guid_ex = define.INVAILD_ID
        msg.sceneid = define.INVAILD_ID
        msg.client_res = define.INVAILD_ID
        msg.name = ""
        msg.portrait_id = 0
        msg.sex = 0
        team:broad_team_msg(msg)
        self.team_list:destory_team(tid)
    else
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_RESULT.TEAM_ERROR_DISMISSNOTLEADER
        self:send2client(user, msg)
    end
end

function worldcore:char_leader_ret_invite(guid, ret)
    local leader = self:find_user(guid)
    if not leader then return end
    if ret.return_type == 0 then
        local source = self:find_user(ret.source_guid)
        if source then
            local msg = packet_def.GCTeamError.new()
            msg.error_code = define.TEAM_ERROR.TEAM_ERROR_INVITELEADERREFUSE
            self:send2client(source, msg)
        end
        return
    end
    local accpter = self:find_user(ret.dest_guid)
    if not accpter then return end
    if accpter.uinfo.team_id ~= define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_INVITEDESTHASTEAM
        self:send2client(leader, msg)
        return
    end
    local tid = leader.uinfo.team_id
    local team = self.team_list:get_team(tid)
    if not team then return end
    if team:is_full() then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_INVITETEAMFULL
        self:send2client(leader, msg)
        return
    end
    local msg = packet_def.GCTeamAskInvite.new()
    msg.guid = guid
    msg.nickname = leader.uinfo.name
    self:create_invite_info(msg, team:get_members())
    self:send2client(accpter, msg)
end

function worldcore:char_ret_invite(guid, ret)
    local inviter = self:find_user(ret.guid)
    local accpter = self:find_user(guid)
    assert(inviter, ret.guid)
	if not accpter then
		return
	end
    if inviter == nil then
        if ret.return_type == 1 then
            local msg = packet_def.GCTeamError.new()
            msg.error_code = define.TEAM_RESULT.TEAM_ERROR_TARGETNOTONLINE
            self:send2client(accpter, msg)
        end
        return
	elseif inviter.uinfo.raid_id ~= define.INVAILD_ID
	or accpter.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_IN_OTHERRAID
		self:send2client(inviter, msg)
		return
    end
    inviter.uinfo.team_id = inviter.uinfo.team_id or define.INVAILD_ID
    accpter.uinfo.team_id = accpter.uinfo.team_id or define.INVAILD_ID
    if ret.return_type == 0 then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_RESULT.TEAM_ERROR_INVITEREFUSE
        self:send2client(inviter, msg)
    elseif accpter.uinfo.team_id ~= define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_RESULT.TEAM_ERROR_INVITEDESTHASTEAM
        self:send2client(inviter, msg)
    elseif inviter.uinfo.team_id == define.INVAILD_ID then
        if ret.guid == guid then
            local tid = self.team_list:create_team()
            assert(tid)
            local team = self.team_list:get_team(tid)
            local member = inviter.uinfo
            team:add_member(member)
            local msg = packet_def.GCTeamList.new()
            msg.team_id = tid
            msg.exp_mode = team:get_exp_mode()
            msg.leader_guid = team:leader().guid
            msg.member_size = team:member_count()
            msg.member_list = team:get_members()
            msg.uinfos = team:get_members()
            team:broad_team_msg(msg)
        else
            local tid = self.team_list:create_team()
            assert(tid)
            local team = self.team_list:get_team(tid)
            team:add_member(inviter.uinfo)
            team:add_member(accpter.uinfo)

            local msg = packet_def.GCTeamList.new()
            msg.team_id = team:get_team_id()
            msg.exp_mode = team:get_exp_mode()
            msg.leader_guid = team:leader().guid
            msg.member_size = team:member_count()
            msg.member_list = team:get_members()
            msg.uinfos = team:get_members()
            team:broad_team_msg(msg)
        end
    else
        local tid = inviter.uinfo.team_id
        local team = self.team_list:get_team(tid)
        if team:is_full() then
            local msg = packet_def.GCTeamError.new()
            msg.error_code = define.TEAM_RESULT.TEAM_ERROR_INVITETEAMFULL
            self:send2client(inviter, msg)

            msg = packet_def.GCTeamError.new()
            msg.error_code = define.TEAM_RESULT.TEAM_ERROR_APPLYTEAMFULL
            self:send2client(inviter, msg)
        else
            team:add_member(accpter.uinfo)

            local msg = packet_def.GCTeamList.new()
            msg.type = define.TEAM_LIST_TYPE.JOIN
            msg.team_id = team:get_team_id()
            msg.exp_mode = team:get_exp_mode()
            msg.leader_guid = team:leader().guid
            msg.member_size = team:member_count()
            msg.member_list = team:get_members()
            msg.uinfos = team:get_members()
            team:broad_team_msg(msg)
        end
    end
end

function worldcore:char_team_apply(guid, cta)
    local me = self:find_user(guid)
    assert(me, guid)
    local dest_name = cta.dest_name
    local dest_user = self:find_user_by_name(dest_name)
    local tid = me.uinfo.team_id
    tid = tid or define.INVAILD_ID
    -- print("tid =", tid)
    if tid ~= define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYWHENINTEAM
        self:send2client(me, msg)
        return
    end
    if not dest_user then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYDESTHASNOTTEAM
        self:send2client(me, msg)
        return
	end
	if dest_user.uinfo.raid_id ~= define.INVAILD_ID then
		if me.uinfo.raid_id ~= define.INVAILD_ID then
			local msg = packet_def.GCRaidError.new()
			msg.error_code = define.RAID_ERROR.RAID_RESERVER_8
			self:send2client(me, msg)
			return
		end
		self:char_apply_raid({m_SourGUID = guid,m_DestName = dest_name})
		return
	elseif me.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_RESERVER_8
		self:send2client(me, msg)
		return
	end
    local dest_tid = dest_user.uinfo.team_id
    dest_tid = dest_tid or define.INVAILD_ID
    if dest_tid == define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYDESTHASNOTTEAM
        self:send2client(me, msg)
        return
    end
    local team = self.team_list:get_team(dest_tid)
    if team == nil then
        return
    end
    local team_leader = team:leader()
    local leader_guid = team_leader.guid
    local leader = self:find_user(leader_guid)
    assert(leader, leader_guid)
    local msg = packet_def.GCTeamAskApply.new()
    msg.source_guid = guid
    msg.dest_guid = leader_guid
    msg.source_name = me.uinfo.name
    msg.dest_name = leader.uinfo.name
    msg.uinfo = table.clone(me.uinfo)
    msg.uinfo.detail_flag = 0
    self:send2client(leader, msg)
end

function worldcore:char_ret_team_apply(guid, rta)
    local source_guid = rta.source_guid
    local me = self:find_user(source_guid)
    if me == nil then
        return
    end
    local leader = self:find_user(guid)
    if leader == nil then
        return
    end
    if rta.return_type == 0 then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYLEADERREFUSE
        self:send2client(me, msg)
        return
    end
	if me.uinfo.raid_id ~= define.INVAILD_ID
	or leader.uinfo.raid_id ~= define.INVAILD_ID then
		local msg = packet_def.GCRaidError.new()
		msg.error_code = define.RAID_ERROR.RAID_ERROR_TARGET_IN_OTHERRAID
		self:send2client(leader, msg)
		return
	end
    local tid = me.uinfo.team_id
    tid = tid or define.INVAILD_ID
    if tid ~= define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYSOURHASTEAM
        self:send2client(leader, msg)
        return
    end
    local leader_tid = leader.uinfo.team_id
    leader_tid = leader_tid or define.INVAILD_ID
    local team = self.team_list:get_team(leader_tid)
    if team:is_full() then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYTEAMFULL
        self:send2client(me, msg)
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_TEAMFULL
        self:send2client(leader, msg)
        return
    end
    local team_leader_guid = team:leader().guid
    if team_leader_guid ~= guid then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYLEADERGUIDERROR
        self:send2client(me, msg)
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPLYLEADERGUIDERROR
        self:send2client(leader, msg)
        return
    end
    team:add_member(me.uinfo)
    local msg = packet_def.GCTeamList.new()
    msg.type = define.TEAM_LIST_TYPE.JOIN
    msg.team_id = team:get_team_id()
    msg.exp_mode = team:get_exp_mode()
    msg.leader_guid = team:leader().guid
    msg.member_size = team:member_count()
    msg.member_list = team:get_members()
    msg.uinfos = team:get_members()
    --team:broad_team_msg(msg)
    self:send2client(me, msg)
end

function worldcore:char_team_kick(guid, tk)
    local source_guid = guid
    local me = self:find_user(source_guid)
    if me == nil then
        return
    end
    local other_guid = tk.dest_guid
    local other = self:find_user(other_guid)
    if other == nil then
        return
    end
    local tid = other.uinfo.team_id
    tid = tid or define.INVAILD_ID
    if tid == define.INVAILD_ID then
        return
    end
    local team = self.team_list:get_team(tid)
    local team_leader_guid = team:leader().guid
    if team_leader_guid ~= guid then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_DISMISSNOTLEADER
        self:send2client(me, msg)
        return
    end
    team:del_member(other.uinfo)
    local msg = packet_def.GCTeamResult.new()
    msg.guid = other_guid
    msg.return_type = define.TEAM_RESULT.TEAM_RESULT_TEAMKICK
    msg.team_id = tid
    msg.guid_ex = other_guid
    msg.sceneid = other.uinfo.sceneid
    msg.client_res = other.uinfo.client_res
    msg.name = other.uinfo.name
    msg.portrait_id = other.uinfo.portrait_id
    msg.sex = other.uinfo.model
    self:send2client(other, msg)
    team:broad_team_msg(msg)
end

function worldcore:char_team_appoint(guid, ta)
    local source_guid = guid
    local source = self:find_user(source_guid)
    if source == nil then
        return
    end
    local dest_guid = ta.dest_guid
    local dest = self:find_user(dest_guid)
    if dest == nil then
        return
    end
    local source_tid = source.uinfo.team_id
    source_tid = source_tid or define.INVAILD_ID
    if source_tid == define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPOINTSOURNOTEAM
        self:send2client(source, msg)
        return
    end
    local dest_tid = dest.uinfo.team_id
    dest_tid = dest_tid or define.INVAILD_ID
    if dest_tid == define.INVAILD_ID then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPOINTDESTNOTEAM
        self:send2client(source, msg)
        return
    end
    if source_tid ~= dest_tid then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPOINTNOTSAMETEAM
        self:send2client(source, msg)
        return
    end
    local team = self.team_list:get_team(source_tid)
    local leader_guid = team:leader().guid
    if leader_guid ~= source_guid then
        local msg = packet_def.GCTeamError.new()
        msg.error_code = define.TEAM_ERROR.TEAM_ERROR_APPOINTSOURNOLEADER
        self:send2client(source, msg)
        return
    end
    local member = { guid = dest_guid}
    team:appoint(member)
    local msg = packet_def.GCTeamResult.new()
    msg.guid = source_guid
    msg.return_type = define.TEAM_RESULT.TEAM_RESULT_TEAMAPPOINT
    msg.team_id = source_tid
    msg.guid_ex = dest_guid
    msg.sceneid = dest.uinfo.sceneid
    msg.client_res = dest.uinfo.client_res
    msg.name = dest.uinfo.name
    msg.portrait_id = dest.uinfo.portrait_id
    msg.sex = dest.uinfo.model
    team:broad_team_msg(msg)
    team:clear_followed_members()
end

function worldcore:char_team_change_option(guid, ctco)
    local user = self:find_user(guid)
    if user == nil then
        return
    end
    local tid = user.uinfo.team_id
    tid = tid or define.INVAILD_ID
    local team = self.team_list:get_team(tid)
    if team == nil then
        return
    end
    local leader_guid = team:leader().guid
    if leader_guid ~= guid then
        return
    end
    team:set_option(ctco)
end

function worldcore:ask_team_member_info(guid, ask)
    local me = self:find_user(guid)
    assert(me, guid)
    local tid = me.uinfo.team_id
    local team = self.team_list:get_team(tid)
    assert(team, guid)
    local member = team:get_member_by_guid(ask.guid)
    return member
end

function worldcore:char_leave_team(guid)
    local me = self:find_user(guid)
    -- assert(me, guid)
	if me then
		local tid = me.uinfo.team_id
		local team = self.team_list:get_team(tid)
		if team then
			if tid ~= team:get_team_id() then
				return
			end
			if not team:is_member(me.uinfo) then
				return
			end
			-- assert(tid == team:get_team_id(), tid)
			local team_leader = team:leader()
			local stop_follow_guids = { guid }
			if team_leader.guid == guid then
				local seen = { [guid] = true }
				for _, member in ipairs(team:get_members()) do
					if not seen[member.guid] then
						seen[member.guid] = true
						table.insert(stop_follow_guids, member.guid)
					end
				end
			end
			self:notify_stop_team_follow(stop_follow_guids)
			team:del_member(me.uinfo)
			if team:member_count() == 0 then
				local msg = packet_def.GCTeamResult.new()
				msg.return_type = define.TEAM_RESULT.TEAM_RESULT_TEAMDISMISS
				msg.guid = define.INVAILD_ID
				msg.team_id = tid
				msg.guid_ex = define.INVAILD_ID
				msg.sceneid = define.INVAILD_ID
				msg.client_res = define.INVAILD_ID
				msg.name = ""
				msg.portrait_id = 0
				msg.sex = 0
				self:send2client(me, msg)
				self.team_list:destory_team(tid)
			else
				local msg = packet_def.GCTeamResult.new()
				msg.guid = guid
				if team_leader.guid == guid then
					msg.return_type = define.TEAM_RESULT.TEAM_RESULT_LEADERLEAVETEAM
					team:clear_followed_members()
				else
					msg.return_type = define.TEAM_RESULT.TEAM_RESULT_MEMBERLEAVETEAM
				end
				msg.leader_guid = team:leader().guid
				msg.team_id = tid
				msg.guid_ex = guid
				msg.sceneid = me.uinfo.sceneid
				msg.client_res = me.uinfo.client_res
				msg.name = me.uinfo.name
				msg.portrait_id = me.uinfo.portrait_id
				msg.sex = me.uinfo.model
				self:send2client(me, msg)
				team:broad_team_msg(msg)
			end
		end
	end
end

function worldcore:char_start_change_scene(guid)
    local me = self:find_user(guid)
    assert(me, guid)
    local raid_id = me.uinfo.raid_id
    local raid = self.raid_list:get_raid(raid_id)
	if raid then
		local mb,tid,mid = raid:is_member(me.uinfo.guid)
		if mb then
			local msg = packet_def.GCRaidResult.new()
			msg.name = mb.name
			msg.return_type = define.RAID_RESULT.RAID_RESULT_STARTCHANGESCENE
			msg.guid = guid
			msg.raid_id = raid_id
			msg.guid_ex = guid
			msg.m_objID = mb.m_objID
			msg.sceneid = mb.sceneid
			msg.client_res = mb.client_res
			msg.portrait_id = mb.portrait_id
			msg.sex = mb.model
			msg.m_Position = mb.m_Position
			msg.m_SquadIdx = tid
			msg.m_MemberIdx = mid
			msg.m_ZoneWorldID = mb.m_ZoneWorldID
			msg.m_iFightScore = mb.m_iFightScore
			msg.GuildName = mb.GuildName
			raid:broad_raid_msg(msg)
			return
		end
	end
    local team_id = me.uinfo.team_id
    local team = self.team_list:get_team(team_id)
    if team then
        if team:is_member(me.uinfo) then
            local msg = packet_def.GCTeamResult.new()
            msg.return_type = define.TEAM_RESULT.TEAM_RESULT_STARTCHANGESCENE
            msg.name = me.uinfo.name
            msg.guid = guid
            msg.team_id = team_id
            msg.leader_guid = team:leader().guid
            msg.guid_ex = me.uinfo.m_objID
            msg.sceneid = me.uinfo.sceneid
            msg.portrait_id = me.uinfo.portrait_id
            msg.client_res = me.uinfo.client_res
            msg.sex = me.uinfo.model
            msg.uinfos = team:get_members()
            team:broad_team_msg(msg)
        end
    end
end

function worldcore:char_enter_scene(guid)
    local me = self:find_user(guid)
    assert(me, guid)
    local raid_id = me.uinfo.raid_id
    local raid = self.raid_list:get_raid(raid_id)
	if raid then
		local mb,tid,mid = raid:is_member(me.uinfo.guid)
		if mb then
			local msg = packet_def.GCRaidResult.new()
			msg.name = mb.name
			msg.return_type = define.RAID_RESULT.RAID_RESULT_ENTERSCENE
			msg.guid = guid
			msg.raid_id = raid_id
			msg.guid_ex = guid
			msg.m_objID = mb.m_objID
			msg.sceneid = mb.sceneid
			msg.client_res = mb.client_res
			msg.portrait_id = mb.portrait_id
			msg.sex = mb.model
			msg.m_Position = mb.m_Position
			msg.m_SquadIdx = tid
			msg.m_MemberIdx = mid
			msg.m_ZoneWorldID = mb.m_ZoneWorldID
			msg.m_iFightScore = mb.m_iFightScore
			msg.GuildName = mb.GuildName
			raid:broad_raid_msg(msg)
			
			msg = packet_def.GCRaidList.new()
			msg.m_nEventID = define.RAID_EVENT_ID.RAID_EVENT_RET_RAIDINFO
			msg.m_TeamID = -1
			msg.m_RaidID = raid_id
			msg.m_bLeaveRaid = 0
			msg.member_list = raid:get_members()
			msg.m_nMemberCount = raid:member_count()
			raid:send_msg_to_member(mb, msg)
			
			for _,teams in ipairs(msg.member_list) do
				for _, mb_1 in ipairs(teams) do
					if mb_1.guid ~= guid then
						msg = packet_def.GCRaidMemberInfo.new()
						msg.flag = 0
						msg.data_index = 0
						msg.guid = mb_1.guid
						msg.m_RaidID = raid_id
						msg:set_menpai(mb_1.menpai)
						msg:set_level(mb_1.level)
						msg:set_world_pos(mb_1.world_pos)
						msg:set_hp(mb_1.hp)
						msg:set_hp_max(mb_1.hp_max)
						msg:set_hair_id(mb_1.hair_id)
						msg:set_hair_color(mb_1.hair_color)
						msg:set_portrait_id(mb_1.portrait_id)
						msg:set_weapon(mb_1.weapon)
						msg:set_cap(mb_1.cap)
						msg:set_armour(mb_1.armour)
						msg:set_cuff(mb_1.cuff)
						msg:set_foot(mb_1.foot)
						msg:set_fashion(mb_1.fashion)
						raid:send_msg_to_member(mb, msg)
					end
				end
			end
			return
		end
	end
    local team_id = me.uinfo.team_id
    local team = self.team_list:get_team(team_id)
    if team then
        if team:is_member(me.uinfo) then
            local msg = packet_def.GCTeamResult.new()
            msg.return_type = define.TEAM_RESULT.TEAM_RESULT_ENTERSCENE
            msg.name = me.uinfo.name
            msg.guid = guid
            msg.team_id = team_id
            msg.leader_guid = team:leader().guid
            msg.guid_ex = me.uinfo.m_objID
            msg.sceneid = me.uinfo.sceneid
            msg.portrait_id = me.uinfo.portrait_id
            msg.client_res = me.uinfo.client_res
            msg.sex = me.uinfo.model
            msg.uinfo = me.uinfo
            team:broad_team_msg_expect_self(me, msg)

            msg = packet_def.GCTeamList.new()
            msg.type = define.TEAM_LIST_TYPE.REFRESH
            msg.team_id = team_id
            msg.exp_mode = team:get_exp_mode()
            msg.leader_guid = team:leader().guid
            msg.member_size = team:member_count()
            msg.member_list = team:get_members()
            msg.uinfos = team:get_members()
            self:send2client(me, msg)

            if team:is_followd_member(me.uinfo.guid) then
                local followd_members = team:get_followd_members()
                skynet.send(me.uinfo.agent, "lua", "char_enter_team_follow", followd_members)
            else
                skynet.send(me.uinfo.agent, "lua", "char_stop_team_follow_self")
            end
        end
    end
end

-- CGAskTeamInfo → 返回当前队伍信息给客户端
function worldcore:char_ask_team_info(guid)
    local me = self:find_user(guid)
    if not me then return end
    -- 先检查raid
    local raid_id = me.uinfo.raid_id
    local raid = self.raid_list:get_raid(raid_id)
    if raid then
        local mb = raid:is_member(guid)
        if mb then
            local msg = packet_def.GCRaidList.new()
            msg.m_nEventID = define.RAID_EVENT_ID.RAID_EVENT_RET_RAIDINFO
            msg.m_TeamID = -1
            msg.m_RaidID = raid_id
            msg.m_bLeaveRaid = 0
            msg.member_list = raid:get_members()
            msg.m_nMemberCount = raid:member_count()
            raid:send_msg_to_member(mb, msg)
            -- 发送所有成员的GCRaidMemberInfo
            for _,teams in ipairs(raid:get_members()) do
                for _, mb_1 in ipairs(teams) do
                    if mb_1.guid ~= guid then
                        local rmsg = packet_def.GCRaidMemberInfo.new()
                        rmsg.flag = 0
                        rmsg.data_index = 0
                        rmsg.guid = mb_1.guid
                        rmsg.m_RaidID = raid_id
                        rmsg:set_menpai(mb_1.menpai)
                        rmsg:set_level(mb_1.level)
                        rmsg:set_world_pos(mb_1.world_pos)
                        rmsg:set_hp(mb_1.hp)
                        rmsg:set_hp_max(mb_1.hp_max)
                        rmsg:set_hair_id(mb_1.hair_id)
                        rmsg:set_hair_color(mb_1.hair_color)
                        rmsg:set_portrait_id(mb_1.portrait_id)
                        rmsg:set_weapon(mb_1.weapon)
                        rmsg:set_cap(mb_1.cap)
                        rmsg:set_armour(mb_1.armour)
                        rmsg:set_cuff(mb_1.cuff)
                        rmsg:set_foot(mb_1.foot)
                        rmsg:set_fashion(mb_1.fashion)
                        raid:send_msg_to_member(mb, rmsg)
                    end
                end
            end
            return
        end
    end
    -- 再检查team
    local team_id = me.uinfo.team_id
    local team = self.team_list:get_team(team_id)
    if team and team:is_member(me.uinfo) then
        local msg = packet_def.GCTeamList.new()
        msg.type = define.TEAM_LIST_TYPE.REFRESH
        msg.team_id = team_id
        msg.exp_mode = team:get_exp_mode()
        msg.leader_guid = team:leader().guid
        msg.member_size = team:member_count()
        msg.member_list = team:get_members()
        msg.uinfos = team:get_members()
        self:send2client(me, msg)
    end
end

-- CGAskRaidMemberInfo → 返回团队成员详细信息
function worldcore:char_ask_raid_member_info(guid, pkt)
    local me = self:find_user(guid)
    if not me then return end
    local raid_id = me.uinfo.raid_id
    local raid = self.raid_list:get_raid(raid_id)
    if not raid then return end
    local target_guid = pkt.guid
    local target_mb = raid:get_member_by_guid(target_guid)
    if not target_mb then return end
    local msg = packet_def.GCRaidMemberInfo.new()
    msg.flag = 0
    msg.data_index = 0
    msg.guid = target_guid
    msg.m_RaidID = raid_id
    msg:set_menpai(target_mb.menpai)
    msg:set_level(target_mb.level)
    msg:set_world_pos(target_mb.world_pos)
    msg:set_hp(target_mb.hp)
    msg:set_hp_max(target_mb.hp_max)
    msg:set_hair_id(target_mb.hair_id)
    msg:set_hair_color(target_mb.hair_color)
    msg:set_portrait_id(target_mb.portrait_id)
    msg:set_weapon(target_mb.weapon)
    msg:set_cap(target_mb.cap)
    msg:set_armour(target_mb.armour)
    msg:set_cuff(target_mb.cuff)
    msg:set_foot(target_mb.foot)
    msg:set_fashion(target_mb.fashion)
    self:send2client(me, msg)
end

function worldcore:get_player_raid_id(guid)
    local me = self:find_user(guid)
    if not me then return -1 end
    return me.uinfo.raid_id or -1
end

function worldcore:get_my_team_id(guid)
    local me = self:find_user(guid)
    assert(me, guid)
    local tid = me.uinfo.team_id
    return tid
end

function worldcore:get_my_teaminfo(guid,sceneId)
	local new_sceneId
	if define.LUOYANG[sceneId] then
		local goto_id,min_scene
		local def_max_num = 99999999
		for i,num in pairs(self.luoyang_human) do
			if num < define.LUOYANG_MAXHUMAN then
				goto_id = i
				break
			elseif num < def_max_num then
				def_max_num = num
				min_scene = i
			end
		end
		new_sceneId = goto_id or min_scene
	end
    local me = self:find_user(guid)
	if not me then
		return { id = define.INVAILD_ID, leader = define.INVAILD_ID },new_sceneId
	end
    local tid = me.uinfo.team_id
    local team = self.team_list:get_team(tid)
    local teaminfo = { id = define.INVAILD_ID, leader = define.INVAILD_ID }
    if team then
        local leader = team:leader()
        teaminfo.id = team:get_team_id()
        teaminfo.leader = leader.guid
    end
    return teaminfo,new_sceneId
end

function worldcore:team_chat(guid, msg)
    local me = self:find_user(guid)
    assert(me, guid)
    local tid = me.uinfo.team_id
    local team = self.team_list:get_team(tid)
    assert(team, guid)
    team:broad_team_msg(msg)
end

function worldcore:raid_chat(guid, msg)
    local me = self:find_user(guid)
    assert(me, guid)
    local raid_id = me.uinfo.raid_id
    local raid = self.raid_list:get_raid(raid_id)
    assert(raid, guid)
    raid:broad_raid_msg(msg)
end

function worldcore:raid_chat_team(guid, msg)
    local me = self:find_user(guid)
    assert(me, guid)
    local raid_id = me.uinfo.raid_id
    local raid = self.raid_list:get_raid(raid_id)
    assert(raid, guid)
	local mb,tid = raid:is_member(guid)
    assert(mb, guid)
    raid:broad_raid_team_msg(tid + 1,msg)
end

function worldcore:tell_chat(name, msg)
    local user = self:find_user_by_name(name)
    if not user then return end
    self:send2client(user, msg)
end

function worldcore:mail_chat(guid, name, portrait_id, msg)
    local target_user = self:get_db_user_by_guid(msg.dest_guid)
    if target_user then
        -- print("msg.dest_guid =", msg.dest_guid, ";target_user.attrib.name =", target_user.attrib.name)
        local online_user = self:find_user(msg.dest_guid)
        if online_user then
            self:send2client(online_user, packet_def.GCChat.xy_id, msg)
        else
            local mail = {}
            mail.guid = guid
            mail.source = name
            mail.portrait_id = portrait_id
            mail.dest = target_user.attrib.name
            mail.content = gbk.toutf8(msg.Contex)
            mail.flag = define.MAIL_TYPE.MAIL_TYPE_NORMAL
            mail.create_time = os.time()
            self:send_mail(mail)
        end
    end
end

function worldcore:insert_mail(guid, mail)
    local selector = {["attrib.guid"] = guid}
    local updater = {}
    updater["$push"] = { mail_list = mail }
    local sql = { collection = "character", selector = selector,update = updater,upsert = false,multi = false}
    skynet.send(".char_db", "lua", "update", sql)
end

-- Keep admission across reconnects; never throttle internal quest/system mail.
function worldcore:send_player_mail(guid, mail)
    if not self:find_user(guid) or type(mail) ~= "table" or mail.guid ~= guid then return false end
    local now = skynet.now()/100
    self.cys_mail_admission = self.cys_mail_admission or {}
    if not self.cys_mail_prune or now-self.cys_mail_prune >= 60 then
        for id,state in pairs(self.cys_mail_admission) do
            if now-(state.last or 0) >= 300 then self.cys_mail_admission[id]=nil end
        end
        self.cys_mail_prune=now
    end
    local state=self.cys_mail_admission[guid]
    if not state then state={};self.cys_mail_admission[guid]=state end
    if not require("cys_mail_guard").accept(state,mail,now) then return false end
    self:send_mail(mail)
    return true
end

function worldcore:send_mail(mail)
    local dest = mail.dest
    local user = self:get_db_user_by_name(mail.dest)
    if user then
        self:insert_mail(user.attrib.guid, mail)
        local online_user = self:find_user_by_name(dest)
        if online_user then
            skynet.send(online_user.uinfo.agent, "lua", "new_mail")
        end
    end
end

function worldcore:send_mail_to_guid(mail)
    local user = self:get_db_user_by_guid(mail.dest_guid)
    if user then
        mail.dest = user.attrib.name
        self:insert_mail(user.attrib.guid, mail)
        local online_user = self:find_user(mail.dest_guid)
        if online_user then
            skynet.send(online_user.uinfo.agent, "lua", "new_mail")
        end
    end
end

function worldcore:get_db_user_by_name(name)
    assert(name ~= nil)
    local user = skynet.call(".char_db", "lua", "findOne",  {collection = "character", query = {["attrib.name"] = name, server_id = self.server_id }})
	-- skynet.logi("get_db_user_by_name = ",name,"self.server_id = ",self.server_id,"user = ",user)
	return user
end

function worldcore:get_db_user_by_guid(guid)
    assert(guid ~= nil)
    local user = skynet.call(".char_db", "lua", "findOne",  {collection = "character", query = {["attrib.guid"] = guid, server_id = self.server_id }})
    return user
end

function worldcore:find_online_users_by_like_name(like_name, skip, limit)
    local position = 0
    local users = {}
    for _, user in pairs(self.online_users) do
        if like_name == "" or string.find(user.uinfo.name, like_name) then
            if position >= skip then
                table.insert(users, table.clone(user))
            end
            position = position + 1
        end
        if #users >= limit then
            break
        end
    end
    return users
end

function worldcore:finger(_, arg)
    if arg.type == define.FINGER_REQUEST_TYPE.FREQ_GUID then
        local users = {}
        local response = skynet.call(".char_db", "lua", "findAll",  {collection = "character", query = {["attrib.guid"] = arg.finger_by_guid.target_guid, server_id = self.server_id}})
        local position = 0
        local finger_flag  = 0
        if response then
            for _, u in ipairs(response) do
                if #users < 10 then
                    local online_user = self:find_user(u.attrib.guid)
                    u.attrib.online_flag = online_user and 1 or 0
                    u.attrib.guild_name = ""
                    u.attrib.confederate_name = ""
                    u.attrib.guild = define.INVAILD_ID
                    u.attrib.confederate = define.INVAILD_ID
                    table.insert(users, u.attrib)
                end
            end
            finger_flag = response[11] and 1 or 0
        end
        return users, finger_flag, position
    elseif arg.type == define.FINGER_REQUEST_TYPE.FREQ_NAME then
        local users
        local position
        local finger_flag  = 0
        if arg.finger_by_name.online_flag == 1 then
            users = {}
            local online_users = self:find_online_users_by_like_name(arg.finger_by_name.name, arg.finger_by_name.position, 11)
            for _, u in ipairs(online_users) do
                if #users < 10 then
                    u.uinfo.online_flag = 1
                    u.uinfo.guild_name = ""
                    u.uinfo.confederate_name = ""
                    u.uinfo.guild = define.INVAILD_ID
                    u.uinfo.confederate = define.INVAILD_ID
                    table.insert(users, u.uinfo)
                end
            end
            finger_flag = online_users[11] and 1 or 0
        else
            users = {}
            local query = { ["attrib.name"] = { ["$regex"] = string.format("%s", arg.finger_by_name.name)}, server_id = self.server_id}
            local response = skynet.call(".char_db", "lua", "findAll",  {collection = "character", selector = { attrib = 1 }, query = query, skip = arg.finger_by_name.position, limit = 11})
            if response then
                for _, u in ipairs(response) do
                    if #users < 10 then
                        local online_user = self:find_user(u.attrib.guid)
                        u.attrib.online_flag = online_user and 1 or 0
                        u.attrib.guild_name = ""
                        u.attrib.confederate_name = ""
                        u.attrib.guild = define.INVAILD_ID
                        u.attrib.confederate = define.INVAILD_ID
                        table.insert(users, u.attrib)
                    end
                end
                finger_flag = response[11] and 1 or 0
            end
        end
        position = arg.finger_by_name.position + 9
        return users, finger_flag, position
    elseif arg.type == define.FINGER_REQUEST_TYPE.FREQ_ADVANCED then
        local query = {}
        if arg.advanced_finger.menpai and arg.advanced_finger.menpai >= 0 then
            query["attrib.menpai"] = arg.advanced_finger.menpai
        end
        if arg.advanced_finger.guild and arg.advanced_finger.guild >= 0 then
            query["attrib.guild"] = arg.advanced_finger.guild
        end
        if arg.advanced_finger.sex and arg.advanced_finger.sex ~= define.INVAILD_ID then
            query["attrib.model"] = arg.advanced_finger.sex
        end
        if arg.advanced_finger.bottom_level and arg.advanced_finger.bottom_level ~= define.INVAILD_ID then
            query["attrib.level"] = {["$gte"] = arg.advanced_finger.bottom_level}
            query["attrib.level"]["$lte"] = arg.advanced_finger.bottom_level + 10 - 1
        end
        query.server_id = self.server_id
        local response = skynet.call(".char_db", "lua", "findAll",  {collection = "character", query = query, selector = { attrib = 1}, skip = arg.advanced_finger.position, limit = 11})
        if response then
            local users = {}
            for _, u in ipairs(response) do
                if #users < 10 then
                    local online_user = self:find_user(u.attrib.guid)
                    u.attrib.online_flag = online_user and 1 or 0
                    u.attrib.guild_name = ""
                    u.attrib.confederate_name = ""
                    u.attrib.guild = define.INVAILD_ID
                    u.attrib.confederate = define.INVAILD_ID
                    table.insert(users, u.attrib)
                end
            end
            local position = arg.advanced_finger.position + 9
            local finger_flag = response[11] and 1 or 0
            return users, finger_flag, position
        end
    end
end

function worldcore:get_player_info(guid)
    local user = self:find_user(guid)
    if user then
        local team_size = 0
        local tid = user.uinfo.team_id or define.INVAILD_ID
        if tid ~= define.INVAILD_ID then
            local team = self.team_list:get_team(tid)
            team_size = team:member_count()
        end
        local uinfo = skynet.call(user.uinfo.agent, "lua", "get_player_info")
        uinfo.online_flag = true
        uinfo.team_size = team_size
        return uinfo
    else
        local character = skynet.call(".char_db", "lua", "findOne", { collection = "character", query = {["attrib.guid"] = guid, server_id = self.server_id}})
        if not character then return nil end
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
            online_flag = false,
            team_size = 0,
            title = "",
            relation = character.relation,
            game_flags = (character.setting and character.setting["2"] or {}).data or 0
        }
        return uinfo
    end
end

function worldcore:get_player_info_by_name(name)
    local character = skynet.call(".char_db", "lua", "findOne", { collection = "character", query = {["attrib.name"] = name, server_id = self.server_id}})
    if not character then return nil end
    return self:get_player_info(character.attrib.guid)
end

function worldcore:get_player_world_pos_by_name(name)
    local user = self:find_user_by_name(name)
    if user then
        local scene = string.format(".SCENE_%d", user.uinfo.sceneid)
        local world_pos = skynet.call(scene, "lua", "get_obj_world_pos", user.uinfo.m_objID)
        return world_pos
    end
end

-- 根据 guid 查询在线玩家的场景ID和坐标，用于跨场景跟随传送
function worldcore:get_member_scene_info(guid)
    local user = self:find_user(guid)
    if user and user.uinfo.sceneid and user.uinfo.sceneid ~= define.INVAILD_ID then
        return { sceneid = user.uinfo.sceneid, world_pos = user.uinfo.world_pos }
    end
end

function worldcore:get_online_users_in_list(list)
    local online_users = {}
    for _, guid in ipairs(list) do
        local u = self:find_user(guid)
        if u then
            table.insert(online_users, { guid = u.uinfo.guid, mood = u.uinfo.mood, portrait = u.uinfo.portrait_id })
        end
    end
    return online_users
end

function worldcore:enter_team_follow(guid)
    local user = self:find_user(guid)
    if not user then
        return
    end
    local tid = user.uinfo.team_id
    local team = self.team_list:get_team(tid)
    if team == nil then
        return
    end
    team:add_followd_member(guid)
end

function worldcore:leave_team_follow(guid)
    local user = self:find_user(guid)
    if not user then
        return
    end
    local tid = user.uinfo.team_id
    local team = self.team_list:get_team(tid)
    if team == nil then
        return
    end
    local leader = team:leader().guid
    if leader == guid then
        team:clear_followed_members()
    else
        team:del_followd_member(guid)
    end
end

function worldcore:stop_team_follow(guid)
    local user = self:find_user(guid)
    if not user then
        return
    end
    local team = self.team_list:get_team(user.uinfo.team_id)
    if not team then
        if user.uinfo.agent then
            skynet.send(user.uinfo.agent, "lua", "char_stop_team_follow_self")
        end
        return
    end

    local leader = team:leader()
    if not leader then
        return
    end
    if leader.guid == guid then
        local affected = {}
        local seen = {}
        for _, member in ipairs(team:get_members()) do
            local member_guid = member.guid
            if not seen[member_guid] then
                seen[member_guid] = true
                table.insert(affected, member_guid)
            end
        end
        if not seen[guid] then
            table.insert(affected, guid)
        end
        team:clear_followed_members()
        self:notify_stop_team_follow(affected)
        return
    end

    team:del_followd_member(guid)
    self:notify_stop_team_follow({ guid })
    local teammates = {}
    for _, member in ipairs(team:get_members()) do
        if member.guid ~= guid then
            table.insert(teammates, member.guid)
        end
    end
    self:notify_del_team_follow_member(teammates, guid)
end

function worldcore:notify_stop_team_follow(guids)
    for _, guid in ipairs(guids) do
        local user = self:find_user(guid)
        if user and user.uinfo.agent then
            skynet.send(user.uinfo.agent, "lua", "char_stop_team_follow_self")
        end
    end
end

function worldcore:notify_del_team_follow_member(guids, del_guid)
    for _, guid in ipairs(guids) do
        local user = self:find_user(guid)
        if user and user.uinfo.agent then
            skynet.send(user.uinfo.agent, "lua", "char_del_team_follow_member", del_guid)
        end
    end
end

function worldcore:notify_friends_online(uinfo, list)
    for _, friend in ipairs(list) do
        local user = self:find_user(friend.guid)
        if user then
            skynet.send(user.uinfo.agent, "lua", "be_notifyd_friend_online", uinfo)
        end
    end
end

function worldcore:notify_friend_be_add(guid, tar_guid, relation_type)
    local user = self:find_user(guid)
    if user then
        skynet.send(user.uinfo.agent, "lua", "be_notify_friend_be_add", tar_guid, relation_type)
    end
end

function worldcore:notify_friend_be_del(guid, tar_guid, relation_type)
    local user = self:find_user(guid)
    if user then
        skynet.send(user.uinfo.agent, "lua", "be_notify_friend_be_del", tar_guid, relation_type)
    end
end

function worldcore:notify_friends_offline(uinfo, list)
    for _, friend in ipairs(list) do
        local user = self:find_user(friend.guid)
        if user then
            skynet.send(user.uinfo.agent, "lua", "be_notifyd_friend_offline", uinfo)
        end
    end
end

function worldcore:multicast(...)
    self.multicast_channel:publish(...)
end

function worldcore:menpai_multicast(menpai, ...)
    local channel = self.menpai_channels[menpai]
    if channel then
        channel:publish(...)
    end
end

function worldcore:send2client(...)
    local args = { ... }
    if #args == 2 then
        local user = args[1]
        local packet = args[2]
        skynet.send(user.uinfo.agent, "lua", "send2client", packet.xy_id, packet)
    elseif #args == 3 then
        local user = args[1]
        local xy_id = args[2]
        local packet = args[3]
        skynet.send(user.uinfo.agent, "lua", "send2client", xy_id, packet)
    else
        assert(false)
    end
end


function worldcore:send_to_online_user_by_guid(guid, ...)
    local user = self:find_user(guid)
    if user then
        self:send2client(user, ...)
        return true
    end
    return false
end

function worldcore:set_global_data(index, val)
    self.global_data = self.global_data or {}
    self.global_data[index] = val
end

function worldcore:get_global_data(index)
    self.global_data = self.global_data or {}
    return self.global_data[index] or 0
end

function worldcore:check_guild_users_is_online(users)
    local online_count = 0
    for _, u in ipairs(users) do
        local guid = u.guid
        u.is_online = 0
        if self.online_users[guid] then
            u.is_online = 1
            online_count = online_count + 1
        end
    end
    return users, online_count
end

function worldcore:get_online_users_count()
    local online_count = 0
    for _ in pairs(self.online_users) do
        online_count = online_count + 1
    end
    return online_count
end

function worldcore:change_user_nickname(guid, new_nickname)
    local user = self:find_user(guid)
    return skynet.call(user.uinfo.agent, "lua", "change_user_nickname", new_nickname)
end

function worldcore:award_item(guid, item_id, item_count, is_bind)
    local user = self:find_user(guid)
    return skynet.call(user.uinfo.agent, "lua", "award_item", item_id, item_count, is_bind)
end

function worldcore:change_user_level(guid, new_level)
    local user = self:find_user(guid)
    return skynet.call(user.uinfo.agent, "lua", "change_user_level", new_level)
end

function worldcore:change_user_money(guid, new_level)
    local user = self:find_user(guid)
    return skynet.call(user.uinfo.agent, "lua", "change_user_money", new_level)
end

return require('cys_social_world').install(require('cys_party').install(worldcore))
