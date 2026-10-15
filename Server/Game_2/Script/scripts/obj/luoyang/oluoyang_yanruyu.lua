--洛阳NPC
--颜如玉
--普通

local class = require "class"
local script_base = require "script_base"
local oluoyang_yanruyu = class("oluoyang_yanruyu", script_base)

function oluoyang_yanruyu:OnDefaultEvent(selfId, targetId)
	self:BeginEvent( targetId )
    self:AddText("  Tục ngữ nói, tướng do tâm sinh, khách quan có hài lòng với dung mạo của mình không, có muốn thay đổi một chút không?")
    self:AddNumText("Tu chỉnh dung mạo tửu quán", 11, 10 )
    self:AddNumText("Tu chỉnh dung mạo",6,1)
    self:AddNumText( "Sửa đổi ảnh đại diện tửu quán", 11, 14 )
    self:AddNumText("Sửa đổi ảnh đại diện",6,4)
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_yanruyu:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 80502901)
        return
    end
    if index == 4 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 80503001)
        return
    end
end

return oluoyang_yanruyu