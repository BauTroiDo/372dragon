local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_caibingchen = class("oluoyang_caibingchen", script_base)
function oluoyang_caibingchen:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0024}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_caibingchen
