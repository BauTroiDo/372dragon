local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_fanyicheng = class("oluoyang_fanyicheng", script_base)
oluoyang_fanyicheng.script_id = 143
oluoyang_fanyicheng.g_EventList = {808008, 808009}

function oluoyang_fanyicheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Ta là sứ tiếp đón di dân, nếu ngươi mới chuyển tới, cần giúp gì cứ nói.")
    for i, eventId in pairs(self.g_EventList) do
        self:CallScriptFunction(eventId, "OnEnumerate", self, selfId, targetId)
    end
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_fanyicheng:OnEventRequest(selfId, targetId, arg, index)
    for i, findId in pairs(self.g_EventList) do
        if arg == findId then
            self:CallScriptFunction(arg, "OnDefaultEvent", selfId, targetId, arg, index)
            return
        end
    end
end

return oluoyang_fanyicheng
