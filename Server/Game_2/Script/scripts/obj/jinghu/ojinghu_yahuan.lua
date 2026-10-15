local class = require "class"
local define = require "define"
local script_base = require "script_base"
local ojinghu_yahuan = class("ojinghu_yahuan", script_base)
function ojinghu_yahuan:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Đoạn lão gia chưa đến, tiểu thư Thiên Thiên đều khóc, khuyên thế nào cũng không nín; nhưng khi Đoạn lão gia đến, tiểu thư liền vui vẻ ngay.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return ojinghu_yahuan
