local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshuhe_xiongjian = class("oshuhe_xiongjian", script_base)
oshuhe_xiongjian.script_id = 001178
oshuhe_xiongjian.g_MsgInfo = {"#{SHGZ_0612_04}", "#{SHGZ_0620_10}", "#{SHGZ_0620_11}", "#{SHGZ_0620_12}"}

function oshuhe_xiongjian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    local msgidx = math.random(#(self.g_MsgInfo))
    self:AddText(self.g_MsgInfo[msgidx])
    self:AddNumText("Trang bị tư chất giám định", 6, 1)
    self:AddNumText("Trang bị Giám định tư chất tửu quán", 11, 3)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshuhe_xiongjian:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1001)
    elseif index == 3 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_081}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return oshuhe_xiongjian
