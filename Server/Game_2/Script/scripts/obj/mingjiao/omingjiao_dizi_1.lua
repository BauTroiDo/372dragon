local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omingjiao_dizi_1 = class("omingjiao_dizi_1", script_base)
function omingjiao_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Quang Minh Điện là nơi quan trọng, không được tự tiện đi lại! Nếu ngươi Yêu cầu giúp đỡ, hãy đến gần đại môn tìm Tri khách giúp.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omingjiao_dizi_1
