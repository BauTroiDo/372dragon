local class = require "class"
local define = require "define"
local raidinfo = class("raidinfo")

function raidinfo:ctor(human)
    self.my_guid = define.INVAILD_ID
    self.my_scene_id = define.INVAILD_ID
    self.human = human
    self.options = { exp_mode = 0}
    self:clean_up()
end

function raidinfo:clean_up()
    self.members = {}
    self.scene_members = {}
    self.followd_members = {}
    self.followd_flag = false
    self.data_index = 0
    self.options.exp_mode = 0
    self:set_raid_id(define.INVAILD_ID)
    self:set_raid_position(define.RAID_POISTION.RAID_POISTION_MEMBER)
	self.raid_leader = -1
	self.raid_leader_2 = -1
	self.raid_leader_3 = -1
end

function raidinfo:set_my_guid(guid)
    self.my_guid = guid
end

function raidinfo:set_my_scene_id(sceneid)
    self.my_scene_id = sceneid
end

function raidinfo:dis_miss()
    self:clean_up()
end

function raidinfo:has_raid()
	self.raid_id = self.raid_id or define.INVAILD_ID
    return self.raid_id ~= define.INVAILD_ID
end

function raidinfo:is_full()
	if #self.members >= define.MAX_GRID_MEMBER then
		self.human.db:set_not_gen_attrib({ raid_is_full = 1})
		return true
	end
	self.human.db:set_not_gen_attrib({ raid_is_full = 0})
    return false
end

function raidinfo:is_leader()
    if self:has_raid() and self.raid_leader == self.my_guid then
        return true
    end
    return false
end

function raidinfo:set_raid_position(position)
    self.human.db:set_not_gen_attrib({ raid_position = position})
end

function raidinfo:get_raid_leader()
    return self.raid_leader
end

function raidinfo:resort_members()
    for i, mb in ipairs(self.members) do
        if mb.guid == self.raid_leader then
            table.remove(self.members, i)
            table.insert(self.members, 1, mb)
            break
        end
    end
end

function raidinfo:get_raid_id()
    return self.raid_id or define.INVAILD_ID
end

function raidinfo:set_raid_id(raid_id)
    self.raid_id = raid_id or define.INVAILD_ID
    -- local is_in_raid = self.raid_id ~= define.INVAILD_ID
    self.human.db:set_not_gen_attrib({ raid_id = self.raid_id})
    -- self.human.db:set_not_gen_attrib({ is_in_raid = is_in_raid and 1 or 0})
    self.human:on_raid_id_changed()
end

function raidinfo:get_raid_member_count()
    return #self.members
end

function raidinfo:get_scene_member_count()
    return #self.scene_members
end

function raidinfo:get_scene_member_obj_id(index)
    local oid = self.scene_members[index]
    return oid
end
-- local skynet = require "skynet"
function raidinfo:add_member(member)
	local member_guid = member.guid
	-- skynet.logi("add_member = [",self.my_guid,"] = ",member.m_Position,member_guid)
	if member.m_Position == define.RAID_POISTION.RAID_POISTION_LEADER then
		self.raid_leader = member_guid
	elseif member.m_Position == define.RAID_POISTION.RAID_POISTION_ASSISTANT then
		if self.raid_leader_2 == -1 then
			self.raid_leader_2 = member_guid
		elseif self.raid_leader_2 ~= member.guid then
			self.raid_leader_3 = member_guid
		end
	end
    local inedx
    for i, mb in ipairs(self.members) do
        if mb.guid == member_guid then
            inedx = i
            break
        end
    end
    if inedx then
        self.members[inedx] = member
    else
        table.insert(self.members, member)
    end
    if member_guid ~= self.my_guid then
        if member.sceneid == self.my_scene_id then
            self:add_scene_member(member.m_objID)
        end
	else
		self:set_raid_position(member.m_Position)
    end
	self:is_full()
end

function raidinfo:del_member(guid)
    local oid
    for i, mb in ipairs(self.members) do
        if mb.guid == guid then
            oid = mb.m_objID
            table.remove(self.members, i)
            break
        end
    end
    if oid then
        self:del_scene_member(oid)
    end
	self:is_full()
    -- self:del_followd_member(guid)
end

function raidinfo:change_raid_position()
	if self.raid_leader_2 ~= -1 then
		self.raid_leader = self.raid_leader_2
		self.raid_leader_2 = -1
	elseif self.raid_leader_3 ~= -1 then
		self.raid_leader = self.raid_leader_3
		self.raid_leader_3 = -1
	else
		if self.members[1] then
			self.raid_leader = self.members[1].guid
		end
	end
	if self.raid_leader == self.my_guid then
		self:set_raid_position(define.RAID_POISTION.RAID_POISTION_LEADER)
	end
