local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_xiaotianyi = class("owudang_xiaotianyi", script_base)
owudang_xiaotianyi.script_id = 012035
function owudang_xiaotianyi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Từ xưa đến nay, người Tu luyện ắt gặp phải chuyện tâm ma, vừa hay Thiên Sư bày đại trận ở núi Võ Đang, có cơ hội chiến thắng tâm ma, ngươi có muốn thử thực lực của mình chăng?")
    self:AddNumText("Đi thách thức tâm ma.", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function owudang_xiaotianyi:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 71 then
            self:BeginEvent(self.script_id)
            local strText = "Cái gọi là \"Tiên tu ngoại, hậu tu nội\", Cấp độ của ngươi chưa đến cấp 71, uổng công tiến vào, e rằng sẽ tẩu hỏa nhập ma đó."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 142, 91, 183)
        end
    end
end

return owudang_xiaotianyi
