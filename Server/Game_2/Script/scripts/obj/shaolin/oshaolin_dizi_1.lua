local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oshaolin_dizi_1 = class("oshaolin_dizi_1", script_base)
function oshaolin_dizi_1:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Nơi đây chính là võ lâm thánh địa Thiếu Lâm Tự. Nếu như ngươi yêu cầu giúp đỡ, hãy đến gần cửa chùa tìm Tri khách tăng giúp một tay.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oshaolin_dizi_1