end

function raidinfo:appoint(guid,position)
	if position == define.RAID_POISTION.RAID_POISTION_LEADER then
		self.raid_leader = guid
		if self.raid_leader_2 == guid then
			self.raid_leader_2 = -1
		elseif self.raid_leader_3 == guid then
			self.raid_leader_3 = -1
		end
	else
		if self.raid_leader_2 == -1 then
			self.raid_leader_2 = guid
		elseif self.raid_leader_3 == -1 then
			self.raid_leader_3 = guid
		end
	end
	if guid == self.my_guid then
		self:set_raid_position(position)
	end
end

function raidinfo:start_change_scene(guid)
    for _, mb in ipairs(self.members) do
        if mb.guid == guid then
            if guid == self.my_guid then
                self.members = {}
                self.my_scene_id = define.INVAILD_ID
            elseif mb.sceneid == self.my_scene_id then
                self:del_scene_member(mb.m_objID)
            end
            mb.sceneid = define.INVAILD_ID
            break
        end
    end
end

function raidinfo:enter_scene(guid, sceneid, oid)
    if sceneid == define.INVAILD_ID then
        return
    end
    if guid == self.my_guid then
        for _, mb in ipairs(self.members) do
            if mb.guid == guid then
                mb.sceneid = sceneid
                mb.m_objID = oid
                break
            end
        end
    else
        for _, mb in ipairs(self.members) do
            if mb.guid == guid then
                mb.sceneid = sceneid
                mb.m_objID = oid
                if sceneid == self.my_scene_id then
                    self:add_scene_member(oid)
                end
                break
            end
        end
    end
end

function raidinfo:member_offline(guid)
    for _, mb in ipairs(self.members) do
        if mb.guid == guid then
            if mb.sceneid == self.my_scene_id then
                self:del_scene_member(mb.m_objID)
            end
            mb.sceneid = define.INVAILD_ID
            break
        end
    end
end

function raidinfo:leader()
    local leader_guid = self.raid_leader
    if leader_guid == self.human:get_guid() then
        return { m_objID = self.human:get_obj_id(), guid = leader_guid }
    end
    for _, oid in ipairs(self.scene_members) do
        local obj = self.human:get_scene():get_obj_by_id(oid)
        if obj:get_guid() == leader_guid then
            return { m_objID = oid, guid = leader_guid }
        end
    end
end

function raidinfo:get_raid_member_by_guid(guid)
    for _, mb in ipairs(self.members) do
        if mb.guid == guid then
            return mb
        end
    end
end

function raidinfo:add_followd_member(follow_member)
    for _, mb in ipairs(self.followd_members) do
        if mb.guid == follow_member.guid then
            return
        end
    end
    table.insert(self.followd_members, follow_member)
end

function raidinfo:del_followd_member(guid)
    for i, mb in ipairs(self.followd_members) do
        if mb.guid == guid then
            table.remove(self.followd_members, i)
            break
        end
    end
end

function raidinfo:get_followed_members_count()
    return #self.followd_members
end

function raidinfo:get_followed_member(i)
    return self.followd_members[i]
end

function raidinfo:get_my_guide()
    local guide
    for _, mb in ipairs(self.followd_members) do
        if mb.guid == self.my_guid then
            break
        end
        local obj = self.human:get_scene():get_obj_by_guid(mb.guid)
        if obj then
            if obj:get_is_raid_leader() then
                guide = obj
            else
                guide = obj
            end
        end
    end
    return guide
end

function raidinfo:get_guide_me()
    local guide
    local find_me = false
    for _, mb in ipairs(self.followd_members) do
        if find_me then
            guide = mb.human
            break
        end
        if mb.guid == self.my_guid then
            find_me = true
        end
    end
    return guide
end

function raidinfo:clear_followed_members()
    self.followd_members = {}
end

function raidinfo:add_scene_member(oid)
    if #self.scene_members >= define.MAX_GRID_MEMBER then
        return
    end
    if oid == define.INVAILD_ID then
        return
    end
    for _, id in ipairs(self.scene_members) do
        if id == oid then
            return
        end
    end
    table.insert(self.scene_members, oid)
end

function raidinfo:del_scene_member(oid)
    for i, mb in ipairs(self.scene_members) do
        if mb == oid then
            table.remove(self.scene_members, i)
            break
        end
    end
end

function raidinfo:inc_data_index()
    self.data_index = self.data_index + 1
    return self.data_index
end

function raidinfo:get_exp_mode()
    return self.options.exp_mode
end

function raidinfo:set_exp_mode(exp_mode)
    self.options.exp_mode = exp_mode
end

function raidinfo:set_option(option)
    self.options.exp_mode = option.exp_mode
end

return raidinfo