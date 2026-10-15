local skynet = require "skynet"
local lbt = require "lbt"
local NodeStatus = lbt.NodeStatus
local class = require "class"
local define = require "define"
local online_nodes = class("online_nodes")
local XiaoChang_Pos = {x = 100, y = 170}

function online_nodes:ctor()
    self.is_moveing = false
end

function online_nodes:set_robot(robot)
    assert(self.robot == nil)
    self.robot = robot
end

function online_nodes:IsNearXiaoChang()
    print("IsNearXiaoChang")
    local sceneid = self.robot:get_attrib("sceneid")
    local world_pos = self.robot:get_attrib("world_pos")
    print("sceneid =", sceneid, "world_pos =", table.tostr(world_pos))
    if sceneid ~= 0 then
        return NodeStatus.FAILURE
    else
        local tar_pos = XiaoChang_Pos
        local distsq =
            (world_pos.x - tar_pos.x) * (world_pos.x - tar_pos.x) +
            (world_pos.x - tar_pos.x) * (world_pos.y - tar_pos.y)
        if distsq > 160 then
            return NodeStatus.FAILURE
        end
    end
    return NodeStatus.SUCCESS
end

function online_nodes:MoveToXiaoChang()
    if self.is_moveing then
        return NodeStatus.FAILURE
    end
    local from = self.robot:get_attrib("world_pos")
    local path = self.robot:findpath(XiaoChang_Pos)
    print("path =", table.tostr(path))
    local move = {}
    move.m_objID = self.robot:get_attrib("my_obj_id")
    move.posWorld = from
    move.targetPos = path
    move.handleID = define.INVAILD_ID
    self.robot:send("CGCharMove", move)
    self.is_moveing = true
    return NodeStatus.SUCCESS
end

function online_nodes:registerNodes(factory)
    factory:registerSimpleCondition("IsNearXiaoChang", self, self.IsNearXiaoChang)
    factory:registerSimpleAction("MoveToXiaoChang", self, self.MoveToXiaoChang)
end

return online_nodes
