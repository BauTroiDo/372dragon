local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_hufa = class("omeiling_hufa", script_base)
function omeiling_hufa:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Lật mình rồi! Lật mình rồi! Chúng ta phải làm chủ thôi!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return omeiling_hufa
