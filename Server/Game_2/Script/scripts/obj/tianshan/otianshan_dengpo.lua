local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianshan_dengpo = class("otianshan_dengpo", script_base)
otianshan_dengpo.script_id = 017035
function otianshan_dengpo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Ta, Thiên Sơn, vốn dĩ nước sông không phạm nước giếng với những Tuyết Quái kia, nhưng lũ chúng càng ngày càng tàn bạo, Lão Lão đã dùng kế dẫn chúng lên Linh Thứu Phong, giờ chỉ còn trông cậy vào ngươi thôi.")
    self:AddNumText("Đi tiêu diệt Tuyết Quái", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianshan_dengpo:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 61 then
            self:BeginEvent(self.script_id)
            local strText = "Những Tuyết Quái này sức mạnh vô cùng, Cấp độ của ngươi chưa đến cấp 61, dẫn ngươi đi thật sự là nguy hiểm."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 147, 90, 116)
        end
    end
end

return otianshan_dengpo
