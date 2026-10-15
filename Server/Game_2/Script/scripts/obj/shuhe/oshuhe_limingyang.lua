local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_limingyang = class("oshuhe_limingyang", script_base)
oshuhe_limingyang.script_id = 001172
oshuhe_limingyang.g_MsgInfo = {"#{SHGZ_0612_01}", "#{SHGZ_0620_01}", "#{SHGZ_0620_02}", "#{SHGZ_0620_03}"}

function oshuhe_limingyang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Tiến về Thương Sơn", 9, 3426)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_limingyang:OnEventRequest(selfId, targetId, arg, index)
    if index == 3426 then
        self:CallScriptFunction((400900), "TransferFunc", selfId, 25, 165, 53, 20)
        return
    end
end

function oshuhe_limingyang:MsgBox(selfId, targetId, msg)
    self:BeginEvent(self.script_id)
    self:AddText(msg)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshuhe_limingyang
