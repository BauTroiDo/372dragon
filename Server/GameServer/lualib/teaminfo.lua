local class = require "class"

local define = require "define"

local teaminfo = class("teaminfo")



function teaminfo:ctor(human)

    self.my_guid = define.INVAILD_ID

    self.my_scene_id = define.INVAILD_ID

    self.human = human

    self.options = { exp_mode = 0}

    self:clean_up()

end



function teaminfo:clean_up()

    self.members = {}

    self.scene_members = {}

    self.followd_members = {}

    self.followd_flag = false

    self.data_index = 0

    self.options.exp_mode = 0

    self:set_team_id(define.INVAILD_ID)

    self:set_team_leader(define.INVAILD_ID)

end



function teaminfo:set_my_guid(guid)

    self.my_guid = guid

end



function teaminfo:set_my_scene_id(sceneid)

    self.my_scene_id = sceneid

end



function teaminfo:dis_miss()

    self:clean_up()

end



function teaminfo:has_team()

	self.team_id = self.team_id or define.INVAILD_ID

    return self.team_id ~= define.INVAILD_ID

end



function teaminfo:is_full()

    return #self.members >= define.MAX_TEAM_MEMBER

end



function teaminfo:is_leader()

    if self:has_team() and self.team_leader == self.my_guid then

        return true

    end

    return false

end



function teaminfo:set_team_leader(leader)

    self.team_leader = leader

    local is_team_leader = self.team_leader == self.my_guid

    self.human.db:set_not_gen_attrib({ is_team_leader = is_team_leader and 1 or 0})

    self:resort_members()

    -- [FIX] 立即广播队长状态变化给AOI内的玩家

    self.human:send_refresh_attrib()

end



function teaminfo:get_team_leader()

    return self.team_leader

end



function teaminfo:resort_members()

    for i, mb in ipairs(self.members) do

        if mb.guid == self.team_leader then

            table.remove(self.members, i)

            table.insert(self.members, 1, mb)

            break

        end

    end

end



function teaminfo:get_team_id()

    return self.team_id or define.INVAILD_ID

end



function teaminfo:set_team_id(team_id)

    self.team_id = team_id or define.INVAILD_ID



    local is_in_team = self.team_id ~= define.INVAILD_ID

    self.human.db:set_not_gen_attrib({ team_id = self.team_id})

    self.human.db:set_not_gen_attrib({ is_in_team = is_in_team and 1 or 0})

    self.human:on_team_id_changed()

    -- [FIX] 立即广播组队状态变化给AOI内的玩家

    self.human:send_refresh_attrib()

end



function teaminfo:get_team_member_count()

    return #self.members

end



function teaminfo:get_scene_member_count()

    return #self.scene_members

end



function teaminfo:get_scene_member_obj_id(index)

    local oid = self.scene_members[index]

    return oid

end



function teaminfo:add_member(member)

    local inedx

    for i, mb in ipairs(self.members) do

        if mb.guid == member.guid then

            inedx = i

            break

        end

    end

    if inedx then

        self.members[inedx] = member

    else

        table.insert(self.members, member)

    end

    if member.guid ~= self.my_guid then

        if member.sceneid == self.my_scene_id then

            self:add_scene_member(member.m_objID)

        end

    end

end



function teaminfo:del_member(guid)

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

    self:del_followd_member(guid)

end



function teaminfo:appoint(guid)

    for i, mb in ipairs(self.members) do

        if mb.guid == guid then

            table.insert(self.members, 1, table.remove(self.members, i))

            break

        end

    end

    self:set_team_leader(guid)

end



function teaminfo:start_change_scene(guid)

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



function teaminfo:enter_scene(guid, sceneid, oid)

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



function teaminfo:member_offline(guid)

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



function teaminfo:leader()

    local leader_guid = self.team_leader

    if leader_guid == self.human:get_guid() then

        return { m_objID = self.human:get_obj_id(), guid = leader_guid }

    end

    for _, oid in ipairs(self.scene_members) do

        local obj = self.human:get_scene():get_obj_by_id(oid)

        if obj and obj:get_guid() == leader_guid then

            return { m_objID = oid, guid = leader_guid }

        end

    end

end



function teaminfo:get_team_member_by_guid(guid)

    for _, mb in ipairs(self.members) do

        if mb.guid == guid then

            return mb

        end

    end

end



function teaminfo:add_followd_member(follow_member)

    for _, mb in ipairs(self.followd_members) do

        if mb.guid == follow_member.guid then

            return

        end

    end

    table.insert(self.followd_members, follow_member)

end



function teaminfo:del_followd_member(guid)

    for i, mb in ipairs(self.followd_members) do

        if mb.guid == guid then

            table.remove(self.followd_members, i)

            break

        end

    end

end



function teaminfo:get_followed_members_count()

    return #self.followd_members

end



function teaminfo:get_followed_member(i)

    return self.followd_members[i]

end



function teaminfo:get_my_guide()

    local guide

    for _, mb in ipairs(self.followd_members) do

        if mb.guid == self.my_guid then

            break

        end

        local obj = self.human:get_scene():get_obj_by_guid(mb.guid)

        if obj then

                guide = obj

        end

    end

    return guide

end



function teaminfo:get_guide_me()

    local guide

    local find_me = false

    for _, mb in ipairs(self.followd_members) do

        if find_me then
			--修改跟随
            --guide = mb.human
			guide = self.human:get_scene():get_obj_by_guid(mb.guid)
            
			break

        end

        if mb.guid == self.my_guid then

            find_me = true

        end

    end

    return guide

end



function teaminfo:clear_followed_members()

    self.followd_members = {}

end



function teaminfo:add_scene_member(oid)

    if #self.scene_members >= define.MAX_TEAM_MEMBER then

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



function teaminfo:del_scene_member(oid)

    for i, mb in ipairs(self.scene_members) do

        if mb == oid then

            table.remove(self.scene_members, i)

            break

        end

    end

end



function teaminfo:inc_data_index()

    self.data_index = self.data_index + 1

    return self.data_index

end



function teaminfo:get_exp_mode()

    return self.options.exp_mode

end



function teaminfo:set_exp_mode(exp_mode)

    self.options.exp_mode = exp_mode

end



function teaminfo:set_option(option)

    self.options.exp_mode = option.exp_mode

end



return teaminfo