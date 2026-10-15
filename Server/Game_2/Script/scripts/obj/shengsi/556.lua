local class = require "class"
local define = require "define"
local script_base = require "script_base"
local shaxing = class("shaxing", script_base)
function shaxing:OnDefaultEvent(selfId, targetId)
    self:BeginEvent(self.script_id)
    self:AddText("#{SXRW_090119_068}")
    self:EndEvent()
    self:DispatchEventList(selfId, targetId)
end

return shaxing
