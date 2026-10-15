local gbk = require "wire_charset"
local skynet = require "skynet"
local packet_def = require "game.packet"
local define = require "define"
local ma_func = require "ma_func"
local ma_relation = ma_func

function ma_relation:CGRelation(packet)
    local msg = packet_def.GCRelation.new()
    if packet.type == 1 then
        self:send_my_relation_list(packet)
    elseif packet.type == 2 then
        local relation_info = self:get_relation_info(packet)
        if relation_info then
            msg.type = packet.type
            msg.relation_info = relation_info
        else
            msg.type = 0x1A
        end
        self:send2client(msg)
    elseif packet.type == 4 then
        local ret, relation_info = self:add_relation_info(packet)
        if ret then
            msg.type = ret
            msg.relation_info = relation_info
            self:send2client(msg)
        end
    elseif packet.type == 9 or packet.type == 23 then
        msg.type = 10
        local del_relation = self:del_relation(packet)
        msg.del_relation = del_relation
        self:send2client(msg)
        skynet.send(".world", "lua", "notify_friend_be_del", del_relation.guid, self.my_guid, del_relation.relation_type)
    elseif packet.type == 6 then
        msg.type = 5
        msg.relation_info = self:add_relation_info(packet)
        self:send2client(msg)
    elseif packet.type == 8 then
        msg.type = 9
        local relation_guid_uchar_uchar = self:change_relation_group(packet)
        if relation_guid_uchar_uchar == nil then
            return
        end
        msg.relation_guid_uchar_uchar = relation_guid_uchar_uchar
        self:send2client(msg)
    elseif packet.type == 5 then
        --加黑名单
    elseif packet.type == 13 then
        msg.type = 16
        self.my_data.relation.mood = packet.request_relation_info.mood
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_mood", self.my_data.relation.mood)
        msg.new_mood = { mood = self.my_data.relation.mood }
        self:send2client(msg)
    end
end

function ma_relation:set_relation_list(relation)
    assert(relation)
    self.my_data.relation = relation
end

function ma_relation:get_relation_list()
    return self.my_data.relation
end

function ma_relation:send_my_relation_list(packet)
    local msg = packet_def.GCRelation.new()
    msg.type = packet.type
    local relation = self:get_relation_list()
    msg.relation_list = table.clone(relation)
    self:send2client(msg)

    local friends = {}
    for _, f in ipairs(relation.friends) do
        table.insert(friends, f.guid)
    end
    local online_list = skynet.call(".world", "lua", "get_online_users_in_list", friends)
    msg = packet_def.GCRelation.new()
    msg.type = define.RELATION_RETURN_TYPE.RET_ONLINELIST
    msg.online_friends = {}
    msg.online_friends.count = #online_list
    msg.online_friends.list = online_list
    self:send2client(msg)
end

function ma_relation:get_relation_by_guid_in_group(guid, group)
    for _, relation in ipairs(group) do
        if relation.guid == guid then
            local re = table.clone(relation)
            re.relation_type = relation.relation_type or define.RELATION_TYPE.RELATION_TYPE_FRIEND
            return re
        end
    end
end

function ma_relation:set_friend_group_by_guid(guid, group)
    assert(group > 0 and group <= 4, group)
    local relation_list = self:get_relation_list()
    for _, friend in ipairs(relation_list.friends) do
        if friend.guid == guid then
            friend.group = group
        end
    end
end

function ma_relation:set_friend_point_by_guid(guid, point)
    local relation_list = self:get_relation_list()
    for _, friend in ipairs(relation_list.friends) do
        if friend.guid == guid then
            friend.friend_point = point
        end
    end
end

function ma_relation:get_realtion_by_guid(guid)
    local relation_list = self:get_relation_list()
    local re
    if re == nil then
        re = self:get_relation_by_guid_in_group(guid, relation_list.friends)
    end
    if re == nil then
        re = self:get_relation_by_guid_in_group(guid, relation_list.black)
    end
    if re == nil then
        re = self:get_relation_by_guid_in_group(guid, relation_list.enemies)
        if re then
            re.group = 6
        end
    end
    if re == nil then
        re = self:get_relation_by_guid_in_group(guid, relation_list.temp)
    end
    if re == nil then
        if guid == self.my_guid then
            re = { relation_type = define.RELATION_TYPE.RELATION_TYPE_TEMPFRIEND, group= 0, friend_point = 0}
        end
    end
    re = re or { relation_type = define.RELATION_TYPE.RELATION_TYPE_TEMPFRIEND, group= 0, friend_point = 0}
    re.group = re.group or 0
    re.friend_point = re.friend_point or 0
    return re
end

