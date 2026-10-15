local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tangong = class("oluoyang_tangong", script_base)
function oluoyang_tangong:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0012}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_tangong
