local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oemei_dizi_1 = class("oemei_dizi_1", script_base)
function oemei_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Hoan nghênh ngươi đến Nga My sơn. Nếu ngươi Yêu cầu giúp đỡ, hãy đến gần sơn môn tìm Tri khách giúp đỡ.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oemei_dizi_1