function ma_relation:get_relation_info(packet)
    local relation_info = {}
    packet.request_relation_info.name = packet.request_relation_info.name or ""
    local uinfo
    if packet.request_relation_info.name ~= "" then
        uinfo = skynet.call(".world", "lua", "get_player_info_by_name", packet.request_relation_info.name)
    elseif packet.request_relation_info.guid ~= define.INVAILD_ID then
        uinfo = skynet.call(".world", "lua", "get_player_info", packet.request_relation_info.guid)
    end
    if uinfo then
        local relation = self:get_realtion_by_guid(uinfo.guid)
        if relation.relation_type == 6 and not relation.online_flag then
            return
        end
        self:check_relation_point(relation, uinfo)
        uinfo.sceneid = uinfo.client_res
        relation.portrait = uinfo.portrait
        relation.name = uinfo.name
        relation.mood = uinfo.mood
        relation_info.relation_type = relation.relation_type
        relation_info.group = relation.group
        relation_info.friend_point = relation.friend_point
        relation_info.relation = uinfo
        return relation_info
    end
end

function ma_relation:check_relation_point(relation, tar_uinfo)
    local is_dirty = false
    local tar_relation = tar_uinfo.relation
    local is_tar_friend = self:is_in_relation_frineds(tar_relation, self.my_guid)
    if is_tar_friend then
        if relation.friend_point == 0 then
            self:set_friend_point_by_guid(relation.guid, 1)
            is_dirty = true
        end
    else
        if relation.friend_point > 0 then
            self:set_friend_point_by_guid(relation.guid, 0)
            is_dirty = true
        end
    end
    if is_dirty then
        local realtion_list = self:get_relation_list()
        skynet.call(self.my_scene, "lua", "call_human_function", self.my_obj_id, "set_relation_list_from_agent", realtion_list)
    end
end

function ma_relation:is_in_relation_frineds(relation, guid)
    local tar_friends = relation.friends
    for _, frined in ipairs(tar_friends) do
        if frined.guid == guid then
            return true
        end
    end
    return false
end

function ma_relation:del_relation(packet)
    local relation_type = define.RELATION_TYPE.RELATION_TYPE_STRANGER
    local guid = packet.request_relation_info.guid
    local relation_list = self:get_relation_list()
    for i, relation in ipairs(relation_list.friends) do
        if relation.guid == guid then
            table.remove(relation_list.friends, i)
            relation_type = define.RELATION_TYPE.RELATION_TYPE_FRIEND
            break
        end
    end
    for i, relation in ipairs(relation_list.black) do
        if relation.guid == guid then
            table.remove(relation_list.black, i)
            relation_type = define.RELATION_TYPE.RELATION_TYPE_BLACKNAME
            break
        end
    end
    for i, relation in ipairs(relation_list.enemies) do
        if relation.guid == guid then
            table.remove(relation_list.enemies, i)
            relation_type = define.RELATION_TYPE.RELATION_TYPE_ENEMIES
            break
        end
    end
    for i, relation in ipairs(relation_list.temp) do
        if relation.guid == guid then
            table.remove(relation_list.temp, i)
            relation_type = define.RELATION_TYPE.RELATION_TYPE_TEMPFRIEND
            break
        end
    end
    return { guid = guid, relation_type = relation_type}
end

function ma_relation:get_realtion_group(relation_type, group)
    local relation_list = self:get_relation_list()
    local relation_gorup = {}
    if relation_type == define.RELATION_TYPE.RELATION_TYPE_FRIEND then
        for _, relation in ipairs(relation_list) do
            if relation.group == group then
                table.insert(relation_gorup, relation)
            end
        end
    end
    return relation_gorup
end

function ma_relation:get_realtion_group_by_group_id(group)
    local relation_list = self:get_relation_list()
    if group <= 4 then
        return relation_list.friends
    elseif group == 5 then
        return relation_list.black
    elseif group == 6 then
        return relation_list.enemies
    end
end

function ma_relation:add_to_relation_enemies(uinfo)
    local relation_list = self:get_relation_list()
    local relation = {}
    relation.friend_point = 0
    relation.relation_type = define.RELATION_TYPE.RELATION_TYPE_ENEMIES
    relation.name = uinfo.name
    relation.mood = uinfo.mood
    relation.guid = uinfo.guid
    relation.portrait = uinfo.portrait
    table.insert(relation_list.enemies, relation)
    if #relation_list.enemies > 10 then
        table.remove(relation_list.enemies, 1)
    end
    return relation
end

function ma_relation:add_to_relation_group(uinfo, relation_type, group)
    local relation_list = self:get_relation_list()
    if relation_type == define.RELATION_TYPE.RELATION_TYPE_FRIEND then
        local relation = {}
        relation.group = group
        relation.friend_point = 0
        relation.relation_type = define.RELATION_TYPE.RELATION_TYPE_FRIEND
        relation.name = uinfo.name
        relation.mood = uinfo.mood
        relation.guid = uinfo.guid
        relation.portrait = uinfo.portrait
        table.insert(relation_list.friends, relation)
        return relation
    end
