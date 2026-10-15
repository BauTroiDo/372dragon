local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_liuzhongfu = class("odali_liuzhongfu", script_base)
odali_liuzhongfu.script_id = 002092
function odali_liuzhongfu:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("    Lưu mỗ học cờ đến nay đã năm mươi hai năm, chưa từng gặp địch thủ. Chỉ là vài năm trước, từng bại dưới tay một vị Ly Sơn Tiên Mỗ, lúc đó mới biết trời ngoài còn có trời, người giỏi còn có người giỏi hơn.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_liuzhongfu
