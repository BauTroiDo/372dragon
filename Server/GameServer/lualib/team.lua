local skynet = require "skynet"
local class = require "class"
local define = require "define"
local packet_def = require "game.packet"
local team = class("team")

function team:ctor()
    self.members = {}
    self.followd_members = {}
    self.options = { exp_mode = 0 }
    self:clean_up()
end

function team:clean_up()
    for _, mb in ipairs(self.members) do
        mb.team_id = define.INVAILD_ID
    end
    self.members = {}
    self.followd_members = {}
end

function team:set_team_id(id)
    self.id = id
end

function team:get_team_id()
    return self.id
end

function team:is_empty()
    return #self.members == 0
end

function team:member_count()
    return #self.members
end

function team:get_members()
    return self.members
end

function team:get_member_by_guid(guid)
    for _, mb in ipairs(self.members) do
        if mb.guid == guid then
            return mb
        end
    end
end

function team:is_active()
    if self:is_empty() then
        return false
    end
    if #self.members > 0 then
        return true
    end
end

function team:add_member(member, silent)
    member.team_id = self:get_team_id()
    table.insert(self.members, member)

    if silent then
        return
    end

    local msg = packet_def.GCTeamResult.new()
    msg.guid = member.guid
    msg.return_type = define.TEAM_RESULT.TEAM_RESULT_MEMBERENTERTEAM
    msg.team_id = member.team_id
    msg.guid_ex = member.m_objID
    msg.sceneid = member.sceneid
    msg.client_res = member.client_res
    msg.name = member.name
    msg.portrait_id = member.portrait_id
    msg.sex = member.model
    msg.uinfo = member
    msg.leader_guid = self:leader().guid
    self:broad_team_msg(msg)
end

function team:del_member(member)
    for i, mb in ipairs(self.members) do
        if mb.guid == member.guid then
            table.remove(self.members, i)
            mb.team_id = define.INVAILD_ID
            break
        end
    end
    self:del_followd_member(member.guid)
    return true
end

function team:is_member(member)
    for i, mb in ipairs(self.members) do
        if mb.guid == member.guid then
            return true
        end
    end
    return false
end

function team:leader()
    return self.members[define.LEADER_ID]
end

function team:member(index)
    return self.members[index]
end

function team:appoint(newleader)
    for i, mb in ipairs(self.members) do
        if mb.guid == newleader.guid then
            local member = table.remove(self.members, i)
            table.insert(self.members, 1, member)
            break
        end
    end
end

function team:add_followd_member(guid)
    if self:is_followd_member(guid) then
        return
    end
    table.insert(self.followd_members, guid)
end

function team:get_followd_members()
    return self.followd_members
end

function team:is_followd_member(guid)
    for _, followd_guid in ipairs(self.followd_members) do
        if followd_guid == guid then
            return true
        end
    end
end

function team:del_followd_member(guid)
    for i, mb in ipairs(self.followd_members) do
        if mb == guid then
            table.remove(self.followd_members, i)
            break
        end
    end
end

function team:clear_followed_members()
    self.followd_members = {}
end

function team:is_full()
    return #self.members >= define.MAX_TEAM_MEMBER
end

function team:broad_team_msg(packet)
    for _, mb in ipairs(self.members) do
		if mb.agent then 
			local exist = pcall(skynet.call, mb.agent, "debug", "PING")
			if exist then
				pcall(skynet.call, mb.agent, "lua", "send2client", packet.xy_id, packet)
			end
		end
    end
end

function team:broad_team_msg_expect_self(me, packet)
    for _, mb in ipairs(self.members) do
        if mb ~= me then
			if mb.agent then 
				local exist = pcall(skynet.call, mb.agent, "debug", "PING")
				if exist then
					pcall(skynet.call, mb.agent, "lua", "send2client", packet.xy_id, packet)
				end
			end
        end
    end
end

function team:send_msg_to_member(member, packet)
	if member.agent then 
		local exist = pcall(skynet.call, member.agent, "debug", "PING")
		if exist then
			skynet.call(member.agent, "lua", "send2client", packet.xy_id, packet)
		end
	end
end

function team:set_option(option)
    self.options.exp_mode = option.exp_mode
    local msg = packet_def.GCTeamOptionChanged.new()
    msg.exp_mode = option.exp_mode
    msg.unknow_2 = option.unknow_2
    self:broad_team_msg(msg)
end

function team:get_exp_mode()
    return self.options.exp_mode or 0
end

return team