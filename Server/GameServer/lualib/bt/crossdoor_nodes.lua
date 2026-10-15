local skynet = require "skynet"
local lbt = require "lbt"
local NodeStatus = lbt.NodeStatus
local class = require "class"
local crossdoor_nodes = class("crossdoor_nodes")

function crossdoor_nodes:ctor()
    self:reset()
end

local function SleepMS(ms)
    --skynet.sleep(ms * 10)
end

function crossdoor_nodes:isDoorClosed()
    SleepMS(200)
    local result = (not self._door_open and NodeStatus.SUCCESS or NodeStatus.FAILURE)
    print("crossdoor_nodes:isDoorClosed =", result)
    return result
end

function crossdoor_nodes:passThroughDoor()
    print("crossdoor_nodes:passThroughDoor")
    SleepMS(500)
    return (self._door_open and NodeStatus.SUCCESS or NodeStatus.FAILURE)
end

function crossdoor_nodes:openDoor()
    print("crossdoor_nodes:openDoor")
    SleepMS(500)
    if self._door_locked then
        return NodeStatus.FAILURE
    else
        self._door_open = true
        return NodeStatus.SUCCESS
    end
end

function crossdoor_nodes:pickLock()
    print("crossdoor_nodes:pickLock self._pick_attempts =", self._pick_attempts)
    SleepMS(500)
    if self._pick_attempts > 3 then
        self._door_locked = false
        self._door_open = true
    end
    self._pick_attempts = self._pick_attempts + 1
    return (self._door_open and NodeStatus.SUCCESS or NodeStatus.FAILURE)
end

function crossdoor_nodes:smashDoor()
    print("crossdoor_nodes:smashDoor")
    self._door_locked = false
    self._door_open = true
    return NodeStatus.SUCCESS
end

function crossdoor_nodes:registerNodes(factory)
    factory:registerSimpleCondition("IsDoorClosed", self, self.isDoorClosed)
    factory:registerSimpleAction("PassThroughDoor", self, self.passThroughDoor)
    factory:registerSimpleAction("OpenDoor", self, self.openDoor)
    factory:registerSimpleAction("PickLock", self, self.pickLock)
    factory:registerSimpleCondition("SmashDoor", self, self.smashDoor)
end

function crossdoor_nodes:reset()
    self._door_locked = true
    self._door_open = false
    self._pick_attempts = 0
end


return crossdoor_nodes