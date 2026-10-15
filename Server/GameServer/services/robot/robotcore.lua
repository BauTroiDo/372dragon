local skynet = require "skynet"
local bt = require "lbt"
local class = require "class"
local robotcore = class("robotcore")

function robotcore:getinstance()
    if robotcore.instance == nil then
        robotcore.instance = robotcore.new()
    end
    return robotcore.instance
end

function robotcore:start()
    local config_path = skynet.getenv("config_path")
    local xml_path = string.format(config_path, "tlbb.xml")
    local file = io.open(xml_path)
    local xml = file:read("*a")
    self.agent = skynet.newservice("msgagent")
    skynet.call(self.agent, "lua", "set_client_address", skynet.self())
    self.login_nodes = require "bt.login_nodes".new()
    self.online_nodes = require "bt.online_nodes".new()
    self.login_nodes:set_robot(self)
    self.online_nodes:set_robot(self)
    local factory = bt.BehaviorTreeFactory.new()
    self.login_nodes:registerNodes(factory)
    self.online_nodes:registerNodes(factory)
    factory:registerBehaviorTreeFromText(xml)
    local tree = factory:createTree("main")
    while true do
        tree:tickWhileRunning()
        skynet.sleep(300)
    end
end

function robotcore:send(f, args)
    print("robotcore:send f =", f, ";args =", table.tostr(args))
    skynet.send(self.agent, "lua", "unpack_server_message", f, args)
end

function robotcore:GCConnect(args)
    self.login_nodes:set_connect_finish(args)
    self.attribs = {}
end

function robotcore:GCEnterScene(args)
    self.login_nodes:set_enter_scene_finish(args)
    self:set_attrib("sceneid", args.sceneid)
    self:set_attrib("world_pos", args.m_posWorld)
    self:set_attrib("my_obj_id", args.m_objID)
    self.scene_address = string.format(".SCENE_%d", args.sceneid)
    self.scene = require "robot.world.scene".new()
    local ok, navmapname = pcall(skynet.call, self.scene_address, "lua", "get_navmapname")
    self.scene:LoadNavMesh(ok and navmapname or nil)
end

function robotcore:GCCharMove(args)
  local obj_id = self:get_attrib("my_obj_id")
  if args.m_objID == obj_id then
    self:set_attrib()
  end
end

function robotcore:set_attrib(key, value)
  self.attribs[key] = value
end

function robotcore:get_attrib(key)
  return self.attribs[key]
end

function robotcore:findpath(tar)
  local from = self:get_attrib("world_pos")
  local path = self.scene:FindPath(from, tar)
  return path
end

function robotcore:sync_world_pos()
  local my_obj_id = self:get_attrib("my_obj_id")
  local world_pos = skynet.call(self.scene_address, "lua", "get_obj_world_pos", my_obj_id)
  self:set_attrib("world_pos", world_pos)
end

function robotcore:process_cmd(cmd, args)
    local f = self[cmd]
    if f then
        f(self, args)
    else
        print("unsupport cmd =", cmd, ";args =", table.tostr(args))
    end
end

return robotcore
