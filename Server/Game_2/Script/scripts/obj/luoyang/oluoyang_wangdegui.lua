local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_wangdegui = class("oluoyang_wangdegui", script_base)
oluoyang_wangdegui.script_id = 000050
oluoyang_wangdegui.g_shoptableindex = 11
function oluoyang_wangdegui:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Đến xem thử đi, binh khí ở chỗ ta đều là tốt nhất thành Lạc Dương.")
    self:AddNumText("Mua Binh Khí", 7, 100)
    self:AddNumText("Giám định tư chất", 6, 101)
    self:AddNumText("Giám định lại Trang bị tư chất", 6, 102)
    self:AddNumText("Trang bị Giám định tư chất tửu quán", 11, 105)
    self:AddNumText("Giám định lại Trang bị tư chất tửu quán", 11, 106)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oluoyang_wangdegui:OnEventRequest(selfId, targetId, arg, index)
    if index == 105 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_081}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    if index == 106 then
        self:BeginEvent(self.script_id)
        self:AddText("#{function_help_097}")
        self:EndEvent()
        self:DispatchEventList(selfId, targetId)
        return
    end
    local key = index
    if key == 100 then
        self:DispatchShopItem(selfId, targetId, self.g_shoptableindex)
    elseif key == 101 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 1001)
    elseif key == 102 then
        self:BeginUICommand()
        self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 112233)
    end
end

return oluoyang_wangdegui
