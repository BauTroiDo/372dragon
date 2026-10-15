local skynet = require "skynet"
local cluster = require "skynet.cluster"
local define = require "define"
local packet_def = require "game.packet"
local ai_human = require "scene.obj.span_human"
local class = require "class"
local AOI = require "scene.sceneaoi":getinstance()
local scenecore = require "scene.scenecore"
local spanscenecore = class("spanscenecore", scenecore)

function spanscenecore:getinstance()
    if spanscenecore.instance == nil then spanscenecore.instance = spanscenecore.new() end
    return spanscenecore.instance
end

function spanscenecore:init(conf)
    local scene_id = conf.id
    local sceneInfo = skynet.call(".CfgDB", "lua", "get_scene_info")
    local key = string.format("scene%d", scene_id)
    local scene_conf = table.clone(sceneInfo[key])
    scene_conf.id = scene_id
    scene_conf.world_id = conf.world_id
    self:load(scene_conf)
end

function spanscenecore:get_type()
    return 4
end

function spanscenecore:get_is_t_server()
    return 1
end

function spanscenecore:create_human(...) return ai_human.new(..., self) end

function spanscenecore:player_enter_scene(player_data, node_name, teaminfo, guildinfo, is_first_login)
    -- print("scenecore:player_enter_scene")
	local guid = player_data.attrib.guid
    local old_obj = self:get_obj_by_guid(guid)
	if old_obj then
		return
	end
    -- assert(old_obj == nil, player_data.attrib.guid)
    local obj_id = self:gen_obj_id()
	if not obj_id then
		return
	end
    -- assert(obj_id, "gen_obj_id fail")
    player_data.obj_id = obj_id
    player_data.node_name = node_name
    player_data.guid = guid
    local obj = self:create_human(player_data)
    obj:set_enter_scene_time()
    obj:set_server_id(player_data.server_id)
    self.objs[obj_id] = obj
    self:on_obj_id_occupated(obj)
    self.guid2objs[guid] = obj_id
    pcall(AOI.enter, AOI, obj)
    self:send_enter_scene(obj_id, obj_id, is_first_login)
    local r, err = pcall(self.init_human, self, obj, player_data, teaminfo, guildinfo, obj_id)
    if not r then
        skynet.loge("[SCENE_ENTER] init_human failed, scene =", tostring(self.id),
            " guid =", tostring(guid), " error =", tostring(err))
        self:delete_obj(obj)
        return nil, self.client_res
    end
    return obj_id, self.client_res
end

function spanscenecore:send2client(obj_id, packet)
    local obj
    if type(obj_id) == "number" then
        obj = self.objs[obj_id]
    else
        obj = obj_id
    end
    if not obj or obj._leaving or obj._scene_detached
        or self:get_obj_by_id(obj:get_obj_id()) ~= obj then
        return false
    end
    --print("obj classname =", obj.classname)
    if obj:get_obj_type() == "human" then
        local node_name = obj:get_node_name()
        print("send2client node_name =", node_name, ";obj_id =", obj_id, ", obj_name =", obj:get_name(), ", xy_id =", packet.xy_id)
        if node_name then
            --print("send2client xy_id =", packet.xy_id)
            cluster.send(node_name, ".clusteragentproxy", "send2client", obj:get_guid(), packet.xy_id, packet)
            return true
        end
    end
    return false
end

function spanscenecore:broadcastall_with_xyid(xy_id, packet)
    for _, obj in pairs(self.objs) do
        if obj:get_obj_type() == "human" then
            self:send2client_with_xyid(obj, xy_id, packet)
        end
    end
end

function spanscenecore:send2client_with_xyid(obj_id, xy_id, packet)
    local obj
    if type(obj_id) == "number" then
        obj = self.objs[obj_id]
    else
        obj = obj_id
    end
    if not obj or obj._leaving or obj._scene_detached
        or self:get_obj_by_id(obj:get_obj_id()) ~= obj then
        return false
    end
    --print("obj classname =", obj.classname)
    if obj:get_obj_type() == "human" then
        local node_name = obj:get_node_name()
        print("send2client node_name =", node_name, ";obj_id =", obj_id, ", obj_name =", obj:get_name(), ", xy_id =", xy_id)
        if node_name then
            --print("send2client xy_id =", packet.xy_id)
            cluster.send(node_name, ".clusteragentproxy", "send2client", obj:get_guid(), xy_id, packet)
            return true
        end
    end
    return false
end

function spanscenecore:send_world(obj, _, ...)
    local node_name = obj:get_node_name()
    cluster.send(node_name, ".world", ...)
end

function spanscenecore:send_guild(obj, _, ...)
    local node_name = obj:get_node_name()
    cluster.send(node_name, ".Guildmanager", ...)
end
function spanscenecore:span_close()

end
return spanscenecore
