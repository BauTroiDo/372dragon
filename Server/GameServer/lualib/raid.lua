local skynet = require "skynet"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local raid = class("raid")

function raid:ctor()
    self.members = {{},{},{},{},{}}
    self:clean_up()
end

function raid:clean_up()
    for _, team in ipairs(self.members) do
		for _, mb in ipairs(team) do
			mb.raid_id = define.INVAILD_ID
		end
    end
    self.members = {{},{},{},{},{}}
end

function raid:set_raid_id(id)
    self.id = id
end

function raid:get_raid_id()
    return self.id
end

function raid:is_empty()
    return self:member_count() < 1
end

function raid:member_count()
    return #self.members[1] + #self.members[2] + #self.members[3] + #self.members[4] + #self.members[5]
end

function raid:get_members()
    return self.members
end

function raid:get_member_by_guid(guid)
    for _, team in ipairs(self.members) do
		for _,mb in ipairs(team) do
			if mb.guid == guid then
				return mb
			end
		end
    end
end

function raid:is_active()
	return self:member_count() > 0
end

function raid:add_member(member,guid)
	local m_SquadIdx,m_MemberIdx
	local team_num
	for tid,team in ipairs(self.members) do
		team_num = #team
		if team_num < 6 then
			m_SquadIdx = tid - 1
			m_MemberIdx = team_num
			table.insert(team, member)
			break
		end
	end
	if not m_SquadIdx or not m_MemberIdx then
		return
	end
	if member.guid ~= guid then
		return
	end
	local raid_id = member.raid_id
	local msg = packet_def.GCRaidResult.new()
	msg.name = member.name
	msg.return_type = define.RAID_RESULT.RAID_RESULT_MEMBERENTER
	msg.guid = guid
	msg.raid_id = raid_id
	msg.guid_ex = guid
	msg.m_objID = member.m_objID
	msg.sceneid = member.sceneid
	msg.client_res = member.client_res
	msg.portrait_id = member.portrait_id
	msg.sex = member.model
	msg.m_Position = member.m_Position
	msg.m_SquadIdx = m_SquadIdx
	msg.m_MemberIdx = m_MemberIdx
	msg.m_ZoneWorldID = member.m_ZoneWorldID
	msg.m_iFightScore = member.m_iFightScore
	msg.GuildName = member.GuildName
	self:broad_raid_msg(msg,guid)
	
	msg = packet_def.GCRaidMemberInfo.new()
	msg.flag = 0
	msg.data_index = 0
	msg.guid = guid
	msg.m_RaidID = raid_id
	msg:set_menpai(member.menpai)
	msg:set_level(member.level)
	msg:set_world_pos(member.world_pos)
	msg:set_hp(member.hp)
	msg:set_hp_max(member.hp_max)
	msg:set_hair_id(member.hair_id)
	msg:set_hair_color(member.hair_color)
	msg:set_portrait_id(member.portrait_id)
	msg:set_weapon(member.weapon)
	msg:set_cap(member.cap)
	msg:set_armour(member.armour)
	msg:set_cuff(member.cuff)
	msg:set_foot(member.foot)
	msg:set_fashion(member.fashion)
	self:broad_raid_msg(msg,guid)
	
	msg = packet_def.GCRaidList.new()
	msg.m_nEventID = define.RAID_EVENT_ID.RAID_EVENT_ADD_NEWMEM
	msg.m_TeamID = -1
	msg.m_RaidID = raid_id
	msg.m_bLeaveRaid = 0
	msg.member_list = self.members
	msg.m_nMemberCount = self:member_count()
	self:send_msg_to_member(member, msg)
	
	for _,team in ipairs(self.members) do
		for _, mb in ipairs(team) do
			if mb.guid ~= guid then
				msg = packet_def.GCRaidMemberInfo.new()
				msg.flag = 0
				msg.data_index = 0
				msg.guid = mb.guid
				msg.m_RaidID = raid_id
				msg:set_menpai(mb.menpai)
				msg:set_level(mb.level)
				msg:set_world_pos(mb.world_pos)
				msg:set_hp(mb.hp)
				msg:set_hp_max(mb.hp_max)
				msg:set_hair_id(mb.hair_id)
				msg:set_hair_color(mb.hair_color)
				msg:set_portrait_id(mb.portrait_id)
				msg:set_weapon(mb.weapon)
				msg:set_cap(mb.cap)
				msg:set_armour(mb.armour)
				msg:set_cuff(mb.cuff)
				msg:set_foot(mb.foot)
				msg:set_fashion(mb.fashion)
				self:send_msg_to_member(member, msg)
			end
		end
	end
