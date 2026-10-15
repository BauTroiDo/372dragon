local class = require "class"
local define = require "define"
local script_base = require "script_base"
local owudang_dizi_1 = class("owudang_dizi_1", script_base)
function owudang_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Viên chuyển như ý, thanh tĩnh vô vi, nơi đây chính là Võ Đang sơn. Nếu ngươi Yêu cầu trợ giúp, xin đến gần sơn môn tìm Tri khách đạo nhân giúp đỡ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return owudang_dizi_1
