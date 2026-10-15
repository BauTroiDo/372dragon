local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_xuefei = class("osuzhou_xuefei", script_base)
osuzhou_xuefei.script_id = 001056
function osuzhou_xuefei:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SQXL_20071011}")
    self:AddNumText("Ta muốn Sửa chữa Trang bị", 6, 1)
    self:AddNumText("Trang bị sửa chữa tửu quán", 11, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function osuzhou_xuefei:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19810313)
    end
    if index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_043}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return osuzhou_xuefei
