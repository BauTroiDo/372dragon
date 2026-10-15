local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_liusanmei = class("oemei_liusanmei", script_base)
oemei_liusanmei.script_id = 015035
function oemei_liusanmei:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Nga My sơn từ xưa đã nổi danh bởi loài vượn, gần đây những Vượn hung ác này càng ngày càng quá quắt, lại dám đến bổn phái quấy phá, ngươi có nguyện ý thử đi đánh lui chúng không?")
    self:AddNumText("Đi đánh lui Vượn hung ác", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oemei_liusanmei:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 21 then
            self:BeginEvent(self.script_id)
            local strText = "Chớ nên coi thường những Vượn hung ác này, ta thấy Cấp độ ngươi vượt quá cấp 21 rồi hãy đến tìm ta."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 145, 89, 142)
        end
    end
end

return oemei_liusanmei