end

function ma_relation:add_relation_info(packet)
    local name = packet.request_relation_info.name
    local relation_type = packet.request_relation_info.relation_type
    local group = packet.request_relation_info.group
    local uinfo = skynet.call(".world", "lua", "get_player_info_by_name", name)
    if uinfo then
        local relation = self:get_realtion_by_guid(uinfo.guid)
        if relation.relation_type == define.RELATION_TYPE.RELATION_TYPE_STRANGER or relation.relation_type == define.RELATION_TYPE.RELATION_TYPE_TEMPFRIEND then
            if group == "enemy" then
                relation = self:add_to_relation_enemies(uinfo)
                local relation_info = table.clone(uinfo)
                relation_info.relation_type = relation.relation_type
                relation_info.group = 4 --relation.group
                relation_info.relation_type = relation.relation_type
                return define.RELATION_RETURN_TYPE.RET_ADDFRIEND, relation_info
            else
                relation = self:add_to_relation_group(uinfo, relation_type, group)
                local relation_info = table.clone(uinfo)
                relation_info.relation_type = relation.relation_type
                relation_info.group = relation.group
                relation_info.relation_type = relation.relation_type
                self:check_relation_point(relation, uinfo)
                skynet.send(".world", "lua", "notify_friend_be_add", uinfo.guid, self.my_guid, relation_info.relation_type)
                return define.RELATION_RETURN_TYPE.RET_ADDFRIEND, relation_info
            end
        end
    end
end

function ma_relation:change_relation_group(packet)
    local guid = packet.request_relation_info.guid
    local from = packet.request_relation_info.from
    local to = packet.request_relation_info.to
    local from_group = self:get_realtion_group_by_group_id(from)
    local to_group = self:get_realtion_group_by_group_id(to)
    local relation_count_limit = 0x50
    if to >= 5 then
        relation_count_limit = 0xA
    end
    local old_relation = self:get_relation_by_guid_in_group(guid, from_group)
    if #to_group >= relation_count_limit then
        local msg = packet_def.GCRelation.new()
        msg.type = define.RELATION_RETURN_TYPE.RET_ERR_GROUPISFULL
        self:send2client(msg)
        return
    end
    if from <= 4 and to == 5 then
        if old_relation.realtion_type == define.RELATION_TYPE.RELATION_TYPE_BROTHER then
            local msg = packet_def.GCRelation.new()
            msg.type = define.RELATION_RETURN_TYPE.RET_ERR_BROTHERTOBLACKLIST
            self:send2client(msg)
            return
        end
        if old_relation.realtion_type == define.RELATION_TYPE.RELATION_TYPE_MARRY then
            local msg = packet_def.GCRelation.new()
            msg.type = define.RELATION_RETURN_TYPE.RET_ERR_SPOUSETOBLACKLIST
            self:send2client(msg)
            return
        end
        if old_relation.realtion_type == define.RELATION_TYPE.RELATION_TYPE_PRENTICE then
            local msg = packet_def.GCRelation.new()
            msg.type = define.RELATION_RETURN_TYPE.RET_ERR_PRENTICETOBLACKLIST
            self:send2client(msg)
            return
        end
        if old_relation.realtion_type == define.RELATION_TYPE.RELATION_TYPE_MASTER then
            local msg = packet_def.GCRelation.new()
            msg.type = define.RELATION_RETURN_TYPE.RET_ERR_MASTERTOBLACKLIST
            self:send2client(msg)
            return
        end
    end
    if from <= 4 then
        if to <= 4 then
            self:set_friend_group_by_guid(guid, to)
            return { guid = guid, relation_type = old_relation.relation_type, group = to}
        elseif to == 5 then
            self:realtion_group_to_group(guid, from_group, to_group, define.RELATION_TYPE.RELATION_TYPE_BLACKNAME, true)
            return { guid = guid, relation_type = define.RELATION_TYPE.RELATION_TYPE_BLACKNAME, group = to}
        elseif to == 6 then
            assert(false)
        end
    elseif from == 5 then
        if to <= 4 then
            self:realtion_group_to_group(guid, from_group, to_group, define.RELATION_TYPE.RELATION_TYPE_FRIEND, true)
            return { guid = guid, relation_type = define.RELATION_TYPE.RELATION_TYPE_FRIEND, group = to}
        elseif to == 5 then
            assert(false)
        elseif to == 6 then
            assert(false)
        end
    elseif from == 6 then
        if to <= 4 then
            self:realtion_group_to_group(guid, from_group, to_group, define.RELATION_TYPE.RELATION_TYPE_FRIEND, true)
            return { guid = guid, relation_type = define.RELATION_TYPE.RELATION_TYPE_FRIEND, group = to}
        elseif to == 5 then
            self:realtion_group_to_group(guid, from_group, to_group, define.RELATION_TYPE.RELATION_TYPE_BLACKNAME, true)
            return { guid = guid, relation_type = define.RELATION_TYPE.RELATION_TYPE_BLACKNAME, group = to}
        elseif to == 6 then
            assert(false)
        end
    end
