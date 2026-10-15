local skynet = require "skynet"
require "skynet.manager"
local define = require "define"
local class = require "class"
local copyscenemanager_core = require "copyscenemanager_core"
local spancopyscenemanager_core = class("spancopyscenemanager_core", copyscenemanager_core)

function spancopyscenemanager_core:getinstance()
    if spancopyscenemanager_core.instance == nil then
        spancopyscenemanager_core.instance = spancopyscenemanager_core.new()
    end
    return spancopyscenemanager_core.instance
end

function spancopyscenemanager_core:init(conf)
    skynet.logi("spancopyscenemanager_core init")
    self.world_id = conf.world_id
    for i = 1, define.MAX_SCENE do
        local handle = skynet.newservice("spancopyscene")
        local alias = skynet.call(handle, "lua", "register", i + define.SPAN_COPY_SCENE_BEGIN)
        skynet.call(".cluster_agent", "lua", "server_add", alias)
        skynet.call(handle, "lua", "init")
        self.load[i] = handle
        self.sleeping[handle] = i
    end
    skynet.timeout(self.delta_time, function()
        self:safe_message_update()
    end)
end

return spancopyscenemanager_core