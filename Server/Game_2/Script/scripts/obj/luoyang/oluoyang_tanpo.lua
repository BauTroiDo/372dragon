local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_tanpo = class("oluoyang_tanpo", script_base)
function oluoyang_tanpo:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0013}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_tanpo
