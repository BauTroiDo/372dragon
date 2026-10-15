local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shaxing = class("shaxing", script_base)
shaxing.script_id = 760703
shaxing.g_eventList = { 892009 }

function shaxing:UpdateEventList(selfId, targetId)
    self:BeginEvent(self.script_id)
    local str = string.format("#{SXRW_090119_001}")
    self:AddText(str)
    self:AddNumText("Giới thiệu Sát Tinh", 11, 100)
    for i, eventId in pairs(self.g_eventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function shaxing:OnDefaultEvent(selfId, targetId)
    self:UpdateEventList(selfId, targetId)
end

function shaxing:OnEventRequest(selfId, targetId, arg, index)
    if index == 100 then
        self:BeginEvent(self.script_id)
        self:AddText("#{SXRW_090119_069}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 800 then
        self:BeginEvent(self.script_id)
        self:AddText("#{LHFD_160203_120}")
        self:AddNumText("#{LHFD_160203_106}", 6, 8000)
        self:AddNumText("#{LHFD_160203_107}", 6, 8001)
        self:AddNumText("#{LHFD_160203_108}", 6, 8002)
        self:AddNumText("#{LHFD_160203_109}", 6, 8003)
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    for i, findId in pairs(self.g_eventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnEventRequest", selfId, targetId, arg, index, self.script_id)
            return
        end
    end
end

return shaxing
