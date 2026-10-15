local class = require "class"
local define = require "define"
local script_base = require "script_base"
local osuzhou_chaobuzhi = class("osuzhou_chaobuzhi", script_base)
function osuzhou_chaobuzhi:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Tài hoa của Trương Lôi huynh và Hạ Niên huynh đều hơn ta rất nhiều.")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return osuzhou_chaobuzhi
