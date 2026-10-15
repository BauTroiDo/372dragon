local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_xuanzheng = class("oshaolin_xuanzheng", script_base)
oshaolin_xuanzheng.script_id = 009035
function oshaolin_xuanzheng:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Chẳng hay vì duyên cớ gì, mà Mộc Nhân trong Mộc Nhân Hạng nhất thời mất kiểm soát, nay chạy loạn cả trong chùa. Thấy thí chủ từ bi hỷ xả, ta cho ngươi cơ hội rèn luyện, ngươi có bằng lòng không?")
    self:AddNumText("Đánh Mộc Nhân rèn luyện", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function oshaolin_xuanzheng:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 41 then
            self:BeginEvent(self.script_id)
            local strText = "Mộc Nhân trong chùa ta tuy dễ đánh, nhưng Cấp độ của thí chủ chưa đến 41, e rằng sức lực không kham nổi, theo lão tăng thì nên đợi một thời gian rồi hãy đến."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 139, 95, 141)
        end
    end
end

return oshaolin_xuanzheng
