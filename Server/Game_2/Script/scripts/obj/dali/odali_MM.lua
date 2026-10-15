local class = require "class"
local define = require "define"
local script_base = require "script_base"
local odali_MM = class("odali_MM", script_base)
function odali_MM:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{OBJ_dali_0031}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return odali_MM
