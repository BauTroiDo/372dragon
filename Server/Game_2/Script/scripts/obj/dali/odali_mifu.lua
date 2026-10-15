local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_mifu = class("odali_mifu", script_base)
function odali_mifu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Thương Sơn không mực ngàn thu họa, Nhĩ Hải vô huyền vạn cổ cầm. Đại Lý quốc này quả nhiên là một nơi tốt, Vương đại tướng quân thật có nhãn lực, lại có thể chọn nơi này ẩn cư.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_mifu
