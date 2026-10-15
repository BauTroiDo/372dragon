local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_helingzhi = class("oluoyang_helingzhi", script_base)
oluoyang_helingzhi.script_id = 000087
oluoyang_helingzhi.g_eventList = {801011}

function oluoyang_helingzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Chỉ cần ngươi có thuốc nhuộm tóc là có thể thay đổi màu tóc.")
    self:AddNumText("Sửa Màu Tóc tửu quán", 11, 10)
    self:AddNumText("Sửa Màu Tóc", 6, 2)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_helingzhi:OnEventRequest(selfId, targetId, arg, index)
    if index == 10 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_060}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 2 then
        self:CallScriptFunction(801011, "OnEnumerate", self, selfId, targetId)
        return
    end
end

return oluoyang_helingzhi
