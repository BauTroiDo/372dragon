local skynet = require "skynet"
local lbt = require "lbt"
local NodeStatus = lbt.NodeStatus
local class = require "class"
local login_nodes = class("login_nodes")

function login_nodes:ctor()
    self.guid = nil
    self.connect_finish = false
    self.enter_scene_finish = false
end

function login_nodes:set_robot(robot)
    assert(self.robot == nil)
    self.robot = robot
end

function login_nodes:HaveGUID()
    return self.guid and NodeStatus.SUCCESS or NodeStatus.FAILURE
end

function login_nodes:IsConnectFinish()
    return self.connect_finish and NodeStatus.SUCCESS or NodeStatus.FAILURE
end

function login_nodes:IsEnterSceneFinish()
    return self.enter_scene_finish and NodeStatus.SUCCESS or NodeStatus.FAILURE
end

function login_nodes:SelectCharacterGUID()
    self.guid = 100015
    return NodeStatus.SUCCESS
end

function login_nodes:Connect()
    self.robot:send("CGConnect", { guid = self.guid })
    return NodeStatus.SUCCESS
end

function login_nodes:set_connect_finish()
    self.connect_finish = true
end

function login_nodes:EnterScene()
    self.robot:send("CGEnterScene", {})
    return NodeStatus.SUCCESS
end

function login_nodes:set_enter_scene_finish()
    self.enter_scene_finish = true
end

function login_nodes:registerNodes(factory)
    factory:registerSimpleCondition("HaveGUID", self, self.HaveGUID)
    factory:registerSimpleCondition("IsConnectFinish", self, self.IsConnectFinish)
    factory:registerSimpleCondition("IsEnterSceneFinish", self, self.IsEnterSceneFinish)
    factory:registerSimpleAction("SelectCharacterGUID", self, self.SelectCharacterGUID)
    factory:registerSimpleAction("Connect", self, self.Connect)
    factory:registerSimpleAction("EnterScene", self, self.EnterScene)
end

return login_nodes