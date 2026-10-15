local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_chuqian = class("osuzhou_chuqian", script_base)
function osuzhou_chuqian:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Trên có thiên đường, dưới có Tô Hàng. Tô Châu của cảnh đẹp, ngươi đã từng thấy qua chưa?")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_chuqian
