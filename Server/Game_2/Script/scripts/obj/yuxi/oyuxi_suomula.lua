local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oyuxi_suomula = class("oyuxi_suomula", script_base)

function oyuxi_suomula:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Lão phu năm đó tuổi trẻ khí thịnh, từng làm một con Chung Quỳ biết bắt chuột cho Thẩm đại nhân xem. Không biết là hắn thật sự thấy không tồi, hay là cố ý làm nhục ta, chuyện này đã được hắn viết vào \"Mộng Khê Bút Đàm\". Giờ nhìn lại con Chung Quỳ đó, quả thực chỉ là trò đùa con trẻ...#r Haizz, con người thật sự không thể không cẩn trọng mà.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oyuxi_suomula