end

function ma_relation:realtion_group_to_group(guid, from_group, to_group, relation_type, reset_friend_point)
    local relation
    for i = #from_group, 1, -1 do
        if from_group[i].guid == guid then
            relation = from_group[i]
            table.remove(from_group, i)
        end
    end
    assert(relation, guid)
    relation.relation_type = relation_type
    if reset_friend_point then
        relation.friend_point = 0
    end
    table.insert(to_group, relation)
end

function ma_relation:CGLookUpOther(packet)
    local msg = packet_def.GCLookUpOther.new()
    local name = packet.name
    local uinfo = skynet.call(".world", "lua", "get_player_info_by_name", name)
    for key, val in pairs(uinfo) do
        msg[key] = val
    end
    msg.sceneid = uinfo.client_res
	-- skynet.logi("msg.sceneid = ",msg.sceneid)
    local world_pos = skynet.call(".world", "lua", "get_player_world_pos_by_name", name)
	if world_pos then
		msg.world_pos = world_pos
		self:send2client(msg)
	end
end

function ma_relation:be_notifyd_friend_online(uinfo)
    local relation_list = self:get_relation_list()
    for _, relation in ipairs(relation_list.friends) do
        if relation.guid == uinfo.guid then
            relation.name = uinfo.name
            relation.mood = uinfo.mood
            self:notify_client_friend_online(relation)
            return
        end
    end
end

function ma_relation:get_friend_point(guid)
    local relation_list = self:get_relation_list()
    for _, friend in ipairs(relation_list.friends) do
        if friend.guid == guid then
            return friend.friend_point
        end
    end
    return 0
end

function ma_relation:be_notify_friend_be_add(guid, relation_type)
    if relation_type == define.RELATION_TYPE.RELATION_TYPE_FRIEND then
        local relation = self:get_realtion_by_guid(guid)
        local uinfo = skynet.call(".world", "lua", "get_player_info", guid)
        if relation and relation.relation_type == define.RELATION_TYPE.RELATION_TYPE_FRIEND then
            self:check_relation_point(relation, uinfo)
        end
        local msg = packet_def.GCRelation.new()
        msg.type = define.RELATION_RETURN_TYPE.RET_ADDFRIENDNOTIFY
        local name = gbk.fromutf8(uinfo.name)
        msg.notify_friend = { guid = guid, name = name }
        self:send2client(msg)
    end
end

function ma_relation:be_notify_friend_be_del(guid, relation_type)
    if relation_type == define.RELATION_TYPE.RELATION_TYPE_FRIEND then
        local relation = self:get_realtion_by_guid(guid)
        if relation and relation.relation_type == define.RELATION_TYPE.RELATION_TYPE_FRIEND then
            local uinfo = skynet.call(".world", "lua", "get_player_info", guid)
            self:check_relation_point(relation, uinfo)
        end
    end
end

function ma_relation:notify_client_friend_online(uinfo)
    local msg = packet_def.GCRelation.new()
    msg.type = define.RELATION_RETURN_TYPE.RET_RELATIONONLINE
    msg.relation_online = table.clone(uinfo)
    self:send2client(msg)
end

function ma_relation:notify_friends_offline()
    if self.my_data then
        local uinfo = { guid = self.my_guid, mood = self.my_data.relation.mood, name = self.my_data.attrib.name }
        skynet.send(".world", "lua", "notify_friends_offline", uinfo, self.my_data.relation.friends)
    else
        print("notify_friends_offline not my_data")
    end
end

function ma_relation:be_notifyd_friend_offline(uinfo)
    local relation_list = self:get_relation_list()
    for _, relation in ipairs(relation_list.friends) do
        if relation.guid == uinfo.guid then
            relation.name = uinfo.name
            relation.mood = uinfo.mood
            self:notify_client_friend_offline(relation)
            return
        end
    end
end

function ma_relation:notify_client_friend_offline(uinfo)
    local msg = packet_def.GCRelation.new()
    msg.type = define.RELATION_RETURN_TYPE.RET_RELATIONOFFLINE
    msg.del_relation = { guid = uinfo.guid }
    self:send2client(msg)
end

return require('cys_community').install(ma_relation)