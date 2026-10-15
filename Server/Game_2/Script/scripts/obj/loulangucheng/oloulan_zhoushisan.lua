local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oloulan_zhoushisan = class("oloulan_zhoushisan", script_base)
oloulan_zhoushisan.script_id = 001106
function oloulan_zhoushisan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{LLXL_081113_1}")
    self:AddNumText("Ta muốn Sửa chữa Trang bị", 6, 1)
    self:AddNumText("Tăng Số lần sửa chữa khả dụng", 6, 2)
    self:AddNumText("Trang bị sửa chữa tửu quán", 11, 12)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oloulan_zhoushisan:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:UICommand_AddInt(-1)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 19810313)
    elseif index == 2 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1004)
        return
    end
    if index == 12 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_043}#r")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
end

return oloulan_zhoushisan
