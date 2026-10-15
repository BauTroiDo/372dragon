local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_shutong = class("oluoyang_shutong", script_base)
function oluoyang_shutong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText(
        "  Lão gia hoàn thành \"Tư Trị Thông Giám\" xong, thân thể đã rất suy yếu, còn thường xuyên vì quốc sự mà lo lắng, thật khiến người ta lo lắng a.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_shutong
