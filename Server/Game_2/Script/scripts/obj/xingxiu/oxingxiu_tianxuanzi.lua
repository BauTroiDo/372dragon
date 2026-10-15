local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oxingxiu_tianxuanzi = class("oxingxiu_tianxuanzi", script_base)
oxingxiu_tianxuanzi.script_id = 016035
function oxingxiu_tianxuanzi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Mấy hôm trước Thương Long xuất hiện trên trời, Thần Mộc Vương Đỉnh của sư phụ ta lại phát ra tiếng vo ve, dẫn dụ vô số nhện khổng lồ, đây đúng là thời cơ tốt để Tu luyện, con có bằng lòng đi xem không?")
    self:AddNumText("Đả Tri Chu Tu luyện", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oxingxiu_tianxuanzi:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 51 then
            self:BeginEvent(self.script_id)
            local strText = "Những người trong giang hồ bước vào Tu luyện, phần lớn đều trên cấp 51, xem võ công của con bình thường, ta không dám dẫn con đi đâu."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 146, 91, 144)
        end
    end
end

return oxingxiu_tianxuanzi
