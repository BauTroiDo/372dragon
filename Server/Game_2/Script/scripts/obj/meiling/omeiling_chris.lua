local class = require "class"
local define = require "define"
local script_base = require "script_base"
local omeiling_chris = class("omeiling_chris", script_base)
function omeiling_chris:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("  Bạn hữu thân mến! Mau đến giúp ta với!")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

function omeiling_chris:OnDie(selfId, killerId) end

return omeiling_chris
