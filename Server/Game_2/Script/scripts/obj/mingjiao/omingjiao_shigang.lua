local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_shigang = class("omingjiao_shigang", script_base)
omingjiao_shigang.script_id = 011035
function omingjiao_shigang:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Quan binh lại đến vây quét Quang Minh Điện, thật là phiền phức, nhưng đến toàn là những tên vô danh tiểu tốt, ngươi nguyện ý đi luyện luyện quyền cước không?")
    self:AddNumText("Đi chống đỡ cuộc vây quét.", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omingjiao_shigang:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 31 then
            self:BeginEvent(self.script_id)
            local strText = "Dẫu là vô danh tiểu tốt, cũng chớ nên khinh thường, ngươi còn chưa đến cấp 31, vì sự an toàn của ngươi, ta thấy vẫn nên luyện tập thêm rồi quay lại."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 141, 97, 157)
        end
    end
end

return omingjiao_shigang