end

function raid:del_member(guid)
	for tid,team in ipairs(self.members) do
		for mid, mb in ipairs(team) do
			if mb.guid == guid then
				table.remove(self.members[tid], mid)
				mb.raid_id = define.INVAILD_ID
				break
			end
		end
    end
    return true
end

function raid:is_member(guid)
	for tid,team in ipairs(self.members) do
		for mid, mb in ipairs(team) do
			if mb.guid == guid then
				return mb,tid - 1,mid - 1
			end
		end
    end
end

function raid:find_member_pos(tid,mid)
	if not tid or not mid then
		return
	end
	if self.members[tid] then
		return self.members[tid][mid]
	end
end

function raid:change_member_pos(guid,raid_id,tid,mid,tid_ex,mid_ex)
	if self.members[tid] then
		if self.members[tid][mid] then
			if self.members[tid_ex] then
				local mb_d = self.members[tid_ex][mid_ex]
				if mb_d then
					self.members[tid_ex][mid_ex] = self.members[tid][mid]
					self.members[tid][mid] = mb_d
				else
					local mb_s = table.remove(self.members[tid], mid)
					table.insert(self.members[tid_ex],mb_s)
				end
			end
			local msg = packet_def.GCRetRaidModifyMemberPosition.new()
			msg.m_yOk = 1
			msg.raid_id = raid_id
			msg.m_OperateGUID = guid
			msg.m_sSquadIndex = tid - 1
			msg.m_sMemIndex = mid - 1
			msg.m_dSquadIndex = tid_ex-1
			msg.m_dMemIndex = mid_ex-1
			self:broad_raid_msg(msg)
		end
	end
end

function raid:leader(position,position_2)
	if not position_2 then
		for tid,team in ipairs(self.members) do
			for mid, mb in ipairs(team) do
				if mb.m_Position == position then
					return mb,tid - 1,mid - 1
				end
			end
		end
	else
		for tid,team in ipairs(self.members) do
			for mid, mb in ipairs(team) do
				if mb.m_Position == position or  mb.m_Position == position_2 then
					return mb,tid - 1,mid - 1
				end
			end
		end
	end
end

function raid:member(tid,mid)
    return self.members[tid][mid]
end

function raid:get_appoint_count(position)
	local count = 0
	for _,team in ipairs(self.members) do
		for _, mb in ipairs(team) do
			if mb.m_Position == define.RAID_POISTION.RAID_POISTION_ASSISTANT then
				count = count + 1
			end
		end
	end
	return count
end

function raid:is_full()
    return self:member_count() >= define.MAX_GRID_MEMBER
end

function raid:broad_raid_msg(packet,guid)
	for _,team in ipairs(self.members) do
		for _, mb in ipairs(team) do
			if mb.guid ~= guid then
				if mb.agent then 
					local exist = pcall(skynet.call, mb.agent, "debug", "PING")
					if exist then
						skynet.call(mb.agent, "lua", "send2client", packet.xy_id, packet)
					end
				end
			end
		end
	end
end

function raid:broad_raid_team_msg(tid,packet)
	if tid and self.members[tid] then
		for _, mb in ipairs(self.members[tid]) do
			if mb.agent then 
				local exist = pcall(skynet.call, mb.agent, "debug", "PING")
				if exist then
					skynet.call(mb.agent, "lua", "send2client", packet.xy_id, packet)
				end
			end
		end
	end
end

function raid:broad_raid_msg_expect_self(me, packet)
	for _,team in ipairs(self.members) do
		for _, mb in ipairs(team) do
			if mb ~= me then
				if mb.agent then 
					local exist = pcall(skynet.call, mb.agent, "debug", "PING")
					if exist then
						skynet.call(mb.agent, "lua", "send2client", packet.xy_id, packet)
					end
				end
			end
		end
	end
end

function raid:send_msg_to_member(member, packet)
	if member.agent then 
		local exist = pcall(skynet.call, member.agent, "debug", "PING")
		if exist then
			skynet.call(member.agent, "lua", "send2client", packet.xy_id, packet)
		end
	end
end

return raid