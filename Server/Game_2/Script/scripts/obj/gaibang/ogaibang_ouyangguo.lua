local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ogaibang_ouyangguo = class("ogaibang_ouyangguo", script_base)
ogaibang_ouyangguo.script_id = 010035
function ogaibang_ouyangguo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Bọn ác hầu kia vẫn thường lẻn vào tửu quán chúng ta trộm rượu, thật đáng ghét! Chúng ta đã dạy dỗ chúng mấy lần, vậy mà không biết đường lui còn dám đến tấn công Cái Bang Tổng đà, có muốn cho chúng biết tay không?")
    self:AddNumText("Đi chống trả ác hầu.", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function ogaibang_ouyangguo:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 11 then
            self:BeginEvent(self.script_id)
            local strText = "Đừng coi thường bọn ác hầu này, ta thấy Cấp độ của ngươi phải vượt qua cấp 11 rồi hãy đến tìm ta."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 140, 91, 151)
        end
    end
end

return ogaibang_ouyangguo
