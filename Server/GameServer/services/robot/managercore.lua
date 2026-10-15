local skynet = require "skynet"
local class = require "class"
local managercore = class("managercore")

function managercore:getinstance()
    if managercore.instance == nil then
        managercore.instance = managercore.new()
    end
    return managercore.instance
end

function managercore:init()
    for i = 1, 1 do
      local robot = skynet.newservice("robot")
      skynet.send(robot, "lua", "start")
    end
end

return managercore