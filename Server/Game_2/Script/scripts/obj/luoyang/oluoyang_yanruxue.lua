--洛阳NPC
--颜如雪
--普通

local class = require "class"
local script_base = require "script_base"
local oluoyang_yanruxue = class("oluoyang_yanruxue", script_base)

function oluoyang_yanruxue:OnDefaultEvent(selfId, targetId)
	self:BeginEvent( targetId )
    self:AddText("  Hoa tựa lìa cành nước tự trôi, Nhẹ nhàng tóc biếc sầu tự khơi, Xuân ấm thu sương thương tà áo, Trăng tròn trăng khuyết móc cong trời. Đã không nơi tỏ nỗi sầu, Cớ sao không đổi kiểu đầu cho khuây?")
    self:AddNumText("Sửa Kiểu Tóc tửu quán", 11, 10 )
    self:AddNumText("Sửa Kiểu Tóc",6,1)
    self:AddNumText( "Sửa đổi ảnh đại diện tửu quán", 11, 14 )
    self:EndEvent()
    self:DispatchEventList(selfId,targetId)
end

function oluoyang_yanruxue:OnEventRequest(selfId, targetId, arg, index)
    if index == 1 then
        self:BeginUICommand()
            self:UICommand_AddInt(targetId)
        self:EndUICommand()
        self:DispatchUICommand(selfId, 80101001)
        return
    end
end

return oluoyang_yanruxue