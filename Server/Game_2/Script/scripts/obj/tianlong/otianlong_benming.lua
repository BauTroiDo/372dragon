local class = require "class"
local define = require "define"
local script_base = require "script_base"
local otianlong_benming = class("otianlong_benming", script_base)
otianlong_benming.script_id = 013035
function otianlong_benming:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("Lão tăng gần đây tham phá Huyền Cơ của Hàn Ngọc Tháp, liễu nhân liễu quả, vô danh vô tướng, ngươi muốn khiêu chiến Ma Đạo Khôi Lỗi Đế trong truyền thuyết không?")
    self:AddNumText("Đến đại chiến khôi lỗi.", 10, 0)
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function otianlong_benming:OnEventRequest(selfId, targetId, arg, index)
    if index == 0 then
        if self:GetLevel(selfId) < 91 then
            self:BeginEvent(self.script_id)
            local strText = "Thí chủ này Cấp độ chưa đến cấp 91, tiến vào ảo cảnh e rằng nguy hiểm khôn lường a."
            self:AddText(strText)
            self:EndEvent()
            self:DispatchEventList(selfId, targetId)
        else
            self:CallScriptFunction((400900), "TransferFunc", selfId, 143, 95, 134)
        end
    end
end

return otianlong_benming
