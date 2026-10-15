local skynet = require "skynet"
require "skynet.manager"
local class = require "class"
local sceneaoi = class("sceneaoi")

function sceneaoi:getinstance()
    if sceneaoi.instance == nil then
        sceneaoi.instance = sceneaoi.new()
    end
    return sceneaoi.instance
end

function sceneaoi:ctor()
    self.aoi = nil
end

function sceneaoi:init(core, conf)
    local name = conf["name"]
    self.core = core
    self.aoi = skynet.launch("caoi", name)
    skynet.send(self.aoi, "text", "register".. " " .. tostring(skynet.self()))
end

function sceneaoi:message_update()
    pcall(skynet.send, self.aoi, "text", "message")
end

-- aoi回调
function sceneaoi:aoicallback(cmd, w, m)
    local r, err = pcall(self.core.addaoiobj, self.core, w, m)
    if not r then
        print("sceneaoi:aoicallback error =", err, "w =", w, "m =", m, "cmd =", cmd)
    end
end

function sceneaoi:request(request)
    skynet.send(self.aoi, "text", request)
end

-- 添加到aoi
function sceneaoi:enter(obj)
    local obj_id = obj:get_obj_id()
    assert(obj_id > 0)
    --local name = obj:get_name()
    local pos = obj:get_world_pos()
    local mode = obj:get_aoi_mode()
    local request = string.format("update %d %s %f %f %f", obj_id, mode, pos.x, pos.y, 0)
    self:request(request)
    --print("sceneaoi:enter request =", request)
    --print("sceneaoi:enter obj =", obj_id, " name =", name)
end

-- 从aoi中移除
function sceneaoi:leave(obj)
    local obj_id = obj:get_obj_id()
    --local name = obj:get_name()
    local pos = obj:get_world_pos()
    local request = string.format("update %d d %f %f %f", obj_id, pos.x, pos.y, 0)
    self:request(request)
    --print("sceneaoi:leave request =", request)
    --print("sceneaoi:leave obj =", obj_id, " name =", name)
end

skynet.register_protocol {
    name = "text",
    id = skynet.PTYPE_TEXT,
    pack = function(text)
        return text
    end,
    unpack = function(buf, sz)
        return skynet.tostring(buf, sz)
    end
}

return sceneaoi
