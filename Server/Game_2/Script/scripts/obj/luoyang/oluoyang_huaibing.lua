local class = require "class"
local define = require "define"
local script_base = require "script_base"
local oluoyang_huaibing = class("oluoyang_huaibing", script_base)
function oluoyang_huaibing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_luoyang_0008}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return oluoyang_huaibing
