local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oliaoxi_liaobing = class("oliaoxi_liaobing", script_base)
function oliaoxi_liaobing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Đại Liêu ta tập trung một lượng lớn tinh nhuệ, gây áp lực lên Nhạn Môn Quan; Liêu Tây chỉ còn lại chúng ta, những kẻ già yếu này, ứng phó với đám mã phỉ thần long kiến thủ bất kiến vĩ #của#.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oliaoxi_liaobing
